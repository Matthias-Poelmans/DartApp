import 'package:flutter/material.dart';

import 'colors.dart';

/// App-wide theme. A clean, modern light palette built entirely from
/// [AppColors]: deep blue primary, yellow accent, soft-white background.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.blue,
      onPrimary: AppColors.softWhite,
      secondary: AppColors.yellow,
      onSecondary: AppColors.ink,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.inkMuted,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.softWhite,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: AppColors.blue,
        foregroundColor: AppColors.softWhite,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.softWhite,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        color: AppColors.surface,
        elevation: 2,
        shadowColor: AppColors.blue.withValues(alpha: 0.15),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
    );
  }
}
