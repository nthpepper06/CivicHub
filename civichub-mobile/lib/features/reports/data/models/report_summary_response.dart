import '../../domain/models/report_status.dart';
import '../../domain/models/report_summary.dart';

class ReportSummaryResponse {
  const ReportSummaryResponse({
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

  factory ReportSummaryResponse.fromJson(Map<String, dynamic> json) {
    return ReportSummaryResponse(
      id: _requiredInt(json['id']),
      title: _stringOrEmpty(json['title']),
      address: _stringOrEmpty(json['address']),
      status: ReportStatus.fromApiValue(json['status']),
      categoryId: _nullableInt(json['categoryId']),
      categoryName: _nullableString(json['categoryName']),
      departmentId: _nullableInt(json['departmentId']),
      departmentName: _nullableString(json['departmentName']),
      citizenId: _nullableInt(json['citizenId']),
      citizenName: _nullableString(json['citizenName']),
      primaryImageUrl: _nullableString(json['primaryImageUrl']),
      createdAt: _nullableDateTime(json['createdAt']),
      updatedAt: _nullableDateTime(json['updatedAt']),
    );
  }

  CitizenReportSummary toDomain() {
    return CitizenReportSummary(
      id: id,
      title: title,
      address: address,
      status: status,
      categoryId: categoryId,
      categoryName: categoryName,
      departmentId: departmentId,
      departmentName: departmentName,
      citizenId: citizenId,
      citizenName: citizenName,
      primaryImageUrl: primaryImageUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static int _requiredInt(Object? value) {
    final parsed = _nullableInt(value);
    if (parsed == null) {
      throw const FormatException('Missing report id');
    }
    return parsed;
  }

  static int? _nullableInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return null;
  }

  static String _stringOrEmpty(Object? value) {
    return value is String ? value : '';
  }

  static String? _nullableString(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return null;
  }

  static DateTime? _nullableDateTime(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}
