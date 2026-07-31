import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:civichub_mobile/core/network/api_client.dart';
import 'package:civichub_mobile/core/network/api_exception.dart';
import 'package:civichub_mobile/features/notifications/data/datasources/notifications_remote_data_source.dart';
import 'package:civichub_mobile/features/notifications/data/models/notification_response.dart';
import 'package:civichub_mobile/features/notifications/domain/models/notification_type.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

class NotificationsJsonAdapter implements HttpClientAdapter {
  NotificationsJsonAdapter(this.body, {this.statusCode = 200});

  final Map<String, dynamic> body;
  final int statusCode;
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('Notification parser handles valid read and unread response', () {
    final unread = NotificationResponse.fromJson(const {
      'id': 10,
      'type': 'REPORT_STATUS_CHANGED',
      'title': 'Report updated',
      'message': 'Your report moved to in progress.',
      'reportId': 42,
      'read': false,
      'createdAt': '2026-07-20T10:15:00',
    }).toDomain();
    final read = NotificationResponse.fromJson(const {
      'id': 11,
      'type': 'REPORT_ASSIGNED',
      'title': 'Assigned',
      'message': 'Assigned to Public Works.',
      'read': true,
      'readAt': '2026-07-20T11:15:00',
    }).toDomain();

    expect(unread.type, CitizenNotificationType.reportStatusChanged);
    expect(unread.isRead, isFalse);
    expect(unread.reportId, 42);
    expect(read.isRead, isTrue);
    expect(read.readAt, DateTime.parse('2026-07-20T11:15:00'));
  });

  test(
    'Notification parser handles optional fields and unknown type safely',
    () {
      final notification = NotificationResponse.fromJson(const {
        'id': '12',
        'type': 'SOMETHING_NEW',
        'read': null,
        'reportId': 0,
      }).toDomain();

      expect(notification.id, 12);
      expect(notification.type, CitizenNotificationType.unknown);
      expect(notification.title, '');
      expect(notification.message, '');
      expect(notification.reportId, isNull);
      expect(notification.isRead, isFalse);
    },
  );

  test('Remote data source unwraps notifications ApiResponse', () async {
    final storage = MemoryAuthTokenStorage();
    await storage.saveAccessToken('jwt-token');
    final adapter = NotificationsJsonAdapter(const {
      'success': true,
      'message': 'Notifications',
      'data': {
        'content': [
          {
            'id': 10,
            'type': 'REPORT_ASSIGNED',
            'title': 'Assigned',
            'message': 'Assigned to Public Works.',
            'reportId': 42,
            'read': false,
          },
        ],
        'page': 0,
        'size': 20,
        'totalElements': 1,
        'totalPages': 1,
        'first': true,
        'last': true,
      },
    });
    final client = ApiClient(tokenStorage: storage);
    client.dio.httpClientAdapter = adapter;
    final dataSource = NotificationsRemoteDataSourceImpl(apiClient: client);

    final page = await dataSource.getMyNotifications(
      page: 0,
      size: 20,
      sortBy: 'createdAt',
      direction: 'DESC',
    );

    expect(adapter.request?.method, 'GET');
    expect(adapter.request?.path, '/api/notifications');
    expect(adapter.request?.headers['Authorization'], 'Bearer jwt-token');
    expect(adapter.request?.queryParameters['sortBy'], 'createdAt');
    expect(page.content.single.id, 10);
  });

  test('Remote data source loads unread count', () async {
    final client = ApiClient(tokenStorage: MemoryAuthTokenStorage());
    final adapter = NotificationsJsonAdapter(const {
      'success': true,
      'message': 'Unread notification count',
      'data': {'count': 5},
    });
    client.dio.httpClientAdapter = adapter;
    final dataSource = NotificationsRemoteDataSourceImpl(apiClient: client);

    final count = await dataSource.getUnreadCount();

    expect(adapter.request?.path, '/api/notifications/unread-count');
    expect(count, 5);
  });

  test('Remote data source marks notification as read', () async {
    final client = ApiClient(tokenStorage: MemoryAuthTokenStorage());
    final adapter = NotificationsJsonAdapter(const {
      'success': true,
      'message': 'Notification marked as read',
      'data': {
        'id': 10,
        'type': 'REPORT_ASSIGNED',
        'title': 'Assigned',
        'message': 'Assigned to Public Works.',
        'read': true,
      },
    });
    client.dio.httpClientAdapter = adapter;
    final dataSource = NotificationsRemoteDataSourceImpl(apiClient: client);

    final updated = await dataSource.markAsRead(10);

    expect(adapter.request?.method, 'PATCH');
    expect(adapter.request?.path, '/api/notifications/10/read');
    expect(updated.isRead, isTrue);
  });

  test('Remote data source propagates mapped API errors', () async {
    final client = ApiClient(tokenStorage: MemoryAuthTokenStorage());
    client.dio.httpClientAdapter = NotificationsJsonAdapter(const {
      'success': false,
      'message': 'Unauthorized',
    }, statusCode: 401);
    final dataSource = NotificationsRemoteDataSourceImpl(apiClient: client);

    await expectLater(
      dataSource.getUnreadCount(),
      throwsA(
        isA<ApiException>().having(
          (error) => error.kind,
          'kind',
          ApiErrorKind.unauthorized,
        ),
      ),
    );
  });
}
