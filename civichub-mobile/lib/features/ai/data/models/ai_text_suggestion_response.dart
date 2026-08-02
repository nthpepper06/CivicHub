import '../../domain/models/ai_text_suggestion.dart';

class AiTextSuggestionResponse {
  const AiTextSuggestionResponse({
    required this.requestId,
    required this.suggestion,
    this.provider,
    this.model,
  });

  factory AiTextSuggestionResponse.fromJson(Map<String, dynamic> json) {
    return AiTextSuggestionResponse(
      requestId: json['requestId'] as String? ?? '',
      suggestion: json['suggestion'] as String? ?? '',
      provider: json['provider'] as String?,
      model: json['model'] as String?,
    );
  }

  final String requestId;
  final String suggestion;
  final String? provider;
  final String? model;

  AiTextSuggestion toDomain() {
    return AiTextSuggestion(
      requestId: requestId,
      suggestion: suggestion,
      provider: provider,
      model: model,
    );
  }
}
