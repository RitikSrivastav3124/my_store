import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/notification_view_model.dart';
import '../../widgets/async_state_widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationViewModel>(
      builder: (context, vm, _) => Scaffold(
        appBar: AppBar(
          title: Text('Notifications${vm.unreadCount > 0 ? ' (${vm.unreadCount})' : ''}'),
          actions: [
            IconButton(onPressed: vm.refresh, icon: const Icon(Icons.refresh), tooltip: 'Refresh'),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: vm.refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (vm.error != null) ErrorBanner(message: vm.error!, onClose: vm.clearError),
              if (vm.loading && vm.notifications.isEmpty)
                const SizedBox(height: 320, child: LoadingView())
              else if (vm.notifications.isEmpty)
                const SizedBox(
                  height: 320,
                  child: EmptyState(
                    icon: Icons.notifications_none,
                    title: 'No notifications',
                    message: 'Due updates and payment alerts will appear here.',
                  ),
                )
              else
                ...vm.notifications.map(
                  (item) => Card(
                    child: ListTile(
                      leading: Icon(item.read ? Icons.notifications_none : Icons.notifications_active),
                      title: Text(item.title),
                      subtitle: Text('${item.body}\n${DateFormat.yMMMd().add_jm().format(item.createdAt)}'),
                      isThreeLine: true,
                      trailing: item.read
                          ? null
                          : IconButton(
                              tooltip: 'Mark read',
                              onPressed: () => vm.markRead(item.id),
                              icon: const Icon(Icons.done),
                            ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
