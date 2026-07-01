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
      profile = await _ledgerRepository.fetchMyProfile();
      history = await _ledgerRepository.fetchMyHistory();
    });
  }
}
