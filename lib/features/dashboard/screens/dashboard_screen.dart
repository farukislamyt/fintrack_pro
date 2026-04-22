import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/design/fintrack_ui.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/providers/transaction_provider.dart';
import '../../../core/providers/preferences_provider.dart';
import '../../../core/widgets/premium_empty_state.dart';


class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionProvider);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            scrolledUnderElevation: 4,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('FinTrack Pro', 
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold, 
                ),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
            ),
          ),
          if (transactions.isEmpty)
             SliverFillRemaining(
              hasScrollBody: false,
              child: PremiumEmptyState(
                icon: LucideIcons.layoutDashboard,
                title: 'Welcome to FinTrack Pro',
                subtitle: 'Your dashboard is empty. Add your first transaction to see monthly analytics.',
                actionLabel: 'Add Transaction',
                onAction: () => context.go('/add_transaction'),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverMainAxisGroup(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const _DashboardBalanceCard(),
                        const SizedBox(height: 24),
                        const _DashboardMonthlyPulse(),
                        const SizedBox(height: 24),
                        const _DashboardMonthlyFlowChart(),
                        const SizedBox(height: 32),
                        FintrackUI.sectionHeader(
                          context, 
                          'Recent Activity', 
                          actionLabel: 'View All',
                          onAction: () => context.go('/history'),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  const _RecentTransactionsSliver(),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
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
    final transactions = ref.watch(transactionProvider);
    final theme = Theme.of(context);
    final currencySymbol = ref.watch(preferencesProvider.select((p) => p.currencySymbol));
    final currencyFormat = NumberFormat.currency(symbol: currencySymbol);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.primaryColor, const Color(0xFFF43F5E)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: theme.primaryColor.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(LucideIcons.wallet, size: 120, color: Colors.white.withValues(alpha: 0.05)),
          ),
          if (transactions.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 100,
              child: Opacity(
                opacity: 0.3,
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: LineChart(_buildSparklineData(transactions)),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.globe, size: 14, color: Colors.white70),
                    const SizedBox(width: 8),
                    Text('TOTAL NET BALANCE', 
                      style: theme.textTheme.labelMedium?.copyWith(color: Colors.white70, letterSpacing: 1.2)),
                  ],
                ),
                const SizedBox(height: 12),
                FittedBox(
                  child: Text(
                    currencyFormat.format(balance),
                    style: theme.textTheme.displayMedium?.copyWith(
                      color: Colors.white, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    _StatLabel(label: 'Assets', value: transactions.length.toString()),
                    const SizedBox(width: 24),
                    const _StatLabel(label: 'Status', value: 'Active'),
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
      tx.type == TransactionType.income ? runningNet += tx.amount : runningNet -= tx.amount;
      spots.add(FlSpot(i.toDouble(), runningNet));
    }
    if (spots.isEmpty) spots.add(const FlSpot(0, 0));
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
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: true, color: Colors.white.withValues(alpha: 0.1)),
        ),
      ],
    );
  }
}

class _StatLabel extends StatelessWidget {
  final String label;
  final String value;
  const _StatLabel({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _DashboardMonthlyPulse extends ConsumerWidget {
  const _DashboardMonthlyPulse();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final income = ref.watch(thisMonthIncomeProvider);
    final expense = ref.watch(thisMonthExpenseProvider);
    final currencySymbol = ref.watch(preferencesProvider.select((p) => p.currencySymbol));
    final currencyFormat = NumberFormat.currency(symbol: currencySymbol, decimalDigits: 0);

    return Row(
      children: [
        Expanded(
          child: _PulseCard(
            label: 'Income',
            amount: currencyFormat.format(income),
            color: Colors.green,
            icon: LucideIcons.trendingUp,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PulseCard(
            label: 'Spending',
            amount: currencyFormat.format(expense),
            color: Colors.orange,
            icon: LucideIcons.trendingDown,
          ),
        ),
      ],
    );
  }
}

class _PulseCard extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final IconData icon;

  const _PulseCard({required this.label, required this.amount, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FintrackUI.glassCard(
      padding: const EdgeInsets.all(20),
      opacity: isDark ? 0.05 : 0.6,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 16),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          FittedBox(child: Text(amount, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}

class _DashboardMonthlyFlowChart extends ConsumerWidget {
  const _DashboardMonthlyFlowChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final income = ref.watch(thisMonthIncomeProvider);
    final expense = ref.watch(thisMonthExpenseProvider);
    if (income == 0 && expense == 0) return const SizedBox();

    return FintrackUI.glassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Flow Dynamics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 32),
          SizedBox(
            height: 80,
            child: RepaintBoundary(
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [
                      BarChartRodData(toY: income, color: Colors.green, width: 30, borderRadius: BorderRadius.circular(6)),
                      BarChartRodData(toY: expense, color: Colors.orange, width: 30, borderRadius: BorderRadius.circular(6)),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentTransactionsSliver extends ConsumerWidget {
  const _RecentTransactionsSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(dashboardRecentTransactionsProvider);
    final currencySymbol = ref.watch(preferencesProvider.select((p) => p.currencySymbol));
    final currencyFormat = NumberFormat.currency(symbol: currencySymbol);

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final tx = transactions[index];
          final isIncome = tx.type == TransactionType.income;
          
          return FintrackUI.listTile(
            context: context,
            onTap: () => context.go('/history'),
            leading: CircleAvatar(
              backgroundColor: isIncome ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
              child: Icon(
                isIncome ? LucideIcons.arrowDownToLine : LucideIcons.arrowUpFromLine, 
                size: 16, 
                color: isIncome ? Colors.green : Colors.orange
              ),
            ),
            title: Text(tx.category, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(DateFormat('MMM d').format(tx.date), style: const TextStyle(fontSize: 12)),
            trailing: Text(
              '${isIncome ? '+' : '-'}${currencyFormat.format(tx.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isIncome ? Colors.green : Colors.orange,
              ),
            ),
          ).animate().fade(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
        },
        childCount: transactions.length,
      ),
    );
  }
}
