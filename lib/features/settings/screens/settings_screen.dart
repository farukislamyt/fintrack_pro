import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/providers/transaction_provider.dart';
import '../../../core/providers/preferences_provider.dart';
import '../../../core/providers/category_provider.dart';
import '../../../core/models/transaction_model.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  void _clearData() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text('Are you sure you want to delete all transactions? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.heavyImpact();
              ref.read(transactionProvider.notifier).clearAll();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data cleared successfully.')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _manageCategories() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const _CategoryManagerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(preferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 30,
                child: Icon(LucideIcons.user, size: 30),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prefs.userName.isNotEmpty ? prefs.userName : 'User',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'admin@fintrack.pro',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSettingsGroup(
            context,
            'Preferences',
            [
              _buildSettingsTile(context, 'Currency', LucideIcons.coins, trailing: Text(prefs.currencySymbol)),
              _buildSettingsTile(context, 'Dark Mode', LucideIcons.moon, 
                trailing: Switch(
                  value: prefs.themeMode == ThemeMode.dark, 
                  onChanged: (v) {
                    HapticFeedback.mediumImpact();
                    ref.read(preferencesProvider.notifier).updateTheme(v ? ThemeMode.dark : ThemeMode.light);
                  }
                )),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingsGroup(
            context,
            'Content',
            [
              _buildSettingsTile(
                context, 
                'Manage Categories', 
                LucideIcons.tag, 
                onTap: _manageCategories,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingsGroup(
            context,
            'Legal',
            [
              _buildSettingsTile(
                context, 
                'Privacy Policy', 
                LucideIcons.shieldCheck, 
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/settings/privacy');
                },
              ),
              _buildSettingsTile(
                context, 
                'Terms & Conditions', 
                LucideIcons.fileText, 
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/settings/terms');
                },
              ),
              _buildSettingsTile(
                context, 
                'Data Safety', 
                LucideIcons.lock, 
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/settings/safety');
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingsGroup(
            context,
            'Data Management',
            [
              _buildSettingsTile(
                context, 
                'Data & Backup', 
                LucideIcons.database, 
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/settings/data_management');
                },
              ),
              _buildSettingsTile(
                context, 
                'Clear All Data', 
                LucideIcons.trash2, 
                color: Theme.of(context).colorScheme.error,
                onTap: _clearData,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'FinTrack Pro v1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(BuildContext context, String title, IconData icon, {Widget? trailing, Color? color, VoidCallback? onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (color ?? Theme.of(context).iconTheme.color)?.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color ?? Theme.of(context).iconTheme.color),
      ),
      title: Text(title, style: TextStyle(color: color)),
      trailing: trailing ?? const Icon(LucideIcons.chevronRight, size: 20),
      onTap: onTap,
    );
  }
}

class _CategoryManagerSheet extends ConsumerWidget {
  const _CategoryManagerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoryProvider);

    return DefaultTabController(
      length: 2,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Manage Categories', style: Theme.of(context).textTheme.headlineSmall),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x)),
              ],
            ),
            const SizedBox(height: 16),
            TabBar(
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).primaryColor,
              tabs: const [
                Tab(text: 'Expenses'),
                Tab(text: 'Income'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                children: [
                  _CategoryList(type: TransactionType.expense, list: categories.expenseCategories),
                  _CategoryList(type: TransactionType.income, list: categories.incomeCategories),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                _showAddDialog(context, ref);
              },
              icon: const Icon(LucideIcons.plus),
              label: const Text('Add New Category'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final typeIndex = DefaultTabController.of(context).index;
    final type = typeIndex == 0 ? TransactionType.expense : TransactionType.income;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add ${type == TransactionType.income ? 'Income' : 'Expense'} Category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Category Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                HapticFeedback.lightImpact();
                ref.read(categoryProvider.notifier).addCategory(type, controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _CategoryList extends ConsumerWidget {
  final TransactionType type;
  final List<String> list;

  const _CategoryList({required this.type, required this.list});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final category = list[index];
        return ListTile(
          title: Text(category),
          trailing: IconButton(
            icon: const Icon(LucideIcons.trash2, color: Colors.grey, size: 20),
            onPressed: () {
              HapticFeedback.mediumImpact();
              ref.read(categoryProvider.notifier).deleteCategory(type, category);
            },
          ),
        );
      },
    );
  }
}
