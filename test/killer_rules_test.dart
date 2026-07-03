import 'package:flutter_test/flutter_test.dart';

import 'package:darts_games/games/killer/killer_models.dart';

void main() {
  group('gaining lives (own number, not yet a Killer)', () {
    test('adds up to the cap of 5', () {
      expect(KillerRules.gain(1, 1), 2);
      expect(KillerRules.gain(3, 2), 5);
      expect(KillerRules.gain(2, 3), 5);
    });

    test('bounces back off 5 (docs example: 4 + triple -> 3)', () {
      expect(KillerRules.gain(4, 3), 3);
      expect(KillerRules.gain(4, 2), 4);
    });
  });

  group('damage (attacks / being hit)', () {
    test('subtracts normally', () {
      expect(KillerRules.damage(5, 2), 3);
      expect(KillerRules.damage(3, 3), 0); // exactly zero = death
    });

    test('bounces back off zero (docs examples)', () {
      expect(KillerRules.damage(1, 2), 1);
      expect(KillerRules.damage(1, 3), 2);
    });
  });

  test('a Killer (5 lives) hitting their own number takes damage, never dies', () {
    // A Killer is always at exactly 5 lives, so a self-hit can never reach 0.
    expect(KillerRules.damage(5, 1), 4); // -> 4: no longer a Killer
    expect(KillerRules.damage(5, 2), 3);
    expect(KillerRules.damage(5, 3), 2);
  });

  group('killer status is dynamic (5 lives)', () {
    test('a player is a Killer exactly at 5 lives, and loses it below 5', () {
      final p = KillerPlayer('Sam')..lives = 4;
      expect(p.isKiller, isFalse);
      p.lives = 5;
      expect(p.isKiller, isTrue);
      p.lives = KillerRules.damage(p.lives, 2); // hit for 2 -> 3
      expect(p.lives, 3);
      expect(p.isKiller, isFalse); // reverts to non-Killer
    });
  });

  group('rank titles', () {
    test('map lives to ranks; 5 lives = Killer', () {
      expect(KillerRules.rankTitle(1), 'Recruit');
      expect(KillerRules.rankTitle(2), 'Hunter');
      expect(KillerRules.rankTitle(3), 'Slayer');
      expect(KillerRules.rankTitle(4), 'Predator');
      expect(KillerRules.rankTitle(5), 'Killer');
    });
  });
}
