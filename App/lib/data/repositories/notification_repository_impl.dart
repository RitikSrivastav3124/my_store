import 'package:flutter/foundation.dart';

import '../../domain/entities/notification_item.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/remote/notification_remote_datasource.dart';

const _modelMappingIsolateThreshold = 20;

List<NotificationItem> _notificationItemsFromRows(List<dynamic> rows) {
  return rows
      .map((item) => NotificationItem.fromJson(Map<String, dynamic>.from(item as Map)))
      .toList();
}

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._remoteDataSource);

  final NotificationRemoteDataSource _remoteDataSource;

  @override
  Future<List<NotificationItem>> fetchNotifications() async {
    final rows = await _remoteDataSource.notifications();
    return rows.length >= _modelMappingIsolateThreshold
        ? compute(_notificationItemsFromRows, rows)
        : _notificationItemsFromRows(rows);
  }

  @override
  Future<NotificationItem> markRead(String id) async {
    return NotificationItem.fromJson(await _remoteDataSource.markRead(id));
  }
}
