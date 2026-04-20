import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'core/providers/preferences_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    const ProviderScope(
      child: FinTrackProApp(),
    ),
  );
}

class FinTrackProApp extends ConsumerWidget {
  const FinTrackProApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final preferences = ref.watch(preferencesProvider);

    return MaterialApp.router(
      title: 'FinTrack Pro',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: preferences.themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
