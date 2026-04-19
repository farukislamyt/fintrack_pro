import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/providers/transaction_provider.dart';
import '../../../core/providers/preferences_provider.dart';
import '../../../core/widgets/premium_empty_state.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionProvider);
    final currencySymbol = ref.watch(preferencesProvider).currencySymbol;
    final currencyFormat = NumberFormat.currency(symbol: currencySymbol);

    final filteredTransactions = transactions.where((tx) {
      final matchesSearch = tx.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            tx.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: const Icon(LucideIcons.search, size: 20),
                filled: true,
                fillColor: Theme.of(context).cardTheme.color,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: filteredTransactions.isEmpty
          ? PremiumEmptyState(
              icon: _searchQuery.isEmpty ? LucideIcons.history : LucideIcons.searchX,
              title: _searchQuery.isEmpty ? 'No Transactions Yet' : 'No Results Found',
              subtitle: _searchQuery.isEmpty 
                  ? 'Your financial journey starts here. Add your first transaction to see it in history.'
                  : 'We couldn\'t find any transactions matching "$_searchQuery".',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredTransactions.length,
              itemBuilder: (context, index) {
                final tx = filteredTransactions[index];
                final isIncome = tx.type == TransactionType.income;

                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    // Show details modal in future
                  },
                  borderRadius: BorderRadius.circular(16),
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
                          size: 20,
                        ),
                      ),
                      title: Text(tx.category, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        '${DateFormat.yMMMd().format(tx.date)}${tx.description.isNotEmpty ? ' • ${tx.description}' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        '${isIncome ? '+' : '-'}${currencyFormat.format(tx.amount)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isIncome ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ).animate().fade(duration: 400.ms, delay: (index * 50).ms).slideX(begin: 0.05, end: 0);
              },
            ),
    );
  }
}
