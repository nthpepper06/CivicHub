import 'package:equatable/equatable.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/models/report_detail.dart';

enum ReportDetailStatus { initial, loading, success, empty, failure }

class ReportDetailState extends Equatable {
  const ReportDetailState({
    this.status = ReportDetailStatus.initial,
    this.report,
    this.errorMessage,
    this.errorKind,
  });

  final ReportDetailStatus status;
  final CitizenReportDetail? report;
  final String? errorMessage;
  final ApiErrorKind? errorKind;

  bool get isUnauthorized =>
      errorKind == ApiErrorKind.unauthorized ||
      errorKind == ApiErrorKind.forbidden;

  ReportDetailState copyWith({
    ReportDetailStatus? status,
    Object? report = _unchanged,
    Object? errorMessage = _unchanged,
    Object? errorKind = _unchanged,
  }) {
    return ReportDetailState(
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
