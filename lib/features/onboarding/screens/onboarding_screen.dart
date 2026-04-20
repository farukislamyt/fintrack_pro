import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/providers/preferences_provider.dart';
import '../../../core/design/fintrack_ui.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  
  String _selectedCurrency = '\$';
  ThemeMode _selectedTheme = ThemeMode.dark;
  int _currentPage = 0;
  
  final List<Map<String, String>> _currencies = [
    {'symbol': '\$', 'name': 'USD', 'flag': '🇺🇸'},
    {'symbol': '€', 'name': 'EUR', 'flag': '🇪🇺'},
    {'symbol': '£', 'name': 'GBP', 'flag': '🇬🇧'},
    {'symbol': '₹', 'name': 'INR', 'flag': '🇮🇳'},
    {'symbol': '¥', 'name': 'JPY', 'flag': '🇯🇵'},
    {'symbol': '৳', 'name': 'BDT', 'flag': '🇧🇩'},
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    HapticFeedback.mediumImpact();
    
    if (_currentPage == 1 && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('We need to know what to call you!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        )
      );
      return;
    }
    
    if (_currentPage < 3) {
      _pageController.nextPage(duration: 600.ms, curve: Curves.easeOutQuart);
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() {
    HapticFeedback.mediumImpact();
    ref.read(preferencesProvider.notifier).completeOnboarding(
      _nameController.text.trim(),
      _selectedCurrency,
      _selectedTheme,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient base
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).primaryColor.withValues(alpha: 0.05),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (idx) => setState(() => _currentPage = idx),
                    children: [
                      _buildWelcomeStep(),
                      _buildNameStep(),
                      _buildCurrencyStep(),
                      _buildThemeStep(),
                    ],
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _currentPage > 0 
              ? IconButton(
                  icon: const Icon(LucideIcons.arrowLeft, size: 20),
                  onPressed: () => _pageController.previousPage(duration: 500.ms, curve: Curves.easeOut),
                )
              : const SizedBox(width: 48),
          Row(
            children: List.generate(4, (i) => AnimatedContainer(
              duration: 300.ms,
              width: _currentPage == i ? 24 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: _currentPage == i ? Theme.of(context).primaryColor : Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            )),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildWelcomeStep() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Theme.of(context).primaryColor, const Color(0xFF818CF8)]),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))
              ],
            ),
            child: const Icon(LucideIcons.piggyBank, size: 64, color: Colors.white),
          ).animate().scale(duration: 600.ms, curve: Curves.bounceOut).shimmer(delay: 1.seconds),
          const SizedBox(height: 48),
          Text(
            'FinTrack Pro',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: Theme.of(context).primaryColor,
              letterSpacing: -1,
            ),
          ).animate().fade(delay: 200.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 12),
          Text(
            'Master your money with cinematic insights and precision tracking.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
          ).animate().fade(delay: 400.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildNameStep() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hello, I am FinTrack.', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
            .animate().fade().slideX(begin: -0.1, end: 0),
          const SizedBox(height: 8),
          const Text('What should I call you?', style: TextStyle(color: Colors.grey, fontSize: 18))
            .animate().fade(delay: 200.ms).slideX(begin: -0.1, end: 0),
          const SizedBox(height: 48),
          TextField(
            controller: _nameController,
            autofocus: true,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'Your name',
              hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.3)),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ).animate().fade(delay: 400.ms).slideY(begin: 0.1, end: 0),
        ],
      ),
    );
  }

  Widget _buildCurrencyStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Currency', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('This will be your primary unit for reports.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: _currencies.length,
            itemBuilder: (context, index) {
              final curr = _currencies[index];
              final isSelected = _selectedCurrency == curr['symbol'];
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedCurrency = curr['symbol']!);
                },
                child: AnimatedContainer(
                  duration: 300.ms,
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.grey.withValues(alpha: 0.1),
                      width: 2,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))
                    ] : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(curr['flag']!, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 4),
                      Text(
                        curr['symbol']!,
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fade(delay: (index * 50).ms).scale();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemeStep() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Visual Aesthetic', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Choose the style that matches your flow.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          Row(
            children: [
              _ThemeOption(
                label: 'Light',
                icon: LucideIcons.sun,
                isSelected: _selectedTheme == ThemeMode.light,
                onTap: () => setState(() => _selectedTheme = ThemeMode.light),
              ),
              const SizedBox(width: 16),
              _ThemeOption(
                label: 'Dark',
                icon: LucideIcons.moon,
                isSelected: _selectedTheme == ThemeMode.dark,
                onTap: () => setState(() => _selectedTheme = ThemeMode.dark),
              ),
            ],
          ),
          const SizedBox(height: 32),
          FintrackUI.glassCard(
            padding: const EdgeInsets.all(24),
            color: _selectedTheme == ThemeMode.dark ? const Color(0xFF1E293B) : Colors.white,
            opacity: _selectedTheme == ThemeMode.dark ? 0.4 : 0.8,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(height: 8, width: 60, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4))),
                    const CircleAvatar(radius: 10, backgroundColor: Colors.blueAccent),
                  ],
                ),
                const SizedBox(height: 20),
                Container(height: 30, width: double.infinity, decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(10))),
              ],
            ),
          ).animate().fade().scale(),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: FintrackUI.actionButton(
        context: context,
        label: _currentPage == 3 ? 'Get Started' : 'Continue',
        onPressed: _nextPage,
        icon: _currentPage == 3 ? LucideIcons.rocket : LucideIcons.arrowRight,
      ),
    ).animate().fade(delay: 400.ms).slideY(begin: 0.2, end: 0);
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: 300.ms,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey.withValues(alpha: 0.1),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 32),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
