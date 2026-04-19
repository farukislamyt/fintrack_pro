import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/providers/preferences_provider.dart';

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
    {'symbol': '\$', 'name': 'USD - US Dollar'},
    {'symbol': '€', 'name': 'EUR - Euro'},
    {'symbol': '£', 'name': 'GBP - British Pound'},
    {'symbol': '₹', 'name': 'INR - Indian Rupee'},
    {'symbol': '¥', 'name': 'JPY - Japanese Yen'},
    {'symbol': '৳', 'name': 'BDT - Bangladeshi Taka'},
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 0 && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your name')));
      return;
    }
    
    if (_currentPage < 2) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      // Finish
      ref.read(preferencesProvider.notifier).completeOnboarding(
        _nameController.text.trim(),
        _selectedCurrency,
        _selectedTheme,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    IconButton(
                      icon: const Icon(LucideIcons.arrowLeft),
                      onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                    )
                  else
                    const SizedBox(width: 48), // Padding
                  Text('Step ${_currentPage + 1} of 3', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(width: 48), // To balance the back button
                ],
              ),
            ),
            
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                children: [
                  _buildNameStep(),
                  _buildCurrencyStep(),
                  _buildThemeStep(),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(_currentPage == 2 ? 'Let\'s Go!' : 'Continue', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ).animate().fade(delay: 500.ms).slideY(begin: 0.2, end: 0),
          ],
        ),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Theme.of(context).primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(LucideIcons.user, size: 48, color: Theme.of(context).primaryColor),
          ).animate().scale(delay: 100.ms),
          const SizedBox(height: 32),
          Text('Welcome to FinTrack Pro', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('What should we call you?', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
          const SizedBox(height: 32),
          TextField(
            controller: _nameController,
            style: const TextStyle(fontSize: 24),
            decoration: const InputDecoration(
              hintText: 'Your proper name',
              border: UnderlineInputBorder(),
            ),
          ),
        ],
      ).animate().fade(duration: 400.ms),
    );
  }

  Widget _buildCurrencyStep() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Theme.of(context).primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(LucideIcons.coins, size: 48, color: Theme.of(context).primaryColor),
          ).animate().scale(),
          const SizedBox(height: 32),
          Text('Primary Currency', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('This will be used across all your reports.', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCurrency,
                isExpanded: true,
                items: _currencies.map((currency) {
                  return DropdownMenuItem(
                    value: currency['symbol'],
                    child: Text('${currency['symbol']}   ${currency['name']}'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCurrency = val);
                },
              ),
            ),
          ),
        ],
      ).animate().fade(duration: 400.ms),
    );
  }

  Widget _buildThemeStep() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Theme.of(context).primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(LucideIcons.palette, size: 48, color: Theme.of(context).primaryColor),
          ).animate().scale(),
          const SizedBox(height: 32),
          Text('Choose an Aesthetic', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('You can always change this later.', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTheme = ThemeMode.light),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _selectedTheme == ThemeMode.light ? Theme.of(context).primaryColor : Colors.grey, width: 2),
                    ),
                    child: Column(
                      children: [
                        Icon(LucideIcons.sun, color: _selectedTheme == ThemeMode.light ? Theme.of(context).primaryColor : Colors.grey),
                        const SizedBox(height: 8),
                        Text('Light', style: TextStyle(color: _selectedTheme == ThemeMode.light ? Theme.of(context).primaryColor : Colors.grey, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTheme = ThemeMode.dark),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _selectedTheme == ThemeMode.dark ? Theme.of(context).primaryColor : Colors.transparent, width: 2),
                    ),
                    child: Column(
                      children: [
                        Icon(LucideIcons.moon, color: _selectedTheme == ThemeMode.dark ? Theme.of(context).primaryColor : Colors.grey),
                        const SizedBox(height: 8),
                        Text('Dark', style: TextStyle(color: _selectedTheme == ThemeMode.dark ? Theme.of(context).primaryColor : Colors.grey, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ).animate().fade(duration: 400.ms),
    );
  }
}
