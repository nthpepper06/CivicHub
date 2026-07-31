import 'package:civichub_mobile/features/notifications/domain/models/citizen_notification.dart';
import 'package:civichub_mobile/features/notifications/domain/models/notification_type.dart';
import 'package:civichub_mobile/features/notifications/domain/models/notifications_page.dart';
import 'package:civichub_mobile/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:civichub_mobile/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class WidgetNotificationsRepository implements NotificationsRepository {
  WidgetNotificationsRepository({
    List<CitizenNotification>? notifications,
    this.unreadCount = 1,
    this.error,
  }) : notifications = notifications ?? [widgetNotification()];

  List<CitizenNotification> notifications;
  int unreadCount;
  Object? error;
  int listCalls = 0;
  int countCalls = 0;
  int markCalls = 0;

  @override
  Future<NotificationsPage<CitizenNotification>> getMyNotifications({
    required int page,
    required int size,
    bool? unread,
    String? type,
    String? sortBy,
    String? direction,
  }) async {
    listCalls += 1;
    if (error != null) {
      throw error!;
    }
    return NotificationsPage(
      content: notifications,
      page: 0,
      size: 20,
      totalElements: notifications.length,
      totalPages: 1,
      first: true,
      last: true,
    );
  }

  @override
  Future<int> getUnreadCount() async {
    countCalls += 1;
    if (error != null) {
      throw error!;
    }
    return unreadCount;
  }

  @override
  Future<CitizenNotification> markAsRead(int id) async {
    markCalls += 1;
    final updated = notifications
        .firstWhere((notification) => notification.id == id)
        .copyWith(isRead: true, readAt: DateTime.parse('2026-07-20T11:15:00'));
    notifications = notifications
        .map((notification) => notification.id == id ? updated : notification)
        .toList();
    return updated;
  }
}

void main() {
  testWidgets('renders loading then notification list with unread badge', (
    tester,
  ) async {
    final repository = WidgetNotificationsRepository(unreadCount: 2);

    await tester.pumpWidget(_app(repository));
    expect(find.text('Loading notifications'), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('2 unread'), findsWidgets);
    expect(find.text('Report assigned'), findsWidgets);
    expect(find.text('Your report was assigned.'), findsOneWidget);
    expect(find.byIcon(Icons.circle), findsOneWidget);
  });

  testWidgets('renders empty state', (tester) async {
    final repository = WidgetNotificationsRepository(
      notifications: const [],
      unreadCount: 0,
    );

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(find.text('No notifications yet'), findsOneWidget);
  });

  testWidgets('renders failure and retries', (tester) async {
    final repository = WidgetNotificationsRepository(error: Exception('boom'));

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    expect(find.text('Unable to load notifications'), findsOneWidget);

    repository.error = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Report assigned'), findsWidgets);
    expect(repository.listCalls, 2);
  });

  testWidgets('mark-as-read interaction updates badge and navigates safely', (
    tester,
  ) async {
    final repository = WidgetNotificationsRepository(unreadCount: 1);

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Report assigned').first);
    await tester.pumpAndSettle();

    expect(repository.markCalls, 1);
    expect(find.text('1 unread'), findsNothing);
    expect(find.text('Report detail 42'), findsOneWidget);
  });

  testWidgets('pull-to-refresh reloads notifications', (tester) async {
    final repository = WidgetNotificationsRepository();

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, 300),
      800,
    );
    await tester.pumpAndSettle();

    expect(repository.listCalls, greaterThanOrEqualTo(2));
  });
}

Widget _app(WidgetNotificationsRepository repository) {
  final router = GoRouter(
    initialLocation: '/notifications',
    routes: [
      GoRoute(
        path: '/notifications',
        builder: (context, state) =>
            RepositoryProvider<NotificationsRepository>.value(
              value: repository,
              child: const NotificationsScreen(),
            ),
      ),
      GoRoute(
        path: '/reports/detail/:id',
        builder: (context, state) =>
            Scaffold(body: Text('Report detail ${state.pathParameters['id']}')),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

CitizenNotification widgetNotification({bool isRead = false}) {
  return CitizenNotification(
    id: 1,
    type: CitizenNotificationType.reportAssigned,
    title: 'Report assigned',
    message: 'Your report was assigned.',
    reportId: 42,
    isRead: isRead,
    createdAt: DateTime.parse('2026-07-20T10:15:00'),
  );
}
