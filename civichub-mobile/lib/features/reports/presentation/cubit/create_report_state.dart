import 'package:equatable/equatable.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/models/report_category.dart';
import '../../domain/models/report_detail.dart';

enum CreateReportStatus { initial, loadingCategories, ready, categoryFailure }

enum CreateReportSubmitStatus { idle, submitting, success, failure }

class CreateReportState extends Equatable {
  const CreateReportState({
    this.status = CreateReportStatus.initial,
    this.submitStatus = CreateReportSubmitStatus.idle,
    this.categories = const [],
    this.selectedCategoryId,
    this.categoryErrorMessage,
    this.submitErrorMessage,
    this.submitErrorKind,
    this.createdReport,
  });

  final CreateReportStatus status;
  final CreateReportSubmitStatus submitStatus;
  final List<ReportCategory> categories;
  final int? selectedCategoryId;
  final String? categoryErrorMessage;
  final String? submitErrorMessage;
  final ApiErrorKind? submitErrorKind;
  final CitizenReportDetail? createdReport;

  bool get canSubmit =>
      status == CreateReportStatus.ready &&
      submitStatus != CreateReportSubmitStatus.submitting &&
      selectedCategoryId != null;

  CreateReportState copyWith({
    CreateReportStatus? status,
    CreateReportSubmitStatus? submitStatus,
    List<ReportCategory>? categories,
    Object? selectedCategoryId = _unchanged,
    Object? categoryErrorMessage = _unchanged,
    Object? submitErrorMessage = _unchanged,
    Object? submitErrorKind = _unchanged,
    Object? createdReport = _unchanged,
  }) {
    return CreateReportState(
      status: status ?? this.status,
      submitStatus: submitStatus ?? this.submitStatus,
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId == _unchanged
          ? this.selectedCategoryId
          : selectedCategoryId as int?,
      categoryErrorMessage: categoryErrorMessage == _unchanged
          ? this.categoryErrorMessage
          : categoryErrorMessage as String?,
      submitErrorMessage: submitErrorMessage == _unchanged
          ? this.submitErrorMessage
          : submitErrorMessage as String?,
      submitErrorKind: submitErrorKind == _unchanged
          ? this.submitErrorKind
          : submitErrorKind as ApiErrorKind?,
      createdReport: createdReport == _unchanged
          ? this.createdReport
          : createdReport as CitizenReportDetail?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    submitStatus,
    categories,
    selectedCategoryId,
    categoryErrorMessage,
    submitErrorMessage,
    submitErrorKind,
    createdReport,
  ];
}

const _unchanged = Object();
