import 'dart:async';
import 'dart:math' show sin;

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
import 'package:dice/features/daily/domain/daily_puzzle_play_result.dart';
import 'package:dice/features/daily/presentation/controllers/daily_controller.dart';
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
import 'package:dice/features/game/presentation/widgets/practice_game_area.dart';
import 'package:dice/features/game/presentation/widgets/practice_result_overlay.dart';
import 'package:dice/features/game/presentation/widgets/practice_top_controls_bar.dart';
import 'package:dice/features/game/presentation/widgets/solution_impossible_dialog.dart';
import 'package:dice/features/game/presentation/widgets/target_display_widget.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum RoundPhase { preStart, rolling, playing, ended }

enum EndReason { solved, failed, timeout, giveUp }

enum PracticeDifficulty { easy, medium, hard, expert }

class PracticeScreen extends StatefulWidget {
  final Puzzle? initialPuzzle;
  final bool isDailyMode;
  final bool isReplayMode;
  final int? dailyPuzzleIndex;
  final int? dailyPuzzleCount;
  final DailyController? dailyController;
  final bool initialTrainingMode;
  final PracticeDifficulty initialDifficulty;
  const PracticeScreen({
    super.key,
    this.initialPuzzle,
    this.isDailyMode = false,
    this.isReplayMode = false,
    this.dailyPuzzleIndex,
    this.dailyPuzzleCount,
    this.dailyController,
    this.initialTrainingMode = false,
    this.initialDifficulty = PracticeDifficulty.easy,
  });

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

abstract class ModeClock {
  const ModeClock();

  bool get enabled;

  bool isExpired({required Duration puzzleElapsed, required Duration runElapsed});
}

class NoClock extends ModeClock {
  const NoClock();

  @override
  bool get enabled => false;

  @override
  bool isExpired({required Duration puzzleElapsed, required Duration runElapsed}) {
    return false;
  }
}

class PerPuzzleClock extends ModeClock {
  final Duration limit;

  const PerPuzzleClock(this.limit);

  @override
  bool get enabled => true;

  @override
  bool isExpired({required Duration puzzleElapsed, required Duration runElapsed}) {
    return puzzleElapsed >= limit;
  }
}

class RunClock extends ModeClock {
  final Duration total;

  const RunClock(this.total);

  @override
  bool get enabled => true;

  @override
  bool isExpired({required Duration puzzleElapsed, required Duration runElapsed}) {
    return runElapsed >= total;
  }
}

class _PracticeScreenState extends State<PracticeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final SolverService _solverService = SolverService();
  final PuzzleGenerator _puzzleGenerator = PuzzleGenerator();
  final GameRules _gameRules = GameRules();
  final RoundEvaluator _roundEvaluator = const RoundEvaluator();
  final MoveApplicationService _moveApplicationService = const MoveApplicationService();

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

  bool _showMergedResults = true;
  RoundPhase _phase = RoundPhase.preStart;

  ModeClock _clock = const NoClock();

  List<int> _initialDice = [];
  int _initialTarget = 0;

  final Set<int> _selected = <int>{};
  bool _busy = false;
  bool _resultDialogOpen = false;

  int _mergePopKey = 0;
  FinalDiceState _finalDiceState = FinalDiceState.none;

  Timer? _timeoutTimer;
  Timer? _invalidTimer;

  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  late final AnimationController _celebrateCtrl;
  late final Animation<double> _celebrateT;

  late final AnimationController _confettiCtrl;

  final List<_UndoSnapshot> _undoStack = <_UndoSnapshot>[];
  static const int _maxUndo = 30;

  bool _rollAfterNoSolutionArmed = false;

  double _dailyTransitionOpacity = 0.0;
  bool _isDailyTransitionRunning = false;
  bool _showFinalDailyOverlay = false;

  Timer? _memoryFadeTimer;

  late SharedPreferences _prefs;
  bool _prefsLoaded = false;

  static final DateTime _dailyNumberEpoch = DateTime(2026, 3, 17);
  static const String _dailyStateKey = 'daily_in_progress_state';

  int _dailyNumberForToday() {
    final today = DateTime.now();
    final normalized = DateTime(today.year, today.month, today.day);
    final epoch = DateTime(_dailyNumberEpoch.year, _dailyNumberEpoch.month, _dailyNumberEpoch.day);
    final diff = normalized.difference(epoch).inDays;
    return diff < 0 ? 1 : diff + 1;
  }

