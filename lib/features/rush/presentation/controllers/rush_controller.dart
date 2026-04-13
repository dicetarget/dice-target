// lib/features/rush/presentation/controllers/rush_controller.dart

import 'dart:async';
import 'dart:math';

import 'package:dice/core/audio/sfx_singleton.dart';
import 'package:dice/core/difficulty_config.dart';
import 'package:dice/core/puzzle/game_mode.dart';
import 'package:dice/core/puzzle/puzzle.dart';
import 'package:dice/core/puzzle/puzzle_coordinator.dart';
import 'package:dice/core/puzzle/puzzle_generator.dart';
import 'package:dice/core/ui_op.dart';
import 'package:dice/features/game/logic/move_application_service.dart';
import 'package:dice/features/rush/data/rush_daily_storage.dart';
import 'package:dice/features/rush/data/rush_highscore_storage.dart';
import 'package:dice/features/rush/domain/rush_difficulty.dart';
import 'package:dice/features/rush/domain/rush_state.dart';
import 'package:flutter/foundation.dart';

// ── Events ───────────────────────────────────────────────────────────────────

sealed class RushEvent {}

/// Shake-Feedback bei ungültigem Ergebnis.
class RushEventShake extends RushEvent {}

/// Kurzer grüner Flash bei gelöstem Puzzle.
class RushEventSolveFlash extends RushEvent {}

/// Run abgelaufen → navigiere zum Result-Screen.
class RushEventFinished extends RushEvent {}

// ── Controller ────────────────────────────────────────────────────────────────

class RushController extends ChangeNotifier {
  // ── Konstanten ────────────────────────────────────────────────────────────

  static const int standardDuration = 90;
  static const int dailyDuration = 120;
  static const int maxUndoDepth = 4;

  // ── Konfiguration ─────────────────────────────────────────────────────────

  /// Schwierigkeit (Standard-Mode). Für Daily-Mode null.
  final RushDifficulty? difficulty;

  /// Laufdauer in Sekunden. Standard = 90, Daily = 120.
  final int runDuration;

  /// Überschreibt den Target-Range (Daily: 15–55). Null = Difficulty-Phase.
  final int? forcedTargetMin;
  final int? forcedTargetMax;

  /// Daily-Modus: Saves in RushDailyStorage statt RushHighscoreStorage.
  final bool isDailyMode;

  /// Welcher der 2 Daily-Runs (1 oder 2). Nur relevant wenn isDailyMode=true.
  final int dailyRunNumber;

  /// Fixer Seed für Daily-Mode (gleiche Puzzles für alle). Null = Zufalls-Seed.
  final int? seedOverride;

  // ── Engines ───────────────────────────────────────────────────────────────

  final PuzzleGenerator _generator;
  final MoveApplicationService _moveService;
  final RushHighscoreStorage _scoreStorage;
  final RushDailyStorage _dailyStorage;

  late final PuzzleCoordinator _coordinator;

  // ── Interner State ────────────────────────────────────────────────────────

  RushState _state;
  final List<List<int>> _undoStack = [];
  Puzzle? _prefetchedPuzzle;
  Timer? _timer;

  final StreamController<RushEvent> _eventCtrl = StreamController<RushEvent>.broadcast();

  // ── Public ─────────────────────────────────────────────────────────────────

  RushState get state => _state;
  Stream<RushEvent> get events => _eventCtrl.stream;

  RushController({
    this.difficulty,
    this.runDuration = standardDuration,
    this.forcedTargetMin,
    this.forcedTargetMax,
    this.isDailyMode = false,
    this.dailyRunNumber = 1,
    this.seedOverride,
    PuzzleGenerator? generator,
    MoveApplicationService? moveService,
    RushHighscoreStorage? scoreStorage,
    RushDailyStorage? dailyStorage,
  }) : _generator = generator ?? PuzzleGenerator(),
       _moveService = moveService ?? const MoveApplicationService(),
       _scoreStorage = scoreStorage ?? RushHighscoreStorage(),
       _dailyStorage = dailyStorage ?? RushDailyStorage(),
       _state = RushState.initial(difficulty: difficulty, runDuration: runDuration) {
    _coordinator = PuzzleCoordinator(
      generator: _generator,
      mode: GameMode.rush,
      config: DifficultyConfig.easy,
      baseSeed: 0,
    );
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _timer?.cancel();
    _eventCtrl.close();
    super.dispose();
  }

