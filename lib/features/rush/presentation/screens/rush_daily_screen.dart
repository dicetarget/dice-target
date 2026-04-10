// lib/features/rush/presentation/screens/rush_daily_screen.dart

import 'dart:async';

import 'package:dice/core/audio/sfx_singleton.dart';
import 'package:dice/core/difficulty_config.dart';
import 'package:dice/core/game_rules.dart';
import 'package:dice/core/puzzle/game_mode.dart';
import 'package:dice/core/puzzle/puzzle_coordinator.dart';
import 'package:dice/core/puzzle/puzzle_generator.dart';
import 'package:dice/core/theme/app_colors.dart';
import 'package:dice/core/theme/app_radius.dart';
import 'package:dice/core/theme/app_spacing.dart';
import 'package:dice/core/ui_op.dart';
import 'package:dice/features/game/logic/move_application_service.dart';
import 'package:dice/features/game/logic/round_evaluator.dart';
import 'package:dice/features/game/logic/solver_service.dart';
import 'package:dice/features/game/models/dice_state.dart';
import 'package:dice/features/game/presentation/widgets/practice_dice_row.dart';
import 'package:dice/features/game/presentation/widgets/practice_game_area.dart';
import 'package:dice/features/game/presentation/widgets/target_display_widget.dart';
import 'package:dice/features/rush/data/rush_daily_storage.dart';
import 'package:dice/features/rush/presentation/screens/rush_daily_between_screen.dart';
import 'package:dice/features/rush/presentation/screens/rush_daily_result_screen.dart';
import 'package:flutter/material.dart';

class RushDailyScreen extends StatefulWidget {
  final int runNumber;
  final int run1Score;

  const RushDailyScreen({super.key, required this.runNumber, this.run1Score = -1});

  @override
  State<RushDailyScreen> createState() => _RushDailyScreenState();
}

enum _RunPhase { running, ended }

