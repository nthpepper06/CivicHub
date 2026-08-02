import 'package:civichub_mobile/features/ai/data/datasources/ai_assist_remote_data_source.dart';
import 'package:civichub_mobile/features/ai/data/models/ai_image_context_suggestion_response.dart';
import 'package:civichub_mobile/features/ai/data/models/ai_text_suggestion_response.dart';
import 'package:civichub_mobile/features/ai/data/repositories/ai_assist_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('repository maps report description suggestion', () async {
    final remote = _FakeAiAssistRemoteDataSource();
    final repository = AiAssistRepositoryImpl(remoteDataSource: remote);

    final suggestion = await repository.improveReportDescription(
      title: 'Broken sidewalk',
      description: 'bad paving',
      reportId: 12,
    );

    expect(suggestion.suggestion, 'Improved text.');
    expect(remote.descriptionCalls, 1);
  });

  test('repository maps image context suggestion', () async {
    final remote = _FakeAiAssistRemoteDataSource();
    final repository = AiAssistRepositoryImpl(remoteDataSource: remote);

    final suggestion = await repository.describeImage(
      title: 'Broken sidewalk',
      imageUrl: 'https://uploads.test/path.png',
      location: '12 Nguyen Hue',
    );

    expect(suggestion.suggestion, 'Image context.');
    expect(suggestion.confidence, 0.82);
    expect(remote.imageCalls, 1);
  });

  test('repository maps staff resolution summary suggestion', () async {
    final remote = _FakeAiAssistRemoteDataSource();
    final repository = AiAssistRepositoryImpl(remoteDataSource: remote);

    final suggestion = await repository.improveResolutionSummary(
      title: 'Broken sidewalk',
      summary: 'fixed panel',
      reportId: 12,
    );

    expect(suggestion.suggestion, 'Improved text.');
    expect(remote.resolutionCalls, 1);
  });
}

class _FakeAiAssistRemoteDataSource implements AiAssistRemoteDataSource {
  int descriptionCalls = 0;
  int imageCalls = 0;
  int resolutionCalls = 0;

  @override
  Future<AiTextSuggestionResponse> improveReportDescription({
    required String title,
    required String description,
    int? reportId,
  }) async {
    descriptionCalls += 1;
    return const AiTextSuggestionResponse(
      requestId: 'req-1',
      suggestion: 'Improved text.',
      provider: 'OPENAI',
      model: 'gpt-test',
    );
  }

  @override
  Future<AiImageContextSuggestionResponse> describeImage({
    required String title,
    required String imageUrl,
    String? location,
    int? reportId,
  }) async {
    imageCalls += 1;
    return const AiImageContextSuggestionResponse(
      requestId: 'req-2',
      suggestion: 'Image context.',
      confidence: 0.82,
      provider: 'OPENAI',
      model: 'gpt-test',
    );
  }

  @override
  Future<AiTextSuggestionResponse> improveResolutionSummary({
    required String title,
    required String summary,
    int? reportId,
  }) async {
    resolutionCalls += 1;
    return const AiTextSuggestionResponse(
      requestId: 'req-3',
      suggestion: 'Improved text.',
      provider: 'OPENAI',
      model: 'gpt-test',
    );
  }
}
