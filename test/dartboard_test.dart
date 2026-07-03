import 'package:flutter_test/flutter_test.dart';

import 'package:darts_games/games/dartboard.dart';

void main() {
  test('board has the 20 numbers once each in the standard order', () {
    expect(Dartboard.clockwise.length, 20);
    expect(Dartboard.clockwise.toSet().length, 20);
    expect(Dartboard.clockwise.first, 20);
    // 20's neighbours on a real board are 1 (cw) and 5 (ccw).
    expect(Dartboard.neighbour(20, 1), 1);
    expect(Dartboard.neighbour(20, -1), 5);
  });

  test('alternatives to a taken number are the nearest free each way', () {
    // From the docs example: 20 taken -> neighbours 1 and 5.
    expect(Dartboard.alternatives(20, {20}).toSet(), {1, 5});
  });

  test('walks past taken neighbours to the next free number', () {
    // 20 and 1 taken: clockwise from 20 skips 1 to 18; ccw gives 5.
    expect(Dartboard.alternatives(20, {20, 1}).toSet(), {18, 5});
  });

  test('firstAvailable returns null when the board is full', () {
    final full = Dartboard.allNumbers;
    expect(Dartboard.firstAvailable(20, 1, full), isNull);
  });
}
