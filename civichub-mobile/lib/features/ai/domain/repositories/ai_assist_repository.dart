import '../models/ai_image_context_suggestion.dart';
import '../models/ai_text_suggestion.dart';

abstract class AiAssistRepository {
  Future<AiTextSuggestion> improveReportDescription({
    required String title,
    required String description,
    int? reportId,
  });

  Future<AiImageContextSuggestion> describeImage({
    required String title,
    required String imageUrl,
    String? location,
    int? reportId,
  });

  Future<AiTextSuggestion> improveResolutionSummary({
    required String title,
    required String summary,
    int? reportId,
  });
}
