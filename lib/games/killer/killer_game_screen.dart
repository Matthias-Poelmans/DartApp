import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/colors.dart';
import '../../app/fonts.dart';
import '../dartboard.dart';
import '../players/player_roster.dart';
import 'killer_models.dart';

/// The phases a Killer match moves through.
enum _Phase { loading, assigning, resolving, playing, finished }

/// The full Killer game. Loads the cached roster, runs the number-assignment
/// round, resolves Bull/missed players, then plays the main game turn by turn.
///
/// Rules: docs/game-explanations/killer.md. Rule math lives in [KillerRules];
/// board geometry (neighbours) in [Dartboard].
class KillerGameScreen extends StatefulWidget {
  const KillerGameScreen({super.key});

  @override
  State<KillerGameScreen> createState() => _KillerGameScreenState();
}

class _KillerGameScreenState extends State<KillerGameScreen> {
  /// Brief pause after the 3rd dart so the completed turn registers before the
  /// next player appears. Kept short so it feels snappy, not like loading.
  static const Duration _autoAdvanceDelay = Duration(milliseconds: 300);

  final _random = Random();

  _Phase _phase = _Phase.loading;

  /// All players, in roster (throwing) order.
  List<KillerPlayer> _players = [];

  // --- Assignment phase state ---
  int _assignPos = 0; // index into _players currently throwing for a number
  int _missAttempts = 0; // misses by the current assigning player (max 3)
  final List<KillerPlayer> _pendingBull = []; // hit Bull, choose later
  final List<KillerPlayer> _pendingFailed = []; // missed 3x, assigned last

  // --- Resolution phase state ---
  List<KillerPlayer> _resolveQueue = [];
  int _resolvePos = 0;

  // --- Playing phase state ---
  List<KillerPlayer> _turnOrder = []; // sorted by assigned number ascending
  int _turnIndex = 0;
  final List<_Dart> _turnDarts = []; // darts thrown so far this turn (max 3)
  final List<_Snapshot> _undo = []; // one snapshot per dart, for undo
  Multiplier _multiplier = Multiplier.single;

  /// State captured at the start of the current turn, so a completed turn can
  /// be pushed to [_history] and later restored via "Previous player".
  _Snapshot? _turnStartSnapshot;

  /// Completed turns, newest last, for stepping back to a previous player.
  final List<_TurnRecord> _history = [];

  /// Guards the delayed auto-advance against undo / back / manual advance.
  int _turnToken = 0;

