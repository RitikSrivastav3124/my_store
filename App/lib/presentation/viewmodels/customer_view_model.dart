import '../../domain/entities/ledger_transaction.dart';
import '../../domain/entities/store_customer.dart';
import '../../domain/repositories/ledger_repository.dart';
import 'base_view_model.dart';

class CustomerViewModel extends BaseViewModel {
  CustomerViewModel(this._ledgerRepository);

  final LedgerRepository _ledgerRepository;

  StoreCustomer? profile;
  List<LedgerTransaction> history = [];

  Future<void> refresh() async {
    await guard(() async {
      final results = await Future.wait<dynamic>([
        _ledgerRepository.fetchMyProfile(),
        _ledgerRepository.fetchMyHistory(),
      ]);
      profile = results[0] as StoreCustomer;
      history = results[1] as List<LedgerTransaction>;
    });
  }
}
