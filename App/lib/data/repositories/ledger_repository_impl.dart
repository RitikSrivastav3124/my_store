import '../../domain/entities/dashboard_summary.dart';
import '../../domain/entities/ledger_transaction.dart';
import '../../domain/entities/store_customer.dart';
import '../../domain/repositories/ledger_repository.dart';
import '../datasources/remote/ledger_remote_datasource.dart';

class LedgerRepositoryImpl implements LedgerRepository {
  LedgerRepositoryImpl(this._remoteDataSource);

  final LedgerRemoteDataSource _remoteDataSource;

  @override
  Future<DashboardSummary> fetchDashboard() async {
    return DashboardSummary.fromJson(await _remoteDataSource.dashboard());
  }

  @override
  Future<List<StoreCustomer>> fetchCustomers({String? search, String? status, int page = 1}) async {
    final rows = await _remoteDataSource.customers(search: search, status: status, page: page);
    return rows.map((item) => StoreCustomer.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<StoreCustomer> createCustomer(Map<String, dynamic> payload) async {
    return StoreCustomer.fromJson(await _remoteDataSource.createCustomer(payload));
  }

  @override
  Future<StoreCustomer> updateCustomer(String id, Map<String, dynamic> payload) async {
    return StoreCustomer.fromJson(await _remoteDataSource.updateCustomer(id, payload));
  }

  @override
  Future<void> deleteCustomer(String id) => _remoteDataSource.deleteCustomer(id);

  @override
  Future<StoreCustomer> toggleSuspend(String id) async {
    return StoreCustomer.fromJson(await _remoteDataSource.toggleSuspend(id));
  }

  @override
  Future<StoreCustomer> fetchCustomer(String id) async {
    return StoreCustomer.fromJson(await _remoteDataSource.customer(id));
  }

  @override
  Future<List<LedgerTransaction>> fetchCustomerHistory(String id) async {
    final rows = await _remoteDataSource.ownerHistory(id);
    return rows.map((item) => LedgerTransaction.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<StoreCustomer> fetchMyProfile() async {
    return StoreCustomer.fromJson(await _remoteDataSource.myProfile());
  }

  @override
  Future<List<LedgerTransaction>> fetchMyHistory() async {
    final rows = await _remoteDataSource.myHistory();
    return rows.map((item) => LedgerTransaction.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<Map<String, dynamic>> addDue(String id, double amount, String description) {
    return _remoteDataSource.addDue(id, {
      'amount': amount,
      'description': description,
      'paymentMethod': 'other',
    });
  }

  @override
  Future<Map<String, dynamic>> recordPayment(
    String id,
    double amount,
    String description,
    String paymentMethod,
  ) {
    return _remoteDataSource.payment(id, {
      'amount': amount,
      'description': description,
      'paymentMethod': paymentMethod,
    });
  }

  @override
  Future<Map<String, dynamic>> reduceDue(String id, double amount, String description) {
    return _remoteDataSource.reduceDue(id, {
      'amount': amount,
      'description': description,
      'paymentMethod': 'other',
    });
  }

  @override
  Future<List<StoreCustomer>> fetchOutstanding() async {
    final rows = await _remoteDataSource.outstanding();
    return rows.map((item) => StoreCustomer.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMonthlyReport() async {
    final rows = await _remoteDataSource.monthlyReport();
    return rows.map((item) => item as Map<String, dynamic>).toList();
  }
}
