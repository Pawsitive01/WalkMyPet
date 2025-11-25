import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  // Cache for address lookups to avoid excessive API calls
  final Map<String, String> _addressCache = {};
  Timer? _debounceTimer;

  /// Check and request location permissions
  Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Check location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get current location with optimized settings (Uber-like accuracy)
  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) return null;

      // Use best accuracy with timeout for better UX
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 10, // Only update if moved 10 meters
          timeLimit: Duration(seconds: 10), // Timeout after 10 seconds
        ),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () async {
          // Fallback to high accuracy if best takes too long
          return await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 5),
            ),
          );
        },
      );

      return position;
    } catch (e) {
      return null;
    }
  }

  /// Get last known location (instant, no loading)
  Future<Position?> getLastKnownLocation() async {
    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) return null;

      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      return null;
    }
  }

  /// Convert coordinates to address with caching
  Future<String?> getAddressFromCoordinates(
      double latitude, double longitude) async {
    // Create cache key with rounded coordinates
    final cacheKey = '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}';

    // Check cache first
    if (_addressCache.containsKey(cacheKey)) {
      return _addressCache[cacheKey];
    }

    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isEmpty) {
        return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
      }

      final placemark = placemarks.first;
      final addressComponents = [
        placemark.street,
        placemark.subLocality,
        placemark.locality,
        placemark.administrativeArea,
        placemark.postalCode,
      ].where((component) => component != null && component.isNotEmpty);

      if (addressComponents.isEmpty) {
        return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
      }

      final address = addressComponents.join(', ');

      // Cache the result
      _addressCache[cacheKey] = address;

      return address;
    } catch (e) {
      // Fallback to coordinates if geocoding fails
      return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
    }
  }

  /// Debounced address lookup (prevents excessive API calls during map dragging)
  Future<String?> getDebouncedAddressFromCoordinates(
    double latitude,
    double longitude, {
    Duration delay = const Duration(milliseconds: 500),
    required Function(String?) onAddressReady,
  }) async {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Create new timer
    final completer = Completer<String?>();

    _debounceTimer = Timer(delay, () async {
      final address = await getAddressFromCoordinates(latitude, longitude);
      onAddressReady(address);
      completer.complete(address);
    });

    return completer.future;
  }

  /// Get formatted address (shorter version)
  Future<String?> getFormattedAddress(
      double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isEmpty) return null;

      final placemark = placemarks.first;

      // Short format: Street, City
      final parts = [
        placemark.street,
        placemark.locality,
      ].where((component) => component != null && component.isNotEmpty);

      return parts.join(', ');
    } catch (e) {
      return null;
    }
  }

  /// Clear address cache
  void clearCache() {
    _addressCache.clear();
  }

  /// Dispose timers
  void dispose() {
    _debounceTimer?.cancel();
  }
}
