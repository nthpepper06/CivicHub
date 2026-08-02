import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/models/ai_text_suggestion.dart';
import '../../domain/repositories/ai_assist_repository.dart';
import 'ai_suggestion_state.dart';

class AiSuggestionCubit extends Cubit<AiSuggestionState> {
  AiSuggestionCubit({required AiAssistRepository aiAssistRepository})
    : _aiAssistRepository = aiAssistRepository,
      super(const AiSuggestionState());

  final AiAssistRepository _aiAssistRepository;

  Future<void> improveReportDescription({
    required String title,
    required String description,
    int? reportId,
  }) async {
    if (state.isLoading) {
      return;
    }
    await _runText(
      () => _aiAssistRepository.improveReportDescription(
        title: title.trim(),
        description: description.trim(),
        reportId: reportId,
      ),
    );
  }

  Future<void> improveResolutionSummary({
    required String title,
    required String summary,
    int? reportId,
  }) async {
    if (state.isLoading) {
      return;
    }
    await _runText(
      () => _aiAssistRepository.improveResolutionSummary(
        title: title.trim(),
        summary: summary.trim(),
        reportId: reportId,
      ),
    );
  }

  Future<void> describeImage({
    required String title,
    required String imageUrl,
    String? location,
    int? reportId,
  }) async {
    if (state.isLoading) {
      return;
    }
    emit(
      state.copyWith(
        status: AiSuggestionStatus.loading,
        textSuggestion: null,
        imageSuggestion: null,
        errorMessage: null,
        errorKind: null,
      ),
    );
    try {
      final suggestion = await _aiAssistRepository.describeImage(
        title: title.trim(),
        imageUrl: imageUrl.trim(),
        location: location?.trim(),
        reportId: reportId,
      );
      emit(
        state.copyWith(
          status: AiSuggestionStatus.success,
          imageSuggestion: suggestion,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          status: AiSuggestionStatus.failure,
          errorMessage: _friendlyMessage(error),
          errorKind: error.kind,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AiSuggestionStatus.failure,
          errorMessage: ApiException.unknown.message,
          errorKind: ApiErrorKind.unknown,
        ),
      );
    }
  }

  void reset() {
    emit(const AiSuggestionState());
  }

  Future<void> _runText(Future<AiTextSuggestion> Function() request) async {
    emit(
      state.copyWith(
        status: AiSuggestionStatus.loading,
        textSuggestion: null,
        imageSuggestion: null,
        errorMessage: null,
        errorKind: null,
      ),
    );
    try {
      final suggestion = await request();
      emit(
        state.copyWith(
          status: AiSuggestionStatus.success,
          textSuggestion: suggestion,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          status: AiSuggestionStatus.failure,
          errorMessage: _friendlyMessage(error),
          errorKind: error.kind,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AiSuggestionStatus.failure,
          errorMessage: ApiException.unknown.message,
          errorKind: ApiErrorKind.unknown,
        ),
      );
    }
  }

  String _friendlyMessage(ApiException error) {
    return switch (error.kind) {
      ApiErrorKind.timeout =>
        'AI suggestion timed out. You can retry or continue without it.',
      ApiErrorKind.network => 'AI suggestion is unavailable offline.',
      ApiErrorKind.unauthorized || ApiErrorKind.forbidden => error.message,
      ApiErrorKind.server => 'AI suggestion is temporarily unavailable.',
      ApiErrorKind.invalidResponse => 'AI suggestion could not be read.',
      ApiErrorKind.badRequest ||
      ApiErrorKind.notFound ||
      ApiErrorKind.conflict ||
      ApiErrorKind.unknown => error.message,
    };
  }
}
