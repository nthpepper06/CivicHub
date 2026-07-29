import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/auth_token_storage.dart';
import 'api_exception.dart';
import 'unauthorized_handler.dart';

class ApiClient {
  ApiClient({
    required AuthTokenStorage tokenStorage,
    UnauthorizedHandler? unauthorizedHandler,
  }) : _tokenStorage = tokenStorage,
       _unauthorizedHandler = unauthorizedHandler,
       dio = Dio(
         BaseOptions(
           baseUrl: AppConfig.apiBaseUrl,
           connectTimeout: AppConfig.connectTimeout,
           receiveTimeout: AppConfig.receiveTimeout,
           responseType: ResponseType.json,
           contentType: Headers.jsonContentType,
           headers: const {Headers.acceptHeader: Headers.jsonContentType},
         ),
       ) {
    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          if (!_requiresAuth(options)) {
            handler.next(options);
            return;
          }

          final token = await _tokenStorage.readAccessToken();
          if (token != null && token.trim().isNotEmpty) {
            final normalizedToken = token.trim();
            if (normalizedToken != _lastAuthorizedToken) {
              _lastAuthorizedToken = normalizedToken;
              _handledUnauthorizedForToken = false;
            }
            options.headers['Authorization'] = 'Bearer $normalizedToken';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (_shouldHandleUnauthorized(error)) {
            await _handleUnauthorizedOnce();
          }
          handler.next(error);
        },
      ),
    );
  }

  static const requiresAuthExtraKey = 'requiresAuth';

  final Dio dio;
  final AuthTokenStorage _tokenStorage;
  UnauthorizedHandler? _unauthorizedHandler;
  Future<void>? _unauthorizedFuture;
  String? _lastAuthorizedToken;
  bool _handledUnauthorizedForToken = false;

  set unauthorizedHandler(UnauthorizedHandler? handler) {
    _unauthorizedHandler = handler;
  }

  ApiException mapDioError(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseMessage = _extractResponseMessage(error.response?.data);

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.transformTimeout:
        return ApiException.timeout.copyWith(
          message: responseMessage ?? ApiException.timeout.message,
          statusCode: statusCode,
        );
      case DioExceptionType.connectionError:
        return ApiException.network.copyWith(
          message: responseMessage ?? ApiException.network.message,
          statusCode: statusCode,
        );
      case DioExceptionType.badResponse:
        return _mapStatusCode(statusCode, responseMessage);
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return ApiException.unknown.copyWith(
          message: responseMessage ?? ApiException.unknown.message,
          statusCode: statusCode,
        );
      case DioExceptionType.badCertificate:
        return ApiException.network.copyWith(
          message: 'Secure connection failed.',
          statusCode: statusCode,
        );
    }
  }

  bool _requiresAuth(RequestOptions options) {
    return options.extra[requiresAuthExtraKey] != false;
  }

  bool _shouldHandleUnauthorized(DioException error) {
    return error.response?.statusCode == 401 &&
        _requiresAuth(error.requestOptions);
  }

  Future<void> _handleUnauthorizedOnce() {
    final pending = _unauthorizedFuture;
    if (pending != null) {
      return pending;
    }

    final handler = _unauthorizedHandler;
    if (handler == null || _handledUnauthorizedForToken) {
      return Future<void>.value();
    }

    _handledUnauthorizedForToken = true;
    final future = handler.handleUnauthorized();
    _unauthorizedFuture = future.whenComplete(() {
      _unauthorizedFuture = null;
    });
    return _unauthorizedFuture!;
  }

  ApiException _mapStatusCode(int? statusCode, String? responseMessage) {
    final message = responseMessage ?? _defaultMessageFor(statusCode);
    if (statusCode == 400) {
      return ApiException.badRequest.copyWith(
        message: message,
        statusCode: statusCode,
      );
    }
    if (statusCode == 401) {
      return ApiException.unauthorized.copyWith(
        message: message,
        statusCode: statusCode,
      );
    }
    if (statusCode == 403) {
      return ApiException.forbidden.copyWith(
        message: message,
        statusCode: statusCode,
      );
    }
    if (statusCode == 404) {
      return ApiException.notFound.copyWith(
        message: message,
        statusCode: statusCode,
      );
    }
    if (statusCode == 409) {
      return ApiException.conflict.copyWith(
        message: message,
        statusCode: statusCode,
      );
    }
    if (statusCode != null && statusCode >= 500) {
      return ApiException.server.copyWith(
        message: message,
        statusCode: statusCode,
      );
    }
    return ApiException.unknown.copyWith(
      message: message,
      statusCode: statusCode,
    );
  }

  String? _extractResponseMessage(Object? data) {
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }

      final errors = data['errors'];
      if (errors is List && errors.isNotEmpty) {
        final first = errors.first;
        if (first is Map<String, dynamic>) {
          final field = first['field'];
          final errorMessage = first['message'];
          if (field is String && errorMessage is String) {
            return '${field.trim()}: ${errorMessage.trim()}';
          }
          if (errorMessage is String && errorMessage.trim().isNotEmpty) {
            return errorMessage.trim();
          }
        }
      }
    }
    return null;
  }

  String _defaultMessageFor(int? statusCode) {
    if (statusCode == 400) {
      return 'The request was invalid.';
    }
    if (statusCode == 401) {
      return 'Your session expired. Please log in again.';
    }
    if (statusCode == 403) {
      return 'You do not have permission to perform this action.';
    }
    if (statusCode == 404) {
      return 'The requested resource was not found.';
    }
    if (statusCode == 409) {
      return 'The request conflicts with existing data.';
    }
    if (statusCode != null && statusCode >= 500) {
      return 'The server encountered an error.';
    }
    return 'Something went wrong.';
  }
}
