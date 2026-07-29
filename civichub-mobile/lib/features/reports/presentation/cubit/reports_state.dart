import 'package:equatable/equatable.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/models/report_status.dart';
import '../../domain/models/report_summary.dart';

enum ReportsStatus { initial, loading, success, failure }

class ReportsState extends Equatable {
  const ReportsState({
    this.status = ReportsStatus.initial,
    this.reports = const [],
    this.page = 0,
    this.totalElements = 0,
    this.totalPages = 0,
    this.hasReachedEnd = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.search = '',
    this.statusFilter,
    this.errorMessage,
    this.paginationErrorMessage,
    this.errorKind,
  });

  final ReportsStatus status;
  final List<CitizenReportSummary> reports;
  final int page;
  final int totalElements;
  final int totalPages;
  final bool hasReachedEnd;
  final bool isRefreshing;
  final bool isLoadingMore;
  final String search;
  final ReportStatus? statusFilter;
  final String? errorMessage;
  final String? paginationErrorMessage;
  final ApiErrorKind? errorKind;

  bool get isInitialLoading =>
      status == ReportsStatus.loading && reports.isEmpty && !isRefreshing;

  ReportsState copyWith({
    ReportsStatus? status,
    List<CitizenReportSummary>? reports,
    int? page,
    int? totalElements,
    int? totalPages,
    bool? hasReachedEnd,
    bool? isRefreshing,
    bool? isLoadingMore,
    String? search,
    Object? statusFilter = _unchanged,
    Object? errorMessage = _unchanged,
    Object? paginationErrorMessage = _unchanged,
    Object? errorKind = _unchanged,
  }) {
    return ReportsState(
      status: status ?? this.status,
      reports: reports ?? this.reports,
      page: page ?? this.page,
      totalElements: totalElements ?? this.totalElements,
      totalPages: totalPages ?? this.totalPages,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      search: search ?? this.search,
      statusFilter: statusFilter == _unchanged
          ? this.statusFilter
          : statusFilter as ReportStatus?,
      errorMessage: errorMessage == _unchanged
          ? this.errorMessage
          : errorMessage as String?,
      paginationErrorMessage: paginationErrorMessage == _unchanged
          ? this.paginationErrorMessage
          : paginationErrorMessage as String?,
      errorKind: errorKind == _unchanged
          ? this.errorKind
          : errorKind as ApiErrorKind?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    reports,
    page,
    totalElements,
    totalPages,
    hasReachedEnd,
    isRefreshing,
    isLoadingMore,
    search,
    statusFilter,
    errorMessage,
    paginationErrorMessage,
    errorKind,
  ];
}

const _unchanged = Object();
