import 'package:equatable/equatable.dart';

import 'location_point.dart';

class ReportMapPoint extends Equatable {
  const ReportMapPoint({
    required this.reportId,
    required this.point,
    required this.title,
    required this.statusKey,
    required this.statusLabel,
    this.category,
    this.department,
    this.address,
    this.createdAt,
  });

  final int reportId;
  final LocationPoint point;
  final String title;
  final String statusKey;
  final String statusLabel;
  final String? category;
  final String? department;
  final String? address;
  final DateTime? createdAt;

  String get locationLabel {
    final value = address?.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
    return point.coordinatesLabel;
  }

  String get semanticLabel =>
      'Report $reportId, ${title.isEmpty ? 'Untitled report' : title}, '
      'status $statusLabel, at $locationLabel';

  @override
  List<Object?> get props => [
    reportId,
    point,
    title,
    statusKey,
    statusLabel,
    category,
    department,
    address,
    createdAt,
  ];
}

class ReportMapPointResult extends Equatable {
  const ReportMapPointResult({required this.points, required this.excluded});

  final List<ReportMapPoint> points;
  final int excluded;

  @override
  List<Object?> get props => [points, excluded];
}
