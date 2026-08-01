import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../reports/domain/models/report_category.dart';
import '../../../reports/domain/models/report_status.dart';
import '../../../reports/domain/models/report_summary.dart';
import '../../../reports/domain/repositories/reports_repository.dart';
import '../../domain/repositories/staff_repository.dart';
import 'staff_reports_filters.dart';
import 'staff_reports_state.dart';

class StaffReportsCubit extends Cubit<StaffReportsState> {
  StaffReportsCubit({
    required StaffRepository staffRepository,
    required ReportsRepository reportsRepository,
  }) : _staffRepository = staffRepository,
       _reportsRepository = reportsRepository,
       super(
         StaffReportsState(
           search: _savedFilters.search,
           statusFilter: _savedFilters.status,
           categoryIdFilter: _savedFilters.categoryId,
           citizenIdFilter: _savedFilters.citizenId,
           createdFromFilter: _savedFilters.createdFrom,
           createdToFilter: _savedFilters.createdTo,
         ),
       );

  static const int pageSize = 10;
  static StaffReportsFilters _savedFilters = const StaffReportsFilters();

  static void resetSessionFiltersForTest() {
    _savedFilters = const StaffReportsFilters();
  }

  final StaffRepository _staffRepository;
  final ReportsRepository _reportsRepository;
  int _requestGeneration = 0;

  Future<void> loadInitial() async {
    if (state.isInitialLoading) {
      return;
    }
    await _loadCategoriesIfNeeded();
    await _loadFirstPage(refreshing: false);
  }

  Future<void> retry() async {
    await _loadFirstPage(refreshing: false);
  }

  Future<void> refresh() async {
    if (state.isRefreshing) {
      return;
    }
    await _loadFirstPage(refreshing: true);
  }

  Future<void> applySearch(String value) async {
    final normalized = value.trim();
    if (state.search == normalized) {
      return;
    }
    emit(state.copyWith(search: normalized));
    _rememberFilters();
    await _loadFirstPage(refreshing: false);
  }

  Future<void> applyStatusFilter(ReportStatus? status) async {
    if (state.statusFilter == status) {
      return;
    }
    emit(state.copyWith(statusFilter: status));
    _rememberFilters();
    await _loadFirstPage(refreshing: false);
  }

  Future<void> applyCategoryFilter(int? categoryId) async {
    if (state.categoryIdFilter == categoryId) {
      return;
    }
    emit(state.copyWith(categoryIdFilter: categoryId));
    _rememberFilters();
    await _loadFirstPage(refreshing: false);
  }

  Future<void> applyCitizenFilter(String value) async {
    final trimmed = value.trim();
    final citizenId = trimmed.isEmpty ? null : int.tryParse(trimmed);
    if (trimmed.isNotEmpty && citizenId == null) {
      return;
    }
    if (state.citizenIdFilter == citizenId) {
      return;
    }
    emit(state.copyWith(citizenIdFilter: citizenId));
    _rememberFilters();
    await _loadFirstPage(refreshing: false);
  }

  Future<void> applyDateRange(DateTime? from, DateTime? to) async {
    if (state.createdFromFilter == from && state.createdToFilter == to) {
      return;
    }
    emit(state.copyWith(createdFromFilter: from, createdToFilter: to));
    _rememberFilters();
    await _loadFirstPage(refreshing: false);
  }

  Future<void> clearFilters() async {
    if (!state.hasActiveFilters) {
      return;
    }
    emit(
      state.copyWith(
        search: '',
        statusFilter: null,
        categoryIdFilter: null,
        citizenIdFilter: null,
        createdFromFilter: null,
        createdToFilter: null,
      ),
    );
    _rememberFilters();
    await _loadFirstPage(refreshing: false);
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore ||
        state.isRefreshing ||
        state.isInitialLoading ||
        state.hasReachedEnd) {
      return;
    }

    final generation = ++_requestGeneration;
    emit(state.copyWith(isLoadingMore: true, paginationErrorMessage: null));

