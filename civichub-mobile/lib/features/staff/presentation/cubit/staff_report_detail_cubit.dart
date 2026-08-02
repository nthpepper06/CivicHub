import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../reports/domain/models/report_status.dart';
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
        updateErrorMessage: null,
        updateSuccessMessage: null,
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

  Future<void> updateStatus(
    ReportStatus nextStatus, {
    String? resolutionSummary,
    String? workPerformed,
    String? publicNote,
    List<String> resolutionImageUrls = const [],
  }) async {
    if (state.isUpdatingStatus ||
        !state.availableActions.contains(nextStatus)) {
      return;
    }
    emit(
      state.copyWith(
        updatingStatus: nextStatus,
        updateErrorMessage: null,
        updateSuccessMessage: null,
      ),
    );
    try {
      final report = await _staffRepository.updateAssignedReportStatus(
        _reportId,
        nextStatus,
        resolutionSummary: resolutionSummary,
        workPerformed: workPerformed,
        publicNote: publicNote,
        resolutionImageUrls: resolutionImageUrls,
      );
      emit(
        state.copyWith(
          status: StaffReportDetailStatus.success,
          report: report,
          updatingStatus: null,
          updateErrorMessage: null,
          updateSuccessMessage: _statusSuccessMessage(nextStatus),
          errorMessage: null,
          errorKind: null,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          updatingStatus: null,
          updateErrorMessage: _friendlyMessage(error),
          updateSuccessMessage: null,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          updatingStatus: null,
          updateErrorMessage: ApiException.unknown.message,
          updateSuccessMessage: null,
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

  String _statusSuccessMessage(ReportStatus status) {
    return switch (status) {
      ReportStatus.received => 'Report marked as received.',
      ReportStatus.inProgress => 'Report moved to in progress.',
      ReportStatus.resolved => 'Report marked as resolved.',
      ReportStatus.rejected => 'Report rejected.',
      ReportStatus.pending => 'Report moved to pending.',
      ReportStatus.cancelled => 'Report cancelled.',
      ReportStatus.unknown => 'Report status updated.',
    };
  }
}
