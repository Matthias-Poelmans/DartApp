import 'package:flutter/widgets.dart';

/// Describes a single darts game mode shown on the home screen.
///
/// This is the **single extension point** for adding a game: create the game's
/// screen(s) under `lib/games/<id>/`, then append one [GameDefinition] to the
/// list in `game_registry.dart`. The home screen renders itself from that list,
/// so no other file needs to change.
@immutable
class GameDefinition {
  const GameDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.builder,
    this.minPlayers = 1,
    this.maxPlayers = 8,
    this.enabled = true,
  });

  /// Stable identifier, also used as the route path segment (e.g. `x01`).
  final String id;

  /// Display name shown on the game card.
  final String title;

  /// Short one-line explanation shown under the title.
  final String description;

  /// Icon shown on the game card.
  final IconData icon;

  /// Builds the game's entry screen. Called when the card is tapped.
  final WidgetBuilder builder;

  /// Minimum / maximum number of local players this game supports.
  final int minPlayers;
  final int maxPlayers;

  /// When false, the card is shown but greyed out and not tappable
  /// (useful for "coming soon" placeholders).
  final bool enabled;

  /// The go_router path for this game.
  String get route => '/game/$id';
}
