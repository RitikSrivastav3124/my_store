import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/ledger_transaction.dart';
import '../../viewmodels/customer_view_model.dart';
import '../../widgets/async_state_widgets.dart';
import '../../widgets/transaction_section_list.dart';

class CustomerHistoryScreen extends StatelessWidget {
  const CustomerHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<CustomerViewModel, _CustomerHistoryData>(
      selector: (_, vm) => _CustomerHistoryData(
        history: vm.history,
        loading: vm.loading,
        error: vm.error,
      ),
      builder: (context, data, _) => Scaffold(
        appBar: AppBar(title: const Text('Transaction History')),
        body: RefreshIndicator(
          onRefresh: context.read<CustomerViewModel>().refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (data.error != null)
                ErrorBanner(
                  message: data.error!,
                  onClose: context.read<CustomerViewModel>().clearError,
                ),
              if (data.loading && data.history.isEmpty)
                const SizedBox(height: 320, child: LoadingView())
              else if (data.history.isEmpty)
                const SizedBox(
                  height: 320,
                  child: EmptyState(
                    icon: Icons.history,
                    title: 'No transactions',
                    message: 'Your complete ledger history will be shown here.',
                  ),
                )
              else
                TransactionSectionList(transactions: data.history),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerHistoryData {
  const _CustomerHistoryData({
    required this.history,
    required this.loading,
    required this.error,
  });

  final List<LedgerTransaction> history;
  final bool loading;
  final String? error;

  @override
  bool operator ==(Object other) {
    return other is _CustomerHistoryData &&
        identical(other.history, history) &&
        other.loading == loading &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(history, loading, error);
}