class _RushDailyScreenState extends State<RushDailyScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const Duration _runDuration = Duration(seconds: 120);
  static const int _maxUndo = 4;
  static const int _targetMin = 15;
  static const int _targetMax = 55;

  static const Color _ink = AppColors.ink;
  static const Color _card = AppColors.card;
  static const Color _accent = AppColors.accent;
  static const Color _timerAmber = Color(0xFFFF9F00);
  static const Color _timerRed = AppColors.failed;
  static const Color _cyan = Color(0xFF3FE8FF);

  // ── Services ──────────────────────────────────────────────────────────────────
  final GameRules _gameRules = GameRules();
  final RoundEvaluator _roundEvaluator = const RoundEvaluator();
  final MoveApplicationService _moveService = const MoveApplicationService();
  final RushDailyStorage _storage = RushDailyStorage();
  late final PuzzleCoordinator _coordinator;

  // ── Run state ─────────────────────────────────────────────────────────────────
  _RunPhase _phase = _RunPhase.running;
  List<DiceState> _dice = [];
  List<int> _originalDice = [];
  int _target = 0;
  int _score = 0;
  Duration _remaining = _runDuration;
  Timer? _timer;
  bool _scoreSaved = false;

  // ── Skip / Hint (1× each) ─────────────────────────────────────────────────────
  bool _skipUsed = false;
  bool _hintUsed = false;

  // ── Interaction ───────────────────────────────────────────────────────────────
  final Set<int> _selected = {};
  UiOp? _pendingOp;
  final List<_UndoSnapshot> _undoStack = [];
  int _moves = 0;
  int _mergePopKey = 0;

  // ── Notifiers ─────────────────────────────────────────────────────────────────
  final ValueNotifier<List<int>> _rollingDiceNotifier = ValueNotifier([]);
  final ValueNotifier<int> _rollingTargetNotifier = ValueNotifier(0);

  // ── Animations ────────────────────────────────────────────────────────────────
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseScale;
  bool _pulseStarted = false;
  bool _warningSoundPlayed = false;

  late final AnimationController _plusOneCtrl;
  late final Animation<double> _plusOneOpacity;
  late final Animation<double> _plusOneOffset;

  late final AnimationController _celebrateCtrl;
  late final Animation<double> _celebrateT;

  bool get _isPlaying => _phase == _RunPhase.running;
  bool get _canSkip => _isPlaying && !_skipUsed;
  bool get _canHint => _isPlaying && !_hintUsed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
    _pulseScale = Tween<double>(
      begin: 1.0,
      end: 1.07,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

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
      baseSeed: RushDailyStorage.dailySeed(),
    );

    _loadPuzzle(first: true);
    _startTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _pulseCtrl.dispose();
    _plusOneCtrl.dispose();
    _celebrateCtrl.dispose();
    _rollingDiceNotifier.dispose();
    _rollingTargetNotifier.dispose();
    super.dispose();
  }

  // ── App lifecycle — save score on background ──────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _phase == _RunPhase.running) {
      _saveCurrentScore();
    }
  }

  Future<void> _saveCurrentScore() async {
    if (_scoreSaved) return;
    _scoreSaved = true;
    _timer?.cancel();
    if (widget.runNumber == 1) {
      await _storage.saveRun1(_score);
    } else {
      await _storage.saveRun2(_score);
    }
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

  void _loadPuzzle({bool first = false}) {
    final puzzle = first
        ? _coordinator.startNewRun(targetMin: _targetMin, targetMax: _targetMax)
        : _coordinator.nextPuzzle(targetMin: _targetMin, targetMax: _targetMax);

    if (first) sfx.rushStart();

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

  // ── Moves ─────────────────────────────────────────────────────────────────────

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
    _plusOneCtrl.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 520), () {
      if (!mounted || _phase == _RunPhase.ended) return;
      setState(() => _loadPuzzle());
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

  void _skip() {
    if (!_canSkip) return;
    setState(() => _skipUsed = true);
    sfx.click();
    setState(() => _loadPuzzle());
  }

  void _showHint() {
    if (!_canHint) return;
    setState(() => _hintUsed = true);
    sfx.click();

    final solver = SolverService();
    final result = solver.check(diceValues: _originalDice, target: _target);
    final solution = result.solvable ? result.fullExpression : null;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppColors.cardBr),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        title: const Text(
          'Hint — Solution',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
        ),
        content: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.bgBottom,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBr),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Target: $_target',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFD4AC0D),
                ),
              ),
              const SizedBox(height: 10),
              SelectableText(
                solution ?? 'No solution found.',
                style: const TextStyle(
                  fontSize: 17,
                  height: 1.5,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Close',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _cyan),
            ),
          ),
        ],
      ),
    );
  }

  // ── End run ───────────────────────────────────────────────────────────────────

  void _endRun() async {
    if (_phase == _RunPhase.ended) return;
    _pulseCtrl.stop();
    setState(() => _phase = _RunPhase.ended);

    if (!_scoreSaved) {
      _scoreSaved = true;
      if (widget.runNumber == 1) {
        await _storage.saveRun1(_score);
      } else {
        await _storage.saveRun2(_score);
      }
    }

    sfx.dailyComplete();
    if (!mounted) return;

    final lastTarget = _target;
    final lastDice = _originalDice.toList();

    if (widget.runNumber == 1) {
      final int savedScore = _score;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (ctx) => RushDailyBetweenScreen(
            run1Score: savedScore,
            lastPuzzleTarget: lastTarget,
            lastPuzzleDice: lastDice,
            onStartRun2: () => Navigator.of(ctx).pushReplacement(
              MaterialPageRoute(
                builder: (_) => RushDailyScreen(runNumber: 2, run1Score: savedScore),
              ),
            ),
          ),
        ),
      );
    } else {
      final state = await _storage.load();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RushDailyResultScreen(
            run1Score: widget.run1Score,
            run2Score: _score,
            allTimeBest: state.allTimeBest,
            lastPuzzleTarget: lastTarget,
            lastPuzzleDice: lastDice,
          ),
        ),
      );
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  Color _timerColor() {
    final s = _remaining.inSeconds;
    if (s <= 10) return _timerRed;
    if (s <= 20) return _timerAmber;
    return Colors.white;
  }

  bool get _timerWarning => _remaining.inSeconds <= 20;

  String _formatRemaining() {
    final m = _remaining.inMinutes;
    final s = _remaining.inSeconds % 60;
    if (m > 0) return '${m}m ${s.toString().padLeft(2, '0')}s';
    return '${s}s';
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final canUndo = _undoStack.isNotEmpty && _isPlaying;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop && _phase == _RunPhase.running) {
          await _saveCurrentScore();
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: const Color(0xFF020408),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () async {
              if (_phase == _RunPhase.running) await _saveCurrentScore();
              if (mounted) Navigator.of(context).pop();
            },
            enableFeedback: false,
            color: _ink.withValues(alpha: 0.70),
          ),
          title: Text(
            'Daily Run ${widget.runNumber}',
            style: const TextStyle(
              color: Colors.white,
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
                      const SizedBox(height: AppSpacing.lg),
                      _buildActionRow(),
                      SizedBox(height: AppSpacing.lg + bottomInset * 0.5),
                    ],
                  ),
                ),
                _buildPlusOneOverlay(),
              ],
            ),
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Run ${widget.runNumber} of 2',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.38),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              'Score: $_score',
              style: const TextStyle(
                fontSize: 22,
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const Spacer(),
        ScaleTransition(
          scale: _pulseScale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _timerWarning ? const Color(0xFF000508) : Colors.white.withValues(alpha: 0.07),
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
              _formatRemaining(),
              style: TextStyle(
                fontSize: 22,
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
      ],
    );
  }

  /// Skip (links) + Hint (rechts) — je 1× verwendbar
  Widget _buildActionRow() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.skip_next_rounded,
            label: _skipUsed ? 'Skipped' : 'Skip',
            enabled: _canSkip,
            onTap: _skip,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionButton(
            icon: Icons.lightbulb_outline_rounded,
            label: _hintUsed ? 'Hint used' : 'Hint',
            enabled: _canHint,
            onTap: _showHint,
            activeColor: _cyan,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
    Color? activeColor,
  }) {
    final color = enabled
        ? (activeColor ?? Colors.white).withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.18);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(
            color: enabled
                ? (activeColor ?? Colors.white).withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.07),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 17),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ),
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
                child: const Text(
                  '+1',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: AppColors.accent,
                    shadows: [Shadow(color: AppColors.accent, blurRadius: 14)],
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

// ── Undo snapshot ──────────────────────────────────────────────────────────────

class _UndoSnapshot {
  final List<DiceState> dice;
  final int moves;
  const _UndoSnapshot({required this.dice, required this.moves});
}
