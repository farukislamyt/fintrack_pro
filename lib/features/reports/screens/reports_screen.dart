import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/providers/transaction_provider.dart';
import '../../../core/models/transaction_model.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(reportDateRangeProvider);
    final expensesByCategory = ref.watch(reportsExpensesByCategoryProvider);
    final income = ref.watch(reportsIncomeProvider);
    final expense = ref.watch(reportsExpenseProvider);
    final transactions = ref.watch(reportsFilteredTransactionsProvider);
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    final netCashflow = income - expense;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Time Filter Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  _buildFilterChip(context, ref, 'All Time', ReportTimeRange.allTime, range == ReportTimeRange.allTime),
                  _buildFilterChip(context, ref, 'This Month', ReportTimeRange.monthly, range == ReportTimeRange.monthly),
                  _buildFilterChip(context, ref, 'This Week', ReportTimeRange.weekly, range == ReportTimeRange.weekly),
                  _buildFilterChip(context, ref, 'Today', ReportTimeRange.daily, range == ReportTimeRange.daily),
                ],
              ),
            ),
            
            // Core Summary Row
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryMiniCard(context, 'Income', currencyFormat.format(income), Colors.green),
                  _buildSummaryMiniCard(context, 'Expenses', currencyFormat.format(expense), Colors.red),
                  _buildSummaryMiniCard(
                    context, 
                    'Net Cashflow', 
                    currencyFormat.format(netCashflow), 
                    netCashflow >= 0 ? Theme.of(context).primaryColor : Colors.red
                  ),
                ],
              ),
            ),

            if (transactions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: Text("No transactions recorded in this period.", style: TextStyle(color: Colors.grey))),
              )
            else ...[
              // Line Chart (Trend Analysis - Overlapping Income vs Expense)
              _buildChartContainer(
                context, 
                'Trend Analysis', 
                SizedBox(
                  height: 220,
                  child: _buildLineChart(context, transactions),
                )
              ),

              // Bar Chart (Income vs Expense)
              _buildChartContainer(
                context, 
                'Income vs Expense', 
                SizedBox(
                  height: 200,
                  child: _buildBarChart(context, income, expense),
                )
              ),

              // Pie Chart (Category Breakdown)
              _buildChartContainer(
                context, 
                'Expense Distribution', 
                Column(
                  children: [
                    if (expensesByCategory.isEmpty)
                      const Text('No expenses to distribute.', style: TextStyle(color: Colors.grey))
                    else ...[
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 50,
                            sections: _buildPieSections(context, expensesByCategory),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildLegend(context, expensesByCategory),
                    ]
                  ],
                ),
              ),

              // Insights Panel
              _buildInsightsPanel(context, transactions, expensesByCategory),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, WidgetRef ref, String label, ReportTimeRange value, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          ref.read(reportDateRangeProvider.notifier).updateRange(value);
        },
        selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
        checkmarkColor: Theme.of(context).primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyMedium?.color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildSummaryMiniCard(BuildContext context, String title, String value, Color color) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Column(
            children: [
              Text(title, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Text(
                value, 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(
                width: 20,
                height: 4,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartContainer(BuildContext context, String title, Widget child) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          child,
        ],
      ),
    );
  }

  Widget _buildLineChart(BuildContext context, List<TransactionModel> transactions) {
    // Reverse so chronologically oldest is first
    final chronoSorted = transactions.toList().reversed.toList();
    
    List<FlSpot> incomeSpots = [];
    List<FlSpot> expenseSpots = [];
    
    // Group roughly by index (representing time progression)
    // For a real production app, we would group by Date
    for (int i = 0; i < chronoSorted.length; i++) {
      final tx = chronoSorted[i];
      if (tx.type == TransactionType.income) {
        incomeSpots.add(FlSpot(i.toDouble(), tx.amount));
        expenseSpots.add(FlSpot(i.toDouble(), 0)); // Padding
      } else {
        expenseSpots.add(FlSpot(i.toDouble(), tx.amount));
        incomeSpots.add(FlSpot(i.toDouble(), 0)); // Padding
      }
    }

    if (incomeSpots.length == 1) incomeSpots.add(FlSpot(1, incomeSpots.first.y));
    if (expenseSpots.length == 1) expenseSpots.add(FlSpot(1, expenseSpots.first.y));

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true, 
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(color: Theme.of(context).dividerColor.withValues(alpha: 0.1), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox();
                return Text(NumberFormat.compact().format(value), style: const TextStyle(fontSize: 10, color: Colors.grey));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: incomeSpots,
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withValues(alpha: 0.1),
            ),
          ),
          LineChartBarData(
            spots: expenseSpots,
            isCurved: true,
            color: Colors.red,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.red.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(BuildContext context, double income, double expense) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (income > expense ? income : expense) * 1.2,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                switch (value.toInt()) {
                  case 0:
                    return const Text('Income', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold));
                  case 1:
                    return const Text('Expense', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold));
                  default:
                    return const Text('');
                }
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [BarChartRodData(toY: income, color: Colors.green, width: 40, borderRadius: BorderRadius.circular(4))],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [BarChartRodData(toY: expense, color: Colors.red, width: 40, borderRadius: BorderRadius.circular(4))],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(BuildContext context, Map<String, double> data) {
    final total = data.values.fold(0.0, (s, e) => s + e);
    final colors = [Colors.blue, Colors.redAccent, Colors.green, Colors.orange, Colors.purple, Colors.teal];
    int colorIndex = 0;

    return data.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      final section = PieChartSectionData(
        color: colors[colorIndex % colors.length],
        value: entry.value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 40,
        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
      );
      colorIndex++;
      return section;
    }).toList();
  }

  Widget _buildLegend(BuildContext context, Map<String, double> data) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final colors = [Colors.blue, Colors.redAccent, Colors.green, Colors.orange, Colors.purple, Colors.teal];
    int colorIndex = 0;

    return Column(
      children: data.entries.map((entry) {
        final color = colors[colorIndex % colors.length];
        colorIndex++;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Expanded(child: Text(entry.key, style: Theme.of(context).textTheme.bodyMedium)),
              Text(currencyFormat.format(entry.value), style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInsightsPanel(BuildContext context, List<TransactionModel> transactions, Map<String, double> expensesByCategory) {
    TransactionModel? highestExpense;
    for (var tx in transactions) {
      if (tx.type == TransactionType.expense) {
        if (highestExpense == null || tx.amount > highestExpense.amount) {
          highestExpense = tx;
        }
      }
    }

    String topCategory = "N/A";
    if (expensesByCategory.isNotEmpty) {
      topCategory = expensesByCategory.entries.first.key; // Sorted in provider
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.lightbulb, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text('Actionable Insights', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).primaryColor)),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(LucideIcons.arrowUpFromLine, color: Colors.white, size: 16)),
            title: const Text('Highest Single Expense', style: TextStyle(fontSize: 12, color: Colors.grey)),
            subtitle: Text(highestExpense != null ? '${highestExpense.category} (${NumberFormat.currency(symbol: '\$').format(highestExpense.amount)})' : 'No expenses recorded', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(LucideIcons.pieChart, color: Colors.white, size: 16)),
            title: const Text('Most Frequent Spending Category', style: TextStyle(fontSize: 12, color: Colors.grey)),
            subtitle: Text(topCategory, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
