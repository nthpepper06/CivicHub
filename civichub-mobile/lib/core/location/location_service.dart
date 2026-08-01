import 'package:geolocator/geolocator.dart';

import 'location_point.dart';

enum CivicLocationFailure {
  permissionDenied,
  permissionPermanentlyDenied,
  serviceDisabled,
  unavailable,
}

class CivicLocationException implements Exception {
  const CivicLocationException(this.failure);

  final CivicLocationFailure failure;

  String get message {
    return switch (failure) {
      CivicLocationFailure.permissionDenied =>
        'Location permission was denied. You can still select a point on the map.',
      CivicLocationFailure.permissionPermanentlyDenied =>
        'Location permission is permanently denied. Enable it in system settings or select a point on the map.',
      CivicLocationFailure.serviceDisabled =>
        'Location services are disabled. Turn on GPS or select a point on the map.',
      CivicLocationFailure.unavailable =>
        'Current location is unavailable right now. Select a point on the map instead.',
    };
  }
}

class CivicLocationService {
  const CivicLocationService();

  Future<LocationPoint> currentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw const CivicLocationException(
          CivicLocationFailure.serviceDisabled,
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw const CivicLocationException(
          CivicLocationFailure.permissionDenied,
        );
      }
      if (permission == LocationPermission.deniedForever) {
        throw const CivicLocationException(
          CivicLocationFailure.permissionPermanentlyDenied,
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      return LocationPoint(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on CivicLocationException {
      rethrow;
    } catch (_) {
      throw const CivicLocationException(CivicLocationFailure.unavailable);
    }
  }
}
