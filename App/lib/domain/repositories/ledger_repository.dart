import '../entities/dashboard_summary.dart';
import '../entities/ledger_transaction.dart';
import '../entities/store_customer.dart';

abstract class LedgerRepository {
  Future<DashboardSummary> fetchDashboard();

  Future<List<StoreCustomer>> fetchCustomers({
    String? search,
    String? status,
    int page,
  });

  Future<StoreCustomer> createCustomer(Map<String, dynamic> payload);

  Future<StoreCustomer> updateCustomer(String id, Map<String, dynamic> payload);

  Future<void> deleteCustomer(String id);

  Future<StoreCustomer> toggleSuspend(String id);

  Future<StoreCustomer> fetchCustomer(String id);

  Future<List<LedgerTransaction>> fetchCustomerHistory(String id);

  Future<List<LedgerTransaction>> fetchMyHistory();

  Future<StoreCustomer> fetchMyProfile();

  Future<Map<String, dynamic>> addDue(String id, double amount, String description);

  Future<Map<String, dynamic>> recordPayment(
    String id,
    double amount,
    String description,
    String paymentMethod,
  );

  Future<Map<String, dynamic>> reduceDue(String id, double amount, String description);

  Future<List<StoreCustomer>> fetchOutstanding();

  Future<List<Map<String, dynamic>>> fetchMonthlyReport();
}
