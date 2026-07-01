import '../../../core/network/api_client.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> registerOwner(Map<String, dynamic> payload) async {
    return await _apiClient.post('/auth/register', body: payload, auth: false) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login(Map<String, dynamic> payload) async {
    return await _apiClient.post('/auth/login', body: payload, auth: false) as Map<String, dynamic>;
  }

  Future<void> logout(String? refreshToken) async {
    await _apiClient.post('/auth/logout', body: {'refreshToken': refreshToken}, auth: false);
  }

  Future<void> changePassword(Map<String, dynamic> payload) async {
    await _apiClient.post('/auth/change-password', body: payload);
  }

  Future<void> registerFcmToken(String token) async {
    await _apiClient.post('/auth/fcm-token', body: {'fcmToken': token});
  }
}
