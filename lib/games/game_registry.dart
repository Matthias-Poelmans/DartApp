import 'game.dart';

/// The list of all darts games available in the app.
///
/// To add a game:
///   1. Create its screen(s) under `lib/games/<id>/`.
///   2. Add a `GameDefinition` entry to this list.
///
/// The home screen and router are both driven by this list, so that's all that's
/// needed — the game then appears on the menu automatically.
///
/// Games are added one at a time as they are specified. The list is intentionally
/// empty for now; the home screen handles the empty state gracefully.
const List<GameDefinition> gameRegistry = <GameDefinition>[
  // Example (kept as a reference, commented out):
  //
  // GameDefinition(
  //   id: 'x01',
  //   title: 'X01 (501 / 301)',
  //   description: 'Count down to exactly zero.',
  //   icon: Icons.exposure_minus_1,
  //   builder: (context) => const X01Screen(),
  // ),
];
