enum ApiErrorKind {
  network,
  timeout,
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  server,
  invalidResponse,
  unknown,
}

class ApiException implements Exception {
  const ApiException(this.kind, this.message, {this.statusCode});

  final ApiErrorKind kind;
  final String message;
  final int? statusCode;

  static const network = ApiException(
    ApiErrorKind.network,
    'No network connection. Check your internet or backend URL.',
  );

  static const timeout = ApiException(
    ApiErrorKind.timeout,
    'Request timed out. Please try again.',
  );

  static const badRequest = ApiException(
    ApiErrorKind.badRequest,
    'The request was invalid.',
  );

  static const unauthorized = ApiException(
    ApiErrorKind.unauthorized,
    'Your session expired. Please log in again.',
  );

  static const forbidden = ApiException(
    ApiErrorKind.forbidden,
    'You do not have permission to perform this action.',
  );

  static const notFound = ApiException(
    ApiErrorKind.notFound,
    'The requested resource was not found.',
  );

  static const conflict = ApiException(
    ApiErrorKind.conflict,
    'The request conflicts with existing data.',
  );

  static const server = ApiException(
    ApiErrorKind.server,
    'The server encountered an error.',
  );

  static const invalidResponse = ApiException(
    ApiErrorKind.invalidResponse,
    'The server returned an invalid response. Please try again.',
  );

  static const unknown = ApiException(
    ApiErrorKind.unknown,
    'Something went wrong.',
  );

  ApiException copyWith({String? message, int? statusCode}) {
    return ApiException(
      kind,
      message ?? this.message,
      statusCode: statusCode ?? this.statusCode,
    );
  }
}
