import 'package:flutter/material.dart';

class AppTheme {
  // Dark Theme Colors
  static const darkColors = {
    'primary': Color(0xFF1F1F1F),
    'secondary': Color(0xFF2D2D2D),
    'accent': Color(0xFF007AFF),
    'text': Colors.white,
    'textSecondary': Color(0xFFB3B3B3),
    'surface': Color(0xFF2D2D2D),
    'background': Color(0xFF121212),
    'error': Color(0xFFCF6679),
  };

  // Gradients
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1F1F1F),
      Color(0xFF2D2D2D),
    ],
  );

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF007AFF),
      Color(0xFF00C6FF),
    ],
  );

  // Theme Data
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      primaryColor: darkColors['primary'],
      scaffoldBackgroundColor: darkColors['background'],
      textTheme: const TextTheme().apply(
        fontFamily: 'Poppins',
        bodyColor: darkColors['text'],
        displayColor: darkColors['text'],
      ),
      colorScheme: ColorScheme.dark(
        primary: darkColors['primary']!,
        secondary: darkColors['accent']!,
        surface: darkColors['surface']!,
        error: darkColors['error']!,
      ),
      cardTheme: CardTheme(
        color: darkColors['secondary'],
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkColors['secondary'],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: darkColors['accent']!,
            width: 2,
          ),
        ),
        labelStyle: TextStyle(color: darkColors['textSecondary']),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkColors['accent'],
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkColors['primary'],
        selectedItemColor: darkColors['accent'],
        unselectedItemColor: darkColors['textSecondary'],
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkColors['primary'],
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  // Animation Durations
  static const Duration quickDuration = Duration(milliseconds: 200);
  static const Duration normalDuration = Duration(milliseconds: 300);
  static const Duration slowDuration = Duration(milliseconds: 500);
}
