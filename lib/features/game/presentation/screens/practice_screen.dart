import 'dart:async';

import 'package:flutter/material.dart';

import 'package:dice/core/audio/sfx_singleton.dart';
import 'package:dice/core/difficulty_config.dart';
import 'package:dice/core/extensions/difficulty_extensions.dart';
import 'package:dice/core/game_rules.dart';
import 'package:dice/core/puzzle/game_mode.dart';
import 'package:dice/core/puzzle/puzzle.dart';
import 'package:dice/core/puzzle/puzzle_coordinator.dart';
import 'package:dice/core/puzzle/puzzle_generator.dart';
import 'package:dice/core/puzzle/puzzle_seed.dart';
import 'package:dice/core/theme/app_colors.dart';
import 'package:dice/core/theme/app_durations.dart';
import 'package:dice/core/theme/app_radius.dart';
import 'package:dice/core/theme/app_spacing.dart';
import 'package:dice/core/theme/app_text_styles.dart';
import 'package:dice/core/ui_op.dart';
import 'package:dice/features/game/logic/move_application_service.dart';
import 'package:dice/features/game/logic/round_evaluator.dart';
import 'package:dice/features/game/logic/solver_service.dart';
import 'package:dice/features/game/models/dice_state.dart';
import 'package:dice/features/game/models/game_state.dart';
import 'package:dice/features/game/models/practice_round_summary.dart';
import 'package:dice/features/game/presentation/animations/dice_roll_controller.dart';
import 'package:dice/features/game/presentation/animations/target_roll_controller.dart';
import 'package:dice/features/game/presentation/coordinators/practice_round_flow_coordinator.dart';
import 'package:dice/features/game/presentation/widgets/practice_bottom_buttons.dart';
import 'package:dice/features/game/presentation/widgets/practice_dice_row.dart';
import 'package:dice/features/game/presentation/widgets/practice_result_overlay.dart';
import 'package:dice/features/game/presentation/widgets/practice_top_controls_bar.dart';
import 'package:dice/features/game/presentation/widgets/solution_impossible_dialog.dart';
import 'package:dice/features/game/presentation/widgets/target_display_widget.dart';
import 'package:dice/features/game/presentation/widgets/practice_game_area.dart';

enum RoundPhase { preStart, rolling, playing, ended }

enum EndReason { solved, failed, timeout }

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

abstract class ModeClock {
  const ModeClock();

  bool get enabled;

  bool isExpired({
    required Duration puzzleElapsed,
    required Duration runElapsed,
  });
}

class NoClock extends ModeClock {
  const NoClock();

  @override
  bool get enabled => false;

  @override
  bool isExpired({
    required Duration puzzleElapsed,
    required Duration runElapsed,
  }) {
    return false;
  }
}

class PerPuzzleClock extends ModeClock {
  final Duration limit;
  const PerPuzzleClock(this.limit);

  @override
  bool get enabled => true;

  @override
  bool isExpired({
    required Duration puzzleElapsed,
    required Duration runElapsed,
  }) {
    return puzzleElapsed >= limit;
  }
}

class RunClock extends ModeClock {
  final Duration total;
  const RunClock(this.total);

  @override
  bool get enabled => true;

  @override
  bool isExpired({
    required Duration puzzleElapsed,
    required Duration runElapsed,
  }) {
    return runElapsed >= total;
  }
}

