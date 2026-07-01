import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../viewmodels/owner_view_model.dart';
import '../../widgets/async_state_widgets.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OwnerViewModel>().loadOutstanding();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OwnerViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Reports')),
          body: RefreshIndicator(
            onRefresh: vm.loadOutstanding,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (vm.error != null) ErrorBanner(message: vm.error!, onClose: vm.clearError),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Export Outstanding', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton.icon(onPressed: () => vm.shareReport('pdf'), icon: const Icon(Icons.picture_as_pdf), label: const Text('PDF')),
                            OutlinedButton.icon(onPressed: () => vm.shareReport('csv'), icon: const Icon(Icons.table_chart), label: const Text('CSV')),
                            OutlinedButton.icon(onPressed: () => vm.shareReport('excel'), icon: const Icon(Icons.grid_on), label: const Text('Excel')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Outstanding Customers', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (vm.loading && vm.outstanding.isEmpty)
                  const SizedBox(height: 260, child: LoadingView())
                else if (vm.outstanding.isEmpty)
                  const EmptyState(
                    icon: Icons.done_all,
                    title: 'Nothing outstanding',
                    message: 'Customers with pending dues will appear here.',
                  )
                else
                  ...vm.outstanding.map(
                    (customer) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.account_balance_wallet_outlined),
                        title: Text(customer.user.name),
                        subtitle: Text(customer.user.phone),
                        trailing: Text(
                          CurrencyFormatter.format(customer.currentDue),
                          style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
