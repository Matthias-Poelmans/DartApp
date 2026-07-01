import 'package:flutter/material.dart';

import '../../games/game.dart';

/// A single tappable card representing a darts game on the home screen.
class GameCard extends StatelessWidget {
  const GameCard({super.key, required this.game, required this.onTap});

  final GameDefinition game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = game.enabled;

    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Card(
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.18),
                  child: Icon(game.icon, color: theme.colorScheme.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              game.title,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (!enabled)
                            const _Badge(text: 'Coming soon'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        game.description,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _playersLabel(game),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (enabled)
                  Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _playersLabel(GameDefinition game) {
    if (game.minPlayers == game.maxPlayers) {
      return '${game.minPlayers} player${game.minPlayers == 1 ? '' : 's'}';
    }
    return '${game.minPlayers}–${game.maxPlayers} players';
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall
            ?.copyWith(color: theme.colorScheme.secondary),
      ),
    );
  }
}