  KillerPlayer? _winner;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final names = await PlayerRoster.load();
    if (!mounted) return;
    setState(() {
      _players = names.map(KillerPlayer.new).toList();
      _phase = _Phase.assigning;
    });
  }

  // ---------------------------------------------------------------------------
  // Assignment phase
  // ---------------------------------------------------------------------------

  Set<int> get _takenNumbers =>
      _players.map((p) => p.number).whereType<int>().toSet();

  KillerPlayer get _assigningPlayer => _players[_assignPos];

  void _assignNumberToCurrent(int number) {
    setState(() {
      _assigningPlayer.number = number;
      _advanceAssignment();
    });
  }

  void _onAssignNumber(int number) {
    final taken = _takenNumbers;
    if (!taken.contains(number)) {
      _assignNumberToCurrent(number);
      return;
    }
    final alts = Dartboard.alternatives(number, taken);
    if (alts.isEmpty) return; // board full (impossible with < 20 players)
    if (alts.length == 1) {
      _assignNumberToCurrent(alts.first);
    } else {
      _pickAlternative(number, alts);
    }
  }

  Future<void> _pickAlternative(int hit, List<int> alts) async {
    final chosen = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$hit is taken', style: _dialogTitleStyle),
        content: const Text('Pick the nearest free number to take instead:'),
        actions: [
          for (final n in alts)
            FilledButton(
              onPressed: () => Navigator.of(context).pop(n),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: AppColors.softWhite,
              ),
              child: Text('$n'),
            ),
        ],
      ),
    );
    if (chosen != null) _assignNumberToCurrent(chosen);
  }

  void _onAssignBull() {
    setState(() {
      _pendingBull.add(_assigningPlayer);
      _advanceAssignment();
    });
  }

  void _onAssignMiss() {
    setState(() {
      _missAttempts++;
      if (_missAttempts >= 3) {
        _pendingFailed.add(_assigningPlayer);
        _advanceAssignment();
      }
    });
  }

  /// Moves to the next player who still needs a number, or into resolution.
  void _advanceAssignment() {
    _missAttempts = 0;
    _assignPos++;
    if (_assignPos >= _players.length) {
      _buildResolveQueue();
    }
  }

  void _buildResolveQueue() {
    // Bull players choose first (random order), then failed players.
    final bull = [..._pendingBull]..shuffle(_random);
    _resolveQueue = [...bull, ..._pendingFailed];
    _resolvePos = 0;
    if (_resolveQueue.isEmpty) {
      _startGame();
    } else {
      _phase = _Phase.resolving;
    }
  }

  // ---------------------------------------------------------------------------
  // Resolution phase (Bull / missed players pick a remaining number)
  // ---------------------------------------------------------------------------

  KillerPlayer get _resolvingPlayer => _resolveQueue[_resolvePos];

  List<int> get _remainingNumbers {
    final taken = _takenNumbers;
    return Dartboard.clockwise.where((n) => !taken.contains(n)).toList()..sort();
  }

  void _assignResolveNumber(int number) {
    setState(() {
      _resolvingPlayer.number = number;
      _resolvePos++;
      if (_resolvePos >= _resolveQueue.length) {
        _startGame();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Playing phase
  // ---------------------------------------------------------------------------

  void _startGame() {
    _turnOrder = [..._players]..sort((a, b) => a.number!.compareTo(b.number!));
    _turnIndex = 0;
    _turnDarts.clear();
    _undo.clear();
    _history.clear();
    _turnStartSnapshot = _Snapshot.capture(_players);
    _phase = _Phase.playing;
  }

  KillerPlayer get _current => _turnOrder[_turnIndex];

  int get _aliveCount => _players.where((p) => p.alive).length;

  bool get _turnComplete => _turnDarts.length >= 3;

  /// Numbers currently worth aiming at: every alive player's assigned number.
  List<int> get _effectNumbers {
    final nums =
        _players.where((p) => p.alive).map((p) => p.number!).toList()..sort();
    return nums;
  }

  KillerPlayer? _aliveOwnerOf(int number) {
    for (final p in _players) {
      if (p.alive && p.number == number) return p;
    }
    return null;
  }

  void _snapshot() => _undo.add(_Snapshot.capture(_players));

  void _recordDart(String label, String effect) {
    _turnDarts.add(_Dart(label, effect));
    if (_aliveCount <= 1) {
      _winner = _players.firstWhere((p) => p.alive, orElse: () => _current);
      _phase = _Phase.finished;
    }
  }

  /// A numbered hit at [mult]. For a non-Killer this is always their own
  /// number; for a Killer it may be their own number (self-damage) or an
  /// opponent's (attack).
  void _applyNumber(int number, Multiplier mult) {
    if (_turnComplete || _phase != _Phase.playing) return;
    final amount = mult.factor;
    final me = _current;
    setState(() {
      _snapshot();
      String effect;
      if (number == me.number) {
        if (!me.isKiller) {
          me.lives = KillerRules.gain(me.lives, amount);
          effect = me.isKiller ? 'became a Killer!' : 'own +$amount';
        } else {
          me.lives = KillerRules.damage(me.lives, amount);
          effect = 'hit self −$amount';
        }
      } else {
        final owner = _aliveOwnerOf(number);
        if (owner != null && me.isKiller) {
          owner.lives = KillerRules.damage(owner.lives, amount);
          if (owner.lives == 0) owner.alive = false;
          effect = owner.alive
              ? '−$amount ${owner.name}'
              : '${owner.name} out!';
        } else {
          effect = 'no effect';
        }
      }
      _recordDart('${mult.short}$number', effect);
    });
    _maybeAutoAdvance();
  }

  Future<void> _onGameBull(int value) async {
    if (_turnComplete || _phase != _Phase.playing) return;
    final me = _current;
    final label = value == 1 ? 'SB' : 'DB';
    if (!me.isKiller) {
      setState(() {
        _snapshot();
        me.lives = KillerRules.gain(me.lives, value);
        _recordDart(label, me.isKiller ? 'became a Killer!' : 'Bull +$value');
      });
      _maybeAutoAdvance();
      return;
    }
    // Killer: Bull is a joker — remove [value] lives from a chosen player.
    final target =
        await _pickTarget('Remove $value ${value == 1 ? "life" : "lives"} from…');
    if (target == null || !mounted) return;
    setState(() {
      _snapshot();
      target.lives = KillerRules.damage(target.lives, value);
      if (target.lives == 0) target.alive = false;
      _recordDart(
        label,
        target.alive ? '−$value ${target.name}' : '${target.name} out!',
      );
    });
    _maybeAutoAdvance();
  }

  void _onGameMiss() {
    if (_turnComplete || _phase != _Phase.playing) return;
    setState(() {
      _snapshot();
      _recordDart('Miss', '—');
    });
    _maybeAutoAdvance();
  }

  Future<KillerPlayer?> _pickTarget(String prompt) {
    final targets = _players.where((p) => p.alive && p != _current).toList();
    return showDialog<KillerPlayer>(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text(prompt, style: _dialogTitleStyle),
        children: [
          for (final p in targets)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(p),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('${p.name}  (#${p.number}, ${p.lives}♥)'),
              ),
            ),
        ],
      ),
    );
  }

  void _undoLastDart() {
    if (_turnDarts.isEmpty || _undo.isEmpty) return;
    setState(() {
      _turnToken++; // cancel any pending auto-advance
      _undo.removeLast().restore(_players);
      _turnDarts.removeLast();
      if (_phase == _Phase.finished) {
        _phase = _Phase.playing;
        _winner = null;
      }
    });
  }

  /// The single Back control: if any dart has been entered this turn, it erases
  /// the last one; otherwise it steps back to the previous player's turn.
  void _back() {
    if (_turnDarts.isNotEmpty) {
      _undoLastDart();
    } else {
      _previousTurn();
    }
  }

  /// Auto-advances to the next player a short moment after the 3rd dart, so the
  /// completed turn is briefly visible. Cancelled if the turn changes.
  void _maybeAutoAdvance() {
    if (_phase != _Phase.playing || _turnDarts.length < 3) return;
    final token = _turnToken;
    Future.delayed(_autoAdvanceDelay, () {
      if (!mounted || _turnToken != token) return;
      if (_phase != _Phase.playing || _turnDarts.length < 3) return;
      _nextTurn();
    });
  }

  void _nextTurn() {
    setState(() {
      _history.add(_TurnRecord(_turnIndex, _turnStartSnapshot!));
      _turnDarts.clear();
      _undo.clear();
      _multiplier = Multiplier.single;
      _turnToken++;
      for (var i = 0; i < _turnOrder.length; i++) {
        _turnIndex = (_turnIndex + 1) % _turnOrder.length;
        if (_turnOrder[_turnIndex].alive) break;
      }
      _turnStartSnapshot = _Snapshot.capture(_players);
    });
  }

  /// Steps back to the previous player's turn, restoring the game to how it was
  /// when that turn began, so a mis-entered turn can be replayed.
  void _previousTurn() {
    if (_history.isEmpty) return;
    setState(() {
      final record = _history.removeLast();
      record.snapshot.restore(_players);
      _turnIndex = record.index;
      _turnStartSnapshot = _Snapshot.capture(_players);
      _turnDarts.clear();
      _undo.clear();
      _multiplier = Multiplier.single;
      _turnToken++;
      _phase = _Phase.playing;
      _winner = null;
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Killer',
          style: TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 22,
            letterSpacing: 1,
            color: AppColors.softWhite,
          ),
        ),
      ),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    switch (_phase) {
      case _Phase.loading:
        return const Center(child: CircularProgressIndicator());
      case _Phase.finished:
        return _WinnerView(winner: _winner);
      case _Phase.assigning:
      case _Phase.resolving:
      case _Phase.playing:
        // Fixed layout: the scoreboard fills the top and never scrolls; the
        // input board is pinned beneath it.
        return Column(
          children: [
            Expanded(
              child: _PlayerBoard(players: _players, highlight: _highlighted),
            ),
            _inputArea(),
          ],
        );
    }
  }

  KillerPlayer? get _highlighted => switch (_phase) {
        _Phase.assigning => _assigningPlayer,
        _Phase.resolving => _resolvingPlayer,
        _Phase.playing => _current,
        _ => null,
      };

  Widget _inputArea() {
    switch (_phase) {
      case _Phase.assigning:
        return _AssignmentInput(
          player: _assigningPlayer,
          missAttempts: _missAttempts,
          taken: _takenNumbers,
          onNumber: _onAssignNumber,
          onBull: _onAssignBull,
          onMiss: _onAssignMiss,
        );
      case _Phase.resolving:
        return _ResolveInput(
          player: _resolvingPlayer,
          remaining: _remainingNumbers,
          onPick: _assignResolveNumber,
        );
      case _Phase.playing:
        return _GameInput(
          player: _current,
          effectNumbers: _effectNumbers,
          darts: _turnDarts,
          multiplier: _multiplier,
          turnComplete: _turnComplete,
          canBack: _turnDarts.isNotEmpty || _history.isNotEmpty,
          onMultiplier: (m) => setState(() => _multiplier = m),
          onNumber: _applyNumber,
          onBull: _onGameBull,
          onMiss: _onGameMiss,
          onBack: _back,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// =============================================================================
// Turn record + undo snapshot
// =============================================================================

class _Dart {
  const _Dart(this.label, this.effect);
  final String label; // e.g. "T20"
  final String effect; // e.g. "−3 Sam"
}

class _TurnRecord {
  const _TurnRecord(this.index, this.snapshot);
  final int index;
  final _Snapshot snapshot;
}

/// A snapshot of every player's mutable state, so a dart or turn can be undone.
class _Snapshot {
  _Snapshot(this._lives, this._alive);

  final List<int> _lives;
  final List<bool> _alive;

  factory _Snapshot.capture(List<KillerPlayer> players) => _Snapshot(
        [for (final p in players) p.lives],
        [for (final p in players) p.alive],
      );

  void restore(List<KillerPlayer> players) {
    for (var i = 0; i < players.length; i++) {
      players[i].lives = _lives[i];
      players[i].alive = _alive[i];
    }
  }
}

// =============================================================================
// Player board (fixed, non-scrolling; current player highlighted in yellow)
// =============================================================================

class _PlayerBoard extends StatelessWidget {
  const _PlayerBoard({required this.players, required this.highlight});

  final List<KillerPlayer> players;
  final KillerPlayer? highlight;

  @override
  Widget build(BuildContext context) {
    // Non-scrolling: rows share the available height evenly.
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        children: [
          for (final p in players)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: _PlayerRow(player: p, active: p == highlight),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.player, required this.active});

  final KillerPlayer player;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dead = !player.alive;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: active ? AppColors.yellow : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Opacity(
        opacity: dead ? 0.45 : 1,
        child: Row(
          children: [
            _NumberBadge(number: player.number, active: active),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      player.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.blue,
                        fontWeight: FontWeight.bold,
                        decoration: dead ? TextDecoration.lineThrough : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dead ? '· Eliminated' : '· ${player.rankTitle}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.blue.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _Lives(lives: player.lives, dead: dead),
          ],
        ),
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge({required this.number, required this.active});

  final int? number;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? AppColors.blue : AppColors.blue.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Text(
        number?.toString() ?? '–',
        style: TextStyle(
          fontFamily: AppFonts.display,
          fontSize: 14,
          color: active ? AppColors.softWhite : AppColors.blue,
        ),
      ),
    );
  }
}

class _Lives extends StatelessWidget {
  const _Lives({required this.lives, required this.dead});

  final int lives;
  final bool dead;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          dead ? Icons.heart_broken : Icons.favorite,
          size: 18,
          color: dead ? AppColors.inkMuted : const Color(0xFFC0392B),
        ),
        const SizedBox(width: 4),
        Text(
          '$lives',
          style: const TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 16,
            color: AppColors.blue,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Assignment input (unchanged — the number grid the user liked)
// =============================================================================

class _AssignmentInput extends StatelessWidget {
  const _AssignmentInput({
    required this.player,
    required this.missAttempts,
    required this.taken,
    required this.onNumber,
    required this.onBull,
    required this.onMiss,
  });

  final KillerPlayer player;
  final int missAttempts;
  final Set<int> taken;
  final ValueChanged<int> onNumber;
  final VoidCallback onBull;
  final VoidCallback onMiss;

  @override
  Widget build(BuildContext context) {
    return _InputPanel(
      children: [
        _InstructionText(
          '${player.name}: throw one dart (non-dominant hand) to claim a number.',
        ),
        if (missAttempts > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Missed — attempt ${missAttempts + 1} of 3.',
              style: const TextStyle(
                color: Color(0xFFC0392B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        const SizedBox(height: 10),
        _NumberGrid(onTap: onNumber, dimmed: taken),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _BullButton(label: 'Bull', onPressed: onBull)),
            const SizedBox(width: 10),
            Expanded(
              child: _WideButton(
                label: 'Miss',
                filled: false,
                onPressed: onMiss,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// Resolve input (pick a remaining number)
// =============================================================================

class _ResolveInput extends StatelessWidget {
  const _ResolveInput({
    required this.player,
    required this.remaining,
    required this.onPick,
  });

  final KillerPlayer player;
  final List<int> remaining;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return _InputPanel(
      children: [
        _InstructionText('${player.name}: choose a remaining number.'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final n in remaining)
              SizedBox(
                width: 56,
                child: _WideButton(label: '$n', onPressed: () => onPick(n)),
              ),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// Game input — differs for non-Killers vs Killers
// =============================================================================

class _GameInput extends StatelessWidget {
  const _GameInput({
    required this.player,
    required this.effectNumbers,
    required this.darts,
    required this.multiplier,
    required this.turnComplete,
    required this.canBack,
    required this.onMultiplier,
    required this.onNumber,
    required this.onBull,
    required this.onMiss,
    required this.onBack,
  });

  /// Fixed height of the swappable input body, so it never grows/shrinks as
  /// turns change — empty space (with a loader) fills any slack instead.
  static const double _bodyHeight = 226;

  final KillerPlayer player;
  final List<int> effectNumbers;
  final List<_Dart> darts;
  final Multiplier multiplier;
  final bool turnComplete;
  final bool canBack;
  final ValueChanged<Multiplier> onMultiplier;
  final void Function(int number, Multiplier mult) onNumber;
  final ValueChanged<int> onBull;
  final VoidCallback onMiss;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return _InputPanel(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                "${player.name}'s turn — dart ${darts.length.clamp(0, 3)}/3",
                style: const TextStyle(
                  color: AppColors.blue,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (player.isKiller)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.yellow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'KILLER',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        _DartTrack(darts: darts),
        const SizedBox(height: 8),
        // One Back control: erases the last dart, or (with none) steps back to
        // the previous player's turn.
        _WideButton(
          label: '◂ Back',
          filled: false,
          enabled: canBack,
          onPressed: onBack,
        ),
        const SizedBox(height: 10),
        // Fixed-height body: the input keeps the same size across turns; while
        // advancing to the next player it shows a loader instead of collapsing.
        // Only the scoring section swaps when a player toggles Killer state —
        // the Bull / Miss controls below are shared and stay in place.
        SizedBox(
          height: _bodyHeight,
          child: turnComplete
              ? const _LoadingBody(message: 'Next player…')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: !player.isKiller
                            ? _NonKillerScore(
                                ownNumber: player.number!,
                                onNumber: onNumber,
                              )
                            : _KillerScore(
                                effectNumbers: effectNumbers,
                                multiplier: multiplier,
                                onMultiplier: onMultiplier,
                                onNumber: onNumber,
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _BullMissControls(onBull: onBull, onMiss: onMiss),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Empty input body with a centred three-dot loading animation, shown while
/// the game pauses between turns.
class _LoadingBody extends StatelessWidget {
  const _LoadingBody({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _LoadingDots(),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: AppColors.blue.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}

/// Three dots that pulse in sequence.
class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

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
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: _dot(i),
              ),
          ],
        );
      },
    );
  }

  Widget _dot(int i) {
    // Each dot's phase is offset so they pulse one after another.
    final phase = (_controller.value + i * 0.2) % 1.0;
    final wave = (sin(phase * 2 * pi) + 1) / 2; // 0..1
    return Opacity(
      opacity: 0.35 + 0.65 * wave,
      child: Transform.scale(
        scale: 0.7 + 0.5 * wave,
        child: Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            color: AppColors.blue,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Non-Killer scoring: three big Single/Double/Triple buttons for the player's
/// own number. Bull / Miss live in the shared [_BullMissControls] below, so a
/// Killer toggle only swaps this part.
class _NonKillerScore extends StatelessWidget {
  const _NonKillerScore({required this.ownNumber, required this.onNumber});

  final int ownNumber;
  final void Function(int number, Multiplier mult) onNumber;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final m in Multiplier.values)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _BigScoreButton(
                title: m.label,
                subtitle: 'on $ownNumber',
                onPressed: () => onNumber(ownNumber, m),
              ),
            ),
          ),
      ],
    );
  }
}

/// Killer scoring: a multiplier selector plus only the numbers that have an
/// effect (alive players' numbers), spread max 4 per row. Bull / Miss live in
/// the shared [_BullMissControls] below.
class _KillerScore extends StatelessWidget {
  const _KillerScore({
    required this.effectNumbers,
    required this.multiplier,
    required this.onMultiplier,
    required this.onNumber,
  });

  final List<int> effectNumbers;
  final Multiplier multiplier;
  final ValueChanged<Multiplier> onMultiplier;
  final void Function(int number, Multiplier mult) onNumber;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MultiplierSelector(value: multiplier, onChanged: onMultiplier),
        const SizedBox(height: 10),
        _EvenNumberGrid(
          numbers: effectNumbers,
          onTap: (n) => onNumber(n, multiplier),
        ),
      ],
    );
  }
}

/// Bull / Double-Bull row plus a full-width Miss button. Shared by Killers and
/// non-Killers so it looks and sits identically — only the scoring buttons
/// above it change when a player toggles Killer state. Bull acts as +1/+2 lives
/// for a non-Killer and as the remove-lives joker for a Killer.
class _BullMissControls extends StatelessWidget {
  const _BullMissControls({required this.onBull, required this.onMiss});

  final ValueChanged<int> onBull;
  final VoidCallback onMiss;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _BullButton(label: 'Bull', onPressed: () => onBull(1))),
            const SizedBox(width: 10),
            Expanded(
              child: _BullButton(label: 'D-Bull', onPressed: () => onBull(2)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _WideButton(
          label: 'Miss / No score',
          filled: false,
          onPressed: onMiss,
        ),
      ],
    );
  }
}

/// Lays numbers out in rows of at most 4, each row spread evenly full-width.
class _EvenNumberGrid extends StatelessWidget {
  const _EvenNumberGrid({required this.numbers, required this.onTap});

  final List<int> numbers;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < numbers.length; i += 4) {
      final slice = numbers.sublist(i, min(i + 4, numbers.length));
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            for (final n in slice)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _NumberButton(
                    number: n,
                    taken: false,
                    onTap: () => onTap(n),
                  ),
                ),
              ),
          ],
        ),
      ));
    }
    return Column(children: rows);
  }
}

