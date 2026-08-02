import 'package:equatable/equatable.dart';

class AiTextSuggestion extends Equatable {
  const AiTextSuggestion({
    required this.requestId,
    required this.suggestion,
    this.provider,
    this.model,
  });

  final String requestId;
  final String suggestion;
  final String? provider;
  final String? model;

  @override
  List<Object?> get props => [requestId, suggestion, provider, model];
}
