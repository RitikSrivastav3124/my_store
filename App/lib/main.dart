import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_config.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/customer/customer_shell_screen.dart';
import 'presentation/screens/owner/owner_shell_screen.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/themes/app_theme.dart';
import 'presentation/viewmodels/auth_view_model.dart';
import 'presentation/viewmodels/customer_view_model.dart';
import 'presentation/viewmodels/notification_view_model.dart';
import 'presentation/viewmodels/owner_view_model.dart';
import 'presentation/viewmodels/theme_view_model.dart';
import 'services/app_dependencies.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final dependencies = AppDependencies();
  runApp(KhataLedgerApp(dependencies: dependencies));
}

class KhataLedgerApp extends StatelessWidget {
  const KhataLedgerApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
        ChangeNotifierProvider(
          create: (_) =>
              AuthViewModel(dependencies.authRepository, dependencies.storage)
                ..bootstrap(),
        ),
        ChangeNotifierProvider(
          create: (_) => OwnerViewModel(
            dependencies.ledgerRepository,
            dependencies.exportService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => CustomerViewModel(dependencies.ledgerRepository),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              NotificationViewModel(dependencies.notificationRepository),
        ),
      ],
      child: Consumer<ThemeViewModel>(
        builder: (context, theme, _) => MaterialApp(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          themeMode: theme.themeMode,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: const SplashScreen(child: _RoleGate()),
        ),
      ),
    );
  }
}

class _RoleGate extends StatelessWidget {
  const _RoleGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    if (!auth.isAuthenticated) return const LoginScreen();
    if (auth.isOwner) return const OwnerShellScreen();
    return const CustomerShellScreen();
  }
}