  // ── API ───────────────────────────────────────────────────────────────────

  Future<void> startRun() async {
    _timer?.cancel();
    _undoStack.clear();
    _prefetchedPuzzle = null;

    // Highscore laden (nur Standard-Mode)
    final int? todayBest = isDailyMode ? null : await _scoreStorage.loadTodayBest(difficulty!);

    // Seed: Daily = datum-basiert (gleich für alle), Standard = Zufall
    final int seed =
        seedOverride ?? (isDailyMode ? _buildDailySeed() : Random().nextInt(0x7FFFFFFF));

    _coordinator.reconfigure(config: DifficultyConfig.easy, baseSeed: seed, startIndex: 0);

    final (min, max) = _currentTargetRange(_state.timeRemaining);
    final puzzle = _coordinator.currentPuzzle(targetMin: min, targetMax: max);
    _prefetchedPuzzle = _coordinator.peekNext(targetMin: min, targetMax: max);

    _state = RushState(
      dice: List<int>.from(puzzle.dice),
      initialDice: List<int>.from(puzzle.dice),
      target: puzzle.target,
      score: 0,
      timeRemaining: runDuration,
      isRunning: true,
      isFinished: false,
      selectedIndices: const {},
      undoStackDepth: 0,
      todayBest: todayBest,
      difficulty: difficulty,
    );

    notifyListeners();
    _playStartSound();
    _startTimer();
  }

  void onToggleSelect(int index) {
    if (!_state.isRunning || _state.isFinished) return;
    if (index < 0 || index >= _state.dice.length) return;

    final selected = Set<int>.from(_state.selectedIndices);

    if (selected.contains(index)) {
      selected.remove(index);
      _state = _state.copyWith(selectedIndices: selected, clearSelectedOp: selected.isEmpty);
      notifyListeners();
      return;
    }

    selected.add(index);

    // Auto-Apply: Op ausstehend + 2 Würfel gewählt
    if (_state.selectedOp != null && selected.length >= 2) {
      final op = _state.selectedOp!;
      _state = _state.copyWith(selectedIndices: selected, clearSelectedOp: true);
      _applyOpInternal(op);
      return;
    }

    _state = _state.copyWith(selectedIndices: selected);
    notifyListeners();
  }

  void onApplyOp(UiOp op) {
    if (!_state.isRunning || _state.isFinished) return;

    // Op-Toggle: selbes Op nochmal tippen → abwählen
    if (_state.selectedOp == op) {
      _state = _state.copyWith(clearSelectedOp: true);
      notifyListeners();
      return;
    }

    if (_state.selectedIndices.length >= 2) {
      // Sofort anwenden
      _state = _state.copyWith(clearSelectedOp: true);
      _applyOpInternal(op);
    } else {
      // Op merken, warten auf 2. Würfel
      _state = _state.copyWith(selectedOp: op);
      notifyListeners();
    }
  }

  void onUndo() {
    if (!_state.isRunning || _state.isFinished) return;
    if (_undoStack.isEmpty) return;

    final previous = _undoStack.removeLast();

    _state = _state.copyWith(
      dice: List<int>.from(previous),
      selectedIndices: const {},
      clearSelectedOp: true,
      undoStackDepth: _undoStack.length,
    );

    if (sfx.enabled) sfx.click();
    notifyListeners();
  }

  // ── Intern: Game-Logik ────────────────────────────────────────────────────

  void _applyOpInternal(UiOp op) {
    final indices = _state.selectedIndices.toList();
    if (indices.length < 2) return;

    final move = _moveService.buildMove(
      diceValues: _state.dice,
      selectedIndices: indices,
      op: op,
      gameMode: GameMode.rush,
    );

    if (move == null) {
      _triggerShake();
      _state = _state.copyWith(selectedIndices: const {}, clearSelectedOp: true);
      notifyListeners();
      return;
    }

    _pushUndo();

    // Würfel anwenden
    final newDice = List<int>.from(_state.dice);
    for (final i in move.removeIndicesDesc) {
      newDice.removeAt(i);
    }
    newDice.add(move.mergedValue);

    if (newDice.length == 1) {
      if (newDice[0] == _state.target) {
        // Solved: kurz den finalen Zustand anzeigen, dann wechseln
        _state = _state.copyWith(
          dice: newDice,
          selectedIndices: const {},
          clearSelectedOp: true,
          undoStackDepth: _undoStack.length,
        );
        notifyListeners();
        _onSolved();
      } else {
        // Falsches Ergebnis: sofort zurücksetzen, nicht zeigen
        _onInvalid();
      }
    } else {
      _state = _state.copyWith(
        dice: newDice,
        selectedIndices: const {},
        clearSelectedOp: true,
        undoStackDepth: _undoStack.length,
      );
      notifyListeners();
      if (sfx.enabled) sfx.valid();
    }
  }

