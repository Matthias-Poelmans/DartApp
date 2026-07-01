import 'package:go_router/go_router.dart';

import '../games/game_registry.dart';
import '../games/players/game_intro_screen.dart';
import '../games/players/player_setup_screen.dart';
import '../home/home_screen.dart';
import '../home/splash_screen.dart';

/// App router. Opens on the splash (`/`), which then moves to the games
/// overview (`/home`). Each registered game gets a route to its player-setup
/// screen, with a nested `play` route for the game itself — so every game
/// runs through the shared setup procedure before it starts. Generated from
/// [gameRegistry], so adding a game requires no router changes.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    for (final game in gameRegistry)
      GoRoute(
        // game.route is an absolute path like `/game/killer`.
        path: game.route,
        builder: (context, state) => PlayerSetupScreen(game: game),
        routes: <RouteBase>[
          GoRoute(
            path: 'intro', // e.g. /game/killer/intro — the pre-game reveal
            builder: (context, state) => GameIntroScreen(
              game: game,
              players: (state.extra as List<String>?) ?? const <String>[],
            ),
          ),
          GoRoute(
            path: 'play', // e.g. /game/killer/play
            builder: (context, state) => game.builder(context),
          ),
        ],
      ),
  ],
);
