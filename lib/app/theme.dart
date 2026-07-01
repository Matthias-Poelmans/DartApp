import 'package:flutter/material.dart';

/// App-wide theme. Dark, dartboard-inspired palette (green + red accents on a
/// near-black background).
class AppTheme {
  AppTheme._();

  // Dartboard colours.
  static const Color dartGreen = Color(0xFF1B7A3D);
  static const Color dartRed = Color(0xFFC0392B);
  static const Color cream = Color(0xFFF5E9C9);

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: dartGreen,
      brightness: Brightness.dark,
    ).copyWith(
      secondary: dartRed,
      surface: const Color(0xFF14161A),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0E0F12),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
