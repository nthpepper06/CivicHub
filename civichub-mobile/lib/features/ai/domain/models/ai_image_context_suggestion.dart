import 'package:equatable/equatable.dart';

class AiImageContextSuggestion extends Equatable {
  const AiImageContextSuggestion({
    required this.requestId,
    required this.suggestion,
    this.confidence,
    this.provider,
    this.model,
  });

  final String requestId;
  final String suggestion;
  final double? confidence;
  final String? provider;
  final String? model;

  @override
  List<Object?> get props => [
    requestId,
    suggestion,
    confidence,
    provider,
    model,
  ];
}
