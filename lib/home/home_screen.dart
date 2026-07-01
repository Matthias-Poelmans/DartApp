import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../games/game_registry.dart';
import 'widgets/game_card.dart';

/// The home screen: a menu of available darts games, rendered from
/// [gameRegistry]. Games are added one at a time to that list.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Darts Games'),
      ),
      body: SafeArea(
        child: gameRegistry.isEmpty
            ? const _EmptyState()
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: gameRegistry.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final game = gameRegistry[index];
                  return GameCard(
                    game: game,
                    onTap: () => context.go(game.route),
                  );
                },
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_score, size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'No games yet',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Games will appear here as they are added.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
