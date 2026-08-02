import 'dart:async';

import 'package:civichub_mobile/core/network/api_exception.dart';
import 'package:civichub_mobile/features/ai/domain/models/ai_text_suggestion.dart';
import 'package:civichub_mobile/features/ai/presentation/cubit/ai_suggestion_cubit.dart';
import 'package:civichub_mobile/features/ai/presentation/cubit/ai_suggestion_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  test('improve description succeeds', () async {
    final repository = FakeAiAssistRepository();
    final cubit = AiSuggestionCubit(aiAssistRepository: repository);

    await cubit.improveReportDescription(
      title: 'Broken sidewalk',
      description: 'bad paving',
    );

    expect(cubit.state.status, AiSuggestionStatus.success);
    expect(cubit.state.textSuggestion?.suggestion, 'Improved AI suggestion.');
    expect(repository.improveDescriptionCalls, 1);
  });

  test('timeout maps to graceful failure', () async {
    final repository = FakeAiAssistRepository()
      ..textError = ApiException.timeout;
    final cubit = AiSuggestionCubit(aiAssistRepository: repository);

    await cubit.improveReportDescription(
      title: 'Broken sidewalk',
      description: 'bad paving',
    );

    expect(cubit.state.status, AiSuggestionStatus.failure);
    expect(cubit.state.errorKind, ApiErrorKind.timeout);
    expect(cubit.state.errorMessage, contains('timed out'));
  });

  test('retry after failure can succeed', () async {
    final repository = FakeAiAssistRepository()
      ..textError = ApiException.network;
    final cubit = AiSuggestionCubit(aiAssistRepository: repository);

    await cubit.improveReportDescription(
      title: 'Broken sidewalk',
      description: 'bad paving',
    );
    repository.textError = null;
    await cubit.improveReportDescription(
      title: 'Broken sidewalk',
      description: 'bad paving',
    );

    expect(repository.improveDescriptionCalls, 2);
    expect(cubit.state.status, AiSuggestionStatus.success);
  });

  test('duplicate request is prevented while loading', () async {
    final completer = Completer<AiTextSuggestion>();
    final repository = FakeAiAssistRepository()
      ..pendingTextSuggestion = completer.future;
    final cubit = AiSuggestionCubit(aiAssistRepository: repository);

    final first = cubit.improveResolutionSummary(
      title: 'Broken sidewalk',
      summary: 'fixed panel',
    );
    final second = cubit.improveResolutionSummary(
      title: 'Broken sidewalk',
      summary: 'fixed panel',
    );
    await Future<void>.delayed(Duration.zero);
    completer.complete(repository.textSuggestion);
    await first;
    await second;

    expect(repository.improveResolutionCalls, 1);
    expect(cubit.state.status, AiSuggestionStatus.success);
  });

  test('image context succeeds', () async {
    final repository = FakeAiAssistRepository();
    final cubit = AiSuggestionCubit(aiAssistRepository: repository);

    await cubit.describeImage(
      title: 'Broken sidewalk',
      imageUrl: 'https://uploads.test/path.png',
      location: '12 Nguyen Hue',
    );

    expect(cubit.state.status, AiSuggestionStatus.success);
    expect(
      cubit.state.imageSuggestion?.suggestion,
      'The image appears to show report context.',
    );
    expect(repository.describeImageCalls, 1);
  });
}
