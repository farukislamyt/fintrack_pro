import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/providers/preferences_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Wait for cinematic animation and preferences load
    await Future.delayed(const Duration(milliseconds: 2500));
    
    if (!mounted) return;
    
    final prefs = ref.read(preferencesProvider);
    if (!prefs.isLoaded) {
       // Loop if not yet loaded (should be fast)
       _navigateToNext();
       return;
    }

    if (prefs.isPasscodeEnabled) {
      context.go('/verify_passcode');
    } else {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Matches AppTheme.backgroundColor
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/images/logo.png',
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            )
            .animate()
            .scale(duration: 800.ms, curve: Curves.easeOutBack)
            .shimmer(delay: 1000.ms, duration: 1500.ms, color: Colors.white24),
            
            const SizedBox(height: 24),
            
            Text(
              'FinTrack Pro',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: const Color(0xFFE2136E), // Brand primary
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
              ),
            )
            .animate()
            .fade(delay: 400.ms)
            .slideY(begin: 0.2, end: 0, duration: 600.ms),
            
            const SizedBox(height: 8),
            
            Text(
              'Professional Cash Management',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 14,
                letterSpacing: 1.5,
              ),
            )
            .animate()
            .fade(delay: 800.ms),
          ],
        ),
      ),
    );
  }
}
