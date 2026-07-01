import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/colors.dart';
import '../../app/fonts.dart';
import '../game.dart';
import 'player_avatar.dart';

/// The pre-game "reveal": a full yellow screen with the game title in blue,
/// where each player pops up one by one — strictly below the title and never
/// overlapping another player. Once everyone is in, it holds briefly and then
/// continues to the game itself.
class GameIntroScreen extends StatefulWidget {
  const GameIntroScreen({super.key, required this.game, required this.players});

  final GameDefinition game;
  final List<String> players;

  /// Delay between each player popping in.
  static const Duration popInterval = Duration(milliseconds: 550);

  /// Pause after the last player before the Play button appears.
  static const Duration pauseBeforePlay = Duration(milliseconds: 450);

  @override
  State<GameIntroScreen> createState() => _GameIntroScreenState();
}

class _GameIntroScreenState extends State<GameIntroScreen> {
  final _random = Random();

  /// A shuffled grid cell (column, row) per player, so positions look random
  /// but two players can never share a spot.
  late final List<Point<int>> _cells;
  late final int _cols;
  late final int _rows;

  int _revealedCount = 0;
  bool _ready = false; // all players shown; Play button is available.

  @override
  void initState() {
    super.initState();
    _assignCells(widget.players.length);
    _run();
  }

  void _assignCells(int count) {
    // A couple of columns keeps the pills wide enough for names; rows grow to
    // fit however many players there are.
    _cols = count <= 3 ? 1 : 2;
    _rows = count == 0 ? 0 : (count / _cols).ceil();
    final all = <Point<int>>[
      for (var r = 0; r < _rows; r++)
        for (var c = 0; c < _cols; c++) Point<int>(c, r),
    ]..shuffle(_random);
    _cells = all.take(count).toList();
  }

  Future<void> _run() async {
    for (var i = 0; i < widget.players.length; i++) {
      await Future.delayed(GameIntroScreen.popInterval);
      if (!mounted) return;
      setState(() => _revealedCount = i + 1);
    }
    await Future.delayed(GameIntroScreen.pauseBeforePlay);
    if (mounted) setState(() => _ready = true);
  }

  void _start() => context.pushReplacement('${widget.game.route}/play');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.yellow,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 72, bottom: 12),
              child: Text(
                widget.game.title,
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 40,
                  letterSpacing: 1,
                  color: AppColors.blue,
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (_rows == 0 || _cols == 0) return const SizedBox.shrink();
                  final cellW = constraints.maxWidth / _cols;
                  final cellH = constraints.maxHeight / _rows;
                  return Stack(
                    children: [
                      for (var i = 0; i < _revealedCount; i++)
                        Positioned(
                          left: _cells[i].x * cellW,
                          top: _cells[i].y * cellH,
                          width: cellW,
                          height: cellH,
                          child: Padding(
                            // Margin so pills never touch cell edges/neighbours.
                            padding: const EdgeInsets.all(10),
                            child: Center(
                              child: _PopIn(
                                child: _PlayerPill(name: widget.players[i]),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            // Reserve space so the players area doesn't jump when Play appears.
            SizedBox(
              height: 108,
              child: Center(
                child: _ready
                    ? _PopIn(child: _PulsingPlayButton(onPressed: _start))
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Play button shown once everyone is in: blue, pulsing to a brighter
/// white with a soft glow to signal it's ready to press.
class _PulsingPlayButton extends StatefulWidget {
  const _PulsingPlayButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_PulsingPlayButton> createState() => _PulsingPlayButtonState();
}

class _PulsingPlayButtonState extends State<_PulsingPlayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller.value);
        final background = Color.lerp(AppColors.blue, Colors.white, t)!;
        final foreground = Color.lerp(Colors.white, AppColors.blue, t)!;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.7 * t),
                blurRadius: 18 * t,
                spreadRadius: 1 * t,
              ),
            ],
          ),
          child: FilledButton.icon(
            onPressed: widget.onPressed,
            icon: Icon(Icons.play_arrow, color: foreground),
            label: Text(
              'Play',
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: background,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Scales + fades its child in with a little bounce when first built.
class _PopIn extends StatelessWidget {
  const _PopIn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.elasticOut,
      builder: (context, value, child) => Transform.scale(
        scale: value,
        child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
      ),
      child: child,
    );
  }
}

/// A white pill showing a player's avatar and name.
class _PlayerPill extends StatelessWidget {
  const _PlayerPill({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PlayerAvatar(radius: 18),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
