import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/providers/transaction_provider.dart';
import '../../../core/providers/preferences_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            scrolledUnderElevation: 8,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Dashboard', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 24)),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
            ),
            actions: [
              IconButton(icon: const Icon(LucideIcons.bell), onPressed: () {}),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const _DashboardBalanceCard().animate().fade(duration: 500.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
                const SizedBox(height: 24),
                const _DashboardQuickActions().animate().fade(duration: 500.ms, delay: 100.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
                const SizedBox(height: 24),
                const _DashboardMiniTrends().animate().fade(duration: 500.ms, delay: 200.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
                const SizedBox(height: 24),
                Text('Recent Transactions', style: Theme.of(context).textTheme.titleLarge).animate().fade(duration: 500.ms, delay: 300.ms),
                const SizedBox(height: 16),
                const _DashboardRecentTransactions().animate().fade(duration: 500.ms, delay: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardBalanceCard extends ConsumerWidget {
  const _DashboardBalanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(totalBalanceProvider);
    final income = ref.watch(totalIncomeProvider);
    final expense = ref.watch(totalExpenseProvider);
    final transactions = ref.watch(transactionProvider);
    final theme = Theme.of(context);
    final currencySymbol = ref.watch(preferencesProvider).currencySymbol;
    final currencyFormat = NumberFormat.currency(symbol: currencySymbol);
    
    final double rawSavings = (income > 0) ? ((income - expense) / income * 100) : 0;
    final double savingsRate = math.max(0.0, rawSavings);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primaryColor,
            theme.primaryColor.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (transactions.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 120,
              child: Opacity(
                opacity: 0.3,
                child: IgnorePointer(
                  child: LineChart(_buildSparklineData(transactions)),
                ),
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Balance',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${savingsRate.toStringAsFixed(1)}% Saved',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  currencyFormat.format(balance),
                  style: theme.textTheme.displayMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _IncomeExpenseStat(label: 'Income', amount: currencyFormat.format(income), icon: LucideIcons.arrowDownToLine, color: theme.colorScheme.secondary),
                    _IncomeExpenseStat(label: 'Expense', amount: currencyFormat.format(expense), icon: LucideIcons.arrowUpFromLine, color: const Color(0xFFFFA500)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _buildSparklineData(List<TransactionModel> transactions) {
    final recent = transactions.take(15).toList().reversed.toList();
    double runningNet = 0;
    List<FlSpot> spots = [];
    
    for (int i = 0; i < recent.length; i++) {
      final tx = recent[i];
      if (tx.type == TransactionType.income) {
        runningNet += tx.amount;
      } else {
        runningNet -= tx.amount;
      }
      spots.add(FlSpot(i.toDouble(), runningNet));
    }

    if (spots.length == 1) spots.add(FlSpot(1, spots.first.y));

    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.white,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }
}

class _IncomeExpenseStat extends StatelessWidget {
  final String label;
  final String amount;
  final IconData icon;
  final Color color;

  const _IncomeExpenseStat({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
            Text(amount, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
          ],
        ),
      ],
    );
  }
}

class _DashboardQuickActions extends StatelessWidget {
  const _DashboardQuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionButton(title: 'Add New', icon: LucideIcons.plus, onTap: () => context.go('/add_transaction')),
        _ActionButton(title: 'Reports', icon: LucideIcons.pieChart, onTap: () => context.go('/reports')),
        _ActionButton(title: 'History', icon: LucideIcons.history, onTap: () => context.go('/history')),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _DashboardMiniTrends extends ConsumerWidget {
  const _DashboardMiniTrends();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionProvider);
    final now = DateTime.now();
    double todayExpense = 0;
    double weekExpense = 0;
    Map<String, double> weekCategories = {};

    for (var tx in transactions) {
      if (tx.type == TransactionType.expense) {
        if (tx.date.year == now.year && tx.date.month == now.month && tx.date.day == now.day) {
          todayExpense += tx.amount;
        }
        
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        if (tx.date.isAfter(startOfWeek.subtract(const Duration(days: 1)))) {
          weekExpense += tx.amount;
          weekCategories[tx.category] = (weekCategories[tx.category] ?? 0) + tx.amount;
        }
      }
    }

    String topCategoryStr = "No data this week";
    if (weekCategories.isNotEmpty) {
      var topCategory = weekCategories.entries.reduce((a, b) => a.value > b.value ? a : b);
      topCategoryStr = "${topCategory.key} is your highest expense this week";
    }

    final currencySymbol = ref.watch(preferencesProvider).currencySymbol;
    final currencyFormat = NumberFormat.currency(symbol: currencySymbol);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.trendingDown, size: 20, color: Colors.orange),
              const SizedBox(width: 8),
              Text('Quick Stats', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Today', style: Theme.of(context).textTheme.bodySmall),
                  Text(currencyFormat.format(todayExpense), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('This Week', style: Theme.of(context).textTheme.bodySmall),
                  Text(currencyFormat.format(weekExpense), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.lightbulb, size: 16, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Expanded(child: Text(topCategoryStr, style: TextStyle(fontSize: 12, color: Theme.of(context).primaryColor))),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _DashboardRecentTransactions extends ConsumerWidget {
  const _DashboardRecentTransactions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionProvider).take(5).toList();
    if (transactions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No recent transactions.'),
        ),
      );
    }

    final currencySymbol = ref.watch(preferencesProvider).currencySymbol;
    final currencyFormat = NumberFormat.currency(symbol: currencySymbol);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final isIncome = tx.type == TransactionType.income;
        
        return Card(
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
            subtitle: Text(DateFormat.MMMd().format(tx.date)),
            trailing: Text(
              '${isIncome ? '+' : '-'}${currencyFormat.format(tx.amount)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isIncome ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ).animate().fade(duration: 500.ms, delay: (100 * index).ms).slideX(begin: 0.1, end: 0, curve: Curves.easeOutQuad);
      },
    );
  }
}
