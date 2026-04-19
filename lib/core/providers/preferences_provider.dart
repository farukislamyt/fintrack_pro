import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  final String userName;
  final String currencySymbol;
  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final bool hasCompletedOnboarding;
  final bool isLoaded;

  UserPreferences({
    this.userName = '',
    this.currencySymbol = '\$',
    this.themeMode = ThemeMode.dark,
    this.notificationsEnabled = true,
    this.hasCompletedOnboarding = false,
    this.isLoaded = false,
  });

  UserPreferences copyWith({
    String? userName,
    String? currencySymbol,
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    bool? hasCompletedOnboarding,
    bool? isLoaded,
  }) {
    return UserPreferences(
      userName: userName ?? this.userName,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

class PreferencesNotifier extends Notifier<UserPreferences> {
  static const _keyUserName = 'pref_user_name';
  static const _keyCurrency = 'pref_currency';
  static const _keyTheme = 'pref_theme';
  static const _keyNotifications = 'pref_notifications';
  static const _keyOnboarding = 'pref_onboarding';

  @override
  UserPreferences build() {
    _loadPrefs();
    return UserPreferences(); // Return default while async loading
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = UserPreferences(
      userName: prefs.getString(_keyUserName) ?? '',
      currencySymbol: prefs.getString(_keyCurrency) ?? '\$',
      themeMode: (prefs.getString(_keyTheme) == 'light') ? ThemeMode.light : ThemeMode.dark,
      notificationsEnabled: prefs.getBool(_keyNotifications) ?? true,
      hasCompletedOnboarding: prefs.getBool(_keyOnboarding) ?? false,
      isLoaded: true,
    );
  }

  Future<void> completeOnboarding(String name, String currency, ThemeMode theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, name);
    await prefs.setString(_keyCurrency, currency);
    await prefs.setString(_keyTheme, theme == ThemeMode.light ? 'light' : 'dark');
    await prefs.setBool(_keyOnboarding, true);
    
    state = state.copyWith(
      userName: name,
      currencySymbol: currency,
      themeMode: theme,
      hasCompletedOnboarding: true,
    );
  }

  Future<void> updateTheme(ThemeMode theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTheme, theme == ThemeMode.light ? 'light' : 'dark');
    state = state.copyWith(themeMode: theme);
  }
  
  Future<void> updateCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrency, currency);
    state = state.copyWith(currencySymbol: currency);
  }

  Future<void> updateNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, enabled);
    state = state.copyWith(notificationsEnabled: enabled);
  }
}

final preferencesProvider = NotifierProvider<PreferencesNotifier, UserPreferences>(() {
  return PreferencesNotifier();
});
