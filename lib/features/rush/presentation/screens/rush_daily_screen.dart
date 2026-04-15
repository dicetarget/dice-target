// lib/features/rush/presentation/screens/rush_daily_screen.dart

import 'dart:async';

import 'package:dice/core/audio/sfx_singleton.dart';
import 'package:dice/core/difficulty_config.dart';
import 'package:dice/core/game_rules.dart';
import 'package:dice/core/puzzle/game_mode.dart';
import 'package:dice/core/puzzle/puzzle.dart';
import 'package:dice/core/puzzle/puzzle_coordinator.dart';
import 'package:dice/core/puzzle/puzzle_generator.dart';
import 'package:dice/core/theme/app_colors.dart';
import 'package:dice/core/theme/app_radius.dart';
import 'package:dice/core/theme/app_spacing.dart';
import 'package:dice/core/ui_op.dart';
import 'package:dice/features/game/logic/move_application_service.dart';
import 'package:dice/features/game/logic/round_evaluator.dart';
import 'package:dice/features/game/models/dice_state.dart';
import 'package:dice/features/game/presentation/widgets/practice_dice_row.dart';
import 'package:dice/features/game/presentation/widgets/practice_game_area.dart';
import 'package:dice/features/game/presentation/widgets/target_display_widget.dart';
import 'package:dice/features/rush/data/rush_daily_storage.dart';
import 'package:flutter/material.dart';

// ── Undo snapshot ─────────────────────────────────────────────────────────────
class _UndoSnapshot {
  final List<DiceState> dice;
  final int moves;
  const _UndoSnapshot({required this.dice, required this.moves});
}

// ── RushDailyScreen ───────────────────────────────────────────────────────────
class RushDailyScreen extends StatefulWidget {
  final int runNumber;
  final int run1Score;

  const RushDailyScreen({super.key, required this.runNumber, required this.run1Score});

  @override
  State<RushDailyScreen> createState() => _RushDailyScreenState();
}

enum _RunPhase { running, ended }

class _RushDailyScreenState extends State<RushDailyScreen> with TickerProviderStateMixin {
  static const Duration _runDuration = Duration(seconds: 90);
  static const int _maxUndo = 4;
  static const int _targetMin = 15;
  static const int _targetMax = 55;

  static const Color _ink = AppColors.ink;
  static const Color _card = AppColors.card;
  static const Color _accent = AppColors.accent;
  static const Color _green = Color(0xFF4CAF82);
  static const Color _timerAmber = Color(0xFFFF9F00);
  static const Color _timerRed = AppColors.failed;

  // ── Services ──────────────────────────────────────────────────────────────
  final GameRules _gameRules = GameRules();
  final RoundEvaluator _roundEvaluator = const RoundEvaluator();
  final MoveApplicationService _moveService = const MoveApplicationService();
  late final PuzzleCoordinator _coordinator;

  // ── Run state ─────────────────────────────────────────────────────────────
  _RunPhase _phase = _RunPhase.running;
  List<DiceState> _dice = [];
  List<int> _originalDice = [];
  int _target = 0;
  int _score = 0;
  Duration _remaining = _runDuration;
  Timer? _timer;
  bool _warningSoundPlayed = false;

  // ── Prefetch ──────────────────────────────────────────────────────────────
  Future<Puzzle>? _prefetchFuture;

  // ── Interaction ───────────────────────────────────────────────────────────
  final Set<int> _selected = {};
  UiOp? _pendingOp;
  final List<_UndoSnapshot> _undoStack = [];
  int _moves = 0;
  int _mergePopKey = 0;

  // ── Notifiers ─────────────────────────────────────────────────────────────
  final ValueNotifier<List<int>> _rollingDiceNotifier = ValueNotifier([]);
  final ValueNotifier<int> _rollingTargetNotifier = ValueNotifier(0);

  // ── Animations ────────────────────────────────────────────────────────────
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseScale;
  bool _pulseStarted = false;

  late final AnimationController _celebrateCtrl;
  late final Animation<double> _celebrateT;

  bool get _isPlaying => _phase == _RunPhase.running;

  // ── Daily Seed (gleich für alle, gleicher Tag) ────────────────────────────
  static int _buildDailySeed() {
    final now = DateTime.now();
    return (now.year * 10000 + now.month * 100 + now.day) ^ 0xDA17BEEF;
  }

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
    _pulseScale = Tween<double>(
      begin: 1.0,
      end: 1.07,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

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
      baseSeed: _buildDailySeed(),
    );

