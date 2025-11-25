import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
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

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      return position;
    } catch (e) {
      return null;
    }
  }

  /// Convert coordinates to address
  Future<String?> getAddressFromCoordinates(
      double latitude, double longitude) async {
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
      return address;
    } catch (e) {
      // Fallback to coordinates if geocoding fails
      return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
    }
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
}
