import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.child});

  final Widget child;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  var _showSplash = true;

  @override
  void initState() {
    super.initState();
    _waitForBackend();
  }

Future<void> _waitForBackend() async {
  final minimumSplashFuture = Future<void>.delayed(
    const Duration(seconds: 3),
  );

  debugPrint('SPLASH: health check started');

  try {
    await Future.wait([
      context.read<ApiClient>().get('/health', auth: false).timeout(
            const Duration(seconds: 60),
          ),
      minimumSplashFuture,
    ]);

    debugPrint('SPLASH: health check SUCCESS');

    if (mounted) {
      setState(() => _showSplash = false);
      debugPrint('SPLASH: hiding splash');
    }
  } catch (error, stackTrace) {
    debugPrint('SPLASH: health check FAILED: $error');
    debugPrintStack(stackTrace: stackTrace);

    await minimumSplashFuture;

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cannot reach the server: $error'),
        duration: const Duration(days: 1),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: _waitForBackend,
        ),
      ),
    );
  }
}  

  @override
  Widget build(BuildContext context) {
    if (!_showSplash) return widget.child;

    return Scaffold(
      body: Center(
        child: Image.asset('assets/app_launcher_icon.png', width: 120, height: 120),
      ),
    );
  }
}
