import 'package:flutter/material.dart';

class AppTheme {
  static const Color darkBg = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color gold = Color(0xFFD4AF37);
  static const Color white = Colors.white;
  static const Color textMuted = Color(0xFF9E9E9E);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      primaryColor: gold,
      colorScheme: const ColorScheme.dark(primary: gold, surface: surfaceDark),
      fontFamily: 'Cairo',
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: gold,
        ),
      ),
    );
  }
}
