import 'package:flutter/material.dart';

import '../../app/colors.dart';

/// A player's avatar: a blue person icon with a small yellow dart accent.
///
/// Shared by the player-setup list and the pre-game intro so a player looks
/// the same everywhere. (Material has no dart glyph, so a target/crosshair mark
/// stands in as the closest darts-themed accent.)
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({super.key, this.radius = 22});

  final double radius;

  @override
  Widget build(BuildContext context) {
    final accent = radius * 0.6;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.blue,
          child: Icon(Icons.person, color: AppColors.softWhite, size: radius * 1.1),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.gps_fixed, size: accent, color: AppColors.yellow),
          ),
        ),
      ],
    );
  }
}
