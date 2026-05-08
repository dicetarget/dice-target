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
  final String? myDisplayName;
  final String? friendName;
  final VsChallengeModel? incomingChallenge;
  final String vsMode;

  const VsScreen({
    super.key,
    required this.seed,
    this.myId,
    this.friendId,
    this.myDisplayName,
    this.friendName,
    this.incomingChallenge,
    this.vsMode = 'rush',
  });

  @override
  State<VsScreen> createState() => _VsScreenState();
}

enum _RunPhase { running, ended }

class _VsScreenState extends State<VsScreen> with TickerProviderStateMixin {
  static const Duration _runDuration = Duration(seconds: 90);
  static const int _maxUndo = 4;
  int get _totalPuzzles => widget.vsMode == 'speedrun_advanced' ? 5 : 3;
  late int _puzzlesRemaining;
  final Stopwatch _stopwatch = Stopwatch();

  static const Color _ink = AppColors.ink;
  static const Color _card = AppColors.card;

  // ── Services ──────────────────────────────────────────────────────────────────
  final GameRules _gameRules = GameRules();
  final _firestore = VsFirestoreService();
  final RoundEvaluator _roundEvaluator = const RoundEvaluator();
  final MoveApplicationService _moveService = const MoveApplicationService();
  late final PuzzleCoordinator _coordinator;

  // ── Run state ─────────────────────────────────────────────────────────────────
  _RunPhase _phase = _RunPhase.running;
  bool _gaveUp = false;
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
  FinalDiceState _finalDiceState = FinalDiceState.none;
  final Set<int> _usedTargets = {};

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

  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  bool get _isPlaying => _phase == _RunPhase.running;

  (int, int) _vsRange() => RushDifficulty.vsPuzzleRange(widget.vsMode, _score);

