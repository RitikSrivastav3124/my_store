import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/utils/currency_formatter.dart';
import '../../domain/entities/ledger_transaction.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction});

  final LedgerTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final isPayment = transaction.type == 'payment_received' || transaction.type == 'due_reduced';
    final color = isPayment ? Colors.green.shade600 : Colors.red.shade600;
    final icon = isPayment ? Icons.south_west : Icons.north_east;
    final title = switch (transaction.type) {
      'payment_received' => 'Payment received',
      'due_reduced' => 'Due reduced',
      _ => 'Due added',
    };

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(
          '${DateFormat.yMMMd().add_jm().format(transaction.createdAt)}'
          '${transaction.description?.isNotEmpty == true ? ' • ${transaction.description}' : ''}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.format(transaction.amount),
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
            Text('Bal ${CurrencyFormatter.format(transaction.balanceAfter)}'),
          ],
        ),
      ),
    );
  }
}
