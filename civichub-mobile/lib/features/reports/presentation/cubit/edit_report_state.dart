import 'package:equatable/equatable.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/models/report_category.dart';
import '../../domain/models/report_detail.dart';

enum EditReportStatus {
  initial,
  loadingReport,
  loadingCategories,
  ready,
  reportFailure,
  categoryFailure,
}

enum EditReportSubmitStatus { idle, updating, success, failure }

class EditReportState extends Equatable {
  const EditReportState({
    this.status = EditReportStatus.initial,
    this.submitStatus = EditReportSubmitStatus.idle,
    this.categories = const [],
    this.selectedCategoryId,
    this.categoryErrorMessage,
    this.reportErrorMessage,
    this.submitErrorMessage,
    this.submitErrorKind,
    this.report,
    this.updatedReport,
  });

  final EditReportStatus status;
  final EditReportSubmitStatus submitStatus;
  final List<ReportCategory> categories;
  final int? selectedCategoryId;
  final String? categoryErrorMessage;
  final String? reportErrorMessage;
  final String? submitErrorMessage;
  final ApiErrorKind? submitErrorKind;
  final CitizenReportDetail? report;
  final CitizenReportDetail? updatedReport;

  bool get canSubmit =>
      status == EditReportStatus.ready &&
      submitStatus != EditReportSubmitStatus.updating &&
      report != null &&
      selectedCategoryId != null;

  EditReportState copyWith({
    EditReportStatus? status,
    EditReportSubmitStatus? submitStatus,
    List<ReportCategory>? categories,
    Object? selectedCategoryId = _unchanged,
    Object? categoryErrorMessage = _unchanged,
    Object? reportErrorMessage = _unchanged,
    Object? submitErrorMessage = _unchanged,
    Object? submitErrorKind = _unchanged,
    Object? report = _unchanged,
    Object? updatedReport = _unchanged,
  }) {
    return EditReportState(
      status: status ?? this.status,
      submitStatus: submitStatus ?? this.submitStatus,
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId == _unchanged
          ? this.selectedCategoryId
          : selectedCategoryId as int?,
      categoryErrorMessage: categoryErrorMessage == _unchanged
          ? this.categoryErrorMessage
          : categoryErrorMessage as String?,
      reportErrorMessage: reportErrorMessage == _unchanged
          ? this.reportErrorMessage
          : reportErrorMessage as String?,
      submitErrorMessage: submitErrorMessage == _unchanged
          ? this.submitErrorMessage
          : submitErrorMessage as String?,
      submitErrorKind: submitErrorKind == _unchanged
          ? this.submitErrorKind
          : submitErrorKind as ApiErrorKind?,
      report: report == _unchanged
          ? this.report
          : report as CitizenReportDetail?,
      updatedReport: updatedReport == _unchanged
          ? this.updatedReport
          : updatedReport as CitizenReportDetail?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    submitStatus,
    categories,
    selectedCategoryId,
    categoryErrorMessage,
    reportErrorMessage,
    submitErrorMessage,
    submitErrorKind,
    report,
    updatedReport,
  ];
}

const _unchanged = Object();
