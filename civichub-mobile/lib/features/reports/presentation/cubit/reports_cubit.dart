import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/models/report_category.dart';
import '../../domain/models/report_status.dart';
import '../../domain/models/report_summary.dart';
import '../../domain/repositories/reports_repository.dart';
import 'reports_state.dart';

class ReportsCubit extends Cubit<ReportsState> {
  ReportsCubit({required ReportsRepository reportsRepository})
    : _reportsRepository = reportsRepository,
      super(const ReportsState());

  static const int pageSize = 10;

  final ReportsRepository _reportsRepository;
  int _requestGeneration = 0;

  Future<void> loadInitial() async {
    if (state.status == ReportsStatus.loading && state.reports.isEmpty) {
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

  Future<void> applyStatusFilter(ReportStatus? status) async {
    if (state.statusFilter == status) {
      return;
    }
    emit(state.copyWith(statusFilter: status));
    await _loadFirstPage(refreshing: false);
  }

  Future<void> applyCategoryFilter(int? categoryId) async {
    if (state.categoryIdFilter == categoryId) {
      return;
    }
    emit(state.copyWith(categoryIdFilter: categoryId));
    await _loadFirstPage(refreshing: false);
  }

  Future<void> applySort(ReportsSortOption sortOption) async {
    if (state.sortOption == sortOption) {
      return;
    }
    emit(state.copyWith(sortOption: sortOption));
    await _loadFirstPage(refreshing: false);
  }

  Future<void> applySearch(String value) async {
    final normalized = value.trim();
    if (state.search == normalized) {
      return;
    }
    emit(state.copyWith(search: normalized));
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
      final page = await _reportsRepository.getMyReports(
        page: nextPage,
        size: pageSize,
        search: state.search,
        status: state.statusFilter,
        categoryId: state.categoryIdFilter,
        sortBy: state.sortOption.sortBy,
        direction: state.sortOption.direction,
      );
      if (generation != _requestGeneration) {
        return;
      }

      final merged = _mergeUnique(state.reports, page.content);
      emit(
        state.copyWith(
          status: ReportsStatus.success,
          reports: merged,
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

  Future<void> _loadFirstPage({required bool refreshing}) async {
    final generation = ++_requestGeneration;
    emit(
      state.copyWith(
        status: refreshing ? state.status : ReportsStatus.loading,
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
      final page = await _reportsRepository.getMyReports(
        page: 0,
        size: pageSize,
        search: state.search,
        status: state.statusFilter,
        categoryId: state.categoryIdFilter,
        sortBy: state.sortOption.sortBy,
        direction: state.sortOption.direction,
      );
      if (generation != _requestGeneration) {
        return;
      }
      emit(
        state.copyWith(
          status: ReportsStatus.success,
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
          status: ReportsStatus.failure,
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
          status: ReportsStatus.failure,
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

  String _friendlyMessage(ApiException error) {
    return switch (error.kind) {
      ApiErrorKind.network =>
        'Cannot load reports right now. Check your connection and try again.',
      ApiErrorKind.timeout => 'Loading reports timed out. Please try again.',
      ApiErrorKind.unauthorized => error.message,
      ApiErrorKind.forbidden => error.message,
      ApiErrorKind.server =>
        'The server is unavailable right now. Please try again.',
      ApiErrorKind.invalidResponse =>
        'Reports could not be read from the server response.',
      ApiErrorKind.badRequest ||
      ApiErrorKind.notFound ||
      ApiErrorKind.conflict ||
      ApiErrorKind.unknown => error.message,
    };
  }
}
