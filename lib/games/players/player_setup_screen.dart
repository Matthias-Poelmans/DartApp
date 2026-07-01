import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/colors.dart';
import '../../app/fonts.dart';
import '../game.dart';
import 'player_avatar.dart';
import 'player_roster.dart';

/// The shared pre-game screen that every game passes through before it starts.
///
/// It shows the selected [game]'s title, the list of players (auto-filled from
/// the cached roster), a button to add more players, and a Play button that is
/// only enabled once the player count is within the game's allowed range.
/// Pressing Play caches the roster and opens the pre-game intro.
class PlayerSetupScreen extends StatefulWidget {
  const PlayerSetupScreen({super.key, required this.game});

  final GameDefinition game;

  @override
  State<PlayerSetupScreen> createState() => _PlayerSetupScreenState();
}

class _PlayerSetupScreenState extends State<PlayerSetupScreen> {
  final _listKey = GlobalKey<AnimatedListState>();
  static const Duration _insertDuration = Duration(milliseconds: 300);
  static const Duration _removeDuration = Duration(milliseconds: 350);

  List<String>? _players; // null while loading from storage.

  @override
  void initState() {
    super.initState();
    _loadRoster();
  }

  Future<void> _loadRoster() async {
    final saved = await PlayerRoster.load();
    if (mounted) setState(() => _players = saved);
  }

  Future<void> _addPlayer() async {
    HapticFeedback.mediumImpact();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _AddPlayerDialog(),
    );
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return;
    _players!.add(trimmed);
    _listKey.currentState?.insertItem(
      _players!.length - 1,
      duration: _insertDuration,
    );
    setState(() {}); // refresh count / hint / Play state
  }

  void _removePlayer(int index) {
    final removed = _players!.removeAt(index);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _RemovingTile(name: removed, animation: animation),
      duration: _removeDuration,
    );
    setState(() {}); // refresh count / hint / Play state
  }

  Future<void> _play() async {
    final players = List<String>.from(_players!);
    await PlayerRoster.save(players);
    if (mounted) {
      context.push('${widget.game.route}/intro', extra: players);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final game = widget.game;
    final players = _players;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          game.title,
          style: const TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 20,
            letterSpacing: 0.5,
            color: AppColors.softWhite,
          ),
        ),
      ),
      body: players == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          'Players',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontFamily: AppFonts.display,
                            letterSpacing: 0.5,
                            color: AppColors.blue,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${players.length}/${game.maxPlayers}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontFamily: AppFonts.display,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        if (players.isEmpty)
                          _EmptyPlayers(minPlayers: game.minPlayers),
                        AnimatedList(
                          key: _listKey,
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                          initialItemCount: players.length,
                          itemBuilder: (context, index, animation) => _PlayerTile(
                            name: players[index],
                            animation: animation,
                            onRemove: () => _removePlayer(index),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                    child: _PressBounce(
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: players.length < game.maxPlayers
                              ? _addPlayer
                              : null,
                          icon: const Icon(Icons.add),
                          label: const Text('Add player'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.yellow,
                            foregroundColor: AppColors.ink,
                            disabledBackgroundColor:
                                AppColors.yellow.withValues(alpha: 0.4),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  _PlayBar(
                    canPlay: players.length >= game.minPlayers &&
                        players.length <= game.maxPlayers,
                    hint: _hint(players.length, game),
                    onPlay: _play,
                  ),
                ],
              ),
            ),
    );
  }

  String _hint(int count, GameDefinition game) {
    if (count < game.minPlayers) {
      final needed = game.minPlayers - count;
      return 'Add $needed more — ${game.minPlayers}–${game.maxPlayers} players needed.';
    }
    if (count > game.maxPlayers) {
      return 'Too many — max ${game.maxPlayers} players.';
    }
    return 'Ready to play with $count players.';
  }
}

/// A single player row (person avatar + dart accent, name, remove button),
/// wrapped in the AnimatedList insert transition.
class _PlayerTile extends StatelessWidget {
  const _PlayerTile({
    required this.name,
    required this.animation,
    required this.onRemove,
  });

  final String name;
  final Animation<double> animation;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const PlayerAvatar(radius: 22),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      name,
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close,
                        color: theme.colorScheme.onSurfaceVariant),
                    tooltip: 'Remove player',
                    onPressed: onRemove,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The red "being removed" tile shown during the AnimatedList exit animation:
/// the row fades and slides off to the right (the list closes underneath it).
class _RemovingTile extends StatelessWidget {
  const _RemovingTile({required this.name, required this.animation});

  final String name;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // animation runs 1 -> 0 during removal: in place & opaque at the start,
    // shifted right & transparent at the end.
    final slide = Tween<Offset>(
      begin: const Offset(1.1, 0),
      end: Offset.zero,
    ).animate(animation);

    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: slide,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              margin: EdgeInsets.zero,
              color: const Color(0xFFC0392B), // delete red
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const PlayerAvatar(radius: 22),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        name,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 48), // balances the removed ✕ button
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyPlayers extends StatelessWidget {
  const _EmptyPlayers({required this.minPlayers});

  final int minPlayers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.group_add, size: 64, color: AppColors.blue),
            const SizedBox(height: 12),
            Text(
              'No players yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: AppFonts.display,
                letterSpacing: 0.5,
                color: AppColors.blue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Tap “Add player” to add at least $minPlayers.',
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

/// The sticky bottom bar: a hint line and the Play button.
class _PlayBar extends StatelessWidget {
  const _PlayBar({
    required this.canPlay,
    required this.hint,
    required this.onPlay,
  });

  final bool canPlay;
  final String hint;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            hint,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: canPlay ? onPlay : null,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Play'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: AppColors.softWhite,
                disabledBackgroundColor: AppColors.blue.withValues(alpha: 0.35),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Wraps a tappable child and gives it a quick scale "bounce" while pressed,
/// for a more distinct press response than the default ink splash.
class _PressBounce extends StatefulWidget {
  const _PressBounce({required this.child});

  final Widget child;

  @override
  State<_PressBounce> createState() => _PressBounceState();
}

class _PressBounceState extends State<_PressBounce> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    // Listener reacts to raw pointer events without competing for the child
    // button's tap gesture, so the button's onPressed still fires normally.
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// A dialog with a focused text field (so the keyboard opens immediately) for
/// entering a new player's name.
class _AddPlayerDialog extends StatefulWidget {
  const _AddPlayerDialog();

  @override
  State<_AddPlayerDialog> createState() => _AddPlayerDialogState();
}

class _AddPlayerDialogState extends State<_AddPlayerDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Add player',
        style: TextStyle(
          fontFamily: AppFonts.display,
          fontSize: 18,
          letterSpacing: 0.5,
          color: AppColors.blue,
        ),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(
          labelText: 'Name',
          hintText: 'e.g. Alex',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.blue,
            foregroundColor: AppColors.softWhite,
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
