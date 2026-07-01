import 'package:flutter/material.dart';

import '../../core/utils/currency_formatter.dart';
import '../../domain/entities/store_customer.dart';

class CustomerTile extends StatelessWidget {
  const CustomerTile({
    super.key,
    required this.customer,
    required this.onTap,
  });

  final StoreCustomer customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dueColor = customer.currentDue > 0 ? Colors.red.shade600 : Colors.green.shade600;
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(child: Text(customer.user.name.isEmpty ? '?' : customer.user.name[0])),
        title: Text(customer.user.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${customer.user.phone} • ${customer.user.status}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.format(customer.currentDue),
              style: TextStyle(color: dueColor, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
