import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/models/create_report_request.dart';
import '../../domain/repositories/reports_repository.dart';
import 'create_report_state.dart';

class CreateReportCubit extends Cubit<CreateReportState> {
  CreateReportCubit({required ReportsRepository reportsRepository})
    : _reportsRepository = reportsRepository,
      super(const CreateReportState());

  final ReportsRepository _reportsRepository;

  Future<void> loadCategories() async {
    if (state.status == CreateReportStatus.loadingCategories) {
      return;
    }

    emit(
      state.copyWith(
        status: CreateReportStatus.loadingCategories,
        categoryErrorMessage: null,
      ),
    );

    try {
      final categories = await _reportsRepository.getCategories();
      emit(
        state.copyWith(
          status: CreateReportStatus.ready,
          categories: categories,
          selectedCategoryId: categories.length == 1
              ? categories.single.id
              : null,
          categoryErrorMessage: null,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          status: CreateReportStatus.categoryFailure,
          categoryErrorMessage: _friendlyCategoryMessage(error),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: CreateReportStatus.categoryFailure,
          categoryErrorMessage: ApiException.unknown.message,
        ),
      );
    }
  }

  void selectCategory(int? categoryId) {
    emit(
      state.copyWith(
        selectedCategoryId: categoryId,
        submitStatus: CreateReportSubmitStatus.idle,
        submitErrorMessage: null,
        submitErrorKind: null,
      ),
    );
  }

  Future<void> useCurrentLocation() async {
    emit(
      state.copyWith(
        locationLoading: false,
        locationErrorMessage:
            'GPS is not available in this build. Enter latitude and longitude manually.',
      ),
    );
  }

  Future<void> submit(CreateReportRequest request) async {
    if (state.submitStatus == CreateReportSubmitStatus.submitting) {
      return;
    }

    emit(
      state.copyWith(
        submitStatus: CreateReportSubmitStatus.submitting,
        submitErrorMessage: null,
        submitErrorKind: null,
        createdReport: null,
      ),
    );

    try {
      final created = await _reportsRepository.createReport(request);
      emit(
        state.copyWith(
          submitStatus: CreateReportSubmitStatus.success,
          submitErrorMessage: null,
          submitErrorKind: null,
          createdReport: created,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          submitStatus: CreateReportSubmitStatus.failure,
          submitErrorMessage: _friendlySubmitMessage(error),
          submitErrorKind: error.kind,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          submitStatus: CreateReportSubmitStatus.failure,
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
        'Cannot submit your report right now. Check your connection and try again.',
      ApiErrorKind.timeout =>
        'Submitting your report timed out. Please try again.',
      ApiErrorKind.invalidResponse =>
        'The created report could not be read from the server response.',
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
