import 'package:equatable/equatable.dart';

import 'notification_type.dart';

class CitizenNotification extends Equatable {
  const CitizenNotification({
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

  CitizenNotification copyWith({
    CitizenNotificationType? type,
    String? title,
    String? message,
    Object? reportId = _unchanged,
    bool? isRead,
    Object? readAt = _unchanged,
    Object? createdAt = _unchanged,
  }) {
    return CitizenNotification(
      id: id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      reportId: reportId == _unchanged ? this.reportId : reportId as int?,
      isRead: isRead ?? this.isRead,
      readAt: readAt == _unchanged ? this.readAt : readAt as DateTime?,
      createdAt: createdAt == _unchanged
          ? this.createdAt
          : createdAt as DateTime?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    title,
    message,
    reportId,
    isRead,
    readAt,
    createdAt,
  ];
}

const _unchanged = Object();
