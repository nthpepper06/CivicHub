import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../models/notification_response.dart';
import '../models/notifications_page_response.dart';

abstract class NotificationsRemoteDataSource {
  Future<NotificationsPageResponse<NotificationResponse>> getMyNotifications({
    required int page,
    required int size,
    bool? unread,
    String? type,
    String? sortBy,
    String? direction,
  });

  Future<int> getUnreadCount();

  Future<NotificationResponse> markAsRead(int id);
}

class NotificationsRemoteDataSourceImpl
    implements NotificationsRemoteDataSource {
  NotificationsRemoteDataSourceImpl({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<NotificationsPageResponse<NotificationResponse>> getMyNotifications({
    required int page,
    required int size,
    bool? unread,
    String? type,
    String? sortBy,
    String? direction,
  }) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        ApiEndpoints.notifications,
        queryParameters: _cleanParams({
          'page': page,
          'size': size,
          'unread': unread,
          'type': type,
          'sortBy': sortBy,
          'direction': direction,
        }),
      );
      final data = _responseData(response.data);
      return NotificationsPageResponse.fromJson(
        data,
        NotificationResponse.fromJson,
      );
    } on DioException catch (error) {
      throw _apiClient.mapDioError(error);
    } on ApiException {
      rethrow;
    } on FormatException {
      throw ApiException.invalidResponse;
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        ApiEndpoints.unreadNotificationCount,
      );
      final data = _responseData(response.data);
      final count = data['count'];
      if (count is int) {
        return count < 0 ? 0 : count;
      }
      if (count is num) {
        return count < 0 ? 0 : count.toInt();
      }
      throw ApiException.invalidResponse;
    } on DioException catch (error) {
      throw _apiClient.mapDioError(error);
    } on ApiException {
      rethrow;
    }
  }

  @override
  Future<NotificationResponse> markAsRead(int id) async {
    try {
      final response = await _apiClient.dio.patch<Map<String, dynamic>>(
        ApiEndpoints.markNotificationRead(id),
      );
      return NotificationResponse.fromJson(_responseData(response.data));
    } on DioException catch (error) {
      throw _apiClient.mapDioError(error);
    } on ApiException {
      rethrow;
    } on FormatException {
      throw ApiException.invalidResponse;
    }
  }

  Map<String, dynamic> _responseData(Map<String, dynamic>? responseBody) {
    final data = responseBody?['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw ApiException.invalidResponse;
  }

  Map<String, dynamic> _cleanParams(Map<String, Object?> params) {
    return Map<String, dynamic>.fromEntries(
      params.entries.where((entry) {
        final value = entry.value;
        return value != null && (value is! String || value.trim().isNotEmpty);
      }),
    );
  }
}
