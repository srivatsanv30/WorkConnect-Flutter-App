import 'package:flutter/material.dart';

/// A calm healthcare-friendly palette with teal/blue gradients,
/// soft surfaces, and modern field/button treatments.
class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF0F88C6);
  static const Color primaryDark = Color(0xFF0A6A97);
  static const Color secondary = Color(0xFF26B6C1);
  static const Color background = Color(0xFFF3F8FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFD7E7F3);

  static const LinearGradient logoGradient = LinearGradient(
    colors: [Color(0xFF39BCF3), Color(0xFF0D77B4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFFE8F4FF), Color(0xFFF5FAFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        secondary: secondary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 6,
        color: surface,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: cardBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFEFF6FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: primary.withAlpha(217), width: 1.5),
        ),
        hintStyle: const TextStyle(color: Colors.black45, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
      ),
      textTheme: ThemeData.light().textTheme.apply(
            bodyColor: Colors.black87,
            displayColor: Colors.black87,
          ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: primary.withAlpha(56)),
          foregroundColor: primaryDark,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: Colors.black45,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
    );
  }
}
