// lib/features/game/presentation/screens/practice_screen.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:dice/core/audio/sfx_singleton.dart';
import 'package:dice/core/difficulty_config.dart';
import 'package:dice/core/extensions/difficulty_extensions.dart';
import 'package:dice/core/game_rules.dart';
import 'package:dice/core/theme/app_colors.dart';
import 'package:dice/core/theme/app_durations.dart';
import 'package:dice/core/theme/app_radius.dart';
import 'package:dice/core/theme/app_spacing.dart';
import 'package:dice/core/theme/app_text_styles.dart';
import 'package:dice/core/ui_op.dart';
import 'package:dice/features/game/logic/move_application_service.dart';
import 'package:dice/features/game/logic/round_engine.dart';
import 'package:dice/features/game/logic/round_evaluator.dart';
import 'package:dice/features/game/logic/solver_service.dart';
import 'package:dice/features/game/models/dice_state.dart';
import 'package:dice/features/game/models/game_state.dart';
import 'package:dice/features/game/presentation/widgets/practice_bottom_buttons.dart';
import 'package:dice/features/game/presentation/widgets/practice_dice_row.dart';
import 'package:dice/features/game/presentation/widgets/practice_ops_row.dart';
import 'package:dice/features/game/presentation/widgets/practice_result_overlay.dart';
import 'package:dice/features/game/presentation/widgets/practice_small_actions_row.dart';
import 'package:dice/features/game/presentation/widgets/practice_target_bar.dart';
import 'package:dice/features/game/presentation/widgets/practice_top_controls_bar.dart';
import 'package:dice/features/game/presentation/widgets/solution_impossible_dialog.dart';

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

class _Puzzle {
  final int target;
  final List<int> dice;
  final int seed;
  const _Puzzle({required this.target, required this.dice, required this.seed});
}

