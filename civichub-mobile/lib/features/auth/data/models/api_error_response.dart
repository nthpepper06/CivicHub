class ApiErrorField {
  const ApiErrorField({required this.field, required this.message});

  final String field;
  final String message;

  factory ApiErrorField.fromJson(Map<String, dynamic> json) {
    return ApiErrorField(
      field: json['field'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }
}

class ApiErrorResponse {
  const ApiErrorResponse({
    required this.success,
    required this.message,
    required this.errors,
    required this.timestamp,
  });

  final bool success;
  final String message;
  final List<ApiErrorField> errors;
  final String? timestamp;

  factory ApiErrorResponse.fromJson(Map<String, dynamic> json) {
    final errors = (json['errors'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ApiErrorField.fromJson)
        .toList();
    return ApiErrorResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      errors: errors,
      timestamp: json['timestamp'] as String?,
    );
  }
}
