import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../reports/domain/repositories/reports_repository.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({required ReportsRepository reportsRepository})
    : _reportsRepository = reportsRepository,
      super(const HomeState());

  static const int recentReportsLimit = 5;

  final ReportsRepository _reportsRepository;

  Future<void> load() async {
    if (state.isInitialLoading) {
      return;
    }
    await _load(refreshing: false);
  }

  Future<void> refresh() async {
    if (state.isRefreshing) {
      return;
    }
    await _load(refreshing: true);
  }

  Future<void> retry() async {
    await _load(refreshing: false);
  }

  Future<void> _load({required bool refreshing}) async {
    emit(
      state.copyWith(
        status: refreshing ? state.status : HomeStatus.loading,
        isRefreshing: refreshing,
        errorMessage: null,
      ),
    );

    try {
      final page = await _reportsRepository.getMyReports(
        page: 0,
        size: recentReportsLimit,
        sortBy: 'createdAt',
        direction: 'DESC',
      );
      emit(
        state.copyWith(
          status: HomeStatus.success,
          recentReports: page.content,
          totalReports: page.totalElements,
          isRefreshing: false,
          errorMessage: null,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          status: HomeStatus.failure,
          isRefreshing: false,
          errorMessage: _friendlyMessage(error),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: HomeStatus.failure,
          isRefreshing: false,
          errorMessage: ApiException.unknown.message,
        ),
      );
    }
  }

  String _friendlyMessage(ApiException error) {
    return switch (error.kind) {
      ApiErrorKind.network =>
        'Cannot load your report summary right now. Check your connection and try again.',
      ApiErrorKind.timeout =>
        'Loading your report summary timed out. Please try again.',
      ApiErrorKind.server =>
        'The server is unavailable right now. Please try again.',
      ApiErrorKind.invalidResponse =>
        'Your report summary could not be read from the server response.',
      ApiErrorKind.badRequest ||
      ApiErrorKind.unauthorized ||
      ApiErrorKind.forbidden ||
      ApiErrorKind.notFound ||
      ApiErrorKind.conflict ||
      ApiErrorKind.unknown => error.message,
    };
  }
}
