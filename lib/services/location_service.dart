import 'package:geolocator/geolocator.dart';

import '../models/report_model.dart';

/// Wraps device GPS access behind a small, mockable interface so screens
/// don't talk to `geolocator` directly.
class LocationService {
  /// Requests permission (if needed) and returns the current device
  /// location. Throws a [LocationServiceException] with a user-facing
  /// message on failure so the UI can display it directly.
  Future<ReportLocation> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceException(
        'Turn on location services to attach your location.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationServiceException('Location permission was denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationServiceException(
        'Location permission is permanently denied. Enable it in your device settings.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return ReportLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      label: 'Current location attached',
    );
  }
}

class LocationServiceException implements Exception {
  final String message;
  LocationServiceException(this.message);

  @override
  String toString() => message;
}
