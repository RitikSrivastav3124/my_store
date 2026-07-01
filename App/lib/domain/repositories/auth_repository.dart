import '../entities/app_user.dart';

class AuthSession {
  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  final AppUser user;
  final String accessToken;
  final String refreshToken;
}

abstract class AuthRepository {
  Future<AuthSession> login({
    required String identifier,
    required String password,
    String? fcmToken,
  });

  Future<AuthSession> registerOwner({
    required String name,
    required String phone,
    required String email,
    required String password,
  });

  Future<void> logout(String? refreshToken);

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> registerFcmToken(String token);
}
