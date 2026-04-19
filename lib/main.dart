import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // NOTE: Firebase initialization is prepared here.
  // It is wrapped in a try/catch so the UI can still run and be built
  // before you actually configure flutterfire (google-services.json / GoogleService-Info.plist).
  try {
    // await Firebase.initializeApp(
    //   options: DefaultFirebaseOptions.currentPlatform,
    // );
  } catch (e) {
    debugPrint("Firebase not configured yet: $e");
  }

  runApp(const ProviderScope(child: FinTrackProApp()));
}

class FinTrackProApp extends StatelessWidget {
  const FinTrackProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FinTrack Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
