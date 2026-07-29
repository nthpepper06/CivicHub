import 'package:equatable/equatable.dart';

import 'report_status.dart';

class CitizenReportDetail extends Equatable {
  const CitizenReportDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.address,
    required this.status,
    this.latitude,
    this.longitude,
    this.categoryId,
    this.categoryName,
    this.departmentId,
    this.departmentName,
    this.citizenId,
    this.citizenName,
    this.images = const [],
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String title;
  final String description;
  final String address;
  final ReportStatus status;
  final double? latitude;
  final double? longitude;
  final int? categoryId;
  final String? categoryName;
  final int? departmentId;
  final String? departmentName;
  final int? citizenId;
  final String? citizenName;
  final List<ReportImage> images;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    address,
    status,
    latitude,
    longitude,
    categoryId,
    categoryName,
    departmentId,
    departmentName,
    citizenId,
    citizenName,
    images,
    createdAt,
    updatedAt,
  ];
}

class ReportImage extends Equatable {
  const ReportImage({this.id, required this.url, required this.displayOrder});

  final int? id;
  final String url;
  final int displayOrder;

  @override
  List<Object?> get props => [id, url, displayOrder];
}
