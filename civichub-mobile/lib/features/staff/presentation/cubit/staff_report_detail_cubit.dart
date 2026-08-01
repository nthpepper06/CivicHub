import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/repositories/staff_repository.dart';
import 'staff_report_detail_state.dart';

class StaffReportDetailCubit extends Cubit<StaffReportDetailState> {
  StaffReportDetailCubit({
    required StaffRepository staffRepository,
    required int reportId,
  }) : _staffRepository = staffRepository,
       _reportId = reportId,
       super(const StaffReportDetailState());

  final StaffRepository _staffRepository;
  final int _reportId;

  Future<void> retry() => load();

  Future<void> refresh() => load();

  Future<void> load() async {
    emit(
      state.copyWith(
        status: StaffReportDetailStatus.loading,
        errorMessage: null,
        errorKind: null,
      ),
    );
    try {
      final report = await _staffRepository.getAssignedReport(_reportId);
      emit(
        state.copyWith(
          status: StaffReportDetailStatus.success,
          report: report,
          errorMessage: null,
          errorKind: null,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          status: StaffReportDetailStatus.failure,
          errorMessage: _friendlyMessage(error),
          errorKind: error.kind,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: StaffReportDetailStatus.failure,
          errorMessage: ApiException.unknown.message,
          errorKind: ApiErrorKind.unknown,
        ),
      );
    }
  }

  String _friendlyMessage(ApiException error) {
    return switch (error.kind) {
      ApiErrorKind.network =>
        'Cannot load this assigned report. Check your connection.',
      ApiErrorKind.timeout => 'Loading this report timed out.',
      ApiErrorKind.unauthorized => error.message,
      ApiErrorKind.forbidden => error.message,
      ApiErrorKind.notFound => 'Report not found for your department.',
      ApiErrorKind.server => 'The server is unavailable right now.',
      ApiErrorKind.invalidResponse =>
        'Report details could not be read from the server response.',
      ApiErrorKind.badRequest ||
      ApiErrorKind.conflict ||
      ApiErrorKind.unknown => error.message,
    };
  }
}
