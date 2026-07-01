import 'package:flutter/painting.dart';

/// The single source of truth for the app's colour palette.
///
/// Every colour used anywhere in the app is defined here and referenced by name,
/// so there are no scattered hex codes. Change a value here and it updates
/// everywhere the corresponding constant is used.
class AppColors {
  AppColors._();

  /// Primary brand colour: app bar, titles, primary buttons, chevrons.
  static const Color blue = Color(0xFF1B4965);

  /// Accent colour: game icon badges and highlights.
  static const Color yellow = Color(0xFFFFC857);

  /// Scaffold background — a soft, warm off-white (not a harsh pure white).
  static const Color softWhite = Color(0xFFF5F3EE);

  /// Card / surface colour, lifted slightly above the soft-white background.
  static const Color surface = Color(0xFFFFFFFF);

  /// Primary text colour — a dark blue-black "ink".
  static const Color ink = Color(0xFF14202B);

  /// Secondary / muted text colour.
  static const Color inkMuted = Color(0xFF5A6B78);
}