class _DartTrack extends StatelessWidget {
  const _DartTrack({required this.darts});

  final List<_Dart> darts;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 3; i++)
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              decoration: BoxDecoration(
                color: AppColors.softWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.blue.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    i < darts.length ? darts[i].label : '·',
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 16,
                      color: AppColors.blue,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    i < darts.length ? darts[i].effect : '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.blue.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _MultiplierSelector extends StatelessWidget {
  const _MultiplierSelector({required this.value, required this.onChanged});

  final Multiplier value;
  final ValueChanged<Multiplier> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final m in Multiplier.values)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: GestureDetector(
                onTap: () => onChanged(m),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: value == m ? AppColors.blue : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.blue, width: 1.5),
                  ),
                  child: Text(
                    m.label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: value == m ? AppColors.softWhite : AppColors.blue,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// =============================================================================
// Shared small widgets
// =============================================================================

class _BigScoreButton extends StatelessWidget {
  const _BigScoreButton({
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.blue,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: Container(
          height: 84,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.softWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.softWhite.withValues(alpha: 0.85),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A blue button with bold yellow text — used for Bull / Double Bull.
class _BullButton extends StatelessWidget {
  const _BullButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.blue,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.yellow,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _NumberGrid extends StatelessWidget {
  const _NumberGrid({required this.onTap, this.dimmed = const {}});

  final ValueChanged<int> onTap;
  final Set<int> dimmed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var n = 1; n <= 20; n++)
          SizedBox(
            width: 52,
            child: _NumberButton(
              number: n,
              taken: dimmed.contains(n),
              onTap: () => onTap(n),
            ),
          ),
      ],
    );
  }
}

class _NumberButton extends StatelessWidget {
  const _NumberButton({
    required this.number,
    required this.taken,
    required this.onTap,
  });

  final int number;
  final bool taken;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: taken ? AppColors.blue.withValues(alpha: 0.12) : AppColors.blue,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 46,
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 15,
              color: taken ? AppColors.blue : AppColors.softWhite,
            ),
          ),
        ),
      ),
    );
  }
}