  bool _hintUsedLocal = false;

  bool _trainingMode = false;
  PracticeDifficulty _practiceDifficulty = PracticeDifficulty.easy;

  String get _practiceDifficultyLabel {
    switch (_practiceDifficulty) {
      case PracticeDifficulty.easy:
        return 'Easy';
      case PracticeDifficulty.medium:
        return 'Medium';
      case PracticeDifficulty.hard:
        return 'Hard';
      case PracticeDifficulty.expert:
        return 'Expert';
    }
  }

  bool get _hasUsedDailyHintGlobally {
    return _hintUsedLocal || (widget.dailyController?.progress?.hintUsed == true);
  }

  List<int>? _hintSuggestedIndices;
  UiOp? _hintSuggestedOp;

  bool get _isPuzzle4Memory => _isDailyMode && _dailyPuzzleNumber == 4;
  bool get _isPuzzle5Hidden => _isDailyMode && _dailyPuzzleNumber == 5;
  bool get _shouldShowMergedResultsInUi {
    if (_isPuzzle5Hidden) return false;
    return _showMergedResults;
  }

  bool get _isDailyMode => widget.isDailyMode;

  int get _dailyPuzzleNumber => ((widget.dailyPuzzleIndex ?? 0) + 1);

  int get _dailyPuzzleCount => widget.dailyPuzzleCount ?? 3;

  double get _topSectionGap => _isDailyMode ? AppSpacing.md : AppSpacing.md;
  double get _bottomSectionGapAfterButtons => _isDailyMode ? AppSpacing.sm : AppSpacing.md;
  double get _topPadding => _isDailyMode ? AppSpacing.sm : AppSpacing.sm;

  bool get _canUseHint {
    if (!_isDailyMode) return false;
    if (widget.isReplayMode) return false;
    if (_busy) return false;
    if (_resultDialogOpen) return false;
    if (_isRolling) return false;
    if (_phase != RoundPhase.playing) return false;
    if (_gameState.moves > 0) return false;
    if (_hasUsedDailyHintGlobally) return false;
    return true;
  }

  (int?, int?) _currentTargetRange() {
    if (!_trainingMode) return (1, 120);

    switch (_practiceDifficulty) {
      case PracticeDifficulty.easy:
        return (10, 40);
      case PracticeDifficulty.medium:
        return (30, 70);
      case PracticeDifficulty.hard:
        return (50, 100);
      case PracticeDifficulty.expert:
        return (80, 120);
    }
  }

  void _syncHintUsedFromController() {
    final globalHintUsed = widget.dailyController?.progress?.hintUsed == true;
    if (_hintUsedLocal == globalHintUsed) return;
    if (!mounted) return;

    setState(() {
      _hintUsedLocal = globalHintUsed;
    });
  }

  void _attachDailyControllerListener() {
    widget.dailyController?.addListener(_syncHintUsedFromController);
  }

