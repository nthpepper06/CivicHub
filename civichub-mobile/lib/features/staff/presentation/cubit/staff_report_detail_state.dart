import 'package:equatable/equatable.dart';

import '../../../../core/network/api_exception.dart';
import '../../../reports/domain/models/report_detail.dart';

enum StaffReportDetailStatus { initial, loading, success, failure }

class StaffReportDetailState extends Equatable {
  const StaffReportDetailState({
    this.status = StaffReportDetailStatus.initial,
    this.report,
    this.errorMessage,
    this.errorKind,
  });

  final StaffReportDetailStatus status;
  final CitizenReportDetail? report;
  final String? errorMessage;
  final ApiErrorKind? errorKind;

  bool get isInitialLoading =>
      status == StaffReportDetailStatus.loading && report == null;

  StaffReportDetailState copyWith({
    StaffReportDetailStatus? status,
    Object? report = _unchanged,
    Object? errorMessage = _unchanged,
    Object? errorKind = _unchanged,
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
    );
  }

  @override
  List<Object?> get props => [status, report, errorMessage, errorKind];
}

const _unchanged = Object();
