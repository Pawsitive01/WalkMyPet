import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:walkmypet/models/booking_model.dart';
import 'package:walkmypet/models/walk_tracking_model.dart';
import 'package:walkmypet/design_system.dart';

class OwnerWalkTrackingScreen extends StatefulWidget {
  final Booking booking;

  const OwnerWalkTrackingScreen({
    super.key,
    required this.booking,
  });

  @override
  State<OwnerWalkTrackingScreen> createState() =>
      _OwnerWalkTrackingScreenState();
}

class _OwnerWalkTrackingScreenState extends State<OwnerWalkTrackingScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  StreamSubscription<DocumentSnapshot>? _trackingSubscription;
  WalkTracking? _walkTracking;
  Timer? _uiUpdateTimer;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isLoading = true;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _initializeTracking();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _trackingSubscription?.cancel();
    _uiUpdateTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeTracking() async {
    try {
      // Find active walk tracking for this booking
      final trackingQuery = await FirebaseFirestore.instance
          .collection('walk_tracking')
          .where('bookingId', isEqualTo: widget.booking.id)
          .where('status', whereIn: ['active', 'paused']).limit(1)
          .get();

      if (trackingQuery.docs.isEmpty) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showError('Walk has not started yet');
        }
        return;
      }

      final trackingDoc = trackingQuery.docs.first;

      // Listen to real-time updates
      _trackingSubscription = FirebaseFirestore.instance
          .collection('walk_tracking')
          .doc(trackingDoc.id)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists && mounted) {
          setState(() {
            _walkTracking = WalkTracking.fromFirestore(snapshot);
            _isLoading = false;
          });
          _updateMapElements();
        }
      });

      // Start UI update timer
      _uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) setState(() {});
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to load walk tracking: $e');
      }
    }
  }

  void _updateMapElements() {
    if (_walkTracking == null || _walkTracking!.locationHistory.isEmpty) return;

    final currentLocation = _walkTracking!.locationHistory.last.position;

    // Update markers
    _markers.clear();

    // Current location (walker)
    _markers.add(
      Marker(
        markerId: const MarkerId('walker_location'),
        position: currentLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: '${widget.booking.walkerName} & ${widget.booking.dogName}',
          snippet: 'Walking now',
        ),
      ),
    );

    // Start location
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

    // Update polyline
    if (_walkTracking!.locationHistory.length >= 2) {
      final points =
          _walkTracking!.locationHistory.map((loc) => loc.position).toList();

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
    }

    // Animate camera to current location
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(currentLocation, 16),
    );
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
        appBar: _buildAppBar(isDark),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: DesignSystem.ownerPrimary,
              ),
              const SizedBox(height: DesignSystem.space2),
              Text(
                'Loading walk tracking...',
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

    if (_walkTracking == null) {
      return Scaffold(
        backgroundColor: DesignSystem.getBackground(isDark),
        appBar: _buildAppBar(isDark),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.route_outlined,
                size: 64,
                color: DesignSystem.getTextTertiary(isDark),
              ),
              const SizedBox(height: DesignSystem.space2),
              Text(
                'Walk not started yet',
                style: TextStyle(
                  fontSize: DesignSystem.h3,
                  fontWeight: FontWeight.w700,
                  color: DesignSystem.getTextPrimary(isDark),
                ),
              ),
              const SizedBox(height: DesignSystem.space1),
              Text(
                'Your walker will start soon',
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

          // Top stats card
          Positioned(
            top: kToolbarHeight + 60,
            left: DesignSystem.space2,
            right: DesignSystem.space2,
            child: _buildStatsCard(isDark),
          ),

          // Bottom info card
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomCard(isDark),
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
      title: Text(
        'Live Walk Tracking',
        style: TextStyle(
          fontSize: DesignSystem.h3,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildMap() {
    if (_walkTracking == null || _walkTracking!.locationHistory.isEmpty) {
      return Container(
        color: DesignSystem.getSurface(Theme.of(context).brightness == Brightness.dark),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final currentLocation = _walkTracking!.locationHistory.last.position;

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: currentLocation,
        zoom: 16,
      ),
      onMapCreated: (controller) {
        _mapController = controller;
        _updateMapElements();
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
                      'with ${widget.booking.walkerName}',
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
                          _walkTracking!.isPaused ? 'PAUSED' : 'LIVE',
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
                  'Duration',
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

  Widget _buildBottomCard(bool isDark) {
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
            const SizedBox(height: DesignSystem.space2),

            // Info message
            Container(
              padding: const EdgeInsets.all(DesignSystem.space2),
              decoration: BoxDecoration(
                color: DesignSystem.ownerPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
                border: Border.all(
                  color: DesignSystem.ownerPrimary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: DesignSystem.ownerPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: DesignSystem.space1_5),
                  Expanded(
                    child: Text(
                      _walkTracking!.isPaused
                          ? 'Walk is currently paused'
                          : 'Your dog is enjoying a walk! Tracking live location...',
                      style: TextStyle(
                        fontSize: DesignSystem.small,
                        color: DesignSystem.getTextSecondary(isDark),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
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
                color: DesignSystem.ownerPrimary,
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
              progress >= 1.0 ? DesignSystem.warning : DesignSystem.ownerPrimary,
            ),
          ),
        ),
      ],
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
