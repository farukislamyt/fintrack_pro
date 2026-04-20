import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';
import 'dart:convert';

class CategoryState {
  final List<String> incomeCategories;
  final List<String> expenseCategories;

  CategoryState({
    required this.incomeCategories,
    required this.expenseCategories,
  });

  Map<String, dynamic> toJson() => {
    'income': incomeCategories,
    'expense': expenseCategories,
  };

  factory CategoryState.fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr);
    return CategoryState(
      incomeCategories: List<String>.from(map['income'] ?? []),
      expenseCategories: List<String>.from(map['expense'] ?? []),
    );
  }
}

class CategoryNotifier extends Notifier<CategoryState> {
  static const _prefsKey = 'categories_data';
  
  static const _defaultIncome = ['Salary', 'Freelance', 'Investments', 'Gift', 'Side Hustle', 'Other'];
  static const _defaultExpense = ['Food', 'Transport', 'Entertainment', 'Shopping', 'Bills', 'Rent', 'Health', 'Education', 'Other'];

  @override
  CategoryState build() {
    _loadFromPrefs();
    return CategoryState(incomeCategories: _defaultIncome, expenseCategories: _defaultExpense);
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_prefsKey);
    if (data != null) {
      state = CategoryState.fromJson(data);
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(state.toJson()));
  }

  void addCategory(TransactionType type, String name) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;

    if (type == TransactionType.income) {
      if (!state.incomeCategories.contains(cleanName)) {
        state = CategoryState(
          incomeCategories: [...state.incomeCategories, cleanName],
          expenseCategories: state.expenseCategories,
        );
      }
    } else {
      if (!state.expenseCategories.contains(cleanName)) {
        state = CategoryState(
          incomeCategories: state.incomeCategories,
          expenseCategories: [...state.expenseCategories, cleanName],
        );
      }
    }
    _saveToPrefs();
  }

  void deleteCategory(TransactionType type, String name) {
    if (type == TransactionType.income) {
      state = CategoryState(
        incomeCategories: state.incomeCategories.where((c) => c != name).toList(),
        expenseCategories: state.expenseCategories,
      );
    } else {
      state = CategoryState(
        incomeCategories: state.incomeCategories,
        expenseCategories: state.expenseCategories.where((c) => c != name).toList(),
      );
    }
    _saveToPrefs();
  }

  void importCategories(List<String> income, List<String> expense) {
    state = CategoryState(
      incomeCategories: income,
      expenseCategories: expense,
    );
    _saveToPrefs();
  }
}

final categoryProvider = NotifierProvider<CategoryNotifier, CategoryState>(() {
  return CategoryNotifier();
});
