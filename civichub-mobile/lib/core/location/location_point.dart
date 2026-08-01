import 'package:equatable/equatable.dart';

class LocationPoint extends Equatable {
  const LocationPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  bool get isValid =>
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  String get coordinatesLabel =>
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';

  String get fallbackAddress => 'Pinned location at $coordinatesLabel';

  @override
  List<Object?> get props => [latitude, longitude];
}
