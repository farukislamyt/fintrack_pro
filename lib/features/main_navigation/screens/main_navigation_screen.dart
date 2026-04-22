import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/widgets/glass_container.dart';

class MainNavigationScreen extends StatefulWidget {
  final Widget child;

  const MainNavigationScreen({super.key, required this.child});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/reports')) return 1;
    if (location.startsWith('/add_transaction')) return 2;
    if (location.startsWith('/history')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    HapticFeedback.lightImpact();
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/reports');
        break;
      case 2:
        context.go('/add_transaction');
        break;
      case 3:
        context.go('/history');
        break;
      case 4:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int currentIndex = _calculateSelectedIndex(context);
    final theme = Theme.of(context);

    return Scaffold(
      extendBody: true, // Crucial for glassmorphism to show whatever is behind
      body: widget.child,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: GlassContainer(
          borderRadius: BorderRadius.circular(32),
          blur: 15,
          opacity: theme.brightness == Brightness.dark ? 0.08 : 0.4,
          color: theme.brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedIndex: currentIndex,
            onDestinationSelected: (index) => _onItemTapped(index, context),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
            height: 70,
            destinations: [
              const NavigationDestination(
                icon: Icon(LucideIcons.layoutDashboard),
                label: 'Dashboard',
              ),
              const NavigationDestination(
                icon: Icon(LucideIcons.pieChart),
                label: 'Reports',
              ),
              NavigationDestination(
                icon: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.primaryColor, const Color(0xFFF43F5E)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryColor.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    LucideIcons.plus,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                label: 'Add',
              ),
              const NavigationDestination(
                icon: Icon(LucideIcons.history),
                label: 'History',
              ),
              const NavigationDestination(
                icon: Icon(LucideIcons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
