import 'package:equatable/equatable.dart';

import '../../../../core/network/api_exception.dart';
import '../../../reports/domain/models/report_detail.dart';
import '../../../reports/domain/models/report_status.dart';
import '../../domain/models/staff_status_workflow.dart';

enum StaffReportDetailStatus { initial, loading, success, failure }

class StaffReportDetailState extends Equatable {
  const StaffReportDetailState({
    this.status = StaffReportDetailStatus.initial,
    this.report,
    this.errorMessage,
    this.errorKind,
    this.updatingStatus,
    this.updateErrorMessage,
    this.updateSuccessMessage,
  });

  final StaffReportDetailStatus status;
  final CitizenReportDetail? report;
  final String? errorMessage;
  final ApiErrorKind? errorKind;
  final ReportStatus? updatingStatus;
  final String? updateErrorMessage;
  final String? updateSuccessMessage;

  bool get isInitialLoading =>
      status == StaffReportDetailStatus.loading && report == null;

  bool get isUpdatingStatus => updatingStatus != null;

  List<ReportStatus> get availableActions {
    final current = report?.status;
    if (current == null) {
      return const [];
    }
    return StaffStatusWorkflow.actionsFor(current);
  }

  StaffReportDetailState copyWith({
    StaffReportDetailStatus? status,
    Object? report = _unchanged,
    Object? errorMessage = _unchanged,
    Object? errorKind = _unchanged,
    Object? updatingStatus = _unchanged,
    Object? updateErrorMessage = _unchanged,
    Object? updateSuccessMessage = _unchanged,
  }) {
    return StaffReportDetailState(
      status: status ?? this.status,
      report: report == _unchanged
          ? this.report
          : report as CitizenReportDetail?,
      errorMessage: errorMessage == _unchanged
          ? this.errorMessage
          : errorMessage as String?,
      errorKind: errorKind == _unchanged
          ? this.errorKind
          : errorKind as ApiErrorKind?,
      updatingStatus: updatingStatus == _unchanged
          ? this.updatingStatus
          : updatingStatus as ReportStatus?,
      updateErrorMessage: updateErrorMessage == _unchanged
          ? this.updateErrorMessage
          : updateErrorMessage as String?,
      updateSuccessMessage: updateSuccessMessage == _unchanged
          ? this.updateSuccessMessage
          : updateSuccessMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    report,
    errorMessage,
    errorKind,
    updatingStatus,
    updateErrorMessage,
    updateSuccessMessage,
  ];
}

const _unchanged = Object();
