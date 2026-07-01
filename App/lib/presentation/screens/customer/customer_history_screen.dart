import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/customer_view_model.dart';
import '../../widgets/async_state_widgets.dart';
import '../../widgets/transaction_tile.dart';

class CustomerHistoryScreen extends StatelessWidget {
  const CustomerHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomerViewModel>(
      builder: (context, vm, _) => Scaffold(
        appBar: AppBar(title: const Text('Transaction History')),
        body: RefreshIndicator(
          onRefresh: vm.refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (vm.error != null) ErrorBanner(message: vm.error!, onClose: vm.clearError),
              if (vm.loading && vm.history.isEmpty)
                const SizedBox(height: 320, child: LoadingView())
              else if (vm.history.isEmpty)
                const SizedBox(
                  height: 320,
                  child: EmptyState(
                    icon: Icons.history,
                    title: 'No transactions',
                    message: 'Your complete ledger history will be shown here.',
                  ),
                )
              else
                ...vm.history.map((item) => TransactionTile(transaction: item)),
            ],
          ),
        ),
      ),
    );
  }
}
