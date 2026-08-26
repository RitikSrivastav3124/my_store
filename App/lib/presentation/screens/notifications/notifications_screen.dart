import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/notification_item.dart';
import '../../viewmodels/notification_view_model.dart';
import '../../widgets/async_state_widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Selector<NotificationViewModel, int>(
          selector: (_, vm) => vm.unreadCount,
          builder: (_, unreadCount, __) => Text(
            'Notifications${unreadCount > 0 ? ' ($unreadCount)' : ''}',
          ),
        ),
        actions: [
          IconButton(
            onPressed: context.read<NotificationViewModel>().refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: context.read<NotificationViewModel>().refresh,
        child: const _NotificationList(),
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList();

  @override
  Widget build(BuildContext context) {
    return Selector<NotificationViewModel, List<NotificationItem>>(
      selector: (_, vm) => vm.notifications,
      shouldRebuild: (previous, next) => !identical(previous, next),
      builder: (context, notifications, _) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.isEmpty ? 2 : notifications.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) return const _NotificationsErrorBanner();
            if (notifications.isEmpty) return const _NotificationsLoadingEmptyState();

            final item = notifications[index - 1];
            return _NotificationTile(item: item);
          },
        );
      },
    );
  }
}

class _NotificationsErrorBanner extends StatelessWidget {
  const _NotificationsErrorBanner();

  @override
  Widget build(BuildContext context) {
    return Selector<NotificationViewModel, String?>(
      selector: (_, vm) => vm.error,
      builder: (context, error, _) {
        return error == null
            ? const SizedBox.shrink()
            : ErrorBanner(
                message: error,
                onClose: context.read<NotificationViewModel>().clearError,
              );
      },
    );
  }
}

class _NotificationsLoadingEmptyState extends StatelessWidget {
  const _NotificationsLoadingEmptyState();

  @override
  Widget build(BuildContext context) {
    return Selector<NotificationViewModel, bool>(
      selector: (_, vm) => vm.loading && vm.notifications.isEmpty,
      builder: (_, loading, __) {
        return loading
            ? const SizedBox(height: 320, child: LoadingView())
            : const SizedBox(
                height: 320,
                child: EmptyState(
                  icon: Icons.notifications_none,
                  title: 'No notifications',
                  message: 'Due updates and payment alerts will appear here.',
                ),
              );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: item.read
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
          child: Icon(
            item.read ? Icons.notifications_none : Icons.notifications_active,
            color: item.read
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('${item.body}\n${DateFormat.yMMMd().add_jm().format(item.createdAt)}'),
        ),
        isThreeLine: true,
        trailing: item.read
            ? null
            : IconButton(
                tooltip: 'Mark read',
                onPressed: () => context.read<NotificationViewModel>().markRead(item.id),
                icon: const Icon(Icons.done),
              ),
      ),
    );
  }
}