class _WideButton extends StatelessWidget {
  const _WideButton({
    required this.label,
    required this.onPressed,
    this.filled = true,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool filled;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    final onTap = enabled ? onPressed : null;
    if (filled) {
      return FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: AppColors.softWhite,
          disabledBackgroundColor: AppColors.blue.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: shape,
        ),
        child: Text(label),
      );
    }
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.blue,
        disabledForegroundColor: AppColors.blue.withValues(alpha: 0.3),
        side: BorderSide(
          color: enabled ? AppColors.blue : AppColors.blue.withValues(alpha: 0.3),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: shape,
      ),
      child: Text(label),
    );
  }
}

class _InputPanel extends StatelessWidget {
  const _InputPanel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _InstructionText extends StatelessWidget {
  const _InstructionText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w600),
    );
  }
}

class _WinnerView extends StatelessWidget {
  const _WinnerView({required this.winner});

  final KillerPlayer? winner;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 88, color: AppColors.yellow),
            const SizedBox(height: 16),
            const Text(
              'Winner',
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 20,
                color: AppColors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              winner?.name ?? '—',
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 34,
                color: AppColors.blue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.home),
              label: const Text('Back to menu'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: AppColors.softWhite,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const TextStyle _dialogTitleStyle = TextStyle(
  fontFamily: AppFonts.display,
  fontSize: 18,
  letterSpacing: 0.5,
  color: AppColors.blue,
);
