import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/models/citizen_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit({required NotificationsRepository notificationsRepository})
    : _notificationsRepository = notificationsRepository,
      super(const NotificationsState());

  static const int pageSize = 20;

  final NotificationsRepository _notificationsRepository;
  int _requestGeneration = 0;

  Future<void> loadInitial() async {
    if (state.status == NotificationsStatus.loading &&
        state.notifications.isEmpty) {
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

  Future<void> markAsRead(CitizenNotification notification) async {
    if (notification.isRead || state.markingIds.contains(notification.id)) {
      return;
    }

    emit(
      state.copyWith(
        markingIds: {...state.markingIds, notification.id},
        markErrorMessage: null,
      ),
    );

    try {
      final updated = await _notificationsRepository.markAsRead(
        notification.id,
      );
      final wasUnread =
          state.notifications
              .firstWhere(
                (item) => item.id == notification.id,
                orElse: () => notification,
              )
              .isRead ==
          false;
      final merged = state.notifications
          .map((item) => item.id == updated.id ? updated : item)
          .toList(growable: false);
      emit(
        state.copyWith(
          notifications: merged,
          unreadCount: wasUnread ? _decrementUnreadCount() : state.unreadCount,
          markingIds: _withoutMarking(notification.id),
          markErrorMessage: null,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          markingIds: _withoutMarking(notification.id),
          markErrorMessage: _friendlyMessage(error),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          markingIds: _withoutMarking(notification.id),
          markErrorMessage: ApiException.unknown.message,
        ),
      );
    }
  }

  Future<void> _load({required bool refreshing}) async {
    final generation = ++_requestGeneration;
    emit(
      state.copyWith(
        status: refreshing ? state.status : NotificationsStatus.loading,
        isRefreshing: refreshing,
        page: 0,
        hasReachedEnd: false,
        errorMessage: null,
        errorKind: null,
        markErrorMessage: null,
      ),
    );

    try {
      final page = await _notificationsRepository.getMyNotifications(
        page: 0,
        size: pageSize,
        sortBy: 'createdAt',
        direction: 'DESC',
      );
      final unreadCount = await _notificationsRepository.getUnreadCount();
      if (generation != _requestGeneration) {
        return;
      }

      emit(
        state.copyWith(
          status: NotificationsStatus.success,
          notifications: page.content,
          page: page.page,
          totalElements: page.totalElements,
          totalPages: page.totalPages,
          hasReachedEnd: page.last,
          isRefreshing: false,
          unreadCount: unreadCount < 0 ? 0 : unreadCount,
          markingIds: const {},
          errorMessage: null,
          errorKind: null,
          markErrorMessage: null,
        ),
      );
    } on ApiException catch (error) {
      if (generation != _requestGeneration) {
        return;
      }
      emit(
        state.copyWith(
          status: NotificationsStatus.failure,
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
          status: NotificationsStatus.failure,
          isRefreshing: false,
          errorMessage: ApiException.unknown.message,
          errorKind: ApiErrorKind.unknown,
        ),
      );
    }
  }

  int _decrementUnreadCount() {
    final next = state.unreadCount - 1;
    return next < 0 ? 0 : next;
  }

  Set<int> _withoutMarking(int id) {
    return {...state.markingIds}..remove(id);
  }

  String _friendlyMessage(ApiException error) {
    return switch (error.kind) {
      ApiErrorKind.network =>
        'Cannot load notifications right now. Check your connection and try again.',
      ApiErrorKind.timeout =>
        'Loading notifications timed out. Please try again.',
      ApiErrorKind.unauthorized => error.message,
      ApiErrorKind.forbidden => error.message,
      ApiErrorKind.server =>
        'The server is unavailable right now. Please try again.',
      ApiErrorKind.invalidResponse =>
        'Notifications could not be read from the server response.',
      ApiErrorKind.badRequest ||
      ApiErrorKind.notFound ||
      ApiErrorKind.conflict ||
      ApiErrorKind.unknown => error.message,
    };
  }
}
