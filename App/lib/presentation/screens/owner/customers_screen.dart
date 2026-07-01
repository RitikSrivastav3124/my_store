import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/owner_view_model.dart';
import '../../widgets/async_state_widgets.dart';
import '../../widgets/customer_tile.dart';
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
    return Consumer<OwnerViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Customers')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openAddDialog,
            icon: const Icon(Icons.person_add),
            label: const Text('Add'),
          ),
          body: RefreshIndicator(
            onRefresh: () => vm.loadCustomers(search: _searchController.text),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SearchBar(
                  controller: _searchController,
                  leading: const Icon(Icons.search),
                  hintText: 'Search customers',
                  onSubmitted: (value) => vm.loadCustomers(search: value),
                  trailing: [
                    IconButton(
                      tooltip: 'Search',
                      onPressed: () => vm.loadCustomers(search: _searchController.text),
                      icon: const Icon(Icons.arrow_forward),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (vm.error != null) ErrorBanner(message: vm.error!, onClose: vm.clearError),
                if (vm.loading && vm.customers.isEmpty)
                  const SizedBox(height: 320, child: LoadingView())
                else if (vm.customers.isEmpty)
                  const SizedBox(
                    height: 320,
                    child: EmptyState(
                      icon: Icons.groups_outlined,
                      title: 'No customers yet',
                      message: 'Create your first customer account to start the ledger.',
                    ),
                  )
                else
                  ...vm.customers.map(
                    (customer) => CustomerTile(
                      customer: customer,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => CustomerDetailScreen(customerId: customer.id)),
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
  final _password = TextEditingController(text: 'Customer123');
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
              TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone'), validator: _required),
              const SizedBox(height: 12),
              TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Email'), validator: _required),
              const SizedBox(height: 12),
              TextFormField(controller: _password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true, validator: _required),
              const SizedBox(height: 12),
              TextFormField(controller: _creditLimit, decoration: const InputDecoration(labelText: 'Credit limit'), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TextFormField(controller: _openingDue, decoration: const InputDecoration(labelText: 'Opening due'), keyboardType: TextInputType.number),
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
