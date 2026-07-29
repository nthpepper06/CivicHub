import '../../domain/models/report_detail.dart';
import '../../domain/models/report_status.dart';

class ReportDetailResponse {
  const ReportDetailResponse({
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
  final List<ReportImageResponse> images;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ReportDetailResponse.fromJson(Map<String, dynamic> json) {
    return ReportDetailResponse(
      id: _requiredInt(json['id']),
      title: _stringOrEmpty(json['title']),
      description: _stringOrEmpty(json['description']),
      address: _stringOrEmpty(json['address']),
      status: ReportStatus.fromApiValue(json['status']),
      latitude: _nullableDouble(json['latitude']),
      longitude: _nullableDouble(json['longitude']),
      categoryId: _nullableInt(json['categoryId']),
      categoryName: _nullableString(json['categoryName']),
      departmentId: _nullableInt(json['departmentId']),
      departmentName: _nullableString(json['departmentName']),
      citizenId: _nullableInt(json['citizenId']),
      citizenName: _nullableString(json['citizenName']),
      images: _imagesFromJson(json['images']),
      createdAt: _nullableDateTime(json['createdAt']),
      updatedAt: _nullableDateTime(json['updatedAt']),
    );
  }

  CitizenReportDetail toDomain() {
    return CitizenReportDetail(
      id: id,
      title: title,
      description: description,
      address: address,
      status: status,
      latitude: latitude,
      longitude: longitude,
      categoryId: categoryId,
      categoryName: categoryName,
      departmentId: departmentId,
      departmentName: departmentName,
      citizenId: citizenId,
      citizenName: citizenName,
      images: images.map((image) => image.toDomain()).toList(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static List<ReportImageResponse> _imagesFromJson(Object? value) {
    if (value == null) {
      return const [];
    }
    if (value is! List) {
      throw const FormatException('Invalid images field');
    }
    return value.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Invalid image item');
      }
      return ReportImageResponse.fromJson(item);
    }).toList();
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

  static double? _nullableDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
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

class ReportImageResponse {
  const ReportImageResponse({
    this.id,
    required this.url,
    required this.displayOrder,
  });

  final int? id;
  final String url;
  final int displayOrder;

  factory ReportImageResponse.fromJson(Map<String, dynamic> json) {
    return ReportImageResponse(
      id: ReportDetailResponse._nullableInt(json['id']),
      url: ReportDetailResponse._stringOrEmpty(json['url']),
      displayOrder:
          ReportDetailResponse._nullableInt(json['displayOrder']) ?? 0,
    );
  }

  ReportImage toDomain() {
    return ReportImage(id: id, url: url, displayOrder: displayOrder);
  }
}
