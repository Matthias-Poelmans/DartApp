/// Data model and pure rule math for the Killer game.
///
/// The rules (lives, ranks, bouncing off the 5-life cap and the 0-life floor,
/// being a Killer) live here as side-effect-free functions so they can be
/// unit-tested independently of the UI. See docs/game-explanations/killer.md.
library;

/// A dart's multiplier and the number of lives it moves.
enum Multiplier {
  single(1, 'S'),
  double(2, 'D'),
  triple(3, 'T');

  const Multiplier(this.factor, this.short);

  /// Lives added or removed by a hit at this multiplier.
  final int factor;

  /// Short label, e.g. "T" for triple.
  final String short;

  String get label => switch (this) {
        Multiplier.single => 'Single',
        Multiplier.double => 'Double',
        Multiplier.triple => 'Triple',
      };
}

/// A single player in a Killer match.
class KillerPlayer {
  KillerPlayer(this.name);

  final String name;

  /// The player's assigned dartboard number (null until assigned).
  int? number;

  /// Current lives (0 = dead). Everyone starts at 1.
  int lives = 1;

  /// Whether the player is currently a Killer. This is **dynamic**: a player is
  /// a Killer exactly while they hold the maximum of 5 lives. If a Killer is
  /// later hit and drops below 5, they stop being a Killer and go back to
  /// gaining lives on their own number. This keeps the scoring rules identical
  /// in both states — the only switch is whether lives are at the 5 cap.
  bool get isKiller => lives >= KillerRules.maxLives;

  /// Whether the player is still in the game.
  bool alive = true;

  /// The rank shown for the player's current state.
  String get rankTitle => KillerRules.rankTitle(lives);
}

/// Side-effect-free Killer rule math.
class KillerRules {
  KillerRules._();

  static const int maxLives = 5;

  /// Rank name for a given life total. 5 lives = Killer.
  static String rankTitle(int lives) => switch (lives) {
        <= 1 => 'Recruit',
        2 => 'Hunter',
        3 => 'Slayer',
        4 => 'Predator',
        _ => 'Killer', // 5
      };

  /// Lives after gaining [amount] on your own number (while not a Killer).
  /// Bounces back off the 5-life cap: e.g. 4 + 3 -> 3. Landing on exactly 5
  /// makes the player a Killer.
  static int gain(int lives, int amount) {
    final total = lives + amount;
    if (total <= maxLives) return total;
    return maxLives - (total - maxLives);
  }

  /// Lives after taking [amount] damage. Below zero bounces back off 0:
  /// e.g. 1 - 2 -> 1, 1 - 3 -> 2. A result of exactly 0 means death.
  ///
  /// A Killer always sits at exactly 5 lives, so a self-hit (5 - 1/2/3) can
  /// never reach 0 — hence there is no separate "self damage" rule any more:
  /// self-hits and attacks both use this single, consistent function.
  static int damage(int lives, int amount) {
    final result = lives - amount;
    return result >= 0 ? result : -result;
  }
}
