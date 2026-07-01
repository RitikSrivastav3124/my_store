import '../../domain/entities/notification_item.dart';
import '../../domain/repositories/notification_repository.dart';
import 'base_view_model.dart';

class NotificationViewModel extends BaseViewModel {
  NotificationViewModel(this._repository);

  final NotificationRepository _repository;

  List<NotificationItem> notifications = [];
  int get unreadCount => notifications.where((item) => !item.read).length;

  Future<void> refresh() async {
    await guard(() async {
      notifications = await _repository.fetchNotifications();
    });
  }

  Future<void> markRead(String id) async {
    await guard(() => _repository.markRead(id));
    notifications = notifications
        .map((item) => item.id == id
            ? NotificationItem(
                id: item.id,
                title: item.title,
                body: item.body,
                read: true,
                createdAt: item.createdAt,
              )
            : item)
        .toList();
  }
}
