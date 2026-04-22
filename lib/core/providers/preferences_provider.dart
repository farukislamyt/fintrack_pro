import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

class UserPreferences {
  final String userName;
  final String currencySymbol;
  final bool hasCompletedOnboarding;
  final bool isLoaded;
  final bool isPasscodeEnabled;
  final String passcode;

  UserPreferences({
    this.userName = '',
    this.currencySymbol = '\$',
    this.hasCompletedOnboarding = true,
    this.isLoaded = false,
    this.isPasscodeEnabled = false,
    this.passcode = '',
  });

  UserPreferences copyWith({
    String? userName,
    String? currencySymbol,
    bool? hasCompletedOnboarding,
    bool? isLoaded,
    bool? isPasscodeEnabled,
    String? passcode,
  }) {
    return UserPreferences(
      userName: userName ?? this.userName,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      isLoaded: isLoaded ?? this.isLoaded,
      isPasscodeEnabled: isPasscodeEnabled ?? this.isPasscodeEnabled,
      passcode: passcode ?? this.passcode,
    );
  }
}

class PreferencesNotifier extends Notifier<UserPreferences> {
  @override
  UserPreferences build() {
    _loadPreferences();
    return UserPreferences();
  }

  static const String _keyUserName = 'user_name';
  static const String _keyCurrency = 'currency_symbol';
  static const String _keyOnboarding = 'has_completed_onboarding';
  static const String _keyPasscodeEnabled = 'is_passcode_enabled';
  static const String _keyPasscode = 'passcode_val';

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      userName: prefs.getString(_keyUserName) ?? '',
      currencySymbol: prefs.getString(_keyCurrency) ?? '\$',
      hasCompletedOnboarding: prefs.getBool(_keyOnboarding) ?? true,
      isPasscodeEnabled: prefs.getBool(_keyPasscodeEnabled) ?? false,
      passcode: prefs.getString(_keyPasscode) ?? '',
      isLoaded: true,
    );
  }

  Future<void> updateUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, name);
    state = state.copyWith(userName: name);
  }

  Future<void> updateCurrency(String symbol) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrency, symbol);
    state = state.copyWith(currencySymbol: symbol);
  }


  Future<void> setPasscode(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hashed = sha256.convert(utf8.encode(code)).toString();
      await prefs.setString(_keyPasscode, hashed);
      await prefs.setBool(_keyPasscodeEnabled, true);
      state = state.copyWith(passcode: hashed, isPasscodeEnabled: true);
    } catch (e) {
      // Log error internally if needed
    }
  }

  bool verifyPasscode(String code) {
    if (state.passcode.isEmpty) return false;
    
    final hashedInput = sha256.convert(utf8.encode(code)).toString();
    
    // Handing legacy plain-text passcodes (length 4) for migration
    if (state.passcode.length == 4) {
      if (state.passcode == code) {
        setPasscode(code); // Migrate to hash on success
        return true;
      }
    }
    
    return hashedInput == state.passcode;
  }

  Future<void> disablePasscode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPasscodeEnabled, false);
    state = state.copyWith(isPasscodeEnabled: false);
  }
}

final preferencesProvider = NotifierProvider<PreferencesNotifier, UserPreferences>(() {
  return PreferencesNotifier();
});
