import 'package:equatable/equatable.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/models/ai_image_context_suggestion.dart';
import '../../domain/models/ai_text_suggestion.dart';

enum AiSuggestionStatus { idle, loading, success, failure }

class AiSuggestionState extends Equatable {
  const AiSuggestionState({
    this.status = AiSuggestionStatus.idle,
    this.textSuggestion,
    this.imageSuggestion,
    this.errorMessage,
    this.errorKind,
  });

  final AiSuggestionStatus status;
  final AiTextSuggestion? textSuggestion;
  final AiImageContextSuggestion? imageSuggestion;
  final String? errorMessage;
  final ApiErrorKind? errorKind;

  bool get isLoading => status == AiSuggestionStatus.loading;

  AiSuggestionState copyWith({
    AiSuggestionStatus? status,
    Object? textSuggestion = _unchanged,
    Object? imageSuggestion = _unchanged,
    Object? errorMessage = _unchanged,
    Object? errorKind = _unchanged,
  }) {
    return AiSuggestionState(
      status: status ?? this.status,
      textSuggestion: textSuggestion == _unchanged
          ? this.textSuggestion
          : textSuggestion as AiTextSuggestion?,
      imageSuggestion: imageSuggestion == _unchanged
          ? this.imageSuggestion
          : imageSuggestion as AiImageContextSuggestion?,
      errorMessage: errorMessage == _unchanged
          ? this.errorMessage
          : errorMessage as String?,
      errorKind: errorKind == _unchanged
          ? this.errorKind
          : errorKind as ApiErrorKind?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    textSuggestion,
    imageSuggestion,
    errorMessage,
    errorKind,
  ];
}

const _unchanged = Object();
