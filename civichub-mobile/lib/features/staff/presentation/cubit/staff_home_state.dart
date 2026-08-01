import 'package:equatable/equatable.dart';

import '../../../../core/network/api_exception.dart';
import '../../../reports/domain/models/report_summary.dart';
import '../../domain/models/staff_dashboard_summary.dart';

enum StaffHomeStatus { initial, loading, success, failure }

class StaffHomeState extends Equatable {
  const StaffHomeState({
    this.status = StaffHomeStatus.initial,
    this.summary,
    this.recentReports = const [],
    this.unreadCount = 0,
    this.isRefreshing = false,
    this.errorMessage,
    this.errorKind,
  });

  final StaffHomeStatus status;
  final StaffDashboardSummary? summary;
  final List<CitizenReportSummary> recentReports;
  final int unreadCount;
  final bool isRefreshing;
  final String? errorMessage;
  final ApiErrorKind? errorKind;

  bool get isInitialLoading =>
      status == StaffHomeStatus.loading && summary == null && !isRefreshing;

  StaffHomeState copyWith({
    StaffHomeStatus? status,
    Object? summary = _unchanged,
    List<CitizenReportSummary>? recentReports,
    int? unreadCount,
    bool? isRefreshing,
    Object? errorMessage = _unchanged,
    Object? errorKind = _unchanged,
  }) {
    return StaffHomeState(
      status: status ?? this.status,
      summary: summary == _unchanged
          ? this.summary
          : summary as StaffDashboardSummary?,
      recentReports: recentReports ?? this.recentReports,
      unreadCount: unreadCount ?? this.unreadCount,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: errorMessage == _unchanged
          ? this.errorMessage
          : errorMessage as String?,
      errorKind: errorKind == _unchanged
          ? this.errorKind
          : errorKind as ApiErrorKind?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    summary,
    recentReports,
    unreadCount,
    isRefreshing,
    errorMessage,
    errorKind,
  ];
}

const _unchanged = Object();
