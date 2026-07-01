class AppConfig {
  const AppConfig._();

  static const appName = 'Khata Ledger';
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5000/api',
  );
}
