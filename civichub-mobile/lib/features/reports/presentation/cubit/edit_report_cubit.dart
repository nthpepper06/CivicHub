import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/models/create_report_request.dart';
import '../../domain/models/report_detail.dart';
import '../../domain/repositories/reports_repository.dart';
import 'edit_report_state.dart';

class EditReportCubit extends Cubit<EditReportState> {
  EditReportCubit({
    required ReportsRepository reportsRepository,
    required CitizenReportDetail initialReport,
  }) : _reportsRepository = reportsRepository,
       _initialReport = initialReport,
       super(EditReportState(selectedCategoryId: initialReport.categoryId));

  final ReportsRepository _reportsRepository;
  final CitizenReportDetail _initialReport;

  Future<void> loadCategories() async {
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
          selectedCategoryId: _initialReport.categoryId,
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
        _initialReport.id,
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
