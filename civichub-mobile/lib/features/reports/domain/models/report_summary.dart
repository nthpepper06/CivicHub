import 'package:equatable/equatable.dart';

import 'report_status.dart';

class CitizenReportSummary extends Equatable {
  const CitizenReportSummary({
    required this.id,
    required this.title,
    required this.address,
    required this.status,
    this.categoryId,
    this.categoryName,
    this.departmentId,
    this.departmentName,
    this.citizenId,
    this.citizenName,
    this.primaryImageUrl,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String title;
  final String address;
  final ReportStatus status;
  final int? categoryId;
  final String? categoryName;
  final int? departmentId;
  final String? departmentName;
  final int? citizenId;
  final String? citizenName;
  final String? primaryImageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
    id,
    title,
    address,
    status,
    categoryId,
    categoryName,
    departmentId,
    departmentName,
    citizenId,
    citizenName,
    primaryImageUrl,
    createdAt,
    updatedAt,
  ];
}
