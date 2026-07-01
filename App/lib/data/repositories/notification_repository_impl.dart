import '../../domain/entities/notification_item.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/remote/notification_remote_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._remoteDataSource);

  final NotificationRemoteDataSource _remoteDataSource;

  @override
  Future<List<NotificationItem>> fetchNotifications() async {
    final rows = await _remoteDataSource.notifications();
    return rows.map((item) => NotificationItem.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<NotificationItem> markRead(String id) async {
    return NotificationItem.fromJson(await _remoteDataSource.markRead(id));
  }
}
