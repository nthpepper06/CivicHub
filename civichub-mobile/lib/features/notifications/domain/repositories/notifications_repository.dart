import '../models/citizen_notification.dart';
import '../models/notifications_page.dart';

abstract class NotificationsRepository {
  Future<NotificationsPage<CitizenNotification>> getMyNotifications({
    required int page,
    required int size,
    bool? unread,
    String? type,
    String? sortBy,
    String? direction,
  });

  Future<int> getUnreadCount();

  Future<CitizenNotification> markAsRead(int id);
}
