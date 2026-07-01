import 'package:go_router/go_router.dart';

import '../games/game_registry.dart';
import '../home/home_screen.dart';

/// App router. The home route plus one route per registered game, generated
/// from [gameRegistry] so adding a game requires no router changes.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
      routes: <RouteBase>[
        for (final game in gameRegistry)
          GoRoute(
            path: 'game/${game.id}',
            builder: (context, state) => game.builder(context),
          ),
      ],
    ),
  ],
);
