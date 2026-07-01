import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../viewmodels/customer_view_model.dart';
import '../../widgets/async_state_widgets.dart';
import '../../widgets/transaction_tile.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomerViewModel>(
      builder: (context, vm, _) {
        final profile = vm.profile;
        return Scaffold(
          appBar: AppBar(
            title: const Text('My Ledger'),
            actions: [
              IconButton(onPressed: vm.refresh, icon: const Icon(Icons.refresh), tooltip: 'Refresh'),
            ],
          ),
          body: profile == null && vm.loading
              ? const LoadingView()
              : RefreshIndicator(
                  onRefresh: vm.refresh,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (vm.error != null) ErrorBanner(message: vm.error!, onClose: vm.clearError),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(profile?.user.name ?? 'Customer', style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 8),
                              Text(profile?.user.phone ?? ''),
                              const SizedBox(height: 20),
                              Text('Total Due', style: Theme.of(context).textTheme.labelLarge),
                              const SizedBox(height: 6),
                              Text(
                                CurrencyFormatter.format(profile?.currentDue ?? 0),
                                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: (profile?.currentDue ?? 0) > 0 ? Colors.red.shade600 : Colors.green.shade600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text('Recent Activity', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      if (vm.history.isEmpty)
                        const EmptyState(
                          icon: Icons.receipt_long,
                          title: 'No ledger activity',
                          message: 'Transactions recorded by the owner will appear here.',
                        )
                      else
                        ...vm.history.take(5).map((item) => TransactionTile(transaction: item)),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
