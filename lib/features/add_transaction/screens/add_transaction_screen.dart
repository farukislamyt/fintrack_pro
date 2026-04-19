import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/providers/transaction_provider.dart';
import '../../../core/providers/preferences_provider.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TransactionType _selectedType = TransactionType.expense;
  String _selectedCategory = 'Food';

  final List<String> _expenseCategories = ['Food', 'Transport', 'Entertainment', 'Shopping', 'Bills', 'Other'];
  final List<String> _incomeCategories = ['Salary', 'Freelance', 'Investments', 'Gift', 'Other'];

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveTransaction() {
    final amountText = _amountController.text;
    if (amountText.isEmpty) return;
    
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) return;

    final transaction = TransactionModel(
      amount: amount,
      date: _selectedDate,
      type: _selectedType,
      category: _selectedCategory,
      description: _descriptionController.text,
    );

    ref.read(transactionProvider.notifier).addTransaction(transaction);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transaction Saved!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    _amountController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedDate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = ref.watch(preferencesProvider).currencySymbol;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.income, 
                  label: Text('Income'),
                  icon: Icon(LucideIcons.arrowDownToLine),
                ),
                ButtonSegment(
                  value: TransactionType.expense, 
                  label: Text('Expense'),
                  icon: Icon(LucideIcons.arrowUpFromLine),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (Set<TransactionType> newSelection) {
                setState(() {
                  _selectedType = newSelection.first;
                  _selectedCategory = _selectedType == TransactionType.income 
                      ? _incomeCategories.first 
                      : _expenseCategories.first;
                });
              },
            ).animate().fade().slideY(begin: 0.1, end: 0),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _amountController,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: '$currencySymbol ',
                      prefixStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      prefixIcon: const Icon(LucideIcons.tag),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                      ),
                    ),
                    items: (_selectedType == TransactionType.income ? _incomeCategories : _expenseCategories)
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedCategory = val);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _selectedDate = date);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date',
                        prefixIcon: const Icon(LucideIcons.calendar),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                        ),
                      ),
                      child: Text(
                        DateFormat.yMMMMd().format(_selectedDate),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      prefixIcon: const Icon(LucideIcons.fileText),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _saveTransaction,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: const Text('Save Transaction', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ).animate().fade(delay: 200.ms).slideY(begin: 0.1, end: 0),
          ],
        ),
      ),
    );
  }
}