    _loadPuzzle();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    _celebrateCtrl.dispose();
    _rollingDiceNotifier.dispose();
    _rollingTargetNotifier.dispose();
    super.dispose();
  }

  // ── Timer ─────────────────────────────────────────────────────────────────

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

  // ── Puzzle ────────────────────────────────────────────────────────────────

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
    final puzzle = _coordinator.startNewRun(targetMin: _targetMin, targetMax: _targetMax);
    _applyPuzzle(puzzle);
    sfx.rushDailyStart();
    _startPrefetch();
  }

  void _startPrefetch() {
    _prefetchFuture = Future(
      () => _coordinator.peekNext(targetMin: _targetMin, targetMax: _targetMax),
    );
  }

  Future<void> _advanceToNextPuzzle() async {
    final prefetched = _prefetchFuture != null ? await _prefetchFuture : null;
    _prefetchFuture = null;

    final Puzzle puzzle;
    if (prefetched != null) {
      _coordinator.advanceIndex();
      puzzle = prefetched;
    } else {
      puzzle = _coordinator.nextPuzzle(targetMin: _targetMin, targetMax: _targetMax);
    }

    if (!mounted) return;
    setState(() => _applyPuzzle(puzzle));
    _startPrefetch();
  }

  // ── Move logic ────────────────────────────────────────────────────────────

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
    setState(() => _score++);
    sfx.win();
    _celebrateCtrl.forward(from: 0);
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
    sfx.click();
  }

  // ── End run ───────────────────────────────────────────────────────────────

  Future<void> _endRun() async {
    if (_phase == _RunPhase.ended) return;
    _pulseCtrl.stop();
    setState(() => _phase = _RunPhase.ended);

    final storage = RushDailyStorage();
    await storage.saveRun1(_score);

    sfx.dailyComplete();
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => _RushDailyResultScreen(score: _score),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Color _timerColor() {
    final s = _remaining.inSeconds;
    if (s <= 10) return _timerRed;
    if (s <= 20) return _timerAmber;
    return Colors.white;
  }

  bool get _timerWarning => _remaining.inSeconds <= 20;

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final canUndo = _undoStack.isNotEmpty && _isPlaying;

    return PopScope(
      canPop: false, // Kein Zurück während des Runs
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: const Color(0xFF020408),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false, // Kein Back-Button
          title: const Text(
            'Rush Daily',
            style: TextStyle(
              color: _green,
              fontWeight: FontWeight.w900,
              fontSize: 17,
              letterSpacing: -0.2,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                sfx.enabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                size: 20,
              ),
              color: Colors.white.withValues(alpha: 0.60),
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
            child: Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.sm,
                bottom: bottomInset,
              ),
              child: Column(
                children: [
                  _buildStatusRow(),
                  const SizedBox(height: AppSpacing.md),
                  TargetDisplayWidget(
                    isPreStart: false,
                    isRolling: false,
                    target: _target,
                    cardColor: _card,
                    accentColor: _accent,
                    inkColor: _ink,
                    rollingTargetListenable: _rollingTargetNotifier,
                    celebrateAnimation: _celebrateT,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: PracticeGameArea(
                      showDice: true,
                      isRolling: false,
                      isPlaying: _isPlaying,
                      busy: false,
                      showMergedResults: true,
                      mergePopKey: _mergePopKey,
                      selectedIndices: _selected,
                      accentColor: _accent,
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
          ),
        ),
      ),
    );
  }

  // ── Status Row ────────────────────────────────────────────────────────────

  Widget _buildStatusRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Score links
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

        // Timer zentriert
        Expanded(
          child: Center(
            child: ScaleTransition(
              scale: _pulseScale,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: _timerWarning
                      ? const Color(0xFF000508)
                      : Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  border: Border.all(
                    color: _timerWarning
                        ? _timerColor().withValues(alpha: 0.85)
                        : Colors.white.withValues(alpha: 0.18),
                    width: _timerWarning ? 2.0 : 1.0,
                  ),
                  boxShadow: _timerWarning
                      ? [
                          BoxShadow(color: _timerColor().withValues(alpha: 0.50), blurRadius: 6),
                          BoxShadow(
                            color: _timerColor().withValues(alpha: 0.22),
                            blurRadius: 16,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  '${_remaining.inSeconds}s',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: _timerColor(),
                    letterSpacing: -0.5,
                    shadows: _timerWarning
                        ? [Shadow(color: _timerColor().withValues(alpha: 0.65), blurRadius: 10)]
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 80),
      ],
    );
  }
}

// ── Daily Result Screen ───────────────────────────────────────────────────────

class _RushDailyResultScreen extends StatelessWidget {
  final int score;

  const _RushDailyResultScreen({required this.score});

  static const Color _green = Color(0xFF4CAF82);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgTop,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A1628), Color(0xFF060B14), Color(0xFF020408)],
                stops: [0.0, 0.5, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  const Text(
                    'Daily Speed\nComplete!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.8,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D0F1F),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _green.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _green.withValues(alpha: 0.06),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Score',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$score',
                          style: const TextStyle(
                            fontSize: 80,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -4,
                            height: 0.9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [_green.withValues(alpha: 0.20), _green.withValues(alpha: 0.09)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _green.withValues(alpha: 0.65), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: _green.withValues(alpha: 0.22), blurRadius: 20),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Back to Home',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: _green,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
