import 'package:equatable/equatable.dart';

import '../../../reports/domain/models/report_summary.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    this.recentReports = const [],
    this.totalReports = 0,
    this.isRefreshing = false,
    this.errorMessage,
  });

  final HomeStatus status;
  final List<CitizenReportSummary> recentReports;
  final int totalReports;
  final bool isRefreshing;
  final String? errorMessage;

  bool get isInitialLoading =>
      status == HomeStatus.loading && recentReports.isEmpty && !isRefreshing;

  HomeState copyWith({
    HomeStatus? status,
    List<CitizenReportSummary>? recentReports,
    int? totalReports,
    bool? isRefreshing,
    Object? errorMessage = _unchanged,
  }) {
    return HomeState(
      status: status ?? this.status,
      recentReports: recentReports ?? this.recentReports,
      totalReports: totalReports ?? this.totalReports,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: errorMessage == _unchanged
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    recentReports,
    totalReports,
    isRefreshing,
    errorMessage,
  ];
}

const _unchanged = Object();
