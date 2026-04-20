import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/providers/transaction_provider.dart';
import '../../../core/providers/preferences_provider.dart';
import '../../../core/providers/category_provider.dart';
import '../../../core/services/data_service.dart';
import '../../../core/design/fintrack_ui.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/widgets/glass_container.dart';

class DataManagementScreen extends ConsumerWidget {
  const DataManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backups & Data'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _SystemHealthCard(),
          const SizedBox(height: 32),
          FintrackUI.sectionHeader(context, 'Full System Backup', icon: LucideIcons.shield),
          const SizedBox(height: 8),
          FintrackUI.listTile(
            context: context,
            title: const Text('Export JSON', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Backup everything including categories and settings.'),
            leading: _buildIcon(context, LucideIcons.download),
            trailing: const Icon(LucideIcons.chevronRight, size: 16),
            onTap: () => _handleJsonExport(context, ref),
          ),
          FintrackUI.listTile(
            context: context,
            title: const Text('Import JSON', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Restore from a previous system backup file.'),
            leading: _buildIcon(context, LucideIcons.upload),
            trailing: const Icon(LucideIcons.chevronRight, size: 16),
            onTap: () => _handleJsonImport(context, ref),
          ),
          const SizedBox(height: 24),
          FintrackUI.sectionHeader(context, 'Spreadsheet Compatibility', icon: LucideIcons.fileSpreadsheet),
          const SizedBox(height: 8),
          FintrackUI.listTile(
            context: context,
            title: const Text('Export to CSV', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Open your transactions in Excel or Google Sheets.'),
            leading: _buildIcon(context, LucideIcons.share2),
            trailing: const Icon(LucideIcons.chevronRight, size: 16),
            onTap: () => _handleCsvExport(context, ref),
          ),
          FintrackUI.listTile(
            context: context,
            title: const Text('Import from CSV', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Merge external transaction lists into your ledger.'),
            leading: _buildIcon(context, LucideIcons.filePlus),
            trailing: const Icon(LucideIcons.chevronRight, size: 16),
            onTap: () => _handleCsvImport(context, ref),
          ),
          const SizedBox(height: 48),
          const Center(
            child: Text(
              'Your data is stored locally on this device.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(BuildContext context, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
    );
  }

  Future<void> _handleJsonExport(BuildContext context, WidgetRef ref) async {
    HapticFeedback.mediumImpact();
    final trs = ref.read(transactionProvider);
    final cats = ref.read(categoryProvider);
    final prefs = ref.read(preferencesProvider);

    final Map<String, dynamic> data = {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'transactions': trs.map((t) => t.toMap()).toList(),
      'categories': {
        'income': cats.incomeCategories,
        'expense': cats.expenseCategories,
      },
      'preferences': {
        'userName': prefs.userName,
        'currencySymbol': prefs.currencySymbol,
        'hasCompletedOnboarding': prefs.hasCompletedOnboarding,
      }
    };

    try {
      await DataExportImportService.exportToJson(data);
    } catch (e) {
      if (context.mounted) _showError(context, e.toString());
    }
  }

  Future<void> _handleJsonImport(BuildContext context, WidgetRef ref) async {
    HapticFeedback.lightImpact();
    
    final bool? confirmImport = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore System Backup?'),
        content: const Text('This will COMPLETELY OVERWRITE your current data.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Overwrite', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmImport != true) return;

    try {
      final resMap = await DataExportImportService.pickAndParseJson();
      if (!context.mounted) return;
      if (resMap != null) {
        if (resMap['transactions'] == null) throw Exception('No data');

        final List rawTransactions = resMap['transactions'] as List;
        final List<TransactionModel> models = rawTransactions.map((e) => TransactionModel.fromMap(Map<String, dynamic>.from(e))).toList();
        ref.read(transactionProvider.notifier).replaceAllData(models);
        
        final dynamic catsDynamic = resMap['categories'];
        if (catsDynamic is Map) {
          final Map catsMap = catsDynamic;
          final dynamic rawInc = catsMap['income'];
          final dynamic rawExp = catsMap['expense'];
          
          List incomeToImport = [];
          if (rawInc is List) {
            incomeToImport = rawInc;
          }
          
          List expenseToImport = [];
          if (rawExp is List) {
            expenseToImport = rawExp;
          }

          final List<String> incFinal = incomeToImport.map((e) => e.toString()).toList();
          final List<String> expFinal = expenseToImport.map((e) => e.toString()).toList();
          
          ref.read(categoryProvider.notifier).importCategories(incFinal, expFinal);
        }

        final dynamic pRaw = resMap['preferences'];
        if (pRaw is Map) {
          final String n = (pRaw['userName'] ?? '').toString();
          final String s = (pRaw["currencySymbol"] ?? "\$").toString();
          ref.read(preferencesProvider.notifier).completeOnboarding(n, s);
        }

        _showSuccess(context, 'Success!');
      }
    } catch (e) {
      if (context.mounted) _showError(context, 'Error: $e');
    }
  }

  Future<void> _handleCsvExport(BuildContext context, WidgetRef ref) async {
    HapticFeedback.mediumImpact();
    final trs = ref.read(transactionProvider);
    try {
      await DataExportImportService.exportToCsv(trs);
    } catch (e) {
      if (context.mounted) _showError(context, e.toString());
    }
  }

  Future<void> _handleCsvImport(BuildContext context, WidgetRef ref) async {
    HapticFeedback.lightImpact();
    try {
      final txs = await DataExportImportService.pickAndParseCsv();
      if (!context.mounted) return;
      if (txs != null && txs.isNotEmpty) {
        final bool? ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Import CSV?'),
            content: Text('Merge ${txs.length} transactions?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Merge')),
            ],
          ),
        );

        if (ok == true) {
          ref.read(transactionProvider.notifier).mergeTransactions(txs);
          if (context.mounted) _showSuccess(context, 'Done!');
        }
      }
    } catch (e) {
      if (context.mounted) _showError(context, 'Error: $e');
    }
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showSuccess(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }
}

class _SystemHealthCard extends ConsumerWidget {
  const _SystemHealthCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txLen = ref.watch(transactionProvider).length;
    final catLen = ref.watch(categoryProvider).expenseCategories.length + ref.watch(categoryProvider).incomeCategories.length;

    return GlassContainer(
      padding: const EdgeInsets.all(24),
      opacity: isDark ? 0.05 : 0.4,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(28),
      child: Column(
        children: [
          const Icon(LucideIcons.hardDrive, size: 40, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Local Data Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(label: 'Entries', value: txLen.toString()),
              _StatItem(label: 'Categories', value: catLen.toString()),
              const _StatItem(label: 'Security', value: 'Local'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
