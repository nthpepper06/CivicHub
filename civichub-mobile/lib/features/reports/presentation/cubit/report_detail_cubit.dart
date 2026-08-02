import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/repositories/reports_repository.dart';
import 'report_detail_state.dart';

class ReportDetailCubit extends Cubit<ReportDetailState> {
  ReportDetailCubit({
    required ReportsRepository reportsRepository,
    required int reportId,
  }) : _reportsRepository = reportsRepository,
       _reportId = reportId,
       super(const ReportDetailState());

  final ReportsRepository _reportsRepository;
  final int _reportId;

  Future<void> load() async {
    emit(
      state.copyWith(
        status: ReportDetailStatus.loading,
        report: null,
        errorMessage: null,
        errorKind: null,
        actionErrorMessage: null,
        actionSuccessMessage: null,
      ),
    );

    try {
      final report = await _reportsRepository.getMyReport(_reportId);
      emit(
        state.copyWith(
          status: ReportDetailStatus.success,
          report: report,
          errorMessage: null,
          errorKind: null,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          status: error.kind == ApiErrorKind.notFound
              ? ReportDetailStatus.empty
              : ReportDetailStatus.failure,
          report: null,
          errorMessage: _friendlyMessage(error),
          errorKind: error.kind,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ReportDetailStatus.failure,
          report: null,
          errorMessage: ApiException.unknown.message,
          errorKind: ApiErrorKind.unknown,
        ),
      );
    }
  }

  Future<void> retry() => load();

  Future<void> cancel() async {
    if (state.isCancelling) {
      return;
    }

    emit(
      state.copyWith(
        isCancelling: true,
        actionErrorMessage: null,
        actionSuccessMessage: null,
        actionSucceeded: false,
      ),
    );

    try {
      await _reportsRepository.cancelMyReport(_reportId);
      final refreshed = await _reportsRepository.getMyReport(_reportId);
      emit(
        state.copyWith(
          status: ReportDetailStatus.success,
          report: refreshed,
          isCancelling: false,
          actionErrorMessage: null,
          actionSuccessMessage: 'Report cancelled.',
          actionSucceeded: true,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          isCancelling: false,
          actionErrorMessage: _friendlyActionMessage(error),
          actionSuccessMessage: null,
          actionSucceeded: false,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isCancelling: false,
          actionErrorMessage: ApiException.unknown.message,
          actionSuccessMessage: null,
          actionSucceeded: false,
        ),
      );
    }
  }

  Future<void> confirmResolution() async {
    if (state.isSubmittingFeedback) {
      return;
    }
    emit(
      state.copyWith(
        isSubmittingFeedback: true,
        actionErrorMessage: null,
        actionSuccessMessage: null,
        actionSucceeded: false,
      ),
    );
    try {
      final report = await _reportsRepository.confirmResolution(_reportId);
      emit(
        state.copyWith(
          status: ReportDetailStatus.success,
          report: report,
          isSubmittingFeedback: false,
          actionErrorMessage: null,
          actionSuccessMessage: 'Resolution confirmed.',
          actionSucceeded: true,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          isSubmittingFeedback: false,
          actionErrorMessage: _friendlyFeedbackMessage(error),
          actionSuccessMessage: null,
          actionSucceeded: false,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isSubmittingFeedback: false,
          actionErrorMessage: ApiException.unknown.message,
          actionSuccessMessage: null,
          actionSucceeded: false,
        ),
      );
    }
  }

  Future<void> rateResolution(int rating, {String? comment}) async {
    if (state.isSubmittingFeedback) {
      return;
    }
    emit(
      state.copyWith(
        isSubmittingFeedback: true,
        actionErrorMessage: null,
        actionSuccessMessage: null,
        actionSucceeded: false,
      ),
    );
    try {
      final report = await _reportsRepository.rateResolution(
        _reportId,
        rating: rating,
        comment: comment,
      );
      emit(
        state.copyWith(
          status: ReportDetailStatus.success,
          report: report,
          isSubmittingFeedback: false,
          actionErrorMessage: null,
          actionSuccessMessage: 'Rating submitted.',
          actionSucceeded: true,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          isSubmittingFeedback: false,
          actionErrorMessage: _friendlyFeedbackMessage(error),
          actionSuccessMessage: null,
          actionSucceeded: false,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isSubmittingFeedback: false,
          actionErrorMessage: ApiException.unknown.message,
          actionSuccessMessage: null,
          actionSucceeded: false,
        ),
      );
    }
  }

  String _friendlyMessage(ApiException error) {
    return switch (error.kind) {
      ApiErrorKind.network =>
        'Cannot load this report right now. Check your connection and try again.',
      ApiErrorKind.timeout =>
        'Loading this report timed out. Please try again.',
      ApiErrorKind.invalidResponse =>
        'Report details could not be read from the server response.',
      ApiErrorKind.notFound => error.message,
      ApiErrorKind.server =>
        'The server is unavailable right now. Please try again.',
      ApiErrorKind.badRequest ||
      ApiErrorKind.unauthorized ||
      ApiErrorKind.forbidden ||
      ApiErrorKind.conflict ||
      ApiErrorKind.unknown => error.message,
    };
  }

  String _friendlyActionMessage(ApiException error) {
    return switch (error.kind) {
      ApiErrorKind.network =>
        'Cannot cancel this report right now. Check your connection and try again.',
      ApiErrorKind.timeout =>
        'Cancelling this report timed out. Please try again.',
      ApiErrorKind.invalidResponse =>
        'The cancelled report could not be read from the server response.',
      ApiErrorKind.server =>
        'The server is unavailable right now. Please try again.',
      ApiErrorKind.badRequest ||
      ApiErrorKind.unauthorized ||
      ApiErrorKind.forbidden ||
      ApiErrorKind.notFound ||
      ApiErrorKind.conflict ||
      ApiErrorKind.unknown => error.message,
    };
  }

  String _friendlyFeedbackMessage(ApiException error) {
    return switch (error.kind) {
      ApiErrorKind.network =>
        'Cannot update resolution feedback right now. Check your connection.',
      ApiErrorKind.timeout =>
        'Resolution feedback timed out. Please try again.',
      ApiErrorKind.invalidResponse =>
        'Updated report details could not be read from the server response.',
      ApiErrorKind.server =>
        'The server is unavailable right now. Please try again.',
      ApiErrorKind.badRequest ||
      ApiErrorKind.unauthorized ||
      ApiErrorKind.forbidden ||
      ApiErrorKind.notFound ||
      ApiErrorKind.conflict ||
      ApiErrorKind.unknown => error.message,
    };
  }
}
