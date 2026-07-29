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
}
