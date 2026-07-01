// Basic smoke test for the Darts Games app.

import 'package:flutter_test/flutter_test.dart';

import 'package:darts_games/main.dart';

void main() {
  testWidgets('Home screen shows the app title', (WidgetTester tester) async {
    await tester.pumpWidget(const DartsGamesApp());
    await tester.pumpAndSettle();

    // The home screen app bar shows the app name.
    expect(find.text('Darts Games'), findsOneWidget);
    // With no games registered yet, the empty state is shown.
    expect(find.text('No games yet'), findsOneWidget);
  });
}
