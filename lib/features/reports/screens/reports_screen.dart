import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/providers/transaction_provider.dart';
import '../../../core/providers/preferences_provider.dart';
import '../../../core/widgets/premium_empty_state.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _timeFilter = 'Monthly';

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionProvider);
    final currencySymbol = ref.watch(preferencesProvider).currencySymbol;
    final currencyFormat = NumberFormat.currency(symbol: currencySymbol);

    final filteredTransactions = _filterTransactions(transactions, _timeFilter);
    final categoryTotals = _calculateCategoryTotals(filteredTransactions);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Reports'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _timeFilter,
            onSelected: (val) {
              HapticFeedback.selectionClick();
              setState(() => _timeFilter = val);
            },
            icon: const Icon(LucideIcons.filter),
            itemBuilder: (context) => ['Weekly', 'Monthly', 'Yearly', 'All Time']
                .map((filter) => PopupMenuItem(value: filter, child: Text(filter)))
                .toList(),
          ),
        ],
      ),
      body: filteredTransactions.isEmpty
          ? PremiumEmptyState(
              icon: LucideIcons.pieChart,
              title: 'Not Enough Data',
              subtitle: 'Add more transactions to generate your visual financial insights.',
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildSummarySection(filteredTransactions, currencyFormat),
                  const SizedBox(height: 24),
                  Text('Category Breakdown', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  _buildPieChart(categoryTotals),
                  const SizedBox(height: 32),
                  Text('Top Expenses', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  _buildCategoryList(categoryTotals, currencyFormat),
                ],
              ),
            ),
    );
  }

  Widget _buildSummarySection(List<TransactionModel> transactions, NumberFormat format) {
    double totalIncome = 0;
    double totalExpense = 0;

    for (var tx in transactions) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
      }
    }

    return Row(
      children: [
        Expanded(child: _SummaryCard(label: 'Income', amount: format.format(totalIncome), color: Colors.green, icon: LucideIcons.trendingUp)),
        const SizedBox(width: 16),
        Expanded(child: _SummaryCard(label: 'Expense', amount: format.format(totalExpense), color: Colors.orange, icon: LucideIcons.trendingDown)),
      ],
    ).animate().fade().slideY(begin: 0.1, end: 0);
  }

  Widget _buildPieChart(Map<String, double> categoryTotals) {
    if (categoryTotals.isEmpty) return const SizedBox();

    final List<PieChartSectionData> sections = [];
    int i = 0;
    final colors = [Colors.indigo, Colors.green, Colors.orange, Colors.pink, Colors.cyan, Colors.purple];

    categoryTotals.forEach((category, amount) {
      sections.add(PieChartSectionData(
        value: amount,
        title: '',
        radius: 50,
        color: colors[i % colors.length],
      ));
      i++;
    });

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: PieChart(
        PieChartData(
          sections: sections,
          sectionsSpace: 4,
          centerSpaceRadius: 40,
        ),
      ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildCategoryList(Map<String, double> categoryTotals, NumberFormat format) {
    final sorted = categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final entry = sorted[index];
        return ListTile(
          leading: Container(
            width: 12, height: 12,
            decoration: BoxDecoration(
              color: [Colors.indigo, Colors.green, Colors.orange, Colors.pink, Colors.cyan, Colors.purple][index % 6],
              shape: BoxShape.circle,
            ),
          ),
          title: Text(entry.key),
          trailing: Text(format.format(entry.value), style: const TextStyle(fontWeight: FontWeight.bold)),
        );
      },
    );
  }

  List<TransactionModel> _filterTransactions(List<TransactionModel> transactions, String filter) {
    final now = DateTime.now();
    return transactions.where((tx) {
      if (filter == 'Weekly') return tx.date.isAfter(now.subtract(const Duration(days: 7)));
      if (filter == 'Monthly') return tx.date.month == now.month && tx.date.year == now.year;
      if (filter == 'Yearly') return tx.date.year == now.year;
      return true;
    }).toList();
  }

  Map<String, double> _calculateCategoryTotals(List<TransactionModel> transactions) {
    final Map<String, double> totals = {};
    for (var tx in transactions) {
      if (tx.type == TransactionType.expense) {
        totals[tx.category] = (totals[tx.category] ?? 0) + tx.amount;
      }
    }
    return totals;
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({required this.label, required this.amount, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          FittedBox(child: Text(amount, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