    try {
      final nextPage = state.page + 1;
      final page = await _staffRepository.getAssignedReports(
        page: nextPage,
        size: pageSize,
        search: state.search,
        status: state.statusFilter,
        categoryId: state.categoryIdFilter,
        citizenId: state.citizenIdFilter,
        createdFrom: state.createdFromFilter,
        createdTo: state.createdToFilter,
      );
      if (generation != _requestGeneration) {
        return;
      }
      emit(
        state.copyWith(
          status: StaffReportsStatus.success,
          reports: _mergeUnique(state.reports, page.content),
          page: page.page,
          totalElements: page.totalElements,
          totalPages: page.totalPages,
          hasReachedEnd: page.last,
          isLoadingMore: false,
          paginationErrorMessage: null,
          errorMessage: null,
          errorKind: null,
        ),
      );
    } on ApiException catch (error) {
      if (generation != _requestGeneration) {
        return;
      }
      emit(
        state.copyWith(
          isLoadingMore: false,
          paginationErrorMessage: _friendlyMessage(error),
        ),
      );
    } catch (_) {
      if (generation != _requestGeneration) {
        return;
      }
      emit(
        state.copyWith(
          isLoadingMore: false,
          paginationErrorMessage: ApiException.unknown.message,
        ),
      );
    }
  }

  CitizenReportSummary? nextReportAfter(int reportId) {
    final index = state.reports.indexWhere((report) => report.id == reportId);
    if (index == -1 || index + 1 >= state.reports.length) {
      return null;
    }
    return state.reports[index + 1];
  }

  CitizenReportSummary? previousReportBefore(int reportId) {
    final index = state.reports.indexWhere((report) => report.id == reportId);
    if (index <= 0) {
      return null;
    }
    return state.reports[index - 1];
  }

  CitizenReportSummary? get oldestPending {
    return _oldestByCreated(
      state.reports.where((report) => report.status == ReportStatus.pending),
    );
  }

  Future<void> _loadFirstPage({required bool refreshing}) async {
    final generation = ++_requestGeneration;
    emit(
      state.copyWith(
        status: refreshing ? state.status : StaffReportsStatus.loading,
        isRefreshing: refreshing,
        isLoadingMore: false,
        page: 0,
        hasReachedEnd: false,
        errorMessage: null,
        paginationErrorMessage: null,
        errorKind: null,
      ),
    );

    try {
      final page = await _staffRepository.getAssignedReports(
        page: 0,
        size: pageSize,
        search: state.search,
        status: state.statusFilter,
        categoryId: state.categoryIdFilter,
        citizenId: state.citizenIdFilter,
        createdFrom: state.createdFromFilter,
        createdTo: state.createdToFilter,
      );
      if (generation != _requestGeneration) {
        return;
      }
      emit(
        state.copyWith(
          status: StaffReportsStatus.success,
          reports: page.content,
          page: page.page,
          totalElements: page.totalElements,
          totalPages: page.totalPages,
          hasReachedEnd: page.last,
          isRefreshing: false,
          isLoadingMore: false,
          errorMessage: null,
          paginationErrorMessage: null,
          errorKind: null,
        ),
      );
    } on ApiException catch (error) {
      if (generation != _requestGeneration) {
        return;
      }
      emit(
        state.copyWith(
          status: StaffReportsStatus.failure,
          isRefreshing: false,
          isLoadingMore: false,
          errorMessage: _friendlyMessage(error),
          errorKind: error.kind,
        ),
      );
    } catch (_) {
      if (generation != _requestGeneration) {
        return;
      }
      emit(
        state.copyWith(
          status: StaffReportsStatus.failure,
          isRefreshing: false,
          isLoadingMore: false,
          errorMessage: ApiException.unknown.message,
          errorKind: ApiErrorKind.unknown,
        ),
      );
    }
  }

  Future<void> _loadCategoriesIfNeeded() async {
    if (state.categories.isNotEmpty || state.isLoadingCategories) {
      return;
    }
    emit(state.copyWith(isLoadingCategories: true, categoryErrorMessage: null));
    try {
      final categories = await _reportsRepository.getCategories();
      emit(
        state.copyWith(
          categories: _activeCategories(categories),
          isLoadingCategories: false,
          categoryErrorMessage: null,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          isLoadingCategories: false,
          categoryErrorMessage: _friendlyMessage(error),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isLoadingCategories: false,
          categoryErrorMessage: ApiException.unknown.message,
        ),
      );
    }
  }

  List<CitizenReportSummary> _mergeUnique(
    List<CitizenReportSummary> existing,
    List<CitizenReportSummary> incoming,
  ) {
    final seenIds = existing.map((report) => report.id).toSet();
    return [
      ...existing,
      for (final report in incoming)
        if (seenIds.add(report.id)) report,
    ];
  }

  List<ReportCategory> _activeCategories(List<ReportCategory> categories) {
    return categories.where((category) => category.isActive).toList();
  }

  CitizenReportSummary? _oldestByCreated(
    Iterable<CitizenReportSummary> reports,
  ) {
    final sorted = reports.toList()
      ..sort((a, b) {
        final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return left.compareTo(right);
      });
    return sorted.isEmpty ? null : sorted.first;
  }

  void _rememberFilters() {
    _savedFilters = StaffReportsFilters(
      search: state.search,
      status: state.statusFilter,
      categoryId: state.categoryIdFilter,
      citizenId: state.citizenIdFilter,
      createdFrom: state.createdFromFilter,
      createdTo: state.createdToFilter,
    );
  }

  String _friendlyMessage(ApiException error) {
    return switch (error.kind) {
      ApiErrorKind.network =>
        'Cannot load assigned reports right now. Check your connection.',
      ApiErrorKind.timeout => 'Loading assigned reports timed out.',
      ApiErrorKind.unauthorized => error.message,
      ApiErrorKind.forbidden => error.message,
      ApiErrorKind.server => 'The server is unavailable right now.',
      ApiErrorKind.invalidResponse =>
        'Assigned reports could not be read from the server response.',
      ApiErrorKind.badRequest ||
      ApiErrorKind.notFound ||
      ApiErrorKind.conflict ||
      ApiErrorKind.unknown => error.message,
    };
  }
}
