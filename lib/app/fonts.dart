/// Central definitions for the app's font families.
///
/// Kept alongside [AppColors] so typography, like colour, has a single source
/// of truth. The family name must match the `family:` declared in pubspec.yaml.
class AppFonts {
  AppFonts._();

  /// Display font — used for the app name ("Dartillect") and game titles.
  /// Bundled from `assets/fonts/Bungee-Regular.ttf`.
  static const String display = 'Bungee';
}
