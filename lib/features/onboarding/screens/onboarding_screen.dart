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
  int _currentPage = 0;
  
  final List<Map<String, String>> _currencies = [
    {'symbol': '\$', 'name': 'USD', 'flag': '🇺🇸'},
    {'symbol': '€', 'name': 'EUR', 'flag': '🇪🇺'},
    {'symbol': '£', 'name': 'GBP', 'flag': '🇬🇧'},
    {'symbol': '৳', 'name': 'BDT', 'flag': '🇧🇩'},
    {'symbol': '₹', 'name': 'INR', 'flag': '🇮🇳'},
    {'symbol': '¥', 'name': 'JPY', 'flag': '🇯🇵'},
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    HapticFeedback.mediumImpact();
    
    if (_currentPage == 0 && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('We need to know what to call you!'),
          behavior: SnackBarBehavior.floating,
        )
      );
      return;
    }
    
    if (_currentPage < 1) {
      _pageController.nextPage(duration: 500.ms, curve: Curves.easeOutQuart);
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() {
    HapticFeedback.mediumImpact();
    ref.read(preferencesProvider.notifier).completeOnboarding(
      _nameController.text.trim(),
      _selectedCurrency,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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
                      _buildWelcomeAndNameStep(),
                      _buildCurrencyStep(),
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
                  onPressed: () => _pageController.previousPage(duration: 400.ms, curve: Curves.easeOut),
                )
              : const SizedBox(width: 48),
          Row(
            children: List.generate(2, (i) => AnimatedContainer(
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

  Widget _buildWelcomeAndNameStep() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/images/logo.png',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.bounceOut),
          const SizedBox(height: 32),
          Text(
            'FinTrack Pro',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fade().slideX(begin: -0.1),
          const SizedBox(height: 8),
          const Text('What should I call you?', style: TextStyle(color: Colors.grey, fontSize: 18))
            .animate().fade(delay: 200.ms).slideX(begin: -0.1),
          const SizedBox(height: 32),
          TextField(
            controller: _nameController,
            autofocus: true,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'Your name',
              hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.3)),
              border: InputBorder.none,
            ),
          ).animate().fade(delay: 400.ms).slideY(begin: 0.1),
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
          const Text('Currency', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Choose your primary currency.', style: TextStyle(color: Colors.grey)),
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
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(curr['flag']!, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 4),
                      Text(curr['symbol']!, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : null)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: FintrackUI.actionButton(
        context: context,
        label: _currentPage == 1 ? 'Start Tracking' : 'Continue',
        onPressed: _nextPage,
        icon: _currentPage == 1 ? LucideIcons.rocket : LucideIcons.arrowRight,
      ),
    );
  }
}
