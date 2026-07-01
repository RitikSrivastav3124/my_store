import '../entities/notification_item.dart';

abstract class NotificationRepository {
  Future<List<NotificationItem>> fetchNotifications();

  Future<NotificationItem> markRead(String id);
}
