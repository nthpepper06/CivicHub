import 'package:equatable/equatable.dart';

import '../../../../core/network/api_exception.dart';
import '../../../reports/domain/models/report_category.dart';
import '../../../reports/domain/models/report_status.dart';
import '../../../reports/domain/models/report_summary.dart';

enum StaffReportsStatus { initial, loading, success, failure }

class StaffReportsState extends Equatable {
  const StaffReportsState({
    this.status = StaffReportsStatus.initial,
    this.reports = const [],
    this.categories = const [],
    this.page = 0,
    this.totalElements = 0,
    this.totalPages = 0,
    this.hasReachedEnd = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.isLoadingCategories = false,
    this.search = '',
    this.statusFilter,
    this.categoryIdFilter,
    this.errorMessage,
    this.paginationErrorMessage,
    this.categoryErrorMessage,
    this.errorKind,
  });

  final StaffReportsStatus status;
  final List<CitizenReportSummary> reports;
  final List<ReportCategory> categories;
  final int page;
  final int totalElements;
  final int totalPages;
  final bool hasReachedEnd;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool isLoadingCategories;
  final String search;
  final ReportStatus? statusFilter;
  final int? categoryIdFilter;
  final String? errorMessage;
  final String? paginationErrorMessage;
  final String? categoryErrorMessage;
  final ApiErrorKind? errorKind;

  bool get isInitialLoading =>
      status == StaffReportsStatus.loading && reports.isEmpty && !isRefreshing;

  bool get hasActiveFilters =>
      search.isNotEmpty || statusFilter != null || categoryIdFilter != null;

  StaffReportsState copyWith({
    StaffReportsStatus? status,
    List<CitizenReportSummary>? reports,
    List<ReportCategory>? categories,
    int? page,
    int? totalElements,
    int? totalPages,
    bool? hasReachedEnd,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? isLoadingCategories,
    String? search,
    Object? statusFilter = _unchanged,
    Object? categoryIdFilter = _unchanged,
    Object? errorMessage = _unchanged,
    Object? paginationErrorMessage = _unchanged,
    Object? categoryErrorMessage = _unchanged,
    Object? errorKind = _unchanged,
  }) {
    return StaffReportsState(
      status: status ?? this.status,
      reports: reports ?? this.reports,
      categories: categories ?? this.categories,
      page: page ?? this.page,
      totalElements: totalElements ?? this.totalElements,
      totalPages: totalPages ?? this.totalPages,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isLoadingCategories: isLoadingCategories ?? this.isLoadingCategories,
      search: search ?? this.search,
      statusFilter: statusFilter == _unchanged
          ? this.statusFilter
          : statusFilter as ReportStatus?,
      categoryIdFilter: categoryIdFilter == _unchanged
          ? this.categoryIdFilter
          : categoryIdFilter as int?,
      errorMessage: errorMessage == _unchanged
          ? this.errorMessage
          : errorMessage as String?,
      paginationErrorMessage: paginationErrorMessage == _unchanged
          ? this.paginationErrorMessage
          : paginationErrorMessage as String?,
      categoryErrorMessage: categoryErrorMessage == _unchanged
          ? this.categoryErrorMessage
          : categoryErrorMessage as String?,
      errorKind: errorKind == _unchanged
          ? this.errorKind
          : errorKind as ApiErrorKind?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    reports,
    categories,
    page,
    totalElements,
    totalPages,
    hasReachedEnd,
    isRefreshing,
    isLoadingMore,
    isLoadingCategories,
    search,
    statusFilter,
    categoryIdFilter,
    errorMessage,
    paginationErrorMessage,
    categoryErrorMessage,
    errorKind,
  ];
}

const _unchanged = Object();
