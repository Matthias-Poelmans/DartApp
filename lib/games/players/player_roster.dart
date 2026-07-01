import 'package:shared_preferences/shared_preferences.dart';

/// Persists the list of player names between games so the setup screen can
/// auto-fill them next time — the user sets their players once and every
/// subsequent game starts with the same roster.
///
/// Stored locally on the device via [SharedPreferences]; nothing leaves the
/// phone, so the app stays fully offline.
class PlayerRoster {
  PlayerRoster._();

  static const String _key = 'player_roster';

  /// Loads the last-used player names, or an empty list if none were saved.
  static Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? <String>[];
  }

  /// Saves [names] as the current roster, replacing any previous value.
  static Future<void> save(List<String> names) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, names);
  }
}
