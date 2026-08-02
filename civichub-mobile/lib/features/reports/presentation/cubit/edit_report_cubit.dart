import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/models/create_report_request.dart';
import '../../domain/models/report_detail.dart';
import '../../domain/repositories/reports_repository.dart';
import 'edit_report_state.dart';

class EditReportCubit extends Cubit<EditReportState> {
  EditReportCubit({
    required ReportsRepository reportsRepository,
    required int reportId,
    CitizenReportDetail? initialReport,
  }) : _reportsRepository = reportsRepository,
       _reportId = reportId,
       super(
         EditReportState(
           selectedCategoryId: initialReport?.categoryId,
           report: initialReport,
         ),
       );

  final ReportsRepository _reportsRepository;
  final int _reportId;

  int get reportId => _reportId;

  Future<void> load() async {
    final currentReport = state.report;
    if (currentReport != null) {
      await _loadCategories(currentReport);
      return;
    }

    await loadReport();
  }

  Future<void> loadReport() async {
    if (state.status == EditReportStatus.loadingReport) {
      return;
    }

    emit(
      state.copyWith(
        status: EditReportStatus.loadingReport,
        reportErrorMessage: null,
        categoryErrorMessage: null,
      ),
    );

    try {
      final report = await _reportsRepository.getMyReport(_reportId);
      emit(
        state.copyWith(
          report: report,
          selectedCategoryId: report.categoryId,
          reportErrorMessage: null,
        ),
      );
      await _loadCategories(report);
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          status: EditReportStatus.reportFailure,
          reportErrorMessage: _friendlyReportMessage(error),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: EditReportStatus.reportFailure,
          reportErrorMessage: ApiException.unknown.message,
        ),
      );
    }
  }

  Future<void> loadCategories() async {
    final report = state.report;
    if (report == null) {
      await loadReport();
      return;
    }

    await _loadCategories(report);
  }

  Future<void> _loadCategories(CitizenReportDetail report) async {
    if (state.status == EditReportStatus.loadingCategories) {
      return;
    }

    emit(
      state.copyWith(
        status: EditReportStatus.loadingCategories,
        categoryErrorMessage: null,
      ),
    );

    try {
      final categories = await _reportsRepository.getCategories();
      emit(
        state.copyWith(
          status: EditReportStatus.ready,
          categories: categories,
          selectedCategoryId: report.categoryId,
          categoryErrorMessage: null,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          status: EditReportStatus.categoryFailure,
          categoryErrorMessage: _friendlyCategoryMessage(error),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: EditReportStatus.categoryFailure,
          categoryErrorMessage: ApiException.unknown.message,
        ),
      );
    }
  }

  void selectCategory(int? categoryId) {
    emit(
      state.copyWith(
        selectedCategoryId: categoryId,
        submitStatus: EditReportSubmitStatus.idle,
        submitErrorMessage: null,
        submitErrorKind: null,
      ),
    );
  }

  Future<void> update(CreateReportRequest request) async {
    if (state.submitStatus == EditReportSubmitStatus.updating) {
      return;
    }

    emit(
      state.copyWith(
        submitStatus: EditReportSubmitStatus.updating,
        submitErrorMessage: null,
        submitErrorKind: null,
        updatedReport: null,
      ),
    );

    try {
      final updated = await _reportsRepository.updateMyReport(
        _reportId,
        request,
      );
      emit(
        state.copyWith(
          submitStatus: EditReportSubmitStatus.success,
          submitErrorMessage: null,
          submitErrorKind: null,
          updatedReport: updated,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          submitStatus: EditReportSubmitStatus.failure,
          submitErrorMessage: _friendlySubmitMessage(error),
          submitErrorKind: error.kind,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          submitStatus: EditReportSubmitStatus.failure,
          submitErrorMessage: ApiException.unknown.message,
          submitErrorKind: ApiErrorKind.unknown,
        ),
      );
    }
  }

  String _friendlyCategoryMessage(ApiException error) {
    return switch (error.kind) {
      ApiErrorKind.network =>
        'Cannot load categories right now. Check your connection and try again.',
      ApiErrorKind.timeout => 'Loading categories timed out. Please try again.',
      ApiErrorKind.invalidResponse =>
        'Categories could not be read from the server response.',
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

  String _friendlyReportMessage(ApiException error) {
    return switch (error.kind) {
      ApiErrorKind.network =>
        'Cannot load this report right now. Check your connection and try again.',
      ApiErrorKind.timeout =>
        'Loading this report timed out. Please try again.',
      ApiErrorKind.invalidResponse =>
        'The report could not be read from the server response.',
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

  String _friendlySubmitMessage(ApiException error) {
    return switch (error.kind) {
      ApiErrorKind.network =>
        'Cannot update your report right now. Check your connection and try again.',
      ApiErrorKind.timeout =>
        'Updating your report timed out. Please try again.',
      ApiErrorKind.invalidResponse =>
        'The updated report could not be read from the server response.',
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
