import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig._();

  static const appName = 'Khata Ledger';

  static String get apiBaseUrl {
    const configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (configuredBaseUrl.isNotEmpty) return configuredBaseUrl;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api';
    }

    return 'http://localhost:5000/api';
  }
}
