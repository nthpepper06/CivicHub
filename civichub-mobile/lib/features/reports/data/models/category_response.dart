import '../../domain/models/report_category.dart';

class CategoryResponse {
  const CategoryResponse({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    required this.isActive,
  });

  final int id;
  final String name;
  final String? description;
  final String? icon;
  final bool isActive;

  factory CategoryResponse.fromJson(Map<String, dynamic> json) {
    return CategoryResponse(
      id: _requiredInt(json['id']),
      name: _stringOrEmpty(json['name']),
      description: _nullableString(json['description']),
      icon: _nullableString(json['icon']),
      isActive: json['isActive'] == true,
    );
  }

  ReportCategory toDomain() {
    return ReportCategory(
      id: id,
      name: name,
      description: description,
      icon: icon,
      isActive: isActive,
    );
  }

  static int _requiredInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    throw const FormatException('Missing category id');
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
}
