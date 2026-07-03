import 'package:flutter/material.dart';

import 'game.dart';
import 'killer/killer_game_screen.dart';
import 'placeholder/placeholder_game_screen.dart';

/// The list of all darts games available in the app.
///
/// To add a game:
///   1. Create its screen(s) under `lib/games/<id>/`.
///   2. Add a `GameDefinition` entry to this list.
///
/// The home screen and router are both driven by this list, so that's all that's
/// needed — the game then appears on the menu automatically.
///
/// The entries below are placeholders: they show on the menu and open a themed
/// "coming soon" screen, but their scoring isn't implemented yet.
final List<GameDefinition> gameRegistry = <GameDefinition>[
  GameDefinition(
    id: 'killer',
    title: 'Killer',
    description: 'Claim a number, become a killer, knock others out.',
    icon: Icons.sports_martial_arts,
    minPlayers: 3,
    maxPlayers: 8,
    builder: (context) => const KillerGameScreen(),
  ),
  GameDefinition(
    id: 'halve_it',
    title: 'Halve It',
    description: 'Hit the target each round or halve your score.',
    icon: Icons.cut,
    minPlayers: 3,
    maxPlayers: 8,
    builder: (context) => const PlaceholderGameScreen(title: 'Halve It'),
  ),
  GameDefinition(
    id: 'tag_team',
    title: 'Tag Team',
    description: 'Play in teams, tag your partner between throws.',
    icon: Icons.groups,
    minPlayers: 3,
    maxPlayers: 8,
    builder: (context) => const PlaceholderGameScreen(title: 'Tag Team'),
  ),
];
