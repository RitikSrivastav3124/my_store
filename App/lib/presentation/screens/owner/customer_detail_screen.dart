import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../viewmodels/owner_view_model.dart';
import '../../widgets/async_state_widgets.dart';
import '../../widgets/transaction_tile.dart';

class CustomerDetailScreen extends StatefulWidget {
  const CustomerDetailScreen({super.key, required this.customerId});

  final String customerId;

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OwnerViewModel>().openCustomer(widget.customerId);
    });
  }

  Future<void> _ledgerAction(String title, Future<bool> Function(double amount, String description) action) async {
    final result = await showDialog<({double amount, String description})>(
      context: context,
      builder: (_) => _LedgerDialog(title: title),
    );
    if (result == null || !mounted) return;
    final success = await action(result.amount, result.description);
    if (!mounted || !success) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$title saved')));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OwnerViewModel>(
      builder: (context, vm, _) {
        final customer = vm.selectedCustomer;
        return Scaffold(
          appBar: AppBar(
            title: Text(customer?.user.name ?? 'Customer'),
            actions: [
              IconButton(
                tooltip: 'Suspend or activate',
                onPressed: customer == null ? null : () => vm.toggleSuspend(customer.id),
                icon: const Icon(Icons.block),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: customer == null
                    ? null
                    : () async {
                        await vm.deleteCustomer(customer.id);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          body: customer == null && vm.loading
              ? const LoadingView()
              : customer == null
                  ? const EmptyState(icon: Icons.person_off, title: 'Customer unavailable', message: 'The customer could not be loaded.')
                  : RefreshIndicator(
                      onRefresh: () => vm.openCustomer(widget.customerId),
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
                                  Text(customer.user.name, style: Theme.of(context).textTheme.headlineSmall),
                                  const SizedBox(height: 6),
                                  Text('${customer.user.phone}${customer.user.email == null ? '' : ' • ${customer.user.email}'}'),
                                  const SizedBox(height: 16),
                                  Text(
                                    CurrencyFormatter.format(customer.currentDue),
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          color: customer.currentDue > 0 ? Colors.red.shade600 : Colors.green.shade600,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Credit limit ${CurrencyFormatter.format(customer.creditLimit)}'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton.icon(
                                onPressed: () => _ledgerAction('Add due', (amount, description) => vm.addDue(customer.id, amount, description)),
                                icon: const Icon(Icons.add),
                                label: const Text('Add Due'),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: () => _ledgerAction('Record payment', (amount, description) => vm.recordPayment(customer.id, amount, description, 'cash')),
                                icon: const Icon(Icons.payments),
                                label: const Text('Payment'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _ledgerAction('Reduce due', (amount, description) => vm.reduceDue(customer.id, amount, description)),
                                icon: const Icon(Icons.remove),
                                label: const Text('Reduce'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text('Transaction History', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          if (vm.selectedHistory.isEmpty)
                            const EmptyState(
                              icon: Icons.receipt_long,
                              title: 'No transactions',
                              message: 'Ledger entries for this customer will appear here.',
                            )
                          else
                            ...vm.selectedHistory.map((item) => TransactionTile(transaction: item)),
                        ],
                      ),
                    ),
        );
      },
    );
  }
}

class _LedgerDialog extends StatefulWidget {
  const _LedgerDialog({required this.title});

  final String title;

  @override
  State<_LedgerDialog> createState() => _LedgerDialogState();
}

class _LedgerDialogState extends State<_LedgerDialog> {
  final _amount = TextEditingController();
  final _description = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final amount = double.tryParse(_amount.text) ?? 0;
            if (amount <= 0) return;
            Navigator.of(context).pop((amount: amount, description: _description.text.trim()));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
