import 'dart:async';

import 'package:civichub_mobile/core/network/api_exception.dart';
import 'package:civichub_mobile/features/notifications/domain/models/citizen_notification.dart';
import 'package:civichub_mobile/features/notifications/domain/models/notification_type.dart';
import 'package:civichub_mobile/features/notifications/domain/models/notifications_page.dart';
import 'package:civichub_mobile/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:civichub_mobile/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:civichub_mobile/features/notifications/presentation/cubit/notifications_state.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeNotificationsRepository implements NotificationsRepository {
  FakeNotificationsRepository({
    List<NotificationsPage<CitizenNotification>>? pages,
    this.unreadCount = 1,
  }) : _pages = List.of(pages ?? [sampleNotificationsPage()]);

  final List<NotificationsPage<CitizenNotification>> _pages;
  final calls = <({int page, int size, String? sortBy, String? direction})>[];
  final markCalls = <int>[];
  int unreadCount;
  Object? error;
  Object? countError;
  Object? markError;
  Future<CitizenNotification>? pendingMarkResponse;

  @override
  Future<NotificationsPage<CitizenNotification>> getMyNotifications({
    required int page,
    required int size,
    bool? unread,
    String? type,
    String? sortBy,
    String? direction,
  }) async {
    calls.add((page: page, size: size, sortBy: sortBy, direction: direction));
    if (error != null) {
      throw error!;
    }
    return _pages.isEmpty
        ? sampleNotificationsPage(content: const [])
        : _pages.removeAt(0);
  }

  @override
  Future<int> getUnreadCount() async {
    if (countError != null) {
      throw countError!;
    }
    return unreadCount;
  }

  @override
  Future<CitizenNotification> markAsRead(int id) async {
    markCalls.add(id);
    if (markError != null) {
      throw markError!;
    }
    if (pendingMarkResponse != null) {
      return pendingMarkResponse!;
    }
    return sampleNotification(id: id, isRead: true);
  }
}

void main() {
  test('Initial load success includes unread count', () async {
    final repository = FakeNotificationsRepository(unreadCount: 2);
    final cubit = NotificationsCubit(notificationsRepository: repository);

    await cubit.loadInitial();

    expect(cubit.state.status, NotificationsStatus.success);
    expect(cubit.state.notifications, hasLength(1));
    expect(cubit.state.unreadCount, 2);
    expect(repository.calls.single.sortBy, 'createdAt');
  });

  test('Initial load empty is success with no notifications', () async {
    final repository = FakeNotificationsRepository(
      pages: [sampleNotificationsPage(content: const [])],
      unreadCount: 0,
    );
    final cubit = NotificationsCubit(notificationsRepository: repository);

    await cubit.loadInitial();

    expect(cubit.state.status, NotificationsStatus.success);
    expect(cubit.state.notifications, isEmpty);
    expect(cubit.state.unreadCount, 0);
  });

  test('Initial load failure emits friendly message', () async {
    final repository = FakeNotificationsRepository();
    repository.error = ApiException.network;
    final cubit = NotificationsCubit(notificationsRepository: repository);

    await cubit.loadInitial();

    expect(cubit.state.status, NotificationsStatus.failure);
    expect(cubit.state.errorKind, ApiErrorKind.network);
    expect(cubit.state.errorMessage, contains('Cannot load notifications'));
  });

  test('Retry and pull-to-refresh reload notifications and count', () async {
    final repository = FakeNotificationsRepository(
      pages: [
        sampleNotificationsPage(content: [sampleNotification(id: 1)]),
        sampleNotificationsPage(content: [sampleNotification(id: 2)]),
        sampleNotificationsPage(content: [sampleNotification(id: 3)]),
      ],
    );
    final cubit = NotificationsCubit(notificationsRepository: repository);

    await cubit.loadInitial();
    repository.unreadCount = 3;
    await cubit.refresh();
    await cubit.retry();

    expect(repository.calls, hasLength(3));
    expect(cubit.state.notifications.single.id, 3);
    expect(cubit.state.unreadCount, 3);
  });

  test('Mark unread notification as read decrements count', () async {
    final repository = FakeNotificationsRepository(unreadCount: 1);
    final cubit = NotificationsCubit(notificationsRepository: repository);

    await cubit.loadInitial();
    await cubit.markAsRead(cubit.state.notifications.single);

    expect(repository.markCalls, [1]);
    expect(cubit.state.notifications.single.isRead, isTrue);
    expect(cubit.state.unreadCount, 0);
  });

  test('Unread count does not decrement below zero', () async {
    final repository = FakeNotificationsRepository(unreadCount: 0);
    final cubit = NotificationsCubit(notificationsRepository: repository);

    await cubit.loadInitial();
    await cubit.markAsRead(cubit.state.notifications.single);

    expect(cubit.state.unreadCount, 0);
  });

  test('Mark-as-read failure preserves unread state', () async {
    final repository = FakeNotificationsRepository(unreadCount: 1);
    repository.markError = ApiException.server;
    final cubit = NotificationsCubit(notificationsRepository: repository);

    await cubit.loadInitial();
    await cubit.markAsRead(cubit.state.notifications.single);

    expect(cubit.state.notifications.single.isRead, isFalse);
    expect(cubit.state.unreadCount, 1);
    expect(cubit.state.markErrorMessage, contains('server'));
  });

  test('Duplicate mark-as-read request is prevented', () async {
    final completer = Completer<CitizenNotification>();
    final repository = FakeNotificationsRepository();
    repository.pendingMarkResponse = completer.future;
    final cubit = NotificationsCubit(notificationsRepository: repository);

    await cubit.loadInitial();
    final notification = cubit.state.notifications.single;
    final first = cubit.markAsRead(notification);
    final second = cubit.markAsRead(notification);
    await Future<void>.delayed(Duration.zero);
    completer.complete(sampleNotification(isRead: true));
    await first;
    await second;

    expect(repository.markCalls, [1]);
  });

  test('Already-read notification does not make a request', () async {
    final repository = FakeNotificationsRepository(
      pages: [
        sampleNotificationsPage(content: [sampleNotification(isRead: true)]),
      ],
    );
    final cubit = NotificationsCubit(notificationsRepository: repository);

    await cubit.loadInitial();
    await cubit.markAsRead(cubit.state.notifications.single);

    expect(repository.markCalls, isEmpty);
  });
}

CitizenNotification sampleNotification({int id = 1, bool isRead = false}) {
  return CitizenNotification(
    id: id,
    type: CitizenNotificationType.reportAssigned,
    title: 'Report assigned',
    message: 'Your report was assigned.',
    reportId: 42,
    isRead: isRead,
    createdAt: DateTime.parse('2026-07-20T10:15:00'),
  );
}

NotificationsPage<CitizenNotification> sampleNotificationsPage({
  List<CitizenNotification>? content,
}) {
  final items = content ?? [sampleNotification()];
  return NotificationsPage(
    content: items,
    page: 0,
    size: 20,
    totalElements: items.length,
    totalPages: 1,
    first: true,
    last: true,
  );
}
