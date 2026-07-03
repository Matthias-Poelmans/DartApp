/// The standard dartboard layout and neighbour helpers.
///
/// Shared by any game that needs to reason about the board — e.g. Killer, which
/// resolves duplicate number picks by walking to the nearest free neighbour.
class Dartboard {
  Dartboard._();

  /// The 20 wedge numbers in clockwise order, starting at 20 (top of board).
  static const List<int> clockwise = <int>[
    20, 1, 18, 4, 13, 6, 10, 15, 2, 17, //
    3, 19, 7, 16, 8, 11, 14, 9, 12, 5,
  ];

  /// All 20 wedge numbers (unordered convenience set).
  static Set<int> get allNumbers => clockwise.toSet();

  static const int singleBull = 25;
  static const int doubleBull = 50;

  static int _index(int number) => clockwise.indexOf(number);

  /// The immediate neighbour of [number] in [direction] (+1 clockwise,
  /// -1 counter-clockwise), wrapping around the board.
  static int neighbour(int number, int direction) {
    final n = clockwise.length;
    final i = _index(number);
    return clockwise[((i + direction) % n + n) % n];
  }

  /// The first number not in [taken], walking from [number] in [direction]
  /// (+1 clockwise, -1 counter-clockwise). Returns null only if the board is
  /// completely full.
  static int? firstAvailable(int number, int direction, Set<int> taken) {
    final n = clockwise.length;
    final i = _index(number);
    for (var step = 1; step <= n; step++) {
      final candidate = clockwise[((i + direction * step) % n + n) % n];
      if (!taken.contains(candidate)) return candidate;
    }
    return null;
  }

  /// The candidate numbers offered when a hit number is already [taken]: the
  /// first free number going each way around the board (deduplicated).
  static List<int> alternatives(int number, Set<int> taken) {
    final cw = firstAvailable(number, 1, taken);
    final ccw = firstAvailable(number, -1, taken);
    return <int>{?cw, ?ccw}.toList();
  }
}
