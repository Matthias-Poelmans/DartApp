// Tests for the shared player-setup screen: roster caching and the
// minimum/maximum player rule that gates the Play button.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:darts_games/games/game.dart';
import 'package:darts_games/games/players/player_setup_screen.dart';

GameDefinition _testGame() => GameDefinition(
      id: 'killer',
      title: 'Killer',
      description: 'test',
      icon: Icons.sports_martial_arts,
      minPlayers: 3,
      maxPlayers: 8,
      builder: (_) => const SizedBox.shrink(),
    );

Finder _playButton() => find.widgetWithText(FilledButton, 'Play');

void main() {
  testWidgets('cached roster auto-fills and enables Play at 3+ players',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'player_roster': <String>['Alex', 'Sam', 'Jo'],
    });

    await tester.pumpWidget(
      MaterialApp(home: PlayerSetupScreen(game: _testGame())),
    );
    await tester.pumpAndSettle();

    // The three cached players are shown.
    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('Sam'), findsOneWidget);
    expect(find.text('Jo'), findsOneWidget);

    // With 3 players, Play is enabled.
    final playButton = tester.widget<FilledButton>(_playButton());
    expect(playButton.onPressed, isNotNull);
  });

  testWidgets('Play is disabled with fewer than the minimum players',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'player_roster': <String>['Alex', 'Sam'],
    });

    await tester.pumpWidget(
      MaterialApp(home: PlayerSetupScreen(game: _testGame())),
    );
    await tester.pumpAndSettle();

    final playButton = tester.widget<FilledButton>(_playButton());
    expect(playButton.onPressed, isNull);
  });

  testWidgets('adding a player via the dialog updates the list',
      (tester) async {
    SharedPreferences.setMockInitialValues({'player_roster': <String>[]});

    await tester.pumpWidget(
      MaterialApp(home: PlayerSetupScreen(game: _testGame())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Add player'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Robin');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.text('Robin'), findsOneWidget);
  });
}
