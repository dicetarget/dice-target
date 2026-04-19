// lib/features/vs/presentation/screens/vs_screen.dart

import 'dart:async';

import 'package:dice/core/analytics/analytics_service.dart';
import 'package:dice/core/audio/sfx_singleton.dart';
import 'package:dice/core/difficulty_config.dart';
import 'package:dice/core/game_rules.dart';
import 'package:dice/core/puzzle/game_mode.dart';
import 'package:dice/core/puzzle/puzzle.dart';
import 'package:dice/core/puzzle/puzzle_coordinator.dart';
import 'package:dice/core/puzzle/puzzle_generator.dart';
import 'package:dice/core/theme/app_colors.dart';
import 'package:dice/core/theme/app_spacing.dart';
import 'package:dice/core/ui_op.dart';
import 'package:dice/features/game/logic/move_application_service.dart';
import 'package:dice/features/game/logic/round_evaluator.dart';
import 'package:dice/features/game/models/dice_state.dart';
import 'package:dice/features/game/presentation/widgets/practice_dice_row.dart';
import 'package:dice/features/game/presentation/widgets/practice_game_area.dart';
import 'package:dice/features/game/presentation/widgets/target_display_widget.dart';
import 'package:dice/features/rush/domain/rush_difficulty.dart';
import 'package:dice/features/vs/data/vs_firestore_service.dart';
import 'package:dice/features/vs/domain/vs_challenge.dart';
import 'package:dice/features/vs/domain/vs_challenge_model.dart';
import 'package:dice/features/vs/presentation/screens/vs_result_screen.dart';
import 'package:flutter/material.dart';

// ──────────────────────────────────────────────────────────────────────────────
// RushRunClock — standalone, NOT imported from practice_screen
// ──────────────────────────────────────────────────────────────────────────────
class VsRunClock {
  final Duration total;
  const VsRunClock(this.total);
  bool isExpired(Duration elapsed) => elapsed >= total;
}

// ──────────────────────────────────────────────────────────────────────────────
// Undo snapshot
// ──────────────────────────────────────────────────────────────────────────────
class _UndoSnapshot {
  final List<DiceState> dice;
  final int moves;
  const _UndoSnapshot({required this.dice, required this.moves});
}

// ──────────────────────────────────────────────────────────────────────────────
// VsScreen
// ──────────────────────────────────────────────────────────────────────────────
class VsScreen extends StatefulWidget {
  final int seed;
  final String? myId;
  final String? friendId;
  final VsChallengeModel? incomingChallenge;

  const VsScreen({
    super.key,
    required this.seed,
    this.myId,
    this.friendId,
    this.incomingChallenge,
  });

  @override
  State<VsScreen> createState() => _VsScreenState();
}

enum _RunPhase { running, ended }

class _VsScreenState extends State<VsScreen> with TickerProviderStateMixin {
  static const Duration _runDuration = Duration(seconds: 90);
  static const int _maxUndo = 4;

  static const Color _ink = AppColors.ink;
  static const Color _card = AppColors.card;
  static const Color _orange = Color(0xFF7B35E8);

  // ── Services ──────────────────────────────────────────────────────────────────
  final GameRules _gameRules = GameRules();
  final _firestore = VsFirestoreService();
  final RoundEvaluator _roundEvaluator = const RoundEvaluator();
  final MoveApplicationService _moveService = const MoveApplicationService();
  late final PuzzleCoordinator _coordinator;

  // ── Run state ─────────────────────────────────────────────────────────────────
  _RunPhase _phase = _RunPhase.running;
  List<DiceState> _dice = [];
  List<int> _originalDice = [];
  int _target = 0;
  int _score = 0;
  int _totalMoves = 0;
  int _timeUsedMs = 0;
  Duration _remaining = _runDuration;
  Timer? _timer;

  // ── Prefetch ──────────────────────────────────────────────────────────────────
  Future<Puzzle>? _prefetchFuture;

  // ── Interaction ───────────────────────────────────────────────────────────────
  final Set<int> _selected = {};
  UiOp? _pendingOp;
  final List<_UndoSnapshot> _undoStack = [];
  int _moves = 0;
  int _mergePopKey = 0;

  // ── Rolling notifiers ─────────────────────────────────────────────────────────
  final ValueNotifier<List<int>> _rollingDiceNotifier = ValueNotifier([]);
  final ValueNotifier<int> _rollingTargetNotifier = ValueNotifier(0);