  void _onSolved() {
    if (sfx.enabled) sfx.valid();
    _eventCtrl.add(RushEventSolveFlash());

    final newScore = _state.score + 1;
    _undoStack.clear();

    final (min, max) = _currentTargetRange(_state.timeRemaining);

    // Nächstes Puzzle instant aus Prefetch
    Puzzle next;
    if (_prefetchedPuzzle != null) {
      _coordinator.advanceIndex();
      next = _prefetchedPuzzle!;
    } else {
      next = _coordinator.nextPuzzle(targetMin: min, targetMax: max);
    }

    // Direkt das übernächste voraus-generieren
    _prefetchedPuzzle = _coordinator.peekNext(targetMin: min, targetMax: max);

    _state = _state.copyWith(
      dice: List<int>.from(next.dice),
      initialDice: List<int>.from(next.dice),
      target: next.target,
      score: newScore,
      selectedIndices: const {},
      clearSelectedOp: true,
      undoStackDepth: 0,
    );

    notifyListeners();
  }

  void _onInvalid() {
    _triggerShake();
    if (sfx.enabled) sfx.invalid();

    // Würfel auf Puzzle-Start zurücksetzen
    _undoStack.clear();
    _state = _state.copyWith(
      dice: List<int>.from(_state.initialDice),
      selectedIndices: const {},
      clearSelectedOp: true,
      undoStackDepth: 0,
    );
    notifyListeners();
  }

  void _triggerShake() {
    _eventCtrl.add(RushEventShake());
  }

  void _pushUndo() {
    if (_undoStack.length >= maxUndoDepth) return;
    _undoStack.add(List<int>.from(_state.dice));
  }

  // ── Intern: Timer ─────────────────────────────────────────────────────────

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!_state.isRunning || _state.isFinished) return;

    final remaining = _state.timeRemaining - 1;

    if (remaining <= 0) {
      _state = _state.copyWith(timeRemaining: 0);
      notifyListeners();
      _finishRun();
      return;
    }

    _state = _state.copyWith(timeRemaining: remaining);
    notifyListeners();

    // Warnsound bei 20s
    if (remaining == 20 && sfx.enabled) {
      sfx.rushWarning();
    }
  }

  Future<void> _finishRun() async {
    _timer?.cancel();

    bool isNewBest = false;
    int? todayBest;

    if (isDailyMode) {
      if (dailyRunNumber == 1) {
        await _dailyStorage.saveRun1(_state.score);
      } else {
        await _dailyStorage.saveRun2(_state.score);
      }
    } else {
      isNewBest = await _scoreStorage.saveTodayBest(difficulty!, _state.score);
      todayBest = await _scoreStorage.loadTodayBest(difficulty!);
    }

    _state = _state.copyWith(
      isRunning: false,
      isFinished: true,
      isNewBest: isNewBest,
      todayBest: todayBest ?? _state.todayBest,
    );

    notifyListeners();
    _eventCtrl.add(RushEventFinished());

    if (sfx.enabled) sfx.win();
  }

  // ── Intern: Hilfsmethoden ────────────────────────────────────────────────

  (int, int) _currentTargetRange(int timeRemaining) {
    if (forcedTargetMin != null && forcedTargetMax != null) {
      return (forcedTargetMin!, forcedTargetMax!);
    }
    return difficulty!.phaseRange(timeRemaining);
  }

  int _buildDailySeed() {
    final now = DateTime.now();
    return (now.year * 10000 + now.month * 100 + now.day) ^ 0xDA17BEEF;
  }

  void _playStartSound() {
    if (!sfx.enabled) return;
    if (isDailyMode) {
      sfx.rushDailyStart();
    } else {
      sfx.rushStart();
    }
  }
}
