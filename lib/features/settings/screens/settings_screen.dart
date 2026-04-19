import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/providers/transaction_provider.dart';
import '../../../core/providers/preferences_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {

  void _clearData() {
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
              _buildSettingsTile(context, 'Notifications', LucideIcons.bell, 
                trailing: Switch(
                  value: prefs.notificationsEnabled, 
                  onChanged: (v) => ref.read(preferencesProvider.notifier).updateNotifications(v),
                )),
              _buildSettingsTile(context, 'Dark Mode', LucideIcons.moon, 
                trailing: Switch(
                  value: prefs.themeMode == ThemeMode.dark, 
                  onChanged: (v) {
                    ref.read(preferencesProvider.notifier).updateTheme(v ? ThemeMode.dark : ThemeMode.light);
                  }
                )),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingsGroup(
            context,
            'Data Management',
            [
              _buildSettingsTile(
                context, 
                'Clear All Data', 
                LucideIcons.trash2, 
                color: Theme.of(context).colorScheme.error,
                onTap: _clearData,
              ),
            ],
          ),
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