class _PracticeScreenState extends State<PracticeScreen>
    with TickerProviderStateMixin {
  final SolverService _solverService = SolverService();
  final PuzzleGenerator _puzzleGenerator = PuzzleGenerator();
  final GameRules _gameRules = GameRules();
  final RoundEvaluator _roundEvaluator = const RoundEvaluator();
  final MoveApplicationService _moveApplicationService =
      const MoveApplicationService();

  final Stopwatch _solveWatch = Stopwatch();
  final Stopwatch _runWatch = Stopwatch();
  Duration _lastSolveTime = Duration.zero;

  static const Color _card = AppColors.card;
  static const Color _accent = AppColors.accent;
  static const Color _ink = AppColors.ink;

  late PracticeGameState _gameState;

  late final TargetRollController _targetRollController;
  late final DiceRollController _diceRollController;
  late final PracticeRoundFlowCoordinator _roundFlowCoordinator;
  late PuzzleCoordinator _puzzleCoordinator;

  Difficulty _difficulty = Difficulty.easy;
  bool _showMergedResults = true;
  RoundPhase _phase = RoundPhase.preStart;

  DifficultyConfig get _config {
    switch (_difficulty) {
      case Difficulty.easy:
        return DifficultyConfig.easy;
      case Difficulty.medium:
        return DifficultyConfig.medium;
      case Difficulty.hard:
        return DifficultyConfig.hard;
    }
  }

  ModeClock _clock = const NoClock();

  List<int> _initialDice = [];
  int _initialTarget = 0;

  final Set<int> _selected = <int>{};
  bool _busy = false;

  bool _resultDialogOpen = false;

  int _mergePopKey = 0;

  Timer? _timeoutTimer;

  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;
  Timer? _invalidTimer;

  late final AnimationController _celebrateCtrl;
  late final Animation<double> _celebrateT;

  final List<_UndoSnapshot> _undoStack = <_UndoSnapshot>[];
  static const int _maxUndo = 30;

  bool _rollAfterNoSolutionArmed = false;

  @override
  void initState() {
    super.initState();

    _gameState = PracticeGameState.initial();

    _targetRollController = TargetRollController()..startIdle(initialValue: 0);
    _diceRollController = DiceRollController()
      ..startIdle(initialDice: List<int>.filled(5, 1));

    _roundFlowCoordinator = PracticeRoundFlowCoordinator(
      targetRollController: _targetRollController,
      diceRollController: _diceRollController,
    );

    _puzzleCoordinator = PuzzleCoordinator(
      generator: _puzzleGenerator,
      mode: GameMode.practice,
      config: _config,
      baseSeed: PuzzleSeed.practiceSeed(),
    );

    _shakeCtrl = AnimationController(vsync: this, duration: AppDurations.shake);

    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeOut));

    _celebrateCtrl = AnimationController(
      vsync: this,
      duration: AppDurations.celebrate,
    );

    _celebrateT = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 45,
      ),
    ]).animate(_celebrateCtrl);

    _goToPreStart();
  }

  @override
  void dispose() {
    _targetRollController.dispose();
    _diceRollController.dispose();

    _timeoutTimer?.cancel();
    _invalidTimer?.cancel();

    _shakeCtrl.dispose();
    _celebrateCtrl.dispose();

    super.dispose();
  }

  bool get _isPreStart => _phase == RoundPhase.preStart;
  bool get _isRolling => _phase == RoundPhase.rolling;
  bool get _isPlaying => _phase == RoundPhase.playing;

  bool get _soundEnabled => _gameState.soundEnabled;
  UiOp? get _selectedOp => _gameState.selectedOp;

  bool get _canInteractGameplay {
    if (_busy) return false;
    if (_phase != RoundPhase.playing) return false;
    if (_isRolling) return false;
    if (_resultDialogOpen) return false;
    return true;
  }

  bool get _canPressBottom {
    if (_busy) return false;
    if (_isRolling) return false;
    if (_resultDialogOpen) return false;
    return true;
  }

  void _clearPendingOp() {
    _gameState = _gameState.copyWith(clearSelectedOp: true);
  }

  void _cancelTimeoutTicker() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  void _cancelRollingControllers() {
    _targetRollController.cancel();
    _diceRollController.cancel();
  }

  void _startTimeoutTickerIfNeeded() {
    _cancelTimeoutTicker();
    if (!_clock.enabled) return;

    _timeoutTimer = Timer.periodic(AppDurations.timeoutTick, (_) {
      if (!mounted) return;
      _checkTimeoutTick();
    });
  }

  void _playTargetCelebrate() {
    if (!mounted) return;
    _celebrateCtrl.forward(from: 0);
  }

  void _handleRoundEndFeedback(bool solved) {
    if (solved) {
      _playTargetCelebrate();

      if (_soundEnabled) {
        sfx.win();
      }
    } else {
      if (_soundEnabled) {
        sfx.lose();
      }
    }
  }

  void _goToPreStart() {
    _cancelRollingControllers();
    _cancelTimeoutTicker();
    _invalidTimer?.cancel();

    _roundFlowCoordinator.resetToIdle(
      initialTarget: 0,
      initialDice: List<int>.filled(5, 1),
    );

    final currentSoundEnabled = _gameState.soundEnabled;

    setState(() {
      _resultDialogOpen = false;
      _mergePopKey = 0;

      _gameRules.reset();

      _solveWatch.reset();
      _lastSolveTime = Duration.zero;

      _runWatch.reset();

      _busy = false;
      _phase = RoundPhase.preStart;

      _initialTarget = 0;
      _initialDice = [];

      _selected.clear();

      _clearPendingOp();

      _undoStack.clear();

      _rollAfterNoSolutionArmed = false;

      _gameState = PracticeGameState.initial().copyWith(
        soundEnabled: currentSoundEnabled,
      );
    });
  }

  Future<void> _newGame() async {
    if (_busy) return;

    if (_soundEnabled) {
      sfx.click();
    }

    await startRound();
  }

  Future<void> _startNextPuzzleKeepingTarget() async {
    await startRound(clock: _clock, resetRun: false, keepTarget: true);
  }

  Puzzle _createRoundPuzzle({
    required DifficultyConfig config,
    required bool keepTarget,
    int? seed,
    int? puzzleIndex,
    Difficulty? difficulty,
  }) {
    final wasReconfigured =
        difficulty != null || seed != null || puzzleIndex != null;

    _puzzleCoordinator.reconfigureIfNeeded(
      config: config,
      seed: seed,
      puzzleIndex: puzzleIndex,
    );

    return _puzzleCoordinator.createRoundPuzzle(
      keepTarget: keepTarget,
      fixedTarget: keepTarget ? _gameState.target : null,
      wasReconfigured: wasReconfigured,
    );
  }

  void _handleRollingUiState({
    required bool isRollingTarget,
    required bool isRollingDice,
    int? target,
  }) {
    if (!mounted) return;

    setState(() {
      _gameState = _gameState.copyWith(
        target: target ?? _gameState.target,
        isRollingTarget: isRollingTarget,
        isRollingDice: isRollingDice,
      );
    });
  }

  Future<void> _rollAndApplyPuzzle({
    required Puzzle puzzle,
    required Difficulty difficulty,
    required DifficultyConfig config,
    required bool keepTarget,
  }) async {
    final rolledPuzzle = await _roundFlowCoordinator.rollPuzzle(
      puzzle: puzzle,
      difficulty: difficulty,
      config: config,
      random: _puzzleCoordinator.createAnimationRandom(),
      keepTarget: keepTarget,
      isActive: () => mounted,
      onUiState: _handleRollingUiState,
    );

    if (!mounted || rolledPuzzle == null) {
      return;
    }

    _applyRolledPuzzle(rolledPuzzle);
  }

  Future<void> startRound({
    int? seed,
    int? puzzleIndex,
    Difficulty? difficulty,
    ModeClock? clock,
    bool resetRun = true,
    bool keepTarget = false,
  }) async {
    if (_busy) return;

    _rollAfterNoSolutionArmed = false;

    final effDifficulty = difficulty ?? _difficulty;
    final effConfig = _difficultyToConfig(effDifficulty);
    final effClock = clock ?? _clockFromConfig(effConfig);

    final puzzle = _createRoundPuzzle(
      config: effConfig,
      keepTarget: keepTarget,
      seed: seed,
      puzzleIndex: puzzleIndex,
      difficulty: difficulty,
    );

    _prepareRoundStart(clock: effClock, resetRun: resetRun);
    _prepareRollingPhase(keepTarget: keepTarget);

    await _rollAndApplyPuzzle(
      puzzle: puzzle,
      difficulty: effDifficulty,
      config: effConfig,
      keepTarget: keepTarget,
    );
  }

  void _prepareRoundStart({required ModeClock clock, required bool resetRun}) {
    _clock = clock;

    if (resetRun) {
      _runWatch
        ..reset()
        ..start();
    } else {
      if (_clock is RunClock && !_runWatch.isRunning) {
        _runWatch.start();
      }
    }

    _resultDialogOpen = false;

    _busy = true;
    _selected.clear();
    _gameState = _gameState.copyWith(moves: 0);
    _solveWatch.reset();
    _lastSolveTime = Duration.zero;
    _clearPendingOp();
    _undoStack.clear();
    _cancelTimeoutTicker();
    _cancelRollingControllers();
  }

  void _prepareRollingPhase({required bool keepTarget}) {
    setState(() {
      _phase = RoundPhase.rolling;
      _gameState = _gameState.copyWith(
        moves: 0,
        isRollingTarget: !keepTarget,
        isRollingDice: true,
        isRoundEnded: false,
        clearSelectedOp: true,
        clearSelectedDieIndex: true,
        clearRevealedSolution: true,
        clearRoundResult: true,
      );
    });
  }

  List<DiceState> _toDiceStateList(List<int> values) {
    return values.map((v) => DiceState(value: v, maskLabel: null)).toList();
  }

  void _enterPlayableRoundState({
    required int target,
    required List<int> diceValues,
  }) {
    final diceState = _toDiceStateList(diceValues);

    _roundFlowCoordinator.resetToIdle(
      initialTarget: target,
      initialDice: List<int>.from(diceValues),
    );

    setState(() {
      _initialTarget = target;
      _initialDice = List<int>.from(diceValues);

      _phase = RoundPhase.playing;
      _busy = false;

      _selected.clear();
      _undoStack.clear();

      _gameState = _gameState.copyWith(
        target: target,
        dice: diceState,
        moves: 0,
        isRollingTarget: false,
        isRollingDice: false,
        isRoundEnded: false,
        clearSelectedOp: true,
        clearSelectedDieIndex: true,
        clearRevealedSolution: true,
        clearRoundResult: true,
      );
    });

    _gameRules.start(target);

    _solveWatch
      ..reset()
      ..start();

    _lastSolveTime = Duration.zero;

    _startTimeoutTickerIfNeeded();
  }

  void _applyRolledPuzzle(Puzzle puzzle) {
    _cancelRollingControllers();
    if (!mounted) return;

    _enterPlayableRoundState(target: puzzle.target, diceValues: puzzle.dice);
  }

  void _resetDice() {
    if (_busy) return;

    if (_soundEnabled) {
      sfx.click();
    }

    if (_initialDice.isEmpty || _initialTarget == 0) {
      _goToPreStart();
      return;
    }

    _resultDialogOpen = false;

    _enterPlayableRoundState(target: _initialTarget, diceValues: _initialDice);
  }

  Future<void> _impossible() async {
    if (_busy) return;
    if (_isPreStart) {
      _showInfo('Press New Game first.');
      return;
    }
    if (!_isPlaying) return;
    if (_resultDialogOpen) return;

    setState(() => _busy = true);

    try {
      final startVals = _initialDice.isNotEmpty
          ? List<int>.from(_initialDice)
          : _gameState.dice.map((d) => d.value).toList();

      final res = _solverService.check(
        diceValues: startVals,
        target: _gameState.target,
      );

      if (res.solvable) {
        if (_soundEnabled) {
          sfx.lose();
        }
        _rollAfterNoSolutionArmed = false;

        await showSolutionOrImpossibleDialog(
          context: context,
          solvable: true,
          startDiceValues: startVals,
          target: _gameState.target,
          fullExpression: res.fullExpression,
        );

        if (!mounted) return;
        setState(() {
          _phase = RoundPhase.ended;
          _busy = false;
          _gameState = _gameState.copyWith(isRoundEnded: true);
        });
        _cancelTimeoutTicker();
        return;
      }

      if (_soundEnabled) {
        sfx.win();
      }
      _rollAfterNoSolutionArmed = true;

      await showSolutionOrImpossibleDialog(
        context: context,
        solvable: false,
        startDiceValues: startVals,
        target: _gameState.target,
        fullExpression: null,
      );

      if (!mounted) return;

      setState(() => _busy = false);

      await _rerollDiceAfterImpossibleWithAnimation();
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      rethrow;
    }
  }

  Future<void> _rerollDiceAfterImpossibleWithAnimation() async {
    _cancelTimeoutTicker();
    _cancelRollingControllers();

    if (_rollAfterNoSolutionArmed && _soundEnabled) {
      sfx.roll();
      _rollAfterNoSolutionArmed = false;
    } else {
      _rollAfterNoSolutionArmed = false;
    }

    await _startNextPuzzleKeepingTarget();
  }

  void _toggleSelect(int index) {
    if (!_canInteractGameplay) return;
    if (index < 0 || index >= _gameState.dice.length) return;

    setState(() {
      final wasSelected = _selected.contains(index);

      if (wasSelected) {
        final wasSingle = _selected.length == 1;
        _selected.remove(index);

        if (wasSingle) {
          _clearPendingOp();
        }
      } else {
        _selected.add(index);
      }
    });

    if (_selectedOp != null && _selected.length == 2) {
      final op = _selectedOp!;
      _clearPendingOp();
      _applyOpInternal(op);
    }
  }

  void _applyOp(UiOp op) {
    if (!_canInteractGameplay) return;

    if (_selectedOp == op) {
      setState(() {
        _clearPendingOp();
      });
      return;
    }

    if (_selected.length == 1) {
      setState(() {
        _gameState = _gameState.copyWith(selectedOp: op);
      });
      return;
    }

    if (_selected.length < 2) {
      _invalidMove(message: 'Select at least 2 dice');
      return;
    }

    _applyOpInternal(op);
  }

  void _pushUndo() {
    final snap = _UndoSnapshot(
      dice: _gameState.dice
          .map((d) => DiceState(value: d.value, maskLabel: d.maskLabel))
          .toList(),
      moves: _gameState.moves,
    );

    _undoStack.add(snap);

    if (_undoStack.length > _maxUndo) {
      _undoStack.removeAt(0);
    }
  }

  void _undo() {
    if (!_canInteractGameplay) return;
    if (_undoStack.isEmpty) return;

    final snapshot = _undoStack.removeLast();

    setState(() {
      _selected.clear();
      _clearPendingOp();

      _gameState = _gameState.copyWith(
        dice: snapshot.dice
            .map((d) => DiceState(value: d.value, maskLabel: d.maskLabel))
            .toList(),
        moves: snapshot.moves,
        clearSelectedOp: true,
        clearSelectedDieIndex: true,
      );
    });
  }

  void _applyOpInternal(UiOp op) {
    if (_selected.length < 2) return;

    final currentDice = _gameState.dice;

    final move = _moveApplicationService.buildMove(
      diceValues: currentDice.map((d) => d.value).toList(),
      selectedIndices: _selected.toList(),
      op: op,
    );

    if (move == null) {
      _invalidMove();
      return;
    }

    _pushUndo();

    final remainingDice = List<DiceState>.from(currentDice);

    for (final i in move.removeIndicesDesc) {
      remainingDice.removeAt(i);
    }

    final mergedMask = _showMergedResults ? null : _nextQuestionMarkLabel();

    remainingDice.add(
      DiceState(value: move.mergedValue, maskLabel: mergedMask),
    );

    _gameRules.registerMove();

    final progress = _moveApplicationService.registerMove(
      currentMoves: _gameState.moves,
    );

    setState(() {
      _gameState = _gameState.copyWith(
        dice: remainingDice,
        moves: progress.moves,
        clearSelectedOp: true,
        clearSelectedDieIndex: true,
      );

      _selected.clear();
      _mergePopKey++;
    });

    if (!move.willEndAfterMove && _soundEnabled) {
      sfx.valid();
    }

    _checkEnd();
  }

  String _nextQuestionMarkLabel() {
    final used = <int>{};
    for (final d in _gameState.dice) {
      final s = d.maskLabel;
      if (s == null) continue;
      if (s == '?') {
        used.add(1);
        continue;
      }
      if (s.startsWith('?')) {
        final n = int.tryParse(s.substring(1));
        if (n != null && n > 0) {
          used.add(n);
        }
      }
    }

    var next = 1;
    while (used.contains(next)) {
      next++;
    }
    return next == 1 ? '?' : '?$next';
  }

  void _invalidMove({String message = 'Invalid move'}) {
    if (!mounted) return;

    if (_soundEnabled) {
      sfx.invalid();
    }

    _shakeCtrl.forward(from: 0);

    _invalidTimer?.cancel();
    _invalidTimer = Timer(AppDurations.invalidOverlay, () {
      if (!mounted) return;
    });

    _showInfo(message);
  }

  Future<void> _checkEnd() async {
    if (_gameState.dice.length != 1) return;

    final finalVal = _gameState.dice.first.value;
    final result = _roundEvaluator.evaluate(
      target: _gameState.target,
      finalValue: finalVal,
      rules: _gameRules,
    );

    final solved = result == GameState.solved;

    await _endRound(
      reason: solved ? EndReason.solved : EndReason.failed,
      solved: solved,
      title: solved ? 'Solved!' : 'Not Solved',
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    final cs = (d.inMilliseconds % 1000) ~/ 10;
    return '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}.'
        '${cs.toString().padLeft(2, '0')}';
  }

  PracticeRoundSummary _buildRoundSummary({
    required String title,
    required bool solved,
  }) {
    int finalValue = 0;
    if (_gameState.dice.isNotEmpty) {
      finalValue = _gameState.dice.first.value;
    }

    final delta = (finalValue - _gameState.target).abs();

    return PracticeRoundSummary(
      title: title,
      target: _gameState.target,
      finalValue: finalValue,
      delta: delta,
      moves: _gameState.moves,
      timeText: _fmt(_lastSolveTime),
      isSolved: solved,
    );
  }

  Future<void> _showRoundResultOverlay(PracticeRoundSummary summary) async {
    await showPracticeResultOverlay(
      context: context,
      title: summary.title,
      target: summary.target,
      finalValue: summary.finalValue,
      delta: summary.delta,
      moves: summary.moves,
      timeText: summary.timeText,
      isSolved: summary.isSolved,
      onRetry: () {
        Navigator.of(context).pop();
        _resetDice();
      },
    );
  }

  Future<void> _endRound({
    required EndReason reason,
    required bool solved,
    required String title,
  }) async {
    if (_resultDialogOpen) return;
    _resultDialogOpen = true;

    try {
      _solveWatch.stop();
      _lastSolveTime = _solveWatch.elapsed;

      _gameRules.finish(_lastSolveTime);
      _cancelTimeoutTicker();

      if (mounted) {
        setState(() {
          _phase = RoundPhase.ended;
          _gameState = _gameState.copyWith(isRoundEnded: true);
        });
      }

      final summary = _buildRoundSummary(title: title, solved: solved);

      _handleRoundEndFeedback(solved);

      await _showRoundResultOverlay(summary);

      if (mounted && _phase == RoundPhase.ended) {
        setState(() {
          _phase = RoundPhase.preStart;
        });
      }
    } finally {
      _resultDialogOpen = false;
    }
  }

  Future<void> _checkTimeoutTick() async {
    if (!_clock.enabled) return;
    if (!_canInteractGameplay) return;
    if (_gameRules.state != GameState.playing) return;

    final puzzleElapsed = _solveWatch.elapsed;
    final runElapsed = _runWatch.elapsed;

    if (!_clock.isExpired(
      puzzleElapsed: puzzleElapsed,
      runElapsed: runElapsed,
    )) {
      return;
    }

    _gameRules.markTimeout();

    await _endRound(
      reason: EndReason.timeout,
      solved: false,
      title: "Time’s up",
    );
  }

  void _showInfo(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: AppTextStyles.snackbar),
        behavior: SnackBarBehavior.floating,
        duration: AppDurations.snackbar,
      ),
    );
  }

  Future<void> _openSettingsSheet() async {
    if (_busy) return;

    var tempDifficulty = _difficulty;
    var tempShowMerged = _showMergedResults;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            Widget radioRow(Difficulty d) {
              return InkWell(
                onTap: () => setLocal(() => tempDifficulty = d),
                borderRadius: BorderRadius.circular(AppRadius.medium),
                enableFeedback: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Radio<Difficulty>(value: d),
                      const SizedBox(width: AppSpacing.sm),
                      Text(d.label, style: AppTextStyles.labelLarge),
                    ],
                  ),
                ),
              );
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: RadioGroup<Difficulty>(
                  groupValue: tempDifficulty,
                  onChanged: (Difficulty? value) {
                    if (value == null) return;
                    setLocal(() => tempDifficulty = value);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: AppSpacing.xs),
                      const Text('Settings', style: AppTextStyles.sheetTitle),
                      const SizedBox(height: AppSpacing.sm),
                      const Divider(height: 1),
                      radioRow(Difficulty.easy),
                      radioRow(Difficulty.medium),
                      radioRow(Difficulty.hard),
                      const Divider(height: 1),
                      SwitchListTile.adaptive(
                        value: tempShowMerged,
                        onChanged: (v) => setLocal(() => tempShowMerged = v),
                        activeThumbColor: _accent,
                        title: const Text(
                          'Show merged result',
                          style: AppTextStyles.bodyStrong,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.md,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.button,
                                    ),
                                  ),
                                  enableFeedback: false,
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: AppTextStyles.buttonMedium,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  final difficultyChanged =
                                      tempDifficulty != _difficulty;
                                  setState(() {
                                    _difficulty = tempDifficulty;
                                    _showMergedResults = tempShowMerged;
                                  });
                                  if (difficultyChanged) {
                                    _puzzleCoordinator.reconfigure(
                                      config: _difficultyToConfig(_difficulty),
                                      baseSeed: PuzzleSeed.practiceSeed(),
                                      startIndex: 0,
                                    );
                                    _goToPreStart();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _accent,
                                  foregroundColor: AppColors.onAccent,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.md,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.button,
                                    ),
                                  ),
                                  enableFeedback: false,
                                ),
                                child: const Text(
                                  'Apply',
                                  style: AppTextStyles.buttonOnAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _toggleSound() {
    final next = !_gameState.soundEnabled;

    setState(() {
      _gameState = _gameState.copyWith(soundEnabled: next);
    });

    if (next) {
      sfx.click();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    final bottomInset = mq.viewPadding.bottom;
    final showDice = !_isPreStart;

    return Theme(
      data: Theme.of(context).copyWith(
        appBarTheme: const AppBarTheme(
          foregroundColor: AppColors.ink,
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          titleTextStyle: AppTextStyles.appBarTitle,
          iconTheme: IconThemeData(color: AppColors.ink),
        ),
      ),
      child: Scaffold(
        extendBodyBehindAppBar: false,
        appBar: AppBar(
          title: const Text('Dice Target'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).maybePop(),
            enableFeedback: false,
          ),
          actions: [
            IconButton(
              tooltip: 'Settings',
              onPressed: _busy ? null : _openSettingsSheet,
              icon: const Icon(Icons.tune_rounded),
              enableFeedback: false,
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.bgTop, AppColors.bgBottom],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  bottom: bottomInset,
                ),
                child: Column(
                  children: [
                    PracticeTopControlsBar(
                      cardColor: _card,
                      accentColor: _accent,
                      inkColor: _ink,
                      difficultyLabel: _difficulty.label,
                      soundOn: _gameState.soundEnabled,
                      onToggleSound: _toggleSound,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TargetDisplayWidget(
                      isPreStart: _isPreStart,
                      isRolling: _isRolling,
                      target: _gameState.target,
                      cardColor: _card,
                      accentColor: _accent,
                      inkColor: _ink,
                      rollingTargetListenable: _targetRollController.value,
                      celebrateAnimation: _celebrateT,
                    ),
                    Expanded(
                      child: PracticeGameArea(
                        showDice: showDice,
                        isRolling: _isRolling,
                        isPlaying: _isPlaying,
                        busy: _busy,
                        showMergedResults: _showMergedResults,
                        mergePopKey: _mergePopKey,
                        selectedIndices: _selected,
                        accentColor: _accent,
                        inkColor: _ink,
                        shakeAnimation: _shakeAnim,
                        rollingDiceListenable: _diceRollController.dice,
                        rollingTargetLocked: _targetRollController.locked.value,
                        dice: _gameState.dice
                            .map(
                              (d) => PracticeDieData(
                                value: d.value,
                                maskLabel: d.maskLabel,
                              ),
                            )
                            .toList(),
                        canInteractGameplay: _canInteractGameplay,
                        allowedOps: _config.allowedOps,
                        pendingOp: _selectedOp,
                        undoEnabled:
                            _canInteractGameplay && _undoStack.isNotEmpty,
                        onToggleSelect: _toggleSelect,
                        onApplyOp: _applyOp,
                        onUndo: _undo,
                      ),
                    ),
                    PracticeBottomButtons(
                      canPressBottom: _canPressBottom,
                      isPlaying: _isPlaying,
                      canReset:
                          _canPressBottom &&
                          _isPlaying &&
                          _undoStack.isNotEmpty,
                      accentColor: _accent,
                      inkColor: _ink,
                      onNoSolution: _impossible,
                      onResetDice: _resetDice,
                      onNewGame: _newGame,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  DifficultyConfig _difficultyToConfig(Difficulty d) {
    switch (d) {
      case Difficulty.easy:
        return DifficultyConfig.easy;
      case Difficulty.medium:
        return DifficultyConfig.medium;
      case Difficulty.hard:
        return DifficultyConfig.hard;
    }
  }

  ModeClock _clockFromConfig(DifficultyConfig c) {
    final limit = c.timeLimit;
    if (limit == null) return const NoClock();
    return PerPuzzleClock(limit);
  }
}

class _UndoSnapshot {
  final List<DiceState> dice;
  final int moves;

  const _UndoSnapshot({required this.dice, required this.moves});
}
