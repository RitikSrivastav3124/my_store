import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/store_customer.dart';
import '../../viewmodels/owner_view_model.dart';
import '../../widgets/async_state_widgets.dart';
import '../../widgets/customer_tile.dart';
import '../../widgets/section_header.dart';
import 'customer_detail_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openAddDialog() async {
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _CustomerFormDialog(),
    );
    if (payload == null || !mounted) return;
    final success = await context.read<OwnerViewModel>().createCustomer(payload);
    if (!mounted || !success) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer created')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Add'),
      ),
      body: RefreshIndicator(
        onRefresh: () => context
            .read<OwnerViewModel>()
            .loadCustomers(search: _searchController.text),
        child: _CustomersList(
          searchBar: _CustomerSearchBar(controller: _searchController),
        ),
      ),
    );
  }
}

class _CustomerSearchBar extends StatelessWidget {
  const _CustomerSearchBar({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      controller: controller,
      leading: const Icon(Icons.search),
      hintText: 'Search by name or phone',
      onSubmitted: (value) => context.read<OwnerViewModel>().loadCustomers(search: value),
      trailing: [
        IconButton(
          tooltip: 'Search',
          onPressed: () => context.read<OwnerViewModel>().loadCustomers(search: controller.text),
          icon: const Icon(Icons.arrow_forward),
        ),
      ],
    );
  }
}

class _CustomersList extends StatelessWidget {
  const _CustomersList({required this.searchBar});

  final Widget searchBar;

  @override
  Widget build(BuildContext context) {
    return Selector<OwnerViewModel, List<StoreCustomer>>(
      selector: (_, vm) => vm.customers,
      shouldRebuild: (previous, next) => !identical(previous, next),
      builder: (context, customers, child) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: customers.isEmpty ? 3 : customers.length + 2,
          itemBuilder: (context, index) {
            if (index == 0) return child!;
            if (index == 1) return _CustomersHeader(customerCount: customers.length);
            if (customers.isEmpty) return const _CustomersLoadingEmptyState();

            final customer = customers[index - 2];
            return CustomerTile(
              customer: customer,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CustomerDetailScreen(customerId: customer.id),
                ),
              ),
            );
          },
        );
      },
      child: searchBar,
    );
  }
}

class _CustomersHeader extends StatelessWidget {
  const _CustomersHeader({required this.customerCount});

  final int customerCount;

  @override
  Widget build(BuildContext context) {
    return Selector<OwnerViewModel, String?>(
      selector: (_, vm) => vm.error,
      builder: (context, error, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            if (error != null)
              ErrorBanner(
                message: error,
                onClose: context.read<OwnerViewModel>().clearError,
              ),
            if (customerCount > 0) SectionHeader(title: '$customerCount Customers'),
          ],
        );
      },
    );
  }
}

class _CustomersLoadingEmptyState extends StatelessWidget {
  const _CustomersLoadingEmptyState();

  @override
  Widget build(BuildContext context) {
    return Selector<OwnerViewModel, bool>(
      selector: (_, vm) => vm.loading && vm.customers.isEmpty,
      builder: (_, loading, __) {
        return loading
            ? const SizedBox(height: 320, child: LoadingView())
            : const SizedBox(
                height: 320,
                child: EmptyState(
                  icon: Icons.groups_outlined,
                  title: 'No customers yet',
                  message: 'Create your first customer account to start the ledger.',
                ),
              );
      },
    );
  }
}

class _CustomerFormDialog extends StatefulWidget {
  const _CustomerFormDialog();

  @override
  State<_CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<_CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController(text: 'Customer123!');
  final _creditLimit = TextEditingController(text: '0');
  final _openingDue = TextEditingController(text: '0');
  final _notes = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _creditLimit.dispose();
    _openingDue.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Customer'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Name'), validator: _required),
              const SizedBox(height: 12),
              TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone, validator: _required),
              const SizedBox(height: 12),
              TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress, validator: _required),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  final password = value ?? '';
                  final strong = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z\d]).{8,72}$');
                  return strong.hasMatch(password) ? null : 'Use uppercase, lowercase, number, and special character';
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _creditLimit,
                decoration: const InputDecoration(labelText: 'Credit limit', prefixIcon: Icon(Icons.currency_rupee)),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _openingDue,
                decoration: const InputDecoration(labelText: 'Opening due', prefixIcon: Icon(Icons.receipt_long)),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _notes, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 2),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop({
              'name': _name.text.trim(),
              'phone': _phone.text.trim(),
              'email': _email.text.trim(),
              'password': _password.text,
              'creditLimit': double.tryParse(_creditLimit.text) ?? 0,
              'openingDue': double.tryParse(_openingDue.text) ?? 0,
              'notes': _notes.text.trim(),
            });
          },
          child: const Text('Create'),
        ),
      ],
    );
  }

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Required' : null;
}
