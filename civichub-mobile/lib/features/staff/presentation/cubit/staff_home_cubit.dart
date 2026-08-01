import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../notifications/domain/repositories/notifications_repository.dart';
import '../../domain/repositories/staff_repository.dart';
import 'staff_home_state.dart';

class StaffHomeCubit extends Cubit<StaffHomeState> {
  StaffHomeCubit({
    required StaffRepository staffRepository,
    required NotificationsRepository notificationsRepository,
  }) : _staffRepository = staffRepository,
       _notificationsRepository = notificationsRepository,
       super(const StaffHomeState());

  final StaffRepository _staffRepository;
  final NotificationsRepository _notificationsRepository;
  int _requestGeneration = 0;

  Future<void> loadInitial() async {
    if (state.isInitialLoading) {
      return;
    }
    await _load(refreshing: false);
  }

  Future<void> retry() async {
    await _load(refreshing: false);
  }

  Future<void> refresh() async {
    if (state.isRefreshing) {
      return;
    }
    await _load(refreshing: true);
  }

  Future<void> _load({required bool refreshing}) async {
    final generation = ++_requestGeneration;
    emit(
      state.copyWith(
        status: refreshing ? state.status : StaffHomeStatus.loading,
        isRefreshing: refreshing,
        errorMessage: null,
        errorKind: null,
      ),
    );

    try {
      final summaryFuture = _staffRepository.getDashboardSummary();
      final recentReportsFuture = _staffRepository.getRecentReports(size: 5);
      final unreadCountFuture = _notificationsRepository.getUnreadCount();

      final summary = await summaryFuture;
      final recentReports = await recentReportsFuture;
      final unreadCount = await unreadCountFuture;
      if (generation != _requestGeneration) {
        return;
      }
      emit(
        state.copyWith(
          status: StaffHomeStatus.success,
          summary: summary,
          recentReports: recentReports.content,
          unreadCount: unreadCount,
          isRefreshing: false,
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
          status: StaffHomeStatus.failure,
          isRefreshing: false,
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
          status: StaffHomeStatus.failure,
          isRefreshing: false,
          errorMessage: ApiException.unknown.message,
          errorKind: ApiErrorKind.unknown,
        ),
      );
    }
  }

  String _friendlyMessage(ApiException error) {
    return switch (error.kind) {
      ApiErrorKind.network =>
        'Cannot load the staff workspace right now. Check your connection.',
      ApiErrorKind.timeout => 'Staff workspace loading timed out.',
      ApiErrorKind.unauthorized => error.message,
      ApiErrorKind.forbidden => error.message,
      ApiErrorKind.server => 'The server is unavailable right now.',
      ApiErrorKind.invalidResponse =>
        'Staff workspace data could not be read from the server.',
      ApiErrorKind.badRequest ||
      ApiErrorKind.notFound ||
      ApiErrorKind.conflict ||
      ApiErrorKind.unknown => error.message,
    };
  }
}
