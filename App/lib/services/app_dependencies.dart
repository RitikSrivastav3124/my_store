import '../core/network/api_client.dart';
import '../core/storage/secure_storage_service.dart';
import '../data/datasources/remote/auth_remote_datasource.dart';
import '../data/datasources/remote/ledger_remote_datasource.dart';
import '../data/datasources/remote/notification_remote_datasource.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/ledger_repository_impl.dart';
import '../data/repositories/notification_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/ledger_repository.dart';
import '../domain/repositories/notification_repository.dart';
import 'export_service.dart';
import 'notification_service.dart';

class AppDependencies {
  AppDependencies() {
    storage = SecureStorageService();
    apiClient = ApiClient(
      tokenReader: storage.readAccessToken,
      refreshTokenReader: storage.readRefreshToken,
      tokenWriter: storage.updateTokens,
      sessionClearer: storage.clearSession,
    );
    authRepository = AuthRepositoryImpl(AuthRemoteDataSource(apiClient), storage);
    ledgerRepository = LedgerRepositoryImpl(LedgerRemoteDataSource(apiClient));
    notificationRepository = NotificationRepositoryImpl(NotificationRemoteDataSource(apiClient));
    notificationService = NotificationService(authRepository);
    exportService = ExportService(apiClient);
  }

  late final SecureStorageService storage;
  late final ApiClient apiClient;
  late final AuthRepository authRepository;
  late final LedgerRepository ledgerRepository;
  late final NotificationRepository notificationRepository;
  late final NotificationService notificationService;
  late final ExportService exportService;
}
