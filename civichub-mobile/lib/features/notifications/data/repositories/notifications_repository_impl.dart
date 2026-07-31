import '../../domain/models/citizen_notification.dart';
import '../../domain/models/notifications_page.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_data_source.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl({
    required NotificationsRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final NotificationsRemoteDataSource _remoteDataSource;

  @override
  Future<NotificationsPage<CitizenNotification>> getMyNotifications({
    required int page,
    required int size,
    bool? unread,
    String? type,
    String? sortBy,
    String? direction,
  }) async {
    final response = await _remoteDataSource.getMyNotifications(
      page: page,
      size: size,
      unread: unread,
      type: type,
      sortBy: sortBy,
      direction: direction,
    );
    return response.toDomain((notification) => notification.toDomain());
  }

  @override
  Future<int> getUnreadCount() {
    return _remoteDataSource.getUnreadCount();
  }

  @override
  Future<CitizenNotification> markAsRead(int id) async {
    return (await _remoteDataSource.markAsRead(id)).toDomain();
  }
}
