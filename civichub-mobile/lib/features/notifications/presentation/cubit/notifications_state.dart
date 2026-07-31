import 'package:equatable/equatable.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/models/citizen_notification.dart';

enum NotificationsStatus { initial, loading, success, failure }

class NotificationsState extends Equatable {
  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.notifications = const [],
    this.page = 0,
    this.totalElements = 0,
    this.totalPages = 0,
    this.hasReachedEnd = false,
    this.isRefreshing = false,
    this.unreadCount = 0,
    this.markingIds = const {},
    this.errorMessage,
    this.errorKind,
    this.markErrorMessage,
  });

  final NotificationsStatus status;
  final List<CitizenNotification> notifications;
  final int page;
  final int totalElements;
  final int totalPages;
  final bool hasReachedEnd;
  final bool isRefreshing;
  final int unreadCount;
  final Set<int> markingIds;
  final String? errorMessage;
  final ApiErrorKind? errorKind;
  final String? markErrorMessage;

  bool get isInitialLoading =>
      status == NotificationsStatus.loading &&
      notifications.isEmpty &&
      !isRefreshing;

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<CitizenNotification>? notifications,
    int? page,
    int? totalElements,
    int? totalPages,
    bool? hasReachedEnd,
    bool? isRefreshing,
    int? unreadCount,
    Set<int>? markingIds,
    Object? errorMessage = _unchanged,
    Object? errorKind = _unchanged,
    Object? markErrorMessage = _unchanged,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      page: page ?? this.page,
      totalElements: totalElements ?? this.totalElements,
      totalPages: totalPages ?? this.totalPages,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      unreadCount: unreadCount ?? this.unreadCount,
      markingIds: markingIds ?? this.markingIds,
      errorMessage: errorMessage == _unchanged
          ? this.errorMessage
          : errorMessage as String?,
      errorKind: errorKind == _unchanged
          ? this.errorKind
          : errorKind as ApiErrorKind?,
      markErrorMessage: markErrorMessage == _unchanged
          ? this.markErrorMessage
          : markErrorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    notifications,
    page,
    totalElements,
    totalPages,
    hasReachedEnd,
    isRefreshing,
    unreadCount,
    markingIds,
    errorMessage,
    errorKind,
    markErrorMessage,
  ];
}

const _unchanged = Object();
