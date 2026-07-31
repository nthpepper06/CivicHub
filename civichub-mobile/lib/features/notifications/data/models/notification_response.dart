import '../../../../core/network/api_exception.dart';
import '../../domain/models/citizen_notification.dart';
import '../../domain/models/notification_type.dart';

class NotificationResponse {
  const NotificationResponse({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    this.reportId,
    this.readAt,
    this.createdAt,
  });

  final int id;
  final CitizenNotificationType type;
  final String title;
  final String message;
  final int? reportId;
  final bool isRead;
  final DateTime? readAt;
  final DateTime? createdAt;

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    try {
      return NotificationResponse(
        id: _requiredPositiveInt(json['id']),
        type: CitizenNotificationType.fromApiValue(json['type']),
        title: _string(json['title']),
        message: _string(json['message']),
        reportId: _nullablePositiveInt(json['reportId']),
        isRead: _bool(json['read']),
        readAt: _nullableDateTime(json['readAt']),
        createdAt: _nullableDateTime(json['createdAt']),
      );
    } on FormatException {
      throw ApiException.invalidResponse;
    }
  }

  CitizenNotification toDomain() {
    return CitizenNotification(
      id: id,
      type: type,
      title: title,
      message: message,
      reportId: reportId,
      isRead: isRead,
      readAt: readAt,
      createdAt: createdAt,
    );
  }

  static int _requiredPositiveInt(Object? value) {
    final parsed = _nullableInt(value);
    if (parsed == null || parsed <= 0) {
      throw const FormatException('Missing positive notification id');
    }
    return parsed;
  }

  static int? _nullablePositiveInt(Object? value) {
    final parsed = _nullableInt(value);
    if (parsed == null || parsed <= 0) {
      return null;
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
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static String _string(Object? value) {
    if (value is String) {
      return value.trim();
    }
    return '';
  }

  static bool _bool(Object? value) {
    if (value is bool) {
      return value;
    }
    return false;
  }

  static DateTime? _nullableDateTime(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}
