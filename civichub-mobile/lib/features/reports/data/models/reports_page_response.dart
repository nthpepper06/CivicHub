import '../../../../core/network/api_exception.dart';
import '../../domain/models/reports_page.dart';

class ReportsPageResponse<T> {
  const ReportsPageResponse({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.first,
    required this.last,
  });

  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool first;
  final bool last;

  factory ReportsPageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    final rawContent = json['content'];
    if (rawContent is! List) {
      throw ApiException.invalidResponse;
    }

    try {
      return ReportsPageResponse<T>(
        content: rawContent.map((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('Invalid page item');
          }
          return itemFromJson(item);
        }).toList(),
        page: _requiredInt(json['page']),
        size: _requiredInt(json['size']),
        totalElements: _requiredInt(json['totalElements']),
        totalPages: _requiredInt(json['totalPages']),
        first: _requiredBool(json['first']),
        last: _requiredBool(json['last']),
      );
    } on FormatException {
      throw ApiException.invalidResponse;
    }
  }

  ReportsPage<R> toDomain<R>(R Function(T item) convert) {
    return ReportsPage<R>(
      content: content.map(convert).toList(),
      page: page,
      size: size,
      totalElements: totalElements,
      totalPages: totalPages,
      first: first,
      last: last,
    );
  }

  static int _requiredInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    throw const FormatException('Missing integer page field');
  }

  static bool _requiredBool(Object? value) {
    if (value is bool) {
      return value;
    }
    throw const FormatException('Missing boolean page field');
  }
}
