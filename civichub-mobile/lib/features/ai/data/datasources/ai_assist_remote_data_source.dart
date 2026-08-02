import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../models/ai_image_context_suggestion_response.dart';
import '../models/ai_text_suggestion_response.dart';

abstract class AiAssistRemoteDataSource {
  Future<AiTextSuggestionResponse> improveReportDescription({
    required String title,
    required String description,
    int? reportId,
  });

  Future<AiImageContextSuggestionResponse> describeImage({
    required String title,
    required String imageUrl,
    String? location,
    int? reportId,
  });

  Future<AiTextSuggestionResponse> improveResolutionSummary({
    required String title,
    required String summary,
    int? reportId,
  });
}

class AiAssistRemoteDataSourceImpl implements AiAssistRemoteDataSource {
  AiAssistRemoteDataSourceImpl({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<AiTextSuggestionResponse> improveReportDescription({
    required String title,
    required String description,
    int? reportId,
  }) async {
    final data = await _post(ApiEndpoints.aiReportDescriptionSuggestion, {
      'title': title,
      'description': description,
      'reportId': reportId,
    });
    return AiTextSuggestionResponse.fromJson(data);
  }

  @override
  Future<AiImageContextSuggestionResponse> describeImage({
    required String title,
    required String imageUrl,
    String? location,
    int? reportId,
  }) async {
    final data = await _post(ApiEndpoints.aiImageContext, {
      'title': title,
      'imageUrl': imageUrl,
      'location': location,
      'reportId': reportId,
    });
    return AiImageContextSuggestionResponse.fromJson(data);
  }

  @override
  Future<AiTextSuggestionResponse> improveResolutionSummary({
    required String title,
    required String summary,
    int? reportId,
  }) async {
    final data = await _post(ApiEndpoints.aiStaffResolutionSummarySuggestion, {
      'title': title,
      'summary': summary,
      'reportId': reportId,
    });
    return AiTextSuggestionResponse.fromJson(data);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, Object?> payload,
  ) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        path,
        data: _cleanPayload(payload),
      );
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      throw ApiException.invalidResponse;
    } on DioException catch (error) {
      throw _apiClient.mapDioError(error);
    } on ApiException {
      rethrow;
    } on FormatException {
      throw ApiException.invalidResponse;
    }
  }

  Map<String, dynamic> _cleanPayload(Map<String, Object?> payload) {
    return Map<String, dynamic>.fromEntries(
      payload.entries.where((entry) {
        final value = entry.value;
        return value != null && (value is! String || value.trim().isNotEmpty);
      }),
    );
  }
}
