import '../../../core/network/api_client.dart';

class LedgerRemoteDataSource {
  LedgerRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> dashboard() async {
    return await _apiClient.get('/reports/dashboard') as Map<String, dynamic>;
  }

  Future<List<dynamic>> customers({String? search, String? status, int page = 1}) async {
    return await _apiClient.get('/customers', query: {
      'page': page,
      'limit': 30,
      'search': search,
      'status': status,
      'sortBy': 'createdAt',
      'sortOrder': 'desc',
    }) as List<dynamic>;
  }

  Future<Map<String, dynamic>> createCustomer(Map<String, dynamic> payload) async {
    return await _apiClient.post('/customers', body: payload) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateCustomer(String id, Map<String, dynamic> payload) async {
    return await _apiClient.put('/customers/$id', body: payload) as Map<String, dynamic>;
  }

  Future<void> deleteCustomer(String id) async {
    await _apiClient.delete('/customers/$id');
  }

  Future<Map<String, dynamic>> toggleSuspend(String id) async {
    return await _apiClient.post('/customers/$id/suspend') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> customer(String id) async {
    return await _apiClient.get('/customers/$id') as Map<String, dynamic>;
  }

  Future<List<dynamic>> ownerHistory(String id) async {
    return await _apiClient.get('/customers/$id/history', query: {'limit': 50}) as List<dynamic>;
  }

  Future<Map<String, dynamic>> myProfile() async {
    return await _apiClient.get('/customer/profile') as Map<String, dynamic>;
  }

  Future<List<dynamic>> myHistory() async {
    return await _apiClient.get('/customer/history', query: {'limit': 50}) as List<dynamic>;
  }

  Future<Map<String, dynamic>> addDue(String id, Map<String, dynamic> payload) async {
    return await _apiClient.post('/customers/$id/addDue', body: payload) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> payment(String id, Map<String, dynamic> payload) async {
    return await _apiClient.post('/customers/$id/payment', body: payload) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> reduceDue(String id, Map<String, dynamic> payload) async {
    return await _apiClient.post('/customers/$id/reduceDue', body: payload) as Map<String, dynamic>;
  }

  Future<List<dynamic>> outstanding() async {
    return await _apiClient.get('/reports/outstanding', query: {'limit': 100}) as List<dynamic>;
  }

  Future<List<dynamic>> monthlyReport() async {
    return await _apiClient.get('/reports/monthly') as List<dynamic>;
  }
}
