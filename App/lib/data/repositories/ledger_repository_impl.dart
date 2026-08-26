import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../domain/entities/dashboard_summary.dart';
import '../../domain/entities/ledger_transaction.dart';
import '../../domain/entities/store_customer.dart';
import '../../domain/repositories/ledger_repository.dart';
import '../datasources/remote/ledger_remote_datasource.dart';

const _modelMappingIsolateThreshold = 20;

List<StoreCustomer> _storeCustomersFromRows(List<dynamic> rows) {
  return rows
      .map((item) => StoreCustomer.fromJson(Map<String, dynamic>.from(item as Map)))
      .toList();
}

List<LedgerTransaction> _ledgerTransactionsFromRows(List<dynamic> rows) {
  return rows
      .map((item) => LedgerTransaction.fromJson(Map<String, dynamic>.from(item as Map)))
      .toList();
}

List<Map<String, dynamic>> _mapsFromRows(List<dynamic> rows) {
  return rows.map((item) => Map<String, dynamic>.from(item as Map)).toList();
}

class LedgerRepositoryImpl implements LedgerRepository {
  LedgerRepositoryImpl(this._remoteDataSource);

  final LedgerRemoteDataSource _remoteDataSource;
  final _random = Random.secure();

  String _requestId() => '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 32)}';

  @override
  Future<DashboardSummary> fetchDashboard() async {
    return DashboardSummary.fromJson(await _remoteDataSource.dashboard());
  }

  @override
  Future<List<StoreCustomer>> fetchCustomers({String? search, String? status, int page = 1}) async {
    final rows = await _remoteDataSource.customers(search: search, status: status, page: page);
    return rows.length >= _modelMappingIsolateThreshold
        ? compute(_storeCustomersFromRows, rows)
        : _storeCustomersFromRows(rows);
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
    return rows.length >= _modelMappingIsolateThreshold
        ? compute(_ledgerTransactionsFromRows, rows)
        : _ledgerTransactionsFromRows(rows);
  }

  @override
  Future<StoreCustomer> fetchMyProfile() async {
    return StoreCustomer.fromJson(await _remoteDataSource.myProfile());
  }

  @override
  Future<List<LedgerTransaction>> fetchMyHistory() async {
    final rows = await _remoteDataSource.myHistory();
    return rows.length >= _modelMappingIsolateThreshold
        ? compute(_ledgerTransactionsFromRows, rows)
        : _ledgerTransactionsFromRows(rows);
  }

  @override
  Future<Map<String, dynamic>> addDue(String id, double amount, String description) {
    return _remoteDataSource.addDue(id, {
      'amount': amount,
      'description': description,
      'paymentMethod': 'other',
      'requestId': _requestId(),
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
      'requestId': _requestId(),
    });
  }

  @override
  Future<Map<String, dynamic>> reduceDue(String id, double amount, String description) {
    return _remoteDataSource.reduceDue(id, {
      'amount': amount,
      'description': description,
      'paymentMethod': 'other',
      'requestId': _requestId(),
    });
  }

  @override
  Future<List<StoreCustomer>> fetchOutstanding() async {
    final rows = await _remoteDataSource.outstanding();
    return rows.length >= _modelMappingIsolateThreshold
        ? compute(_storeCustomersFromRows, rows)
        : _storeCustomersFromRows(rows);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMonthlyReport() async {
    final rows = await _remoteDataSource.monthlyReport();
    return rows.length >= _modelMappingIsolateThreshold
        ? compute(_mapsFromRows, rows)
        : _mapsFromRows(rows);
  }
}
