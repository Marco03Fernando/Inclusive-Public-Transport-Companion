import 'dart:math';

import 'package:geolocator/geolocator.dart';

import '../models/report_model.dart';

/// One-time position reads behind a small, mockable interface so screens
/// don't talk to `geolocator` directly — deliberately not a continuous
/// stream (that's the location-sharing teammate's feature).
class LocationService {
  /// For distance-sorting Request Assistance. Returns null on
  /// denied/disabled permission rather than throwing, so a request can
  /// still be created without a location.
  Future<Position?> getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
    } catch (_) {
      return null;
    }
  }

  /// For attaching a location to a condition report. Requests permission
  /// (if needed) and throws a [LocationServiceException] with a
  /// user-facing message on failure so the UI can display it directly.
  Future<ReportLocation> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceException(
        'Location services are turned off. Please turn on GPS and try again.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationServiceException(
          'Location permission is required to use your current location.',
        );
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationServiceException(
        'Location permission is permanently denied. Enable it in your device settings.',
        permanentlyDenied: true,
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    return ReportLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      label: 'Current location attached',
    );
  }

  /// Opens the OS app-settings page (after a permanent permission denial).
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  /// Haversine distance in kilometers — plain math, no package needed.
  static double distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degToRad(double deg) => deg * pi / 180;
}

class LocationServiceException implements Exception {
  final String message;

  /// True when the user must re-enable the permission in system settings.
  final bool permanentlyDenied;

  LocationServiceException(this.message, {this.permanentlyDenied = false});

  @override
  String toString() => message;
}
