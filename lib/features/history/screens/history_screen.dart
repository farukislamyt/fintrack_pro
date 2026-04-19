import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../../../core/models/transaction_model.dart';
import '../../../core/providers/transaction_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(filteredTransactionsProvider);
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            floating: true,
            pinned: true,
            scrolledUnderElevation: 8,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Transaction History', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 22)),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 16, bottom: 64),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 12.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search categories...',
                    prefixIcon: const Icon(LucideIcons.search),
                    filled: true,
                    fillColor: Theme.of(context).cardTheme.color,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
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
          
          if (transactions.isEmpty)
            SliverFillRemaining(
              child: const Center(child: Text('No transactions found.')).animate().fade(duration: 500.ms),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
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
                          borderRadius: BorderRadius.circular(16),
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
                        clipBehavior: Clip.antiAlias,
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
                      ).animate().fade(duration: 500.ms, delay: (50 * math.min(index, 10)).ms).slideX(begin: 0.05, end: 0, curve: Curves.easeOutQuad),
                    );
                  },
                  childCount: transactions.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
