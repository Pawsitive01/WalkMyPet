import 'dart:math' show sin, cos, sqrt, atan2, pi;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:walkmypet/services/location_service.dart';
import 'package:walkmypet/design_system.dart';

class LocationPickerResult {
  final double latitude;
  final double longitude;
  final String address;

  LocationPickerResult({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

class LocationPicker extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const LocationPicker({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final LocationService _locationService = LocationService();
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String _selectedAddress = 'Loading...';
  bool _isLoadingAddress = false;
  bool _isGettingCurrentLocation = false;

  // Default to San Francisco if no initial location
  static const _defaultLocation = LatLng(37.7749, -122.4194);

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLocation =
          LatLng(widget.initialLatitude!, widget.initialLongitude!);
      _updateAddress(_selectedLocation!);
    } else {
      // Try to get last known location first (instant), then get accurate location
      _getLocationProgressive();
    }
  }

  /// Progressive location loading (Uber-like): Show last known location instantly, then update with accurate location
  Future<void> _getLocationProgressive() async {
    setState(() => _isGettingCurrentLocation = true);

    // First, try to get last known location (instant)
    final lastKnown = await _locationService.getLastKnownLocation();
    if (lastKnown != null) {
      final location = LatLng(lastKnown.latitude, lastKnown.longitude);
      setState(() {
        _selectedLocation = location;
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(location, 15),
      );

      // Start loading address in background
      _updateAddress(location);
    }

    // Then get accurate current location
    final position = await _locationService.getCurrentLocation();

    if (position != null) {
      final location = LatLng(position.latitude, position.longitude);

      // Only update if location changed significantly (more than 50 meters)
      if (_selectedLocation == null ||
          _calculateDistance(_selectedLocation!, location) > 0.05) {
        setState(() {
          _selectedLocation = location;
        });

        // Smooth animation to new location
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(location, 15),
        );

        _updateAddress(location);
      }
    } else if (_selectedLocation == null) {
      // Only use default if we have no location at all
      setState(() {
        _selectedLocation = _defaultLocation;
      });
      _updateAddress(_defaultLocation);
    }

    setState(() => _isGettingCurrentLocation = false);
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingCurrentLocation = true);

    final position = await _locationService.getCurrentLocation();

    if (position != null) {
      final location = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedLocation = location;
      });

      // Smooth camera animation
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: location,
            zoom: 16,
            tilt: 0,
          ),
        ),
      );

      _updateAddress(location);
    }

    setState(() => _isGettingCurrentLocation = false);
  }

  /// Calculate distance between two points in km
  double _calculateDistance(LatLng start, LatLng end) {
    const earthRadius = 6371; // km
    final dLat = _toRadians(end.latitude - start.latitude);
    final dLng = _toRadians(end.longitude - start.longitude);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(start.latitude)) *
            cos(_toRadians(end.latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * (pi / 180);

  /// Update address with debouncing (Uber-like smooth experience)
  void _updateAddress(LatLng location) {
    setState(() {
      _isLoadingAddress = true;
      _selectedAddress = 'Getting address...';
    });

    // Use debounced address lookup to prevent excessive API calls
    _locationService.getDebouncedAddressFromCoordinates(
      location.latitude,
      location.longitude,
      onAddressReady: (address) {
        if (mounted) {
          setState(() {
            _selectedAddress = address ?? 'Address not found';
            _isLoadingAddress = false;
          });
        }
      },
    );
  }

  void _onMapTapped(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
    _updateAddress(location);
  }

  void _confirmLocation() {
    if (_selectedLocation != null) {
      // Ensure we have a valid address, fallback to coordinates if needed
      String finalAddress = _selectedAddress;
      if (finalAddress.isEmpty ||
          finalAddress == 'Loading...' ||
          finalAddress == 'Getting address...') {
        finalAddress = '${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}';
      }

      Navigator.pop(
        context,
        LocationPickerResult(
          latitude: _selectedLocation!.latitude,
          longitude: _selectedLocation!.longitude,
          address: finalAddress,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: DesignSystem.getBackground(isDark),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: DesignSystem.getSurface(isDark),
            shape: BoxShape.circle,
            border: Border.all(
              color: DesignSystem.getBorderColor(isDark),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: DesignSystem.getTextPrimary(isDark),
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'Select Location',
          style: TextStyle(
            fontSize: DesignSystem.h2,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: DesignSystem.getTextPrimary(isDark),
          ),
        ),
        actions: [
          if (!_isGettingCurrentLocation)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: DesignSystem.getSurface(isDark),
                shape: BoxShape.circle,
                border: Border.all(
                  color: DesignSystem.getBorderColor(isDark),
                  width: 1,
                ),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.my_location_rounded,
                  color: DesignSystem.success,
                  size: 20,
                ),
                onPressed: _getCurrentLocation,
                tooltip: 'Use current location',
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation ?? _defaultLocation,
              zoom: 15,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onTap: _onMapTapped,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            markers: _selectedLocation != null
                ? {
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: _selectedLocation!,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueViolet,
                      ),
                    ),
                  }
                : {},
          ),

          // Loading overlay for getting current location
          if (_isGettingCurrentLocation)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: DesignSystem.getSurface(isDark),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: DesignSystem.success,
                      ),
                      SizedBox(height: DesignSystem.space2),
                      Text(
                        'Getting your location...',
                        style: TextStyle(
                          color: DesignSystem.getTextPrimary(isDark),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom sheet with address
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          DesignSystem.surfaceDark,
                          DesignSystem.backgroundDark,
                        ]
                      : [
                          DesignSystem.surfaceLight,
                          DesignSystem.backgroundLight,
                        ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border(
                  top: BorderSide(
                    color: DesignSystem.getBorderColor(isDark),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              padding: EdgeInsets.only(
                top: DesignSystem.space3,
                left: DesignSystem.space3,
                right: DesignSystem.space3,
                bottom: MediaQuery.of(context).padding.bottom +
                    DesignSystem.space3,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: DesignSystem.getTextTertiary(isDark),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: DesignSystem.space3),

                  // Selected Location Header
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(DesignSystem.space1),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              DesignSystem.success
                                  .withValues(alpha: 0.2),
                              DesignSystem.success
                                  .withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius:
                              BorderRadius.circular(DesignSystem.radiusSmall),
                        ),
                        child: Icon(
                          Icons.location_on_rounded,
                          color: DesignSystem.success,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: DesignSystem.space1_5),
                      Text(
                        'Selected Location',
                        style: TextStyle(
                          fontSize: DesignSystem.h3,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: DesignSystem.getTextPrimary(isDark),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: DesignSystem.space2),

                  // Address Container
                  Container(
                    padding: EdgeInsets.all(DesignSystem.space2),
                    decoration: BoxDecoration(
                      color: DesignSystem.getSurface2(isDark),
                      borderRadius:
                          BorderRadius.circular(DesignSystem.radiusMedium),
                      border: Border.all(
                        color: DesignSystem.success
                            .withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (_isLoadingAddress)
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: DesignSystem.success,
                            ),
                          )
                        else
                          Icon(
                            Icons.place_rounded,
                            color: DesignSystem.success,
                            size: 16,
                          ),
                        SizedBox(width: DesignSystem.space1_5),
                        Expanded(
                          child: Text(
                            _selectedAddress,
                            style: TextStyle(
                              fontSize: DesignSystem.body,
                              fontWeight: FontWeight.w500,
                              color: DesignSystem.getTextPrimary(isDark),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: DesignSystem.space3),

                  // Confirm Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed:
                          _selectedLocation != null && !_isLoadingAddress
                              ? _confirmLocation
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignSystem.success,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            isDark ? Colors.grey[800] : Colors.grey[300],
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(DesignSystem.radiusLarge),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 24),
                          SizedBox(width: DesignSystem.space1_5),
                          const Text(
                            'Confirm Location',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _locationService.dispose();
    super.dispose();
  }
}
