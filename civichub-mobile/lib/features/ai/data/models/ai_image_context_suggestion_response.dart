import '../../domain/models/ai_image_context_suggestion.dart';

class AiImageContextSuggestionResponse {
  const AiImageContextSuggestionResponse({
    required this.requestId,
    required this.suggestion,
    this.confidence,
    this.provider,
    this.model,
  });

  factory AiImageContextSuggestionResponse.fromJson(Map<String, dynamic> json) {
    return AiImageContextSuggestionResponse(
      requestId: json['requestId'] as String? ?? '',
      suggestion: json['suggestion'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble(),
      provider: json['provider'] as String?,
      model: json['model'] as String?,
    );
  }

  final String requestId;
  final String suggestion;
  final double? confidence;
  final String? provider;
  final String? model;

  AiImageContextSuggestion toDomain() {
    return AiImageContextSuggestion(
      requestId: requestId,
      suggestion: suggestion,
      confidence: confidence,
      provider: provider,
      model: model,
    );
  }
}
