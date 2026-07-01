import 'package:go_router/go_router.dart';

import '../games/game_registry.dart';
import '../home/home_screen.dart';
import '../home/splash_screen.dart';

/// App router. Opens on the splash (`/`), which then moves to the games
/// overview (`/home`). One route per registered game is generated from
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
        builder: (context, state) => game.builder(context),
      ),
  ],
);
