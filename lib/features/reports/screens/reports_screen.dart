import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/providers/transaction_provider.dart';
import '../../../core/providers/preferences_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/premium_empty_state.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _timeFilter = 'Monthly';
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionProvider);
    final currencySymbol = ref.watch(preferencesProvider).currencySymbol;
    final currencyFormat = NumberFormat.currency(symbol: currencySymbol);

    final currentData = _getPeriodData(transactions, _timeFilter, isCurrent: true);
    final previousData = _getPeriodData(transactions, _timeFilter, isCurrent: false);
    
    final categoryTotals = _calculateCategoryTotals(currentData.transactions);

    if (currentData.transactions.isEmpty) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: PremiumEmptyState(
          icon: LucideIcons.pieChart,
          title: 'No Data for $_timeFilter',
          subtitle: 'You haven\'t recorded any transactions for this period.',
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryRow(currentData, previousData, currencyFormat),
            const SizedBox(height: 24),
            _buildSectionHeader('Cash Flow Trend'),
            const SizedBox(height: 16),
            _buildTrendChart(currentData.transactions, _timeFilter),
            const SizedBox(height: 32),
            _buildSectionHeader('Expense Distribution'),
            const SizedBox(height: 16),
            _buildPieChart(categoryTotals),
            const SizedBox(height: 32),
            _buildSectionHeader('Top Insights'),
            const SizedBox(height: 16),
            _buildInsightsCard(currentData.transactions, currencyFormat),
            const SizedBox(height: 32),
            _buildSectionHeader('Detailed Ledger'),
            const SizedBox(height: 16),
            _buildTransactionLedger(currentData.transactions, currencyFormat),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Detailed Reports'),
      actions: [
        PopupMenuButton<String>(
          initialValue: _timeFilter,
          onSelected: (val) {
            HapticFeedback.selectionClick();
            setState(() {
              _timeFilter = val;
              _touchedIndex = null;
            });
          },
          icon: const Icon(LucideIcons.filter),
          itemBuilder: (context) => ['Daily', 'Weekly', 'Monthly', 'Yearly', 'All Time']
              .map((filter) => PopupMenuItem(value: filter, child: Text(filter)))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSummaryRow(_ReportData current, _ReportData previous, NumberFormat format) {
    final savings = current.income - current.expense;
    final prevSavings = previous.income - previous.expense;
    
    // Comparison indicators
    final expDiff = previous.expense > 0 ? ((current.expense - previous.expense) / previous.expense * 100) : 0.0;
    final savingsGrowth = savings - prevSavings;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _SummaryCard(
              label: 'Income', 
              amount: format.format(current.income), 
              color: AppTheme.chartIncomeColor, 
              icon: LucideIcons.trendingUp,
              subtext: _getDiffText(current.income, previous.income, format),
            )),
            const SizedBox(width: 12),
            Expanded(child: _SummaryCard(
              label: 'Expense', 
              amount: format.format(current.expense), 
              color: AppTheme.chartExpenseColor, 
              icon: LucideIcons.trendingDown,
              subtext: '${expDiff > 0 ? '+' : ''}${expDiff.toStringAsFixed(1)}% vs prev',
              isBad: expDiff > 0,
            )),
          ],
        ),
        const SizedBox(height: 12),
        _SummaryCard(
          label: 'Net Savings', 
          amount: format.format(savings), 
          color: Colors.indigo, 
          icon: LucideIcons.wallet,
          subtext: '${savingsGrowth >= 0 ? '+' : ''}${format.format(savingsGrowth)} vs prev',
          isFullWidth: true,
        ),
      ],
    );
  }

  String _getDiffText(double curr, double prev, NumberFormat format) {
    if (prev == 0) return 'First period data';
    final diff = curr - prev;
    return '${diff >= 0 ? '+' : ''}${format.format(diff)} vs prev';
  }

  Widget _buildTrendChart(List<TransactionModel> transactions, String filter) {
    // Group transactions by date for the period
    final Map<DateTime, double> incomeMap = {};
    final Map<DateTime, double> expenseMap = {};
    
    for (var tx in transactions) {
      final date = DateTime(tx.date.year, tx.date.month, tx.date.day);
      if (tx.type == TransactionType.income) {
        incomeMap[date] = (incomeMap[date] ?? 0) + tx.amount;
      } else {
        expenseMap[date] = (expenseMap[date] ?? 0) + tx.amount;
      }
    }

    final sortedDates = (incomeMap.keys.toList()..addAll(expenseMap.keys))
        .toSet().toList()..sort();

    if (sortedDates.isEmpty) return const SizedBox();

    List<FlSpot> incomeSpots = [];
    List<FlSpot> expenseSpots = [];
    
    for (int i = 0; i < sortedDates.length; i++) {
        incomeSpots.add(FlSpot(i.toDouble(), incomeMap[sortedDates[i]] ?? 0));
        expenseSpots.add(FlSpot(i.toDouble(), expenseMap[sortedDates[i]] ?? 0));
    }

    if (incomeSpots.length == 1) {
        incomeSpots.insert(0, FlSpot(-1, 0));
        expenseSpots.insert(0, FlSpot(-1, 0));
    }

    return RepaintBoundary(
      child: Container(
        height: 220,
        padding: const EdgeInsets.only(top: 24, right: 24, left: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(24),
        ),
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: incomeSpots,
                isCurved: true,
                color: AppTheme.chartIncomeColor,
                barWidth: 3,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: true, color: AppTheme.chartIncomeColor.withValues(alpha: 0.1)),
              ),
              LineChartBarData(
                spots: expenseSpots,
                isCurved: true,
                color: AppTheme.chartExpenseColor,
                barWidth: 3,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: true, color: AppTheme.chartExpenseColor.withValues(alpha: 0.1)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart(Map<String, double> categoryTotals) {
    if (categoryTotals.isEmpty) return const SizedBox();

    final List<PieChartSectionData> sections = [];
    int i = 0;
    final colors = [Colors.indigo, Colors.green, Colors.orange, Colors.pink, Colors.cyan, Colors.purple];

    categoryTotals.forEach((category, amount) {
      final isTouched = i == _touchedIndex;
      sections.add(PieChartSectionData(
        value: amount,
        title: isTouched ? amount.toStringAsFixed(0) : '',
        radius: isTouched ? 60 : 50,
        color: colors[i % colors.length],
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ));
      i++;
    });

    return RepaintBoundary(
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 4,
                  centerSpaceRadius: 40,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        if (!event.isInterestedForInteractions || response == null || response.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex = response.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildLegend(categoryTotals, colors),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildLegend(Map<String, double> totals, List<Color> colors) {
    final List<Widget> legend = [];
    int i = 0;
    totals.forEach((category, amount) {
      legend.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[i % colors.length], shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(child: Text(category, style: TextStyle(fontSize: 12, fontWeight: i == _touchedIndex ? FontWeight.bold : FontWeight.normal))),
            Text('${_getPercentage(amount, totals)}%', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ));
      i++;
    });
    return legend;
  }

  String _getPercentage(double val, Map<String, double> totals) {
    final total = totals.values.fold(0.0, (a, b) => a + b);
    return (val / total * 100).toStringAsFixed(1);
  }

  Widget _buildInsightsCard(List<TransactionModel> transactions, NumberFormat format) {
    final expenses = transactions.where((t) => t.type == TransactionType.expense).toList();
    if (expenses.isEmpty) return const SizedBox();

    final maxExp = expenses.reduce((a, b) => a.amount > b.amount ? a : b);
    final dailyAvg = expenses.fold(0.0, (a, b) => a + b.amount) / (_getDaysInPeriod(_timeFilter));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _InsightRow(icon: LucideIcons.zap, label: 'Highest Spend', value: '${maxExp.category} (${format.format(maxExp.amount)})'),
          const Divider(height: 24),
          _InsightRow(icon: LucideIcons.calendarClock, label: 'Daily Average', value: format.format(dailyAvg)),
          const Divider(height: 24),
          _InsightRow(icon: LucideIcons.pieChart, label: 'Top Category', value: _calculateCategoryTotals(transactions).entries.reduce((a, b) => a.value > b.value ? a : b).key),
        ],
      ),
    );
  }

  Widget _buildTransactionLedger(List<TransactionModel> transactions, NumberFormat format) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length > 10 ? 10 : transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: tx.type == TransactionType.income ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
            child: Icon(
              tx.type == TransactionType.income ? LucideIcons.arrowDownToLine : LucideIcons.arrowUpFromLine, 
              size: 16, 
              color: tx.type == TransactionType.income ? Colors.green : Colors.orange
            ),
          ),
          title: Text(tx.category, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(DateFormat.yMMMd().format(tx.date)),
          trailing: Text(
            '${tx.type == TransactionType.income ? '+' : '-'}${format.format(tx.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: tx.type == TransactionType.income ? Colors.green : Colors.orange,
            ),
          ),
        );
      },
    );
  }

  double _getDaysInPeriod(String filter) {
    if (filter == 'Daily') return 1;
    if (filter == 'Weekly') return 7;
    if (filter == 'Monthly') return 30;
    if (filter == 'Yearly') return 365;
    return 30;
  }

  _ReportData _getPeriodData(List<TransactionModel> all, String filter, {required bool isCurrent}) {
    final now = DateTime.now();
    DateTime start;
    DateTime end;

    if (filter == 'Daily') {
      start = isCurrent ? DateTime(now.year, now.month, now.day) : DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
      end = isCurrent ? now : start.add(const Duration(days: 1));
    } else if (filter == 'Weekly') {
      final daysToSubtract = now.weekday - 1;
      start = isCurrent 
          ? DateTime(now.year, now.month, now.day).subtract(Duration(days: daysToSubtract))
          : DateTime(now.year, now.month, now.day).subtract(Duration(days: daysToSubtract + 7));
      end = start.add(const Duration(days: 7));
    } else if (filter == 'Monthly') {
      start = isCurrent ? DateTime(now.year, now.month, 1) : DateTime(now.year, now.month - 1, 1);
      end = isCurrent ? now : DateTime(now.year, now.month, 1);
    } else if (filter == 'Yearly') {
      start = isCurrent ? DateTime(now.year, 1, 1) : DateTime(now.year - 1, 1, 1);
      end = isCurrent ? now : DateTime(now.year, 1, 1);
    } else {
      return _ReportData(transactions: all, income: _sum(all, TransactionType.income), expense: _sum(all, TransactionType.expense));
    }

    final filtered = all.where((tx) => tx.date.isAfter(start.subtract(const Duration(seconds: 1))) && tx.date.isBefore(end)).toList();
    return _ReportData(transactions: filtered, income: _sum(filtered, TransactionType.income), expense: _sum(filtered, TransactionType.expense));
  }

  double _sum(List<TransactionModel> txs, TransactionType type) {
    return txs.where((t) => t.type == type).fold(0.0, (a, b) => a + b.amount);
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

class _ReportData {
  final List<TransactionModel> transactions;
  final double income;
  final double expense;
  _ReportData({required this.transactions, required this.income, required this.expense});
}

class _InsightRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InsightRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.grey)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final IconData icon;
  final String subtext;
  final bool isBad;
  final bool isFullWidth;

  const _SummaryCard({
    required this.label, 
    required this.amount, 
    required this.color, 
    required this.icon, 
    required this.subtext,
    this.isBad = false,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              if (isFullWidth) Icon(LucideIcons.chevronRight, size: 16, color: Colors.grey.withValues(alpha: 0.5)),
            ],
          ),
          const SizedBox(height: 12),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          FittedBox(child: Text(amount, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          const SizedBox(height: 8),
          Text(
            subtext, 
            style: TextStyle(
              fontSize: 11, 
              color: isBad ? Colors.red : Colors.grey,
              fontWeight: isBad ? FontWeight.bold : FontWeight.normal,
            )
          ),
        ],
      ),
    );
  }
}
