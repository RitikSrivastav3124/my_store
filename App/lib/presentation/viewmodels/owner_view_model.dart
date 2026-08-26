import '../../domain/entities/dashboard_summary.dart';
import '../../domain/entities/ledger_transaction.dart';
import '../../domain/entities/store_customer.dart';
import '../../domain/repositories/ledger_repository.dart';
import '../../services/export_service.dart';
import 'base_view_model.dart';

class OwnerViewModel extends BaseViewModel {
  OwnerViewModel(this._ledgerRepository, this._exportService);

  final LedgerRepository _ledgerRepository;
  final ExportService _exportService;

  DashboardSummary dashboard = DashboardSummary.empty();
  List<StoreCustomer> customers = [];
  List<StoreCustomer> outstanding = [];
  List<LedgerTransaction> selectedHistory = [];
  List<Map<String, dynamic>> monthlyReport = [];
  StoreCustomer? selectedCustomer;

  Future<void> refreshDashboard() async {
    await guard(() async {
      final results = await Future.wait<dynamic>([
        _ledgerRepository.fetchDashboard(),
        _ledgerRepository.fetchMonthlyReport(),
      ]);
      dashboard = results[0] as DashboardSummary;
      monthlyReport = results[1] as List<Map<String, dynamic>>;
    });
  }

  Future<void> loadCustomers({String? search, String? status}) async {
    await guard(() async {
      customers = await _ledgerRepository.fetchCustomers(search: search, status: status);
    });
  }

  Future<void> loadOutstanding() async {
    await guard(() async {
      outstanding = await _ledgerRepository.fetchOutstanding();
    });
  }

  Future<bool> createCustomer(Map<String, dynamic> payload) async {
    final customer = await guard(() => _ledgerRepository.createCustomer(payload));
    if (customer == null) return false;
    customers = [customer, ...customers];
    await refreshDashboard();
    return true;
  }

  Future<void> openCustomer(String id) async {
    await guard(() async {
      final results = await Future.wait<dynamic>([
        _ledgerRepository.fetchCustomer(id),
        _ledgerRepository.fetchCustomerHistory(id),
      ]);
      selectedCustomer = results[0] as StoreCustomer;
      selectedHistory = results[1] as List<LedgerTransaction>;
    });
  }

  Future<bool> addDue(String id, double amount, String description) async {
    final result = await guard(() => _ledgerRepository.addDue(id, amount, description));
    if (result == null) return false;
    await Future.wait([
      openCustomer(id),
      loadCustomers(),
      refreshDashboard(),
    ]);
    return true;
  }

  Future<bool> recordPayment(String id, double amount, String description, String paymentMethod) async {
    final result = await guard(() => _ledgerRepository.recordPayment(id, amount, description, paymentMethod));
    if (result == null) return false;
    await Future.wait([
      openCustomer(id),
      loadCustomers(),
      refreshDashboard(),
    ]);
    return true;
  }

  Future<bool> reduceDue(String id, double amount, String description) async {
    final result = await guard(() => _ledgerRepository.reduceDue(id, amount, description));
    if (result == null) return false;
    await Future.wait([
      openCustomer(id),
      loadCustomers(),
      refreshDashboard(),
    ]);
    return true;
  }

  Future<void> toggleSuspend(String id) async {
    await guard(() => _ledgerRepository.toggleSuspend(id));
    await loadCustomers();
  }

  Future<void> deleteCustomer(String id) async {
    await guard(() => _ledgerRepository.deleteCustomer(id));
    customers = customers.where((customer) => customer.id != id).toList();
    await refreshDashboard();
  }

  Future<void> shareReport(String format) async {
    await guard(() => _exportService.shareOutstanding(format));
  }
}
