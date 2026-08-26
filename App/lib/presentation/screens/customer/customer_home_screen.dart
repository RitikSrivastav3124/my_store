import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/ledger_transaction.dart';
import '../../../domain/entities/store_customer.dart';
import '../../viewmodels/customer_view_model.dart';
import '../../widgets/async_state_widgets.dart';
import '../../widgets/amount_hero_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/transaction_section_list.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<CustomerViewModel, _CustomerHomeData>(
      selector: (_, vm) => _CustomerHomeData(
        profile: vm.profile,
        history: vm.history,
        loading: vm.loading,
        error: vm.error,
      ),
      builder: (context, data, _) {
        final profile = data.profile;
        return Scaffold(
          appBar: AppBar(
            title: const Text('My Ledger'),
            actions: [
              IconButton(
                onPressed: context.read<CustomerViewModel>().refresh,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
          body: profile == null && data.loading
              ? const LoadingView()
              : RefreshIndicator(
                  onRefresh: context.read<CustomerViewModel>().refresh,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (data.error != null)
                        ErrorBanner(
                          message: data.error!,
                          onClose: context.read<CustomerViewModel>().clearError,
                        ),
                      AmountHeroCard(
                        label: 'Current Due',
                        amount: CurrencyFormatter.format(profile?.currentDue ?? 0),
                        icon: Icons.account_balance_wallet,
                        color: (profile?.currentDue ?? 0) > 0 ? Colors.red.shade600 : Colors.green.shade600,
                        subtitle: '${profile?.user.name ?? 'Customer'} • ${profile?.user.phone ?? ''}',
                      ),
                      const SizedBox(height: 18),
                      const SectionHeader(title: 'Recent Transactions'),
                      if (data.history.isEmpty)
                        const EmptyState(
                          icon: Icons.receipt_long,
                          title: 'No ledger activity',
                          message: 'Transactions recorded by the owner will appear here.',
                        )
                      else
                        TransactionSectionList(transactions: data.history, limit: 5),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _CustomerHomeData {
  const _CustomerHomeData({
    required this.profile,
    required this.history,
    required this.loading,
    required this.error,
  });

  final StoreCustomer? profile;
  final List<LedgerTransaction> history;
  final bool loading;
  final String? error;

  @override
  bool operator ==(Object other) {
    return other is _CustomerHomeData &&
        identical(other.profile, profile) &&
        identical(other.history, history) &&
        other.loading == loading &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(profile, history, loading, error);
}