class _PracticeScreenState extends State<PracticeScreen>
    with TickerProviderStateMixin {
  Random? _rng;
  final SolverService _solverService = SolverService();
  final GameRules _gameRules = GameRules();
  final RoundEngine _roundEngine = const RoundEngine();
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

  int _roundSeed = 0;
  int _puzzleIndex = 0;

  _Puzzle? _pendingPuzzle;

  List<int> _initialDice = [];
  int _initialTarget = 0;

  final Set<int> _selected = <int>{};
  bool _busy = false;

  bool _resultDialogOpen = false;

  int _mergePopKey = 0;

  final ValueNotifier<int> _rollingTargetN = ValueNotifier<int>(0);
  final ValueNotifier<List<int>> _rollingDiceN = ValueNotifier<List<int>>(
    List<int>.filled(5, 1),
  );
  bool _rollingTargetLocked = false;
  Timer? _rollTimer;
  Timer? _endTimer;

  Ticker? _rollTicker;
  Duration _lastRollFrameTime = Duration.zero;

  int _rollIntervalMs = 80;

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
    _stopRollTicker();

    _rollTimer?.cancel();
    _endTimer?.cancel();
    _timeoutTimer?.cancel();
    _invalidTimer?.cancel();

    _shakeCtrl.dispose();
    _celebrateCtrl.dispose();

    _rollingTargetN.dispose();
    _rollingDiceN.dispose();

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

  void _stopRollTicker() {
    _rollTicker?.stop();
    _rollTicker?.dispose();
    _rollTicker = null;
    _lastRollFrameTime = Duration.zero;
  }

  void _startRollTicker({
    required bool rollTarget,
    required bool rollDice,
    required DifficultyConfig effConfig,
  }) {
    _stopRollTicker();

    _rollTicker = createTicker((elapsed) {
      if (!mounted) return;

      final last = _lastRollFrameTime;
      if (last != Duration.zero &&
          (elapsed - last).inMilliseconds < _rollIntervalMs) {
        return;
      }
      _lastRollFrameTime = elapsed;

      if (rollTarget && !_rollingTargetLocked) {
        _rollingTargetN.value = _rng!.nextInt(effConfig.maxTarget) + 1;
      }

      if (rollDice) {
        _rollingDiceN.value = List<int>.generate(
          5,
          (_) => _rng!.nextInt(6) + 1,
        );
      }
    });

    _rollTicker!.start();
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

  void _goToPreStart() {
    _rollTimer?.cancel();
    _stopRollTicker();
    _endTimer?.cancel();
    _cancelTimeoutTicker();
    _invalidTimer?.cancel();

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

      _rollingTargetN.value = 0;
      _rollingDiceN.value = List<int>.filled(5, 1);
      _rollingTargetLocked = false;

      _clearPendingOp();

      _undoStack.clear();

      _pendingPuzzle = null;

      _rollAfterNoSolutionArmed = false;

      _gameState = PracticeGameState.initial();
    });
  }

  void _newGame() {
    if (_busy) return;

    if (_soundEnabled) {
      sfx.click();
    }

    startRound();
  }

  void startRound({
    int? seed,
    int? puzzleIndex,
    Difficulty? difficulty,
    ModeClock? clock,
    bool resetRun = true,
    bool keepTarget = false,
  }) {
    if (_busy) return;

    _rollAfterNoSolutionArmed = false;

    final effDifficulty = difficulty ?? _difficulty;
    final effConfig = _difficultyToConfig(effDifficulty);

    final effClock = clock ?? _clockFromConfig(effConfig);
    final effPuzzleIndex = puzzleIndex ?? 0;

    final effSeed = seed ?? DateTime.now().microsecondsSinceEpoch;

    _roundSeed = effSeed;
    _puzzleIndex = effPuzzleIndex;
    _clock = effClock;

    _rng = Random(_mixSeed(_roundSeed, _puzzleIndex));

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

    final puzzle = keepTarget
        ? _generatePuzzle(
            config: effConfig,
            seed: _roundSeed,
            puzzleIndex: _puzzleIndex,
            keepTarget: true,
            fixedTarget: _gameState.target,
          )
        : (() {
            final puzzleRandom = Random(_mixSeed(_roundSeed, _puzzleIndex));
            final round = _roundEngine.startRound(
              config: effConfig,
              random: puzzleRandom,
            );

            return _Puzzle(
              target: round.target,
              dice: List<int>.from(round.dice),
              seed: _roundSeed,
            );
          })();

    _pendingPuzzle = puzzle;

    setState(() {
      _phase = RoundPhase.rolling;
      _rollingTargetLocked = false;
      _gameState = _gameState.copyWith(
        moves: 0,
        isRollingTarget: !keepTarget,
        isRollingDice: keepTarget,
        isRoundEnded: false,
        clearSelectedOp: true,
        clearSelectedDieIndex: true,
        clearRevealedSolution: true,
        clearRoundResult: true,
      );
    });

    _rollingTargetN.value = keepTarget
        ? puzzle.target
        : _rng!.nextInt(effConfig.maxTarget) + 1;
    _rollingDiceN.value = List<int>.filled(5, 1);

    _stopRollTicker();
    _rollTimer?.cancel();
    _endTimer?.cancel();

    if (!keepTarget) {
      _rollIntervalMs = switch (effDifficulty) {
        Difficulty.easy => 40,
        Difficulty.medium => 40,
        Difficulty.hard => 40,
      };

      _startRollTicker(rollTarget: true, rollDice: false, effConfig: effConfig);

      _endTimer = Timer(AppDurations.rollStart, () {
        if (!mounted) return;

        final finalTarget = _pendingPuzzle!.target;

        setState(() {
          _rollingTargetLocked = true;
          _gameState = _gameState.copyWith(
            target: finalTarget,
            isRollingTarget: false,
            isRollingDice: true,
          );
        });

        _rollingTargetN.value = finalTarget;

        _startRollTicker(
          rollTarget: false,
          rollDice: true,
          effConfig: effConfig,
        );

        _endTimer = Timer(AppDurations.rollTarget, () {
          _finalizePendingPuzzle();
        });
      });
    } else {
      setState(() {
        _rollingTargetN.value = puzzle.target;
        _rollingTargetLocked = true;
        _rollingDiceN.value = List<int>.generate(
          5,
          (_) => _rng!.nextInt(6) + 1,
        );
        _gameState = _gameState.copyWith(
          target: puzzle.target,
          isRollingTarget: false,
          isRollingDice: true,
        );
      });

      _rollIntervalMs = switch (effDifficulty) {
        Difficulty.easy => 55,
        Difficulty.medium => 55,
        Difficulty.hard => 55,
      };

      _startRollTicker(rollTarget: false, rollDice: true, effConfig: effConfig);

      _endTimer = Timer(AppDurations.rollDice, () {
        _finalizePendingPuzzle();
      });
    }
  }

  void _finalizePendingPuzzle() {
    _stopRollTicker();
    _rollTimer?.cancel();
    if (!mounted) return;

    final puzzle = _pendingPuzzle;
    if (puzzle == null) {
      setState(() {
        _phase = RoundPhase.preStart;
        _busy = false;
        _gameState = _gameState.copyWith(
          isRollingTarget: false,
          isRollingDice: false,
        );
      });
      return;
    }

    final finalizedDiceState = puzzle.dice
        .map((v) => DiceState(value: v, maskLabel: null))
        .toList();

    setState(() {
      _initialTarget = puzzle.target;
      _initialDice = List<int>.from(puzzle.dice);

      _phase = RoundPhase.playing;
      _busy = false;

      _undoStack.clear();

      _gameState = _gameState.copyWith(
        target: puzzle.target,
        dice: finalizedDiceState,
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

    _solveWatch
      ..reset()
      ..start();

    _gameRules.start(_gameState.target);
    _startTimeoutTickerIfNeeded();
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

    final resetDiceState = _initialDice
        .map((v) => DiceState(value: v, maskLabel: null))
        .toList();

    setState(() {
      _selected.clear();
      _phase = RoundPhase.playing;
      _clearPendingOp();

      _undoStack.clear();

      _gameState = _gameState.copyWith(
        target: _initialTarget,
        dice: resetDiceState,
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

    _gameRules.start(_gameState.target);

    _solveWatch
      ..reset()
      ..start();

    _lastSolveTime = Duration.zero;

    _startTimeoutTickerIfNeeded();
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
    _rollTimer?.cancel();
    _endTimer?.cancel();
    _cancelTimeoutTicker();

    if (_rollAfterNoSolutionArmed && _soundEnabled) {
      sfx.roll();
      _rollAfterNoSolutionArmed = false;
    } else {
      _rollAfterNoSolutionArmed = false;
    }

    startRound(
      seed: _roundSeed,
      puzzleIndex: _puzzleIndex + 1,
      difficulty: _difficulty,
      clock: _clock,
      resetRun: false,
      keepTarget: true,
    );
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

      int finalValue = 0;
      if (_gameState.dice.isNotEmpty) {
        finalValue = _gameState.dice.first.value;
      }
      final int delta = (finalValue - _gameState.target).abs();

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

      await showPracticeResultOverlay(
        context: context,
        title: title,
        target: _gameState.target,
        finalValue: finalValue,
        delta: delta,
        moves: _gameState.moves,
        timeText: _fmt(_lastSolveTime),
        isSolved: solved,
        onRetry: () {
          Navigator.of(context).pop();
          _resetDice();
        },
      );

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
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Radio<Difficulty>(
                        value: d, // ← KOMMA MUSS HIER STEHEN
                      ),
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
          ),
          actions: [
            IconButton(
              tooltip: 'Settings',
              onPressed: _busy ? null : _openSettingsSheet,
              icon: const Icon(Icons.tune_rounded),
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
                    ValueListenableBuilder<int>(
                      valueListenable: _rollingTargetN,
                      builder: (context, rt, child) {
                        final targetDisplay = _isPreStart
                            ? '—'
                            : (_isRolling ? '$rt' : '${_gameState.target}');

                        return PracticeTargetBar(
                          cardColor: _card,
                          accentColor: _accent,
                          inkColor: _ink,
                          targetText: targetDisplay,
                          celebrateAnimation: _celebrateT,
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (showDice) ...[
                            AnimatedBuilder(
                              animation: _shakeAnim,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(_shakeAnim.value, 0),
                                  child: child,
                                );
                              },
                              child: ValueListenableBuilder<List<int>>(
                                valueListenable: _rollingDiceN,
                                builder: (context, rollingDice, child) {
                                  return PracticeDiceRow(
                                    isRolling: _isRolling,
                                    isPlaying: _isPlaying,
                                    busy: _busy,
                                    showMergedResults: _showMergedResults,
                                    rollingTargetLocked: _rollingTargetLocked,
                                    mergePopKey: _mergePopKey,
                                    rollingDice: rollingDice,
                                    dice: _gameState.dice
                                        .map(
                                          (d) => PracticeDieData(
                                            value: d.value,
                                            maskLabel: d.maskLabel,
                                          ),
                                        )
                                        .toList(),
                                    selectedIndices: _selected,
                                    accentColor: _accent,
                                    onToggleSelect: _toggleSelect,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                          ],
                          PracticeOpsRow(
                            canInteractGameplay: _canInteractGameplay,
                            allowedOps: _config.allowedOps,
                            pendingOp: _selectedOp,
                            accentColor: _accent,
                            inkColor: _ink,
                            onApplyOp: _applyOp,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          PracticeSmallActionsRow(
                            enabled:
                                _canInteractGameplay && _undoStack.isNotEmpty,
                            accentColor: _accent,
                            inkColor: _ink,
                            onUndo: _undo,
                          ),
                        ],
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

  _Puzzle _generatePuzzle({
    required DifficultyConfig config,
    required int seed,
    required int puzzleIndex,
    required bool keepTarget,
    required int? fixedTarget,
  }) {
    final gen = Random(_mixSeed(seed, puzzleIndex));

    final target = keepTarget
        ? (fixedTarget ?? 1)
        : (gen.nextInt(config.maxTarget) + 1);
    final dice = List<int>.generate(5, (_) => gen.nextInt(6) + 1);

    return _Puzzle(target: target, dice: dice, seed: seed);
  }

  int _mixSeed(int seed, int puzzleIndex) {
    var x = seed ^ (puzzleIndex * 0x9E3779B9);
    x = (x ^ (x >> 16)) * 0x85EBCA6B;
    x = (x ^ (x >> 13)) * 0xC2B2AE35;
    x = x ^ (x >> 16);
    return x & 0x7fffffff;
  }

  // ignore: unused_element
  static int dailySeedFromDate(DateTime dateUtc) {
    final y = dateUtc.year;
    final m = dateUtc.month;
    final d = dateUtc.day;
    return (y * 10000) + (m * 100) + d;
  }

  // ignore: unused_element
  static int matchSeedFromMatchId(String matchId) {
    var hash = 0x811C9DC5;
    for (final code in matchId.codeUnits) {
      hash ^= code;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash & 0x7fffffff;
  }
}

class _UndoSnapshot {
  final List<DiceState> dice;
  final int moves;

  const _UndoSnapshot({required this.dice, required this.moves});
}
