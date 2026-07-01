// Basic smoke test for the Dartillect app.

import 'package:flutter_test/flutter_test.dart';

import 'package:darts_games/main.dart';
import 'package:darts_games/home/splash_screen.dart';

void main() {
  testWidgets('Splash gives way to the games overview',
      (WidgetTester tester) async {
    await tester.pumpWidget(const DartsGamesApp());

    // Advance past the splash so it navigates to the home screen.
    await tester.pump(SplashScreen.duration + const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // The home screen app bar shows the app name.
    expect(find.text('Dartillect'), findsOneWidget);
    // The registered placeholder games appear on the menu.
    expect(find.text('Killer'), findsOneWidget);
    expect(find.text('Halve It'), findsOneWidget);
    expect(find.text('Tag Team'), findsOneWidget);
  });
}