  void _detachDailyControllerListener() {
    widget.dailyController?.removeListener(_syncHintUsedFromController);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _gameState = PracticeGameState.initial();
    _trainingMode = widget.initialTrainingMode;
    _practiceDifficulty = widget.initialDifficulty;
    _hintUsedLocal = widget.dailyController?.progress?.hintUsed == true;
    _attachDailyControllerListener();

    _targetRollController = TargetRollController()..startIdle(initialValue: 0);
    _diceRollController = DiceRollController()..startIdle(initialDice: List<int>.filled(5, 1));

    _roundFlowCoordinator = PracticeRoundFlowCoordinator(
      targetRollController: _targetRollController,
      diceRollController: _diceRollController,
    );

    _puzzleCoordinator = PuzzleCoordinator(
      generator: _puzzleGenerator,
      mode: _isDailyMode ? GameMode.daily : GameMode.practice,
      config: DifficultyConfig.easy,
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

    _celebrateCtrl = AnimationController(vsync: this, duration: AppDurations.celebrate);

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

    _confettiCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3500));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncHintUsedFromController();
    });

    _initPrefs();
  }

  @override
  void didUpdateWidget(covariant PracticeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.dailyController != widget.dailyController) {
      oldWidget.dailyController?.removeListener(_syncHintUsedFromController);
      _attachDailyControllerListener();
      _syncHintUsedFromController();
    }
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _prefsLoaded = true;
    });

    if (widget.initialPuzzle != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        _prepareRollingPhase(keepTarget: false);
        if (_soundEnabled && (!_isDailyMode || widget.isReplayMode)) sfx.roll();
        await _rollAndApplyPuzzle(
          puzzle: widget.initialPuzzle!,
          difficulty: Difficulty.easy,
          config: DifficultyConfig.easy,
          keepTarget: false,
        );
      });
    } else {
      _goToPreStart();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Removed: saving daily state on pause since resume is disabled
  }

  @override
  void dispose() {
    _detachDailyControllerListener();
    WidgetsBinding.instance.removeObserver(this);
    _targetRollController.dispose();
    _diceRollController.dispose();
    _timeoutTimer?.cancel();
    _invalidTimer?.cancel();
    _shakeCtrl.dispose();
    _celebrateCtrl.dispose();
    _confettiCtrl.dispose();
    _memoryFadeTimer?.cancel();
    super.dispose();
  }

  bool get _isPreStart => _phase == RoundPhase.preStart;
  bool get _isRolling => _phase == RoundPhase.rolling;
  bool get _isPlaying => _phase == RoundPhase.playing;

  bool get _soundEnabled => sfx.enabled;
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

  bool get _canGiveUpDaily {
    if (!_isDailyMode) return false;
    if (_busy) return false;
    if (_resultDialogOpen) return false;
    if (_isRolling) return false;
    return true;
  }

  Future<void> _useHint() async {
    if (!_canUseHint) return;
    if (_hasUsedDailyHintGlobally) return;

    final diceValues = _gameState.dice.map((d) => d.value).toList();
    final target = _gameState.target;

    final suggestion = _solverService.getNextOptimalMove(diceValues: diceValues, target: target);

    if (suggestion == null) {
      _showInfo('No hint available');
      return;
    }

    setState(() {
      _hintUsedLocal = true;
      _hintSuggestedIndices = suggestion.selectedIndices;
      _hintSuggestedOp = suggestion.operator;
    });

    if (_soundEnabled) sfx.hint();
    await widget.dailyController?.markHintUsed();
  }

  void _clearHintSuggestion() {
    if (_hintSuggestedIndices != null || _hintSuggestedOp != null) {
      setState(() {
        _hintSuggestedIndices = null;
        _hintSuggestedOp = null;
      });
    }
  }

  Future<void> _confirmGiveUpDaily() async {
    if (!_isDailyMode) return;
    if (_resultDialogOpen) return;

    final shouldGiveUp = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D1F35),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFE57373).withValues(alpha: 0.35),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.60),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(color: const Color(0xFFE57373).withValues(alpha: 0.10), blurRadius: 24),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE57373).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.flag_outlined, color: Color(0xFFE57373), size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Give up Daily?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFEEEAF6),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'This ends your scored run. You can still practice the puzzles afterwards.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B8CAE),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, false),
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                              width: 0.5,
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF90D5F0),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, true),
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE57373).withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE57373).withValues(alpha: 0.50),
                              width: 0.5,
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'Give Up',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFFF8A80),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldGiveUp != true || !mounted) return;

    if (_soundEnabled) sfx.giveUp();
    await _endRound(reason: EndReason.giveUp, solved: false, title: 'Daily Ended');
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
    }
  }

  Future<void> _runDailySolveFadeOut() async {
    if (!_isDailyMode || !mounted || _isDailyTransitionRunning) return;

    _isDailyTransitionRunning = true;

    setState(() {
      _dailyTransitionOpacity = 1.0;
    });

    await Future.delayed(const Duration(milliseconds: 220));
  }

  Future<void> _runFinalPuzzleCompleteAnimation() async {
    if (!mounted) return;

    _confettiCtrl.forward(from: 0);

    setState(() {
      _showFinalDailyOverlay = true;
    });

    await Future.delayed(const Duration(milliseconds: 3500));

    if (!mounted) return;

    setState(() {
      _showFinalDailyOverlay = false;
    });
  }

  void _goToPreStart() {
    _cancelRollingControllers();
    _cancelTimeoutTicker();
    _invalidTimer?.cancel();

    _roundFlowCoordinator.resetToIdle(initialTarget: 0, initialDice: List<int>.filled(5, 1));

    final currentSoundEnabled = _gameState.soundEnabled;

    setState(() {
      _resultDialogOpen = false;
      _mergePopKey = 0;
      _finalDiceState = FinalDiceState.none;

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

      _dailyTransitionOpacity = 0.0;
      _isDailyTransitionRunning = false;

      _hintSuggestedIndices = null;
      _hintSuggestedOp = null;

      _gameState = PracticeGameState.initial().copyWith(soundEnabled: currentSoundEnabled);
    });

    if (_isDailyMode && _prefsLoaded) {
      _prefs.remove(_dailyStateKey);
    }
  }

  Future<void> _newGame() async {
    if (_busy) return;
    if (_isDailyMode) return;

    await startRound(seed: PuzzleSeed.practiceSeed());
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
    int? targetMin,
    int? targetMax,
  }) {
    final wasReconfigured = difficulty != null || seed != null || puzzleIndex != null;

    _puzzleCoordinator.reconfigureIfNeeded(config: config, seed: seed, puzzleIndex: puzzleIndex);

    return _puzzleCoordinator.createRoundPuzzle(
      keepTarget: keepTarget,
      fixedTarget: keepTarget ? _gameState.target : null,
      wasReconfigured: wasReconfigured,
      targetMin: targetMin,
      targetMax: targetMax,
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

    final effConfig = DifficultyConfig.easy;
    final effClock = clock ?? _clockFromConfig(effConfig);
    final range = _currentTargetRange();

    final puzzle = _createRoundPuzzle(
      config: effConfig,
      keepTarget: keepTarget,
      seed: seed,
      puzzleIndex: puzzleIndex,
      difficulty: difficulty,
      targetMin: range.$1,
      targetMax: range.$2,
    );

    _prepareRoundStart(clock: effClock, resetRun: resetRun);
    _prepareRollingPhase(keepTarget: keepTarget);

    if (_soundEnabled && !_isDailyMode) await sfx.roll();

    await _rollAndApplyPuzzle(
      puzzle: puzzle,
      difficulty: Difficulty.easy,
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
    _hintSuggestedIndices = null;
    _hintSuggestedOp = null;
    _gameState = _gameState.copyWith(moves: 0);
    _solveWatch.reset();
    _lastSolveTime = Duration.zero;
    _clearPendingOp();
    _undoStack.clear();
    _mergePopKey = 0;
    _cancelTimeoutTicker();
    _cancelRollingControllers();
  }

  void _prepareRollingPhase({required bool keepTarget}) {
    setState(() {
      _phase = RoundPhase.rolling;
      _gameState = _gameState.copyWith(
        moves: 0,
        isRollingTarget: false,
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

  void _enterPlayableRoundState({required int target, required List<int> diceValues}) {
    final diceState = _toDiceStateList(diceValues);

    _roundFlowCoordinator.resetToIdle(
      initialTarget: target,
      initialDice: List<int>.from(diceValues),
    );

    _memoryFadeTimer?.cancel();

    setState(() {
      _initialTarget = target;
      _initialDice = List<int>.from(diceValues);

      _phase = RoundPhase.playing;
      _busy = false;

      _selected.clear();
      _hintSuggestedIndices = null;
      _hintSuggestedOp = null;

      _dailyTransitionOpacity = 0.0;
      _isDailyTransitionRunning = false;

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

    _memoryFadeTimer?.cancel();

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
    if (_isDailyMode) return;

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

  Future<void> _resetCurrentPuzzleAfterInvalidFinal() async {
    if (!mounted) return;

    _cancelTimeoutTicker();
    _cancelRollingControllers();

    if (_soundEnabled) {
      await sfx.invalid();
    }

    await Future.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;

    _enterPlayableRoundState(target: _initialTarget, diceValues: _initialDice);
  }

  Future<void> _impossible() async {
    if (_busy) return;
    if (_isDailyMode) return;
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

      final res = _solverService.check(diceValues: startVals, target: _gameState.target);

      if (res.solvable) {
        if (_soundEnabled) sfx.solution();
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

      if (_soundEnabled) sfx.solution();
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
    if (_hintSuggestedIndices != null || _hintSuggestedOp != null) {
      _clearHintSuggestion();
    }

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

    if (_hintSuggestedOp != null && _hintSuggestedOp != op) {
      _clearHintSuggestion();
    }

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
      dice: _gameState.dice.map((d) => DiceState(value: d.value, maskLabel: d.maskLabel)).toList(),
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

    if (_hintSuggestedIndices != null || _hintSuggestedOp != null) {
      _clearHintSuggestion();
    }

    _memoryFadeTimer?.cancel();

    if (_soundEnabled) sfx.undo();

    setState(() {
      _selected.clear();
      _clearPendingOp();

      final snapshot = _undoStack.removeLast();
      _gameState = _gameState.copyWith(
        dice: snapshot.dice.map((d) => DiceState(value: d.value, maskLabel: d.maskLabel)).toList(),
        moves: snapshot.moves,
        clearSelectedOp: true,
        clearSelectedDieIndex: true,
      );
    });
  }

  void _applyOpInternal(UiOp op) {
    if (_selected.length < 2) return;

    if (_hintSuggestedIndices != null || _hintSuggestedOp != null) {
      _hintSuggestedIndices = null;
      _hintSuggestedOp = null;
    }

    final currentDice = _gameState.dice;

    final move = _moveApplicationService.buildMove(
      diceValues: currentDice.map((d) => d.value).toList(),
      selectedIndices: _selected.toList(),
      op: op,
      gameMode: _isDailyMode ? GameMode.daily : GameMode.practice,
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

    final mergedMask = _isPuzzle5Hidden
        ? _nextQuestionMarkLabel()
        : (_showMergedResults ? null : _nextQuestionMarkLabel());

    remainingDice.add(DiceState(value: move.mergedValue, maskLabel: mergedMask));

    _gameRules.registerMove();

    final progress = _moveApplicationService.registerMove(currentMoves: _gameState.moves);

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

    if (_isPuzzle4Memory && !_isPuzzle5Hidden) {
      _memoryFadeTimer?.cancel();

      _memoryFadeTimer = Timer(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        if (_gameState.dice.isEmpty) return;

        final updatedDice = List<DiceState>.from(_gameState.dice);
        final lastIndex = updatedDice.length - 1;
        final lastDie = updatedDice[lastIndex];

        if (lastDie.maskLabel == null) {
          updatedDice[lastIndex] = DiceState(
            value: lastDie.value,
            maskLabel: _nextQuestionMarkLabel(),
          );

          setState(() {
            _gameState = _gameState.copyWith(dice: updatedDice);
          });
        }
      });
    }

    final willBeSingleDie = remainingDice.length == 1;
    if (!move.willEndAfterMove && !willBeSingleDie && _soundEnabled) {
      sfx.valid();
    }

    _checkEnd();
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

    if (solved) {
      setState(() => _finalDiceState = FinalDiceState.success);
      final isLastDailyPuzzle = _isDailyMode && _dailyPuzzleNumber == _dailyPuzzleCount;
      if (_soundEnabled && !isLastDailyPuzzle) sfx.win();
      await Future.delayed(const Duration(milliseconds: 320));
      if (!mounted) return;
      setState(() => _finalDiceState = FinalDiceState.none);
      if (_isDailyMode) {
        await Future<void>.delayed(Duration.zero);
      }
      await _endRound(reason: EndReason.solved, solved: true, title: 'Solved');
      return;
    }

    setState(() => _finalDiceState = FinalDiceState.fail);
    _shakeCtrl.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 370));
    if (!mounted) return;
    setState(() => _finalDiceState = FinalDiceState.none);

    await _resetCurrentPuzzleAfterInvalidFinal();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    final cs = (d.inMilliseconds % 1000) ~/ 10;

    return '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}.'
        '${cs.toString().padLeft(2, '0')}';
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

  PracticeRoundSummary _buildRoundSummary({required String title, required bool solved}) {
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
        _resetDice();
      },
      onNewGame: () {
        _newGame();
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

      if (_isDailyMode) {
        if (solved) {
          _playTargetCelebrate();
          if (widget.isReplayMode && _soundEnabled) sfx.win();
          if (_dailyPuzzleNumber == _dailyPuzzleCount && !widget.isReplayMode) {
            await widget.dailyController?.syncRunProgress(
              solvedCount: _dailyPuzzleCount,
              currentPuzzleIndex: _dailyPuzzleCount,
            );
            sfx.dailyComplete();
            await _runFinalPuzzleCompleteAnimation();
            if (!mounted) return;
          } else {
            await widget.dailyController?.syncRunProgress(
              solvedCount: _dailyPuzzleNumber,
              currentPuzzleIndex: _dailyPuzzleNumber,
            );
            unawaited(_runDailySolveFadeOut());
          }
        }

        if (!mounted) return;

        Navigator.of(context).pop(
          DailyPuzzlePlayResult(
            solved: solved,
            gaveUp: reason == EndReason.giveUp,
            moves: _gameState.moves,
            elapsed: _lastSolveTime,
            solvedCount: 0,
            currentPuzzleIndex: 0,
            puzzleIndex: widget.dailyPuzzleIndex ?? 0,
            puzzleResults: const [],
          ),
        );
        await _prefs.remove(_dailyStateKey);
        return;
      }

      final summary = _buildRoundSummary(title: title, solved: solved);
      _handleRoundEndFeedback(solved);

      await _showRoundResultOverlay(summary);
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

    if (!_clock.isExpired(puzzleElapsed: puzzleElapsed, runElapsed: runElapsed)) {
      return;
    }

    _gameRules.markTimeout();

    await _endRound(reason: EndReason.timeout, solved: false, title: "Time's up");
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

  void _toggleSound() {
    sfx.toggle().then((_) {
      if (mounted) setState(() {});
      if (sfx.enabled) sfx.click();
    });
  }

  void _toggleMerged() {
    if (_isDailyMode) return;

    setState(() {
      _showMergedResults = !_showMergedResults;
    });
  }

  Widget _buildDailyHintButton() {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: _canUseHint
            ? () {
                _useHint();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 50,
          decoration: BoxDecoration(
            color: _canUseHint
                ? const Color(0xFFD4AC0D).withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(
              color: _canUseHint
                  ? const Color(0xFFD4AC0D).withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.06),
              width: 0.5,
            ),
            boxShadow: [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 18,
                color: _canUseHint ? const Color(0xFFFFF0A0) : AppColors.muted,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Hint',
                style: AppTextStyles.body.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _canUseHint ? const Color(0xFFFFF0A0) : AppColors.muted,
                  height: 1,
                  shadows: null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyGiveUpButton() {
    final isReplay = widget.isReplayMode;
    final canAct = isReplay || _canGiveUpDaily;

    final Color activeColor = isReplay
        ? AppColors.ink.withValues(alpha: 0.55)
        : const Color(0xFFE57373).withValues(alpha: 0.45);
    final Color textColor = canAct ? activeColor : AppColors.muted;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: SizedBox(
        width: double.infinity,
        child: GestureDetector(
          onTap: () {
            if (isReplay) {
              Navigator.of(context).pop();
              return;
            }
            if (_canGiveUpDaily) _confirmGiveUpDaily();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 46,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(
                color: isReplay
                    ? Colors.white.withValues(alpha: 0.08)
                    : (_canGiveUpDaily
                          ? const Color(0xFFE57373).withValues(alpha: 0.10)
                          : Colors.white.withValues(alpha: 0.04)),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isReplay ? Icons.arrow_back_ios_new_rounded : Icons.flag_outlined,
                  size: 14,
                  color: textColor,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  isReplay ? 'Return' : 'Give Up',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_prefsLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final mq = MediaQuery.of(context);
    final bottomInset = mq.viewPadding.bottom;
    final showDice = !_isPreStart;

    return Theme(
      data: Theme.of(context).copyWith(
        appBarTheme: AppBarTheme(
          foregroundColor: AppColors.ink,
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          titleTextStyle: AppTextStyles.appBarTitle.copyWith(color: AppColors.ink),
          iconTheme: const IconThemeData(color: AppColors.ink),
        ),
      ),
      child: PopScope(
        canPop: !_isDailyMode,
        child: Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: AppColors.bgBottom,
          appBar: AppBar(
            automaticallyImplyLeading: !_isDailyMode,
            backgroundColor: Colors.transparent,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            title: _isDailyMode
                ? Text(
                    'Daily',
                    style: AppTextStyles.appBarTitle.copyWith(
                      color: const Color(0xFFD4AC0D),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : Text(
                    _trainingMode ? 'Training' : 'Classic',
                    style: AppTextStyles.appBarTitle.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
            centerTitle: true,
            leading: _isDailyMode
                ? null
                : IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    onPressed: () => Navigator.of(context).maybePop(),
                    enableFeedback: false,
                    color: AppColors.ink.withValues(alpha: 0.70),
                  ),
            actions: [
              StatefulBuilder(
                builder: (context, setIcon) => IconButton(
                  icon: Icon(
                    sfx.enabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                    color: Colors.white70,
                  ),
                  onPressed: () async {
                    await sfx.toggle();
                    if (mounted) setState(() {});
                    setIcon(() {});
                  },
                ),
              ),
            ],
          ),
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
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      top: _topPadding,
                      bottom: bottomInset,
                    ),
                    child: Column(
                      children: [
                        PracticeTopControlsBar(
                          cardColor: _card,
                          accentColor: _accent,
                          inkColor: _ink,
                          soundOn: sfx.enabled,
                          onToggleSound: _toggleSound,
                          showMerged: _showMergedResults,
                          onToggleMerged: _toggleMerged,
                          isDailyMode: _isDailyMode,
                          dailyPuzzleNumber: _isDailyMode ? _dailyPuzzleNumber : null,
                          dailyPuzzleCount: _isDailyMode ? _dailyPuzzleCount : null,
                          dailyMoves: (_isDailyMode && !_isPreStart) ? _gameState.moves : null,
                          freePlayMoves: (!_isDailyMode && !_isPreStart) ? _gameState.moves : null,
                          rightLabel: _isDailyMode
                              ? null
                              : _trainingMode
                              ? _practiceDifficultyLabel
                              : 'Random',
                        ),
                        SizedBox(height: _topSectionGap),
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
                        SizedBox(height: _topSectionGap),
                        Expanded(
                          child: PracticeGameArea(
                            showDice: showDice,
                            isRolling: _isRolling,
                            isPlaying: _isPlaying,
                            busy: _busy,
                            showMergedResults: _shouldShowMergedResultsInUi,
                            mergePopKey: _mergePopKey,
                            selectedIndices: {
                              ..._selected,
                              if (_hintSuggestedIndices != null) ..._hintSuggestedIndices!,
                            },
                            accentColor: _accent,
                            inkColor: _ink,
                            shakeAnimation: _shakeAnim,
                            rollingDiceListenable: _diceRollController.dice,
                            rollingTargetLocked: _targetRollController.locked.value,
                            dice: _gameState.dice
                                .map((d) => PracticeDieData(value: d.value, maskLabel: d.maskLabel))
                                .toList(),
                            canInteractGameplay: _canInteractGameplay,
                            allowedOps: DifficultyConfig.easy.allowedOps,
                            pendingOp: _selectedOp ?? _hintSuggestedOp,
                            finalDiceState: _finalDiceState,
                            undoEnabled: _canInteractGameplay && _undoStack.isNotEmpty,
                            resetEnabled: _canInteractGameplay && _undoStack.isNotEmpty,
                            onResetPuzzle: (_canInteractGameplay && _undoStack.isNotEmpty) ? _resetDice : null,
                            onToggleSelect: _toggleSelect,
                            onApplyOp: _applyOp,
                            onUndo: _undo,
                            mainAxisAlignment: _isDailyMode
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.center,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (!_isDailyMode)
                          PracticeBottomButtons(
                            canPressBottom: _canPressBottom,
                            isPlaying: _isPlaying,
                            resetEnabled: _canInteractGameplay && _undoStack.isNotEmpty,
                            accentColor: _accent,
                            inkColor: _ink,
                            onNoSolution: _impossible,
                            onNewGame: _newGame,
                            onResetPuzzle: (_canInteractGameplay && _undoStack.isNotEmpty)
                                ? _resetDice
                                : null,
                          ),
                        if (_isDailyMode && !widget.isReplayMode) _buildDailyHintButton(),
                        if (_isDailyMode) _buildDailyGiveUpButton(),
                        SizedBox(height: _bottomSectionGapAfterButtons),
                      ],
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                ignoring: true,
                child: AnimatedOpacity(
                  opacity: _dailyTransitionOpacity,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  child: Container(color: AppColors.bgBottom),
                ),
              ),
              IgnorePointer(
                ignoring: true,
                child: AnimatedOpacity(
                  opacity: _showFinalDailyOverlay ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(color: Colors.black.withValues(alpha: 0.94)),
                ),
              ),
              if (_showFinalDailyOverlay)
                _DailyCompleteOverlay(
                  confettiCtrl: _confettiCtrl,
                  dailyNumber: _dailyNumberForToday(),
                ),
            ],
          ),
        ),
      ),
    );
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

// ── Daily Complete Overlay ─────────────────────────────────────────────────

class _DailyCompleteOverlay extends StatefulWidget {
  final AnimationController confettiCtrl;
  final int dailyNumber;

  const _DailyCompleteOverlay({required this.confettiCtrl, required this.dailyNumber});

  @override
  State<_DailyCompleteOverlay> createState() => _DailyCompleteOverlayState();
}

class _DailyCompleteOverlayState extends State<_DailyCompleteOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _textCtrl;
  late final Animation<double> _textFade;
  late final Animation<double> _textScale;

  @override
  void initState() {
    super.initState();
    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _textFade = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);
    _textScale = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutBack));
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _textCtrl.forward();
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: widget.confettiCtrl,
            builder: (context, _) {
              return CustomPaint(
                painter: _ConfettiPainter(
                  progress: widget.confettiCtrl.value,
                  seed: widget.dailyNumber,
                ),
                size: Size.infinite,
              );
            },
          ),
          Center(
            child: FadeTransition(
              opacity: _textFade,
              child: ScaleTransition(
                scale: _textScale,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A1828).withValues(alpha: 0.98),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: const Color(0xFFD4AC0D).withValues(alpha: 0.55),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AC0D).withValues(alpha: 0.20),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.60),
                          blurRadius: 40,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFFFF0A0), Color(0xFFD4AC0D)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ).createShader(bounds),
                          child: const Text(
                            'Daily Complete',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                              shadows: [Shadow(color: Color(0xFF3FE8FF), blurRadius: 16)],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Daily solved!',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B8CAE),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Confetti Painter ───────────────────────────────────────────────────────

class _ConfettiParticle {
  final double x;
  final double speed;
  final double wobble;
  final double wobbleSpeed;
  final double size;
  final Color color;
  final double rotation;
  final double rotationSpeed;
  final bool isCircle;
  final double delay;

  const _ConfettiParticle({
    required this.x,
    required this.speed,
    required this.wobble,
    required this.wobbleSpeed,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
    required this.isCircle,
    required this.delay,
  });
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final int seed;

  static const List<Color> _colors = [
    Color(0xFF3FE8FF),
    Color(0xFFFFD700),
    Color(0xFFFFFFFF),
    Color(0xFF90D5F0),
    Color(0xFFFFF0A0),
    Color(0xFF4CAF82),
    Color(0xFFFF9F00),
  ];

  static List<_ConfettiParticle>? _cachedParticles;
  static int? _cachedSeed;

  static List<_ConfettiParticle> _generateParticles(int seed) {
    if (_cachedSeed == seed && _cachedParticles != null) {
      return _cachedParticles!;
    }

    final particles = <_ConfettiParticle>[];
    double r(int n) {
      final x = (seed * 1234567 + n * 987654321) & 0x7FFFFFFF;
      return (x % 10000) / 10000.0;
    }

    for (int i = 0; i < 80; i++) {
      particles.add(
        _ConfettiParticle(
          x: r(i * 7),
          speed: 0.25 + r(i * 3) * 0.45,
          wobble: (r(i * 11) - 0.5) * 0.08,
          wobbleSpeed: 1.5 + r(i * 13) * 3.0,
          size: 6 + r(i * 5) * 10,
          color: _colors[(i * 3 + (r(i) * 6).toInt()) % _colors.length],
          rotation: r(i * 17) * 6.28,
          rotationSpeed: (r(i * 19) - 0.5) * 8.0,
          isCircle: r(i * 23) > 0.6,
          delay: r(i * 29) * 0.35,
        ),
      );
    }

    _cachedSeed = seed;
    _cachedParticles = particles;
    return particles;
  }

  const _ConfettiPainter({required this.progress, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final particles = _generateParticles(seed);

    for (final p in particles) {
      final localProgress = ((progress - p.delay) / (1.0 - p.delay)).clamp(0.0, 1.0);
      if (localProgress <= 0) continue;

      final y = -0.10 + localProgress * p.speed * 1.3;
      final wobbleOffset = p.wobble * sin(localProgress * p.wobbleSpeed * 6.28);
      final x = p.x + wobbleOffset;

      final opacity = localProgress > 0.8
          ? (1.0 - (localProgress - 0.8) / 0.2).clamp(0.0, 1.0)
          : 1.0;

      final px = x * size.width;
      final py = y * size.height;

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(p.rotation + localProgress * p.rotationSpeed);

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size * 0.5, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.55),
            const Radius.circular(2),
          ),
          paint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
