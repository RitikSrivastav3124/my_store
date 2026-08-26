import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/store_customer.dart';
import '../../viewmodels/owner_view_model.dart';
import '../../widgets/async_state_widgets.dart';
import '../../widgets/section_header.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: RefreshIndicator(
        onRefresh: context.read<OwnerViewModel>().loadOutstanding,
        child: const _OutstandingList(exportCard: _ExportCard()),
      ),
    );
  }
}

class _ExportCard extends StatelessWidget {
  const _ExportCard();

  @override
  Widget build(BuildContext context) {
    final ownerViewModel = context.read<OwnerViewModel>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.file_download_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Export Outstanding',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Share reports with your records or accountant.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: () => ownerViewModel.shareReport('pdf'),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF'),
                ),
                OutlinedButton.icon(
                  onPressed: () => ownerViewModel.shareReport('csv'),
                  icon: const Icon(Icons.table_chart),
                  label: const Text('CSV'),
                ),
                OutlinedButton.icon(
                  onPressed: () => ownerViewModel.shareReport('excel'),
                  icon: const Icon(Icons.grid_on),
                  label: const Text('Excel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OutstandingList extends StatelessWidget {
  const _OutstandingList({required this.exportCard});

  final Widget exportCard;

  @override
  Widget build(BuildContext context) {
    return Selector<OwnerViewModel, List<StoreCustomer>>(
      selector: (_, vm) => vm.outstanding,
      shouldRebuild: (previous, next) => !identical(previous, next),
      builder: (context, outstanding, child) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: outstanding.isEmpty ? 5 : outstanding.length + 4,
          itemBuilder: (context, index) {
            if (index == 0) return const _ReportsErrorBanner();
            if (index == 1) return child!;
            if (index == 2) return const SizedBox(height: 18);
            if (index == 3) return const SectionHeader(title: 'Outstanding Customers');
            if (outstanding.isEmpty) return const _OutstandingLoadingEmptyState();

            final customer = outstanding[index - 4];
            return _OutstandingCustomerTile(customer: customer);
          },
        );
      },
      child: exportCard,
    );
  }
}

class _ReportsErrorBanner extends StatelessWidget {
  const _ReportsErrorBanner();

  @override
  Widget build(BuildContext context) {
    return Selector<OwnerViewModel, String?>(
      selector: (_, vm) => vm.error,
      builder: (context, error, _) {
        return error == null
            ? const SizedBox.shrink()
            : ErrorBanner(
                message: error,
                onClose: context.read<OwnerViewModel>().clearError,
              );
      },
    );
  }
}

class _OutstandingLoadingEmptyState extends StatelessWidget {
  const _OutstandingLoadingEmptyState();

  @override
  Widget build(BuildContext context) {
    return Selector<OwnerViewModel, bool>(
      selector: (_, vm) => vm.loading && vm.outstanding.isEmpty,
      builder: (_, loading, __) {
        return loading
            ? const SizedBox(height: 260, child: LoadingView())
            : const EmptyState(
                icon: Icons.done_all,
                title: 'Nothing outstanding',
                message: 'Customers with pending dues will appear here.',
              );
      },
    );
  }
}

class _OutstandingCustomerTile extends StatelessWidget {
  const _OutstandingCustomerTile({required this.customer});

  final StoreCustomer customer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.red.shade50,
          child: Icon(Icons.account_balance_wallet_outlined, color: Colors.red.shade600),
        ),
        title: Text(customer.user.name, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(customer.user.phone),
        trailing: Text(
          CurrencyFormatter.format(customer.currentDue),
          style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
