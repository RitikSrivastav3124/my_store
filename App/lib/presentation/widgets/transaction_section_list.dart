import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/ledger_transaction.dart';
import 'transaction_tile.dart';

class TransactionSectionList extends StatelessWidget {
  const TransactionSectionList({
    super.key,
    required this.transactions,
    this.limit,
  });

  final List<LedgerTransaction> transactions;
  final int? limit;

  @override
  Widget build(BuildContext context) {
    final visible = limit == null ? transactions : transactions.take(limit!).toList();
    final grouped = <String, List<LedgerTransaction>>{};
    for (final transaction in visible) {
      final key = DateFormat.yMMMd().format(transaction.createdAt);
      grouped.putIfAbsent(key, () => []).add(transaction);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in grouped.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8, left: 4),
            child: Text(
              entry.key,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          ...entry.value.map(
            (transaction) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TransactionTile(transaction: transaction),
            ),
          ),
        ],
      ],
    );
  }
}
