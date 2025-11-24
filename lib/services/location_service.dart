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
      print('❌ Location: Location services are disabled');
      return false;
    }

    // Check location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('❌ Location: Location permissions are denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('❌ Location: Location permissions are permanently denied');
      return false;
    }

    print('✅ Location: Permissions granted');
    return true;
  }

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) return null;

      print('📍 Location: Getting current position...');
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      print('✅ Location: Got position: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('❌ Location: Error getting current location: $e');
      return null;
    }
  }

  /// Convert coordinates to address
  Future<String?> getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      print('🗺️ Location: Converting coordinates to address...');
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isEmpty) {
        print('⚠️ Location: No placemarks found, using coordinates');
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
        print('⚠️ Location: No address components, using coordinates');
        return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
      }

      final address = addressComponents.join(', ');
      print('✅ Location: Address: $address');
      return address;
    } catch (e) {
      print('❌ Location: Error converting to address: $e');
      print('⚠️ Location: Falling back to coordinates');
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
      print('❌ Location: Error formatting address: $e');
      return null;
    }
  }
}
