import '../../../core/network/api_client.dart';

class NotificationRemoteDataSource {
  NotificationRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<List<dynamic>> notifications() async {
    return await _apiClient.get('/notifications', query: {'limit': 50}) as List<dynamic>;
  }

  Future<Map<String, dynamic>> markRead(String id) async {
    return await _apiClient.put('/notifications/$id/read') as Map<String, dynamic>;
  }
}
