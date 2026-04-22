import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors - NEW Magenta Theme
  static const Color primaryColor = Color(0xFFE2136E); 
  static const Color secondaryColor = Color(0xFF10B981); // Keep Emerald for stability
  static const Color accentColor = Color(0xFFFB7185); // Lighter pink
  
  // Neutral Colors - Dark
  static const Color backgroundColor = Color(0xFF0F172A); 
  static const Color surfaceColor = Color(0xFF1E293B); 
  static const Color surfaceVariant = Color(0xFF334155); 
  
  // Neutral Colors - Light
  static const Color lightBgColor = Color(0xFFF8FAFC);
  static const Color lightSurfaceColor = Colors.white;
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9);

  // Error Colors
  static const Color errorColor = Color(0xFFF43F5E); 

  static List<BoxShadow> get premiumShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  static LinearGradient get primaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, Color(0xFFF43F5E)],
  );

  static LinearGradient get darkGlassGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withValues(alpha: 0.1),
      Colors.white.withValues(alpha: 0.02),
    ],
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        surfaceContainer: surfaceVariant,
        error: errorColor,
        onPrimary: Colors.white,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: primaryColor.withValues(alpha: 0.1),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        height: 70,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryColor);
          }
          return const IconThemeData(color: Colors.grey);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: lightBgColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: lightSurfaceColor,
        surfaceContainer: lightSurfaceVariant,
        error: errorColor,
        onPrimary: Colors.white,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: lightSurfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
      ),
    );
  }
}