  // ── Animations ────────────────────────────────────────────────────────────────
  late final AnimationController _pulseCtrl;
  bool _pulseStarted = false;
  bool _warningSoundPlayed = false;

  late final AnimationController _plusOneCtrl;
  late final Animation<double> _plusOneOpacity;
  late final Animation<double> _plusOneOffset;

  late final AnimationController _celebrateCtrl;
  late final Animation<double> _celebrateT;

  bool get _isPlaying => _phase == _RunPhase.running;

  /// Stage-based target range driven by solved count.
  (int, int) _stageRange([int? score]) {
    final s = score ?? _score;
    return RushDifficulty.stageRange(s);
  }

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
    _plusOneCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
    _plusOneOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 60),
    ]).animate(_plusOneCtrl);
    _plusOneOffset = Tween<double>(
      begin: 0.0,
      end: -52.0,
    ).animate(CurvedAnimation(parent: _plusOneCtrl, curve: Curves.easeOut));

    _celebrateCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _celebrateT = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 45,
      ),
    ]).animate(_celebrateCtrl);

    _coordinator = PuzzleCoordinator(
      generator: PuzzleGenerator(),
      mode: GameMode.rush,
      config: DifficultyConfig.easy,
      baseSeed: widget.seed,
    );

    _loadPuzzle();
    _startTimer();
    unawaited(analytics.logRushStart());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    _plusOneCtrl.dispose();
    _celebrateCtrl.dispose();
    _rollingDiceNotifier.dispose();
    _rollingTargetNotifier.dispose();
    super.dispose();
  }

  // ── Timer ─────────────────────────────────────────────────────────────────────

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remaining -= const Duration(seconds: 1);
        if (_remaining.inSeconds <= 20 && !_warningSoundPlayed) {
          _warningSoundPlayed = true;
          sfx.rushWarning();
        }
        if (_remaining.inSeconds <= 10 && !_pulseStarted) {
          _pulseStarted = true;
          _pulseCtrl.repeat(reverse: true);
        }
        if (_remaining <= Duration.zero) {
          _remaining = Duration.zero;
          _timer?.cancel();
          _endRun();
        }
      });
    });
  }

  // ── Puzzle ────────────────────────────────────────────────────────────────────

  void _applyPuzzle(Puzzle puzzle) {
    _target = puzzle.target;
    _originalDice = List<int>.from(puzzle.dice);
    _dice = puzzle.dice.map((v) => DiceState(value: v)).toList();
    _undoStack.clear();
    _selected.clear();
    _pendingOp = null;
    _moves = 0;
    _mergePopKey = 0;
    _rollingTargetNotifier.value = _target;
    _rollingDiceNotifier.value = _dice.map((d) => d.value).toList();
    _gameRules.reset();
    _gameRules.start(_target);
  }

  void _loadPuzzle() {
    final (min, max) = _stageRange();
    final puzzle = _coordinator.startNewRun(targetMin: min, targetMax: max);
    _applyPuzzle(puzzle);
    sfx.rushStart();
    _startPrefetch();
  }

  void _startPrefetch() {
    final (min, max) = _stageRange();
    _prefetchFuture = Future(
      () => _coordinator.peekNext(targetMin: min, targetMax: max),
    );
  }

  Future<void> _advanceToNextPuzzle() async {
    final (min, max) = _stageRange();
    // Discard prefetch at stage boundaries (prefetch used previous stage's range).
    final atStageBoundary = _score == 5 || _score == 12;
    final prefetched = (!atStageBoundary && _prefetchFuture != null)
        ? await _prefetchFuture
        : null;
    _prefetchFuture = null;

    final Puzzle puzzle;
    if (prefetched != null) {
      _coordinator.advanceIndex();
      puzzle = prefetched;
    } else {
      puzzle = _coordinator.nextPuzzle(targetMin: min, targetMax: max);
    }

    if (!mounted) return;
    setState(() => _applyPuzzle(puzzle));
    _startPrefetch();
  }

  // ── Move logic ────────────────────────────────────────────────────────────────

  void _handleToggleSelect(int index) {
    if (!_isPlaying) return;
    if (index < 0 || index >= _dice.length) return;
    setState(() {
      if (_selected.contains(index)) {
        if (_selected.length == 1) _pendingOp = null;
        _selected.remove(index);
      } else {
        _selected.add(index);
      }
    });
    if (_pendingOp != null && _selected.length >= 2) {
      final op = _pendingOp!;
      setState(() => _pendingOp = null);
      _applyMove(op);
    }
  }

  void _handleApplyOp(UiOp op) {
    if (!_isPlaying) return;
    if (_pendingOp == op) {
      setState(() => _pendingOp = null);
      return;
    }
    if (_selected.length < 2) {
      setState(() => _pendingOp = op);
      return;
    }
    setState(() => _pendingOp = null);
    _applyMove(op);
  }

  void _applyMove(UiOp op) {
    final result = _moveService.buildMove(
      diceValues: _dice.map((d) => d.value).toList(),
      selectedIndices: _selected.toList(),
      op: op,
      gameMode: GameMode.rush,
    );
    if (result == null) {
      sfx.invalid();
      return;
    }

    if (_undoStack.length >= _maxUndo) _undoStack.removeAt(0);
    _undoStack.add(_UndoSnapshot(dice: List.from(_dice), moves: _moves));

    final newValues = _moveService.applyToDiceValues(
      diceValues: _dice.map((d) => d.value).toList(),
      removeIndicesDesc: result.removeIndicesDesc,
      mergedValue: result.mergedValue,
    );
    _gameRules.registerMove();
    _moves++;

    setState(() {
      _dice = newValues.map((v) => DiceState(value: v)).toList();
      _rollingDiceNotifier.value = _dice.map((d) => d.value).toList();
      _selected.clear();
      _pendingOp = null;
      _mergePopKey++;
    });

    if (!result.willEndAfterMove) sfx.valid();
    if (result.willEndAfterMove) _checkSolve();
  }

  void _checkSolve() {
    if (_dice.isEmpty) return;
    final gs = _roundEvaluator.evaluate(
      target: _target,
      finalValue: _dice.last.value,
      rules: _gameRules,
    );
    if (gs == GameState.solved) {
      _onSolve();
    } else if (gs == GameState.notSolved) {
      _resetCurrentPuzzle();
    }
  }

  void _resetCurrentPuzzle() {
    sfx.invalid();
    setState(() {
      _dice = _originalDice.map((v) => DiceState(value: v)).toList();
      _rollingDiceNotifier.value = List<int>.from(_originalDice);
      _undoStack.clear();
      _selected.clear();
      _pendingOp = null;
      _moves = 0;
    });
    _gameRules.reset();
    _gameRules.start(_target);
  }

  void _onSolve() {
    _totalMoves += _moves;
    setState(() => _score++);
    sfx.win();
    _celebrateCtrl.forward(from: 0);
    _plusOneCtrl.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 520), () {
      if (!mounted || _phase == _RunPhase.ended) return;
      _advanceToNextPuzzle();
    });
  }

  void _undo() {
    if (!_isPlaying || _undoStack.isEmpty) return;
    final snapshot = _undoStack.removeLast();
    _gameRules.moves = snapshot.moves;
    _moves = snapshot.moves;
    setState(() {
      _dice = List.from(snapshot.dice);
      _rollingDiceNotifier.value = _dice.map((d) => d.value).toList();
      _selected.clear();
      _pendingOp = null;
    });
    sfx.undo();
  }

  // ── End run ───────────────────────────────────────────────────────────────────

  void _endRun() {
    if (_phase == _RunPhase.ended) return;
    _pulseCtrl.stop();
    _timeUsedMs = (_runDuration - _remaining).inMilliseconds;
    setState(() => _phase = _RunPhase.ended);
    sfx.dailyComplete();
    unawaited(analytics.logRushComplete(score: _score));
    if (!mounted) return;

    final isChallenger = widget.incomingChallenge == null;

    if (isChallenger) {
      final challenge = VsChallengeModel.create(
        challengerId: widget.myId ?? 'unknown',
        opponentId: widget.friendId ?? 'unknown',
        seed: widget.seed,
        challengerPuzzles: _score,
        challengerTimeMs: _timeUsedMs,
        challengerMoves: _totalMoves,
      );
      unawaited(_firestore.createChallenge(challenge));

      final challengeAsOld = _toVsChallenge(challenge.challengerPuzzles,
          challenge.challengerTimeMs, challenge.challengerMoves);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => VsResultScreen(
            challenger: challengeAsOld,
            opponent: challengeAsOld,
            isChallenger: true,
            pendingOpponent: true,
          ),
        ),
      );
    } else {
      unawaited(_firestore.updateChallengeWithOpponentResult(
        challengeId: widget.incomingChallenge!.id,
        puzzles: _score,
        timeMs: _timeUsedMs,
        moves: _totalMoves,
      ));

      final incoming = widget.incomingChallenge!;
      final challengerOld = _toVsChallenge(incoming.challengerPuzzles,
          incoming.challengerTimeMs, incoming.challengerMoves);
      final opponentOld = _toVsChallenge(_score, _timeUsedMs, _totalMoves);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => VsResultScreen(
            challenger: challengerOld,
            opponent: opponentOld,
            isChallenger: false,
            pendingOpponent: false,
          ),
        ),
      );
    }
  }

  VsChallenge _toVsChallenge(int puzzles, int timeMs, int moves) {
    return VsChallenge(
      seed: widget.seed,
      puzzlesSolved: puzzles,
      timeUsedMs: timeMs,
      movesUsed: moves,
      createdAt: DateTime.now(),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final canUndo = _undoStack.isNotEmpty && _isPlaying;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF020408),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            _timer?.cancel();
            Navigator.of(context).pop();
          },
          enableFeedback: false,
          color: _ink.withValues(alpha: 0.70),
        ),
        title: const Text(
          'VS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 17,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              '${_remaining.inSeconds}s',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _remaining.inSeconds > 20
                    ? const Color(0xFF00FF88)
                    : _remaining.inSeconds > 10
                        ? const Color(0xFFFF9500)
                        : const Color(0xFFFF3B30),
              ),
            ),
          ),
          IconButton(
            icon: Icon(sfx.enabled ? Icons.volume_up_rounded : Icons.volume_off_rounded, size: 20),
            color: _ink.withValues(alpha: 0.60),
            enableFeedback: false,
            onPressed: () async {
              await sfx.toggle();
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A1628), Color(0xFF060B14), Color(0xFF020408)],
            stops: [0.0, 0.5, 1.0],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  top: AppSpacing.sm,
                  bottom: bottomInset,
                ),
                child: Column(
                  children: [
                    _buildStatusRow(),
                    const SizedBox(height: 4),
                    TargetDisplayWidget(
                      isPreStart: false,
                      isRolling: false,
                      target: _target,
                      cardColor: _card,
                      accentColor: _orange,
                      inkColor: _ink,
                      rollingTargetListenable: _rollingTargetNotifier,
                      celebrateAnimation: _celebrateT,
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: PracticeGameArea(
                        showDice: true,
                        isRolling: false,
                        isPlaying: _isPlaying,
                        busy: false,
                        showMergedResults: true,
                        mergePopKey: _mergePopKey,
                        selectedIndices: _selected,
                        accentColor: _orange,
                        inkColor: _ink,
                        shakeAnimation: const AlwaysStoppedAnimation(0.0),
                        rollingDiceListenable: _rollingDiceNotifier,
                        rollingTargetLocked: false,
                        dice: _dice
                            .map((d) => PracticeDieData(value: d.value, maskLabel: d.maskLabel))
                            .toList(),
                        canInteractGameplay: _isPlaying,
                        allowedOps: DifficultyConfig.easy.allowedOps,
                        pendingOp: _pendingOp,
                        undoEnabled: canUndo,
                        onToggleSelect: _handleToggleSelect,
                        onApplyOp: _handleApplyOp,
                        onUndo: _undo,
                      ),
                    ),
                    SizedBox(height: AppSpacing.lg + bottomInset * 0.5),
                  ],
                ),
              ),
              _buildPlusOneOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────────

  Widget _buildStatusRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Score',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.30),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                '$_score',
                style: const TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        SizedBox(
          width: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Stage',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.30),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                _score >= 12 ? '3' : _score >= 5 ? '2' : '1',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlusOneOverlay() {
    return AnimatedBuilder(
      animation: _plusOneCtrl,
      builder: (context, _) {
        if (_plusOneCtrl.value == 0.0) return const SizedBox.shrink();
        return Positioned(
          top: 150 + _plusOneOffset.value,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Center(
              child: Opacity(
                opacity: _plusOneOpacity.value.clamp(0.0, 1.0),
                child: Text(
                  '+1',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: _orange,
                    shadows: const [Shadow(color: Color(0xFF7B35E8), blurRadius: 14)],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
