import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/notification_view_model.dart';
import '../../viewmodels/owner_view_model.dart';
import '../notifications/notifications_screen.dart';
import '../settings/settings_screen.dart';
import 'customers_screen.dart';
import 'dashboard_screen.dart';
import 'reports_screen.dart';

class OwnerShellScreen extends StatefulWidget {
  const OwnerShellScreen({super.key});

  @override
  State<OwnerShellScreen> createState() => _OwnerShellScreenState();
}

class _OwnerShellScreenState extends State<OwnerShellScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final ownerViewModel = context.read<OwnerViewModel>();
      final notificationViewModel = context.read<NotificationViewModel>();

      await Future.wait([
        () async {
          await ownerViewModel.refreshDashboard();
          if (!mounted) return;
          await ownerViewModel.loadCustomers();
        }(),
        notificationViewModel.refresh(),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = const [
      DashboardScreen(),
      CustomersScreen(),
      ReportsScreen(),
      NotificationsScreen(),
      SettingsScreen(),
    ];
    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Customers'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Reports'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'Alerts'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
