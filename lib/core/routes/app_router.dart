import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/main_navigation/screens/main_navigation_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../../features/add_transaction/screens/add_transaction_screen.dart';
import '../../features/history/screens/history_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/screens/legal_detail_screen.dart';
import '../../features/settings/screens/data_management_screen.dart';
import '../../features/onboarding/screens/splash_screen.dart';
import '../../features/onboarding/screens/passcode_screen.dart';
import '../constants/legal_content.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/verify_passcode',
        builder: (context, state) => const PasscodeScreen(mode: PasscodeMode.verify),
      ),
      GoRoute(
        path: '/set_passcode',
        builder: (context, state) => const PasscodeScreen(mode: PasscodeMode.set),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainNavigationScreen(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
               child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/reports',
            pageBuilder: (context, state) => const NoTransitionPage(
               child: ReportsScreen(),
            ),
          ),
          GoRoute(
            path: '/add_transaction',
            pageBuilder: (context, state) => const NoTransitionPage(
               child: AddTransactionScreen(),
            ),
          ),
          GoRoute(
            path: '/history',
            pageBuilder: (context, state) => const NoTransitionPage(
               child: HistoryScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
               child: SettingsScreen(),
            ),
            routes: [
              GoRoute(
                path: 'privacy',
                builder: (context, state) => const LegalDetailScreen(
                  title: 'Privacy Policy',
                  content: LegalContent.privacyPolicy,
                ),
              ),
              GoRoute(
                path: 'terms',
                builder: (context, state) => const LegalDetailScreen(
                  title: 'Terms & Conditions',
                  content: LegalContent.termsConditions,
                ),
              ),
              GoRoute(
                path: 'safety',
                builder: (context, state) => const LegalDetailScreen(
                  title: 'Data Safety',
                  content: LegalContent.dataSafety,
                ),
              ),
              GoRoute(
                path: 'data_management',
                builder: (context, state) => const DataManagementScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
