import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/colors.dart';
import '../app/fonts.dart';
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
        title: const Text(
          'Dartillect',
          style: TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 22,
            letterSpacing: 1,
            color: AppColors.softWhite,
          ),
        ),
      ),
      body: SafeArea(
        child: gameRegistry.isEmpty
            ? const _EmptyState()
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                itemCount: gameRegistry.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  if (index == 0) return const _Header();
                  final game = gameRegistry[index - 1];
                  return GameCard(
                    game: game,
                    onTap: () => context.push(game.route),
                  );
                },
              ),
      ),
    );
  }
}

/// A short blue heading shown above the list of games.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        'Choose a game',
        style: theme.textTheme.headlineSmall?.copyWith(
          fontFamily: AppFonts.display,
          letterSpacing: 0.5,
          color: AppColors.blue,
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
