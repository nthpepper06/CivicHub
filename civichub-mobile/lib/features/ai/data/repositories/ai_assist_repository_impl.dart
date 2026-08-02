import '../../domain/models/ai_image_context_suggestion.dart';
import '../../domain/models/ai_text_suggestion.dart';
import '../../domain/repositories/ai_assist_repository.dart';
import '../datasources/ai_assist_remote_data_source.dart';

class AiAssistRepositoryImpl implements AiAssistRepository {
  AiAssistRepositoryImpl({required AiAssistRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final AiAssistRemoteDataSource _remoteDataSource;

  @override
  Future<AiTextSuggestion> improveReportDescription({
    required String title,
    required String description,
    int? reportId,
  }) async {
    final response = await _remoteDataSource.improveReportDescription(
      title: title,
      description: description,
      reportId: reportId,
    );
    return response.toDomain();
  }

  @override
  Future<AiImageContextSuggestion> describeImage({
    required String title,
    required String imageUrl,
    String? location,
    int? reportId,
  }) async {
    final response = await _remoteDataSource.describeImage(
      title: title,
      imageUrl: imageUrl,
      location: location,
      reportId: reportId,
    );
    return response.toDomain();
  }

  @override
  Future<AiTextSuggestion> improveResolutionSummary({
    required String title,
    required String summary,
    int? reportId,
  }) async {
    final response = await _remoteDataSource.improveResolutionSummary(
      title: title,
      summary: summary,
      reportId: reportId,
    );
    return response.toDomain();
  }
}
