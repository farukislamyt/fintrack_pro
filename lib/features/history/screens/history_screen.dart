import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/providers/transaction_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(filteredTransactionsProvider);
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search categories or descriptions...',
                prefixIcon: const Icon(LucideIcons.search),
                filled: true,
                fillColor: Theme.of(context).cardTheme.color,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).updateQuery(value);
              },
            ),
          ),
        ),
      ),
      body: transactions.isEmpty 
        ? const Center(child: Text('No transactions found.'))
        : ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final tx = transactions[index];
              final isIncome = tx.type == TransactionType.income;
              
              return Dismissible(
                key: Key(tx.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: const Icon(LucideIcons.trash, color: Colors.white),
                ),
                onDismissed: (direction) {
                  ref.read(transactionProvider.notifier).deleteTransaction(tx.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${tx.category} deleted')),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isIncome 
                          ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1)
                          : Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isIncome ? LucideIcons.arrowDownToLine : LucideIcons.arrowUpFromLine,
                        color: isIncome ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.error,
                      ),
                    ),
                    title: Text(tx.category),
                    subtitle: Text(tx.description.isNotEmpty 
                        ? '${tx.description} • ${DateFormat.yMMMd().format(tx.date)}' 
                        : DateFormat.yMMMd().format(tx.date)),
                    trailing: Text(
                      '${isIncome ? '+' : '-'}${currencyFormat.format(tx.amount)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isIncome ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }
}
