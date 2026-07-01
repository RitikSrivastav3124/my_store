import '../../core/storage/secure_storage_service.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/remote/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteDataSource, this._storage);

  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorageService _storage;

  AuthSession _sessionFromJson(Map<String, dynamic> json) {
    return AuthSession(
      user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
    );
  }

  Future<AuthSession> _persist(AuthSession session) async {
    await _storage.saveSession(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      user: session.user,
    );
    return session;
  }

  @override
  Future<AuthSession> login({
    required String identifier,
    required String password,
    String? fcmToken,
  }) async {
    final response = await _remoteDataSource.login({
      'identifier': identifier,
      'password': password,
      if (fcmToken != null) 'fcmToken': fcmToken,
    });
    return _persist(_sessionFromJson(response));
  }

  @override
  Future<AuthSession> registerOwner({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    final response = await _remoteDataSource.registerOwner({
      'name': name,
      'phone': phone,
      'email': email,
      'password': password,
    });
    return _persist(_sessionFromJson(response));
  }

  @override
  Future<void> logout(String? refreshToken) async {
    await _remoteDataSource.logout(refreshToken);
    await _storage.clearSession();
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _remoteDataSource.changePassword({
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  @override
  Future<void> registerFcmToken(String token) => _remoteDataSource.registerFcmToken(token);
}
