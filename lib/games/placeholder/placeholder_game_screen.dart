import 'package:flutter/material.dart';

import '../../app/colors.dart';
import '../../app/fonts.dart';

/// A simple themed placeholder shown for games that appear on the menu but
/// whose scoring isn't built yet (e.g. Killer, Halve It, Tag Team).
///
/// Reused by every placeholder [GameDefinition] — pass the game's [title].
class PlaceholderGameScreen extends StatelessWidget {
  const PlaceholderGameScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: AppColors.yellow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.track_changes,
                    size: 48,
                    color: AppColors.blue,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontFamily: AppFonts.display,
                    color: AppColors.blue,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  "Coming soon — scoring for this game isn't built yet.",
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
