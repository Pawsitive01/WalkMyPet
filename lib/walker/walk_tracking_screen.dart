import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:walkmypet/models/booking_model.dart';
import 'package:walkmypet/models/walk_tracking_model.dart';
import 'package:walkmypet/design_system.dart';

class WalkTrackingScreen extends StatefulWidget {
  final Booking booking;

  const WalkTrackingScreen({
    super.key,
    required this.booking,
  });

  @override
  State<WalkTrackingScreen> createState() => _WalkTrackingScreenState();
}

class _WalkTrackingScreenState extends State<WalkTrackingScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  WalkTracking? _walkTracking;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _updateTimer;
  String? _walkTrackingId;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  LatLng? _currentPosition;
  bool _isLoading = true;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _initializeWalkTracking();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _positionSubscription?.cancel();
    _updateTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeWalkTracking() async {
    try {
      // Check if walk tracking already exists
      final existingTracking = await FirebaseFirestore.instance
          .collection('walk_tracking')
          .where('bookingId', isEqualTo: widget.booking.id)
          .where('status', whereIn: ['active', 'paused']).limit(1)
          .get();

      if (existingTracking.docs.isNotEmpty) {
        // Resume existing walk
        _walkTrackingId = existingTracking.docs.first.id;
        setState(() {
          _walkTracking =
              WalkTracking.fromFirestore(existingTracking.docs.first);
          _isLoading = false;
        });
      } else {
        // Create new walk tracking
        await _startNewWalk();
      }

      // Start location tracking
      await _startLocationTracking();

      // Start timer for UI updates
      _startUpdateTimer();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to initialize walk tracking: $e');
      }
    }
  }

  Future<void> _startNewWalk() async {
    final position = await _getCurrentLocation();
    if (position == null) {
      throw Exception('Unable to get location');
    }

    final initialLocation = WalkLocation(
      position: LatLng(position.latitude, position.longitude),
      timestamp: DateTime.now(),
      accuracy: position.accuracy,
    );

    final walkTracking = WalkTracking(
      id: '',
      bookingId: widget.booking.id,
      walkerId: widget.booking.walkerId,
      ownerId: widget.booking.ownerId,
      status: WalkStatus.active,
      startedAt: DateTime.now(),
      locationHistory: [initialLocation],
      scheduledDuration: widget.booking.duration,
    );

    final docRef = await FirebaseFirestore.instance
        .collection('walk_tracking')
        .add(walkTracking.toFirestore());

    _walkTrackingId = docRef.id;

    setState(() {
      _walkTracking = walkTracking.copyWith(id: docRef.id);
      _currentPosition = initialLocation.position;
      _isLoading = false;
    });

    _updateMarkers();
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await Geolocator.requestPermission();
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      );
    } catch (e) {
      _showError('Failed to get location: $e');
      return null;
    }
  }

  Future<void> _startLocationTracking() async {
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((position) {
      _onLocationUpdate(position);
    });
  }

  void _startUpdateTimer() {
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _walkTracking != null) {
        setState(() {
          // Force UI rebuild every second to update timers
        });
      }
    });
  }

  Future<void> _onLocationUpdate(Position position) async {
    if (_walkTracking == null || !_walkTracking!.isActive) return;

    // Filter out inaccurate GPS readings (accuracy > 50 meters)
    if (position.accuracy > 50) {
      debugPrint('Ignoring inaccurate location: ${position.accuracy}m');
      return;
    }

    final newLocation = WalkLocation(
      position: LatLng(position.latitude, position.longitude),
      timestamp: DateTime.now(),
      accuracy: position.accuracy,
    );

    // Calculate distance from last location
    double segmentDistance = 0.0;
    if (_walkTracking!.locationHistory.isNotEmpty) {
      final lastLoc = _walkTracking!.locationHistory.last;
      segmentDistance = Geolocator.distanceBetween(
        lastLoc.position.latitude,
        lastLoc.position.longitude,
        newLocation.position.latitude,
        newLocation.position.longitude,
      );

      // Filter out unrealistic jumps (> 100m in 10 seconds suggests GPS error)
      final timeDiff = newLocation.timestamp.difference(lastLoc.timestamp).inSeconds;
      final speed = segmentDistance / timeDiff; // meters per second
      if (speed > 30) {
        // More than 30 m/s (108 km/h) is unrealistic for walking
        debugPrint('Ignoring unrealistic GPS jump: ${speed}m/s');
        return;
      }
    }

    final updatedHistory = [..._walkTracking!.locationHistory, newLocation];
    final distance = (_walkTracking!.totalDistance ?? 0.0) + segmentDistance;

    setState(() {
      _walkTracking = _walkTracking!.copyWith(
        locationHistory: updatedHistory,
        totalDistance: distance,
      );
      _currentPosition = newLocation.position;
    });

    _updateMarkers();
    _updatePolyline();
    _animateCamera(newLocation.position);

    // Batch update Firestore (reduce writes)
    if (_walkTrackingId != null) {
      await FirebaseFirestore.instance
          .collection('walk_tracking')
          .doc(_walkTrackingId)
          .update({
        'locationHistory': updatedHistory.map((loc) => loc.toMap()).toList(),
        'totalDistance': distance,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  void _updateMarkers() {
    if (_currentPosition == null) return;

    _markers.clear();
    _markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: _currentPosition!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: widget.booking.dogName,
          snippet: 'Currently walking',
        ),
      ),
    );

    if (_walkTracking != null && _walkTracking!.locationHistory.isNotEmpty) {
      final startLocation = _walkTracking!.locationHistory.first.position;
      _markers.add(
        Marker(
          markerId: const MarkerId('start_location'),
          position: startLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Start',
            snippet: 'Walk started here',
          ),
        ),
      );
    }

    if (mounted) setState(() {});
  }

  void _updatePolyline() {
    if (_walkTracking == null || _walkTracking!.locationHistory.length < 2) {
      return;
    }

    final points = _walkTracking!.locationHistory
        .map((loc) => loc.position)
        .toList();

    _polylines.clear();
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('walk_path'),
        points: points,
        color: DesignSystem.success,
        width: 4,
        patterns: [PatternItem.dot, PatternItem.gap(10)],
      ),
    );

    if (mounted) setState(() {});
  }

  void _animateCamera(LatLng position) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(position),
    );
  }

  Future<void> _togglePauseResume() async {
    if (_walkTracking == null || _walkTrackingId == null) return;

    HapticFeedback.mediumImpact();

    if (_walkTracking!.isPaused) {
      // Resume walk
      final pauseHistory = [..._walkTracking!.pauseHistory];
      if (pauseHistory.isNotEmpty) {
        final lastPause = pauseHistory.last;
        pauseHistory[pauseHistory.length - 1] = PauseRecord(
          pausedAt: lastPause.pausedAt,
          resumedAt: DateTime.now(),
        );
      }

      setState(() {
        _walkTracking = _walkTracking!.copyWith(
          status: WalkStatus.active,
          pauseHistory: pauseHistory,
        );
      });

      await FirebaseFirestore.instance
          .collection('walk_tracking')
          .doc(_walkTrackingId)
          .update({
        'status': 'active',
        'pauseHistory': pauseHistory.map((p) => p.toMap()).toList(),
      });
    } else {
      // Pause walk
      final pauseHistory = [
        ..._walkTracking!.pauseHistory,
        PauseRecord(pausedAt: DateTime.now()),
      ];

      setState(() {
        _walkTracking = _walkTracking!.copyWith(
          status: WalkStatus.paused,
          pauseHistory: pauseHistory,
        );
      });

      await FirebaseFirestore.instance
          .collection('walk_tracking')
          .doc(_walkTrackingId)
          .update({
        'status': 'paused',
        'pauseHistory': pauseHistory.map((p) => p.toMap()).toList(),
      });
    }
  }

  Future<void> _completeWalk() async {
    HapticFeedback.mediumImpact();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => _buildCompleteWalkDialog(),
    );

    if (confirm != true || _walkTrackingId == null) return;

    // Stop tracking
    await _positionSubscription?.cancel();
    _updateTimer?.cancel();

    // Update walk tracking
    await FirebaseFirestore.instance
        .collection('walk_tracking')
        .doc(_walkTrackingId)
        .update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });

    // Update booking status
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.booking.id)
        .update({
      'status': 'completed',
      'completedByWalkerAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Walk completed for ${widget.booking.dogName}!'),
          backgroundColor: DesignSystem.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: DesignSystem.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: DesignSystem.getBackground(isDark),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: DesignSystem.success,
              ),
              const SizedBox(height: DesignSystem.space2),
              Text(
                'Starting walk...',
                style: TextStyle(
                  fontSize: DesignSystem.body,
                  color: DesignSystem.getTextSecondary(isDark),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: DesignSystem.getBackground(isDark),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(isDark),
      body: Stack(
        children: [
          // Google Maps
          _buildMap(),

          // Bottom control panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildControlPanel(isDark),
          ),

          // Top stats card
          if (_walkTracking != null)
            Positioned(
              top: kToolbarHeight + 60,
              left: DesignSystem.space2,
              right: DesignSystem.space2,
              child: _buildStatsCard(isDark),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      systemOverlayStyle:
          isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      leading: Container(
        margin: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
          boxShadow: DesignSystem.shadowCard(Colors.black),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: DesignSystem.getTextPrimary(isDark),
              size: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMap() {
    if (_currentPosition == null) {
      return Container(
        color: DesignSystem.getSurface(
            Theme.of(context).brightness == Brightness.dark),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _currentPosition!,
        zoom: 16,
      ),
      onMapCreated: (controller) {
        _mapController = controller;
      },
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: true,
    );
  }

  Widget _buildStatsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(DesignSystem.space2),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.7)
            : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
        border: Border.all(
          color: DesignSystem.getBorderColor(isDark, opacity: 0.1),
        ),
        boxShadow: DesignSystem.shadowElevated(Colors.black),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: DesignSystem.ownerPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignSystem.radiusCompact),
                ),
                child: const Icon(
                  Icons.pets,
                  size: 20,
                  color: DesignSystem.ownerPrimary,
                ),
              ),
              const SizedBox(width: DesignSystem.space1_5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.booking.dogName,
                      style: TextStyle(
                        fontSize: DesignSystem.subheading,
                        fontWeight: FontWeight.w700,
                        color: DesignSystem.getTextPrimary(isDark),
                      ),
                    ),
                    Text(
                      widget.booking.ownerName,
                      style: TextStyle(
                        fontSize: DesignSystem.small,
                        color: DesignSystem.getTextSecondary(isDark),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _walkTracking!.isPaused
                          ? DesignSystem.warning.withValues(
                              alpha: 0.1 + (_pulseController.value * 0.1),
                            )
                          : DesignSystem.success.withValues(
                              alpha: 0.1 + (_pulseController.value * 0.1),
                            ),
                      borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _walkTracking!.isPaused
                                ? DesignSystem.warning
                                : DesignSystem.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _walkTracking!.isPaused ? 'PAUSED' : 'ACTIVE',
                          style: TextStyle(
                            fontSize: DesignSystem.small,
                            fontWeight: FontWeight.w800,
                            color: _walkTracking!.isPaused
                                ? DesignSystem.warning
                                : DesignSystem.success,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: DesignSystem.space2),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  Icons.timer_outlined,
                  'Elapsed',
                  _formatDuration(_walkTracking!.elapsedTime),
                  isDark,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: DesignSystem.getBorderColor(isDark, opacity: 0.2),
              ),
              Expanded(
                child: _buildStatItem(
                  Icons.route_outlined,
                  'Distance',
                  '${((_walkTracking!.totalDistance ?? 0) / 1000).toStringAsFixed(2)} km',
                  isDark,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: DesignSystem.getBorderColor(isDark, opacity: 0.2),
              ),
              Expanded(
                child: _buildStatItem(
                  Icons.schedule_outlined,
                  'Remaining',
                  _formatDuration(_walkTracking!.remainingTime),
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, bool isDark) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: DesignSystem.getTextTertiary(isDark),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: DesignSystem.body,
            fontWeight: FontWeight.w800,
            color: DesignSystem.getTextPrimary(isDark),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: DesignSystem.small,
            color: DesignSystem.getTextSecondary(isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildControlPanel(bool isDark) {
    if (_walkTracking == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(DesignSystem.space2),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(DesignSystem.radiusXL),
        ),
        boxShadow: DesignSystem.shadowElevated(Colors.black),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar
            _buildProgressBar(isDark),
            const SizedBox(height: DesignSystem.space3),

            // Control buttons
            Row(
              children: [
                // Pause/Resume button
                Expanded(
                  flex: 2,
                  child: _buildPauseResumeButton(isDark),
                ),
                const SizedBox(width: DesignSystem.space2),

                // Complete button
                Expanded(
                  child: _buildCompleteButton(isDark),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(bool isDark) {
    final progress = _walkTracking!.progress;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(_walkTracking!.elapsedTime),
              style: TextStyle(
                fontSize: DesignSystem.body,
                fontWeight: FontWeight.w700,
                color: DesignSystem.getTextPrimary(isDark),
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: DesignSystem.body,
                fontWeight: FontWeight.w700,
                color: DesignSystem.success,
              ),
            ),
            Text(
              _formatDuration(_walkTracking!.remainingTime),
              style: TextStyle(
                fontSize: DesignSystem.body,
                fontWeight: FontWeight.w700,
                color: DesignSystem.getTextSecondary(isDark),
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignSystem.space1),
        ClipRRect(
          borderRadius: BorderRadius.circular(DesignSystem.radiusPill),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: DesignSystem.getBorderColor(isDark, opacity: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1.0 ? DesignSystem.warning : DesignSystem.success,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPauseResumeButton(bool isDark) {
    final isPaused = _walkTracking!.isPaused;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: isPaused
            ? DesignSystem.successGradient
            : const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              ),
        borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
        boxShadow: DesignSystem.shadowGlow(
          isPaused ? DesignSystem.success : DesignSystem.warning,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _togglePauseResume,
          borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPaused
                    ? Icons.play_arrow_rounded
                    : Icons.pause_rounded,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                isPaused ? 'Resume Walk' : 'Pause Walk',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: DesignSystem.subheading,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompleteButton(bool isDark) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
        border: Border.all(
          color: DesignSystem.getBorderColor(isDark, opacity: 0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _completeWalk,
          borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
          child: Icon(
            Icons.check_circle_outline_rounded,
            color: DesignSystem.success,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildCompleteWalkDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: DesignSystem.getSurface(isDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignSystem.space3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: DesignSystem.successGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 32,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: DesignSystem.space2),
            Text(
              'Complete Walk?',
              style: TextStyle(
                fontSize: DesignSystem.h3,
                fontWeight: FontWeight.w800,
                color: DesignSystem.getTextPrimary(isDark),
              ),
            ),
            const SizedBox(height: DesignSystem.space1),
            Text(
              'Mark this walk as completed?',
              style: TextStyle(
                fontSize: DesignSystem.body,
                color: DesignSystem.getTextSecondary(isDark),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignSystem.space3),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: DesignSystem.getBorderColor(isDark, opacity: 0.2),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(DesignSystem.radiusSmall),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: DesignSystem.getTextSecondary(isDark),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: DesignSystem.space2),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: DesignSystem.successGradient,
                      borderRadius:
                          BorderRadius.circular(DesignSystem.radiusSmall),
                      boxShadow: DesignSystem.shadowGlow(DesignSystem.success),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context, true),
                        borderRadius:
                            BorderRadius.circular(DesignSystem.radiusSmall),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Center(
                            child: Text(
                              'Complete',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: DesignSystem.body,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}
