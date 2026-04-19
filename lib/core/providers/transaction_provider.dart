import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';

class TransactionNotifier extends Notifier<List<TransactionModel>> {
  static const _prefsKey = 'transactions_data';
  
  @override
  List<TransactionModel> build() {
    // Return empty initially, load immediately.
    _loadFromPrefs();
    return [];
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_prefsKey);
    if (data != null) {
      final List<TransactionModel> loaded = data
          .map((item) => TransactionModel.fromJson(item))
          .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
      state = loaded;
    } else {
      // Load some dummy data if empty for demonstration
      final dummyData = [
        TransactionModel(amount: 5240, date: DateTime.now().subtract(const Duration(days: 1)), type: TransactionType.income, category: 'Salary', description: 'Monthly Salary'),
        TransactionModel(amount: 120, date: DateTime.now().subtract(const Duration(days: 2)), type: TransactionType.expense, category: 'Food', description: 'Groceries'),
        TransactionModel(amount: 45, date: DateTime.now().subtract(const Duration(days: 2)), type: TransactionType.expense, category: 'Transport', description: 'Gas'),
        TransactionModel(amount: 80, date: DateTime.now().subtract(const Duration(days: 3)), type: TransactionType.expense, category: 'Entertainment', description: 'Movies'),
      ];
      state = dummyData;
      _saveToPrefs(dummyData);
    }
  }

  Future<void> _saveToPrefs(List<TransactionModel> newList) async {
    final prefs = await SharedPreferences.getInstance();
    final data = newList.map((t) => t.toJson()).toList();
    await prefs.setStringList(_prefsKey, data);
  }

  void addTransaction(TransactionModel transaction) {
    final newState = [transaction, ...state];
    newState.sort((a, b) => b.date.compareTo(a.date));
    state = newState;
    _saveToPrefs(state);
  }

  void deleteTransaction(String id) {
    final newState = state.where((t) => t.id != id).toList();
    state = newState;
    _saveToPrefs(state);
  }

  void clearAll() {
    state = [];
    _saveToPrefs(state);
  }
}

final transactionProvider = NotifierProvider<TransactionNotifier, List<TransactionModel>>(() {
  return TransactionNotifier();
});

final totalBalanceProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionProvider);
  return transactions.fold(0.0, (sum, item) {
    return item.type == TransactionType.income ? sum + item.amount : sum - item.amount;
  });
});

final totalIncomeProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionProvider);
  return transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, item) => sum + item.amount);
});

final totalExpenseProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionProvider);
  return transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, item) => sum + item.amount);
});

final expensesByCategoryProvider = Provider<Map<String, double>>((ref) {
  final transactions = ref.watch(transactionProvider);
  final expenses = transactions.where((t) => t.type == TransactionType.expense);
  
  final map = <String, double>{};
  for (var t in expenses) {
    map[t.category] = (map[t.category] ?? 0) + t.amount;
  }
  return map;
});

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  
  void updateQuery(String newQuery) {
    state = newQuery;
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() {
  return SearchQueryNotifier();
});

final filteredTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final transactions = ref.watch(transactionProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();

  if (query.isEmpty) return transactions;

  return transactions.where((tx) {
    return tx.category.toLowerCase().contains(query) || 
           tx.description.toLowerCase().contains(query);
  }).toList();
});

enum ReportTimeRange { allTime, monthly, weekly, daily }

class ReportDateRangeNotifier extends Notifier<ReportTimeRange> {
  @override
  ReportTimeRange build() => ReportTimeRange.monthly;
  
  void updateRange(ReportTimeRange newRange) {
    state = newRange;
  }
}

final reportDateRangeProvider = NotifierProvider<ReportDateRangeNotifier, ReportTimeRange>(() {
  return ReportDateRangeNotifier();
});

final reportsFilteredTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final transactions = ref.watch(transactionProvider);
  final range = ref.watch(reportDateRangeProvider);
  final now = DateTime.now();

  switch (range) {
    case ReportTimeRange.allTime:
      return transactions;
    case ReportTimeRange.monthly:
      return transactions.where((t) => t.date.year == now.year && t.date.month == now.month).toList();
    case ReportTimeRange.weekly:
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      return transactions.where((t) => t.date.isAfter(startOfWeek.subtract(const Duration(days: 1)))).toList();
    case ReportTimeRange.daily:
      return transactions.where((t) => t.date.year == now.year && t.date.month == now.month && t.date.day == now.day).toList();
  }
});

final reportsIncomeProvider = Provider<double>((ref) {
  final tx = ref.watch(reportsFilteredTransactionsProvider);
  return tx.where((t) => t.type == TransactionType.income).fold(0.0, (sum, item) => sum + item.amount);
});

final reportsExpenseProvider = Provider<double>((ref) {
  final tx = ref.watch(reportsFilteredTransactionsProvider);
  return tx.where((t) => t.type == TransactionType.expense).fold(0.0, (sum, item) => sum + item.amount);
});

final reportsExpensesByCategoryProvider = Provider<Map<String, double>>((ref) {
  final expenses = ref.watch(reportsFilteredTransactionsProvider).where((t) => t.type == TransactionType.expense);
  final map = <String, double>{};
  for (var t in expenses) {
    map[t.category] = (map[t.category] ?? 0) + t.amount;
  }
  final sortedMap = Map.fromEntries(
    map.entries.toList()..sort((e1, e2) => e2.value.compareTo(e1.value))
  );
  return sortedMap;
});