  @override
  void initState() {
    super.initState();
    _puzzlesRemaining = _totalPuzzles;

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

    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeOut));

    _coordinator = PuzzleCoordinator(
      generator: PuzzleGenerator(),
      mode: GameMode.rush,
      config: DifficultyConfig.easy,
      baseSeed: widget.seed,
    );

    _loadPuzzle();
    if (widget.vsMode == 'speedrun' || widget.vsMode == 'speedrun_advanced') {
      _stopwatch.start();
    } else {
      _startTimer();
    }
    unawaited(analytics.logRushStart());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    _plusOneCtrl.dispose();
    _celebrateCtrl.dispose();
    _shakeCtrl.dispose();
    _rollingDiceNotifier.dispose();
    _rollingTargetNotifier.dispose();
    super.dispose();
  }

  // ── Timer ─────────────────────────────────────────────────────────────────────

  void _startTimer() {
    if (widget.vsMode == 'speedrun' || widget.vsMode == 'speedrun_advanced') return;
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
          unawaited(_endRun());
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
    final (min, max) = _vsRange();
    final puzzle = _coordinator.startNewRun(targetMin: min, targetMax: max);
    _applyPuzzle(puzzle);
    _usedTargets.add(puzzle.target);
    sfx.rushStart();
    _startPrefetch();
  }

  void _startPrefetch() {
    final (min, max) = _vsRange();
    _prefetchFuture = Future(() => _coordinator.peekNext(targetMin: min, targetMax: max));
  }

  Future<void> _advanceToNextPuzzle() async {
    final (min, max) = _vsRange();
    final atStageBoundary = _score == 5 || _score == 12;
    final prefetched = (!atStageBoundary && _prefetchFuture != null) ? await _prefetchFuture : null;
    _prefetchFuture = null;

    Puzzle puzzle;
    if (prefetched != null && !_usedTargets.contains(prefetched.target)) {
      _coordinator.advanceIndex();
      puzzle = prefetched;
    } else {
      // Skip prefetch if duplicate, generate fresh until unique target
      if (prefetched != null) _coordinator.advanceIndex(); // discard prefetch index
      puzzle = _coordinator.nextPuzzle(targetMin: min, targetMax: max);
      int safety = 0;
      while (_usedTargets.contains(puzzle.target) && safety < 10) {
        puzzle = _coordinator.nextPuzzle(targetMin: min, targetMax: max);
        safety++;
      }
    }

    _usedTargets.add(puzzle.target);

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
      _shakeCtrl.forward(from: 0);
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

    final willBeSingleDie = newValues.length == 1;
    if (!result.willEndAfterMove && !willBeSingleDie) sfx.valid();
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
      unawaited(_onFail());
    }
  }

  Future<void> _onFail() async {
    setState(() => _finalDiceState = FinalDiceState.fail);
    _shakeCtrl.forward(from: 0);
    sfx.invalid();
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() => _finalDiceState = FinalDiceState.none);
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

  void _resetCurrentPuzzle() {
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
    setState(() => _finalDiceState = FinalDiceState.success);
    Future.delayed(const Duration(milliseconds: 520), () {
      if (mounted) setState(() => _finalDiceState = FinalDiceState.none);
    });
    _celebrateCtrl.forward(from: 0);
    _plusOneCtrl.forward(from: 0);

    if (widget.vsMode == 'speedrun' || widget.vsMode == 'speedrun_advanced') {
      _puzzlesRemaining--;
      if (_puzzlesRemaining <= 0) {
        _stopwatch.stop();
        sfx.dailyComplete();
        Future.delayed(const Duration(milliseconds: 520), () {
          if (!mounted) return;
          _timer?.cancel();
          unawaited(_endRun());
        });
        return;
      }
    }

    sfx.win();
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

  Future<void> _confirmGiveUp() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Give Up?',
          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 20),
        ),
        content: Text(
          'Your current score of $_score will be submitted.',
          style: TextStyle(color: AppColors.inkMuted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.inkMuted, fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Give Up',
              style: TextStyle(color: Color(0xFFFF3B30), fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      _gaveUp = true;
      sfx.giveUp();
      _timer?.cancel();
      unawaited(_endRun());
    }
  }

  // ── End run ───────────────────────────────────────────────────────────────────

  Future<void> _endRun() async {
    if (_phase == _RunPhase.ended) return;

    _pulseCtrl.stop();
    _timeUsedMs = (widget.vsMode == 'speedrun' || widget.vsMode == 'speedrun_advanced')
        ? _stopwatch.elapsedMilliseconds
        : (_runDuration - _remaining).inMilliseconds;
    setState(() => _phase = _RunPhase.ended);
    if (!_gaveUp && widget.vsMode != 'speedrun' && widget.vsMode != 'speedrun_advanced') {
      sfx.dailyComplete();
    }
    unawaited(analytics.logRushComplete(score: _score));
    if (!mounted) return;

    final myId = widget.myId;
    final isChallenger = myId != null && widget.incomingChallenge?.challengerId == myId;

    if (widget.incomingChallenge == null) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    if (isChallenger) {
      await _firestore.updateChallengeWithChallengerResult(
        challengeId: widget.incomingChallenge!.id,
        puzzles: _score,
        timeMs: _timeUsedMs,
        moves: _totalMoves,
      );
      await Future.delayed(const Duration(milliseconds: 500));
      final fresh = await _firestore.loadChallenge(widget.incomingChallenge!.id);
      if (!mounted) return;

      final myResult = _toVsChallenge(_score, _timeUsedMs, _totalMoves);
      if (fresh != null && fresh.opponentPlayed) {
        final opponentResult = _toVsChallenge(
          fresh.opponentPuzzles ?? 0,
          fresh.opponentTimeMs ?? 0,
          fresh.opponentMoves ?? 0,
        );
        try {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => VsResultScreen(
                challenger: myResult,
                opponent: opponentResult,
                isChallenger: true,
                pendingOpponent: false,
                vsMode: widget.vsMode,
                friendName: widget.friendName,
              ),
            ),
          );
        } catch (e) {
          debugPrint('VsResultScreen navigation error: $e');
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        try {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => VsResultScreen(
                challenger: myResult,
                opponent: myResult,
                isChallenger: true,
                pendingOpponent: true,
                vsMode: widget.vsMode,
                friendName: widget.friendName,
              ),
            ),
          );
        } catch (e) {
          debugPrint('VsResultScreen navigation error: $e');
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } else {
      await _firestore.updateChallengeWithOpponentResult(
        challengeId: widget.incomingChallenge!.id,
        puzzles: _score,
        timeMs: _timeUsedMs,
        moves: _totalMoves,
      );
      await Future.delayed(const Duration(milliseconds: 500));
      final fresh = await _firestore.loadChallenge(widget.incomingChallenge!.id);
      if (!mounted) return;

      final myResult = _toVsChallenge(_score, _timeUsedMs, _totalMoves);
      if (fresh != null && fresh.challengerPlayed) {
        final challengerResult = _toVsChallenge(
          fresh.challengerPuzzles,
          fresh.challengerTimeMs,
          fresh.challengerMoves,
        );
        try {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => VsResultScreen(
                challenger: challengerResult,
                opponent: myResult,
                isChallenger: false,
                pendingOpponent: false,
                vsMode: widget.vsMode,
                friendName: widget.friendName,
              ),
            ),
          );
        } catch (e) {
          debugPrint('VsResultScreen navigation error: $e');
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        try {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => VsResultScreen(
                challenger: myResult,
                opponent: myResult,
                isChallenger: false,
                pendingOpponent: true,
                vsMode: widget.vsMode,
                friendName: widget.friendName,
              ),
            ),
          );
        } catch (e) {
          debugPrint('VsResultScreen navigation error: $e');
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
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
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: const Text(
          'VS',
          style: TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.w800,
            fontSize: 17,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: true,
        actions: [
          (widget.vsMode == 'speedrun' || widget.vsMode == 'speedrun_advanced')
              ? const SizedBox.shrink()
              : Padding(
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
        color: AppColors.bgDark,
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
                      accentColor: AppColors.gold,
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
                        accentColor: AppColors.gold,
                        inkColor: _ink,
                        shakeAnimation: _shakeAnim,
                        rollingDiceListenable: _rollingDiceNotifier,
                        rollingTargetLocked: false,
                        dice: _dice
                            .map((d) => PracticeDieData(value: d.value, maskLabel: d.maskLabel))
                            .toList(),
                        canInteractGameplay: _isPlaying,
                        allowedOps: DifficultyConfig.easy.allowedOps,
                        pendingOp: _pendingOp,
                        finalDiceState: _finalDiceState,
                        undoEnabled: canUndo,
                        resetEnabled: _undoStack.isNotEmpty && _isPlaying,
                        onToggleSelect: _handleToggleSelect,
                        onApplyOp: _handleApplyOp,
                        onUndo: _undo,
                        onResetPuzzle: (_undoStack.isNotEmpty && _isPlaying)
                            ? _resetCurrentPuzzle
                            : null,
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
        GestureDetector(
          onTap: _confirmGiveUp,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 0.5),
            ),
            child: Text(
              'Give Up',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.inkMuted,
              ),
            ),
          ),
        ),
        const Spacer(),
        SizedBox(
          width: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                (widget.vsMode == 'speedrun' || widget.vsMode == 'speedrun_advanced')
                    ? 'Puzzles'
                    : 'Score',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.inkMuted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                (widget.vsMode == 'speedrun' || widget.vsMode == 'speedrun_advanced')
                    ? '$_score / $_totalPuzzles'
                    : '$_score',
                style: const TextStyle(
                  fontSize: 28,
                  color: AppColors.ink,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
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
                    color: AppColors.gold,
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
