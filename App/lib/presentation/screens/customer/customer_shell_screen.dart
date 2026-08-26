import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/customer_view_model.dart';
import '../../viewmodels/notification_view_model.dart';
import '../notifications/notifications_screen.dart';
import '../settings/settings_screen.dart';
import 'customer_history_screen.dart';
import 'customer_home_screen.dart';

class CustomerShellScreen extends StatefulWidget {
  const CustomerShellScreen({super.key});

  @override
  State<CustomerShellScreen> createState() => _CustomerShellScreenState();
}

class _CustomerShellScreenState extends State<CustomerShellScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final customerViewModel = context.read<CustomerViewModel>();
      final notificationViewModel = context.read<NotificationViewModel>();

      await Future.wait([
        customerViewModel.refresh(),
        notificationViewModel.refresh(),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = const [
      CustomerHomeScreen(),
      CustomerHistoryScreen(),
      NotificationsScreen(),
      SettingsScreen(),
    ];
    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'History'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'Alerts'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
