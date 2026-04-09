import 'dart:math';

import 'package:dice/core/difficulty_config.dart';
import 'package:dice/core/puzzle/game_mode.dart';
import 'package:dice/core/puzzle/puzzle.dart';
import 'package:dice/core/puzzle/puzzle_generator.dart';
import 'package:dice/core/puzzle/puzzle_seed.dart';

class PuzzleCoordinator {
  final PuzzleGenerator _generator;
  final GameMode mode;

  DifficultyConfig _config;
  int _baseSeed;
  int _puzzleIndex;

  Puzzle? _currentPuzzle;

  PuzzleCoordinator({
    required PuzzleGenerator generator,
    required this.mode,
    required DifficultyConfig config,
    required int baseSeed,
    int startIndex = 0,
  }) : _generator = generator,
       _config = config,
       _baseSeed = baseSeed,
       _puzzleIndex = startIndex;

  int get puzzleIndex => _puzzleIndex;
  int get baseSeed => _baseSeed;
  DifficultyConfig get config => _config;
  Puzzle? get current => _currentPuzzle;

  void reconfigure({required DifficultyConfig config, required int baseSeed, int startIndex = 0}) {
    _config = config;
    _baseSeed = baseSeed;
    _puzzleIndex = startIndex;
    _currentPuzzle = null;
  }

  void reconfigureIfNeeded({required DifficultyConfig config, int? seed, int? puzzleIndex}) {
    if (seed == null && puzzleIndex == null && config == _config) {
      return;
    }

    reconfigure(
      config: config,
      baseSeed: seed ?? _baseSeed,
      startIndex: puzzleIndex ?? _puzzleIndex,
    );
  }

  Puzzle _generateCurrent({
    bool keepTarget = false,
    int? fixedTarget,
    int? targetMin,
    int? targetMax,
  }) {
    final puzzle = _generator.generate(
      mode: mode,
      config: _config,
      seed: _baseSeed,
      puzzleIndex: _puzzleIndex,
      keepTarget: keepTarget,
      fixedTarget: fixedTarget,
      targetMin: targetMin,
      targetMax: targetMax,
    );

    _currentPuzzle = puzzle;
    return puzzle;
  }

  Puzzle currentPuzzle({
    bool keepTarget = false,
    int? fixedTarget,
    int? targetMin,
    int? targetMax,
  }) {
    if (_currentPuzzle != null &&
        !keepTarget &&
        fixedTarget == null &&
        targetMin == null &&
        targetMax == null) {
      return _currentPuzzle!;
    }

    return _generateCurrent(
      keepTarget: keepTarget,
      fixedTarget: fixedTarget,
      targetMin: targetMin,
      targetMax: targetMax,
    );
  }

  Puzzle nextPuzzle({bool keepTarget = false, int? fixedTarget, int? targetMin, int? targetMax}) {
    _puzzleIndex++;

    return _generateCurrent(
      keepTarget: keepTarget,
      fixedTarget: fixedTarget,
      targetMin: targetMin,
      targetMax: targetMax,
    );
  }

  /// Generiert puzzleIndex+1 ohne den Index zu verändern — für Rush-Prefetch.
  Puzzle peekNext({int? targetMin, int? targetMax}) {
    return _generator.generate(
      mode: mode,
      config: _config,
      seed: _baseSeed,
      puzzleIndex: _puzzleIndex + 1,
      targetMin: targetMin,
      targetMax: targetMax,
    );
  }

  /// Erhöht Index ohne zu generieren — nach Verwendung eines prefetched Puzzles.
  void advanceIndex() {
    _puzzleIndex++;
    _currentPuzzle = null;
  }

  Puzzle resetAndGetFirstPuzzle({
    bool keepTarget = false,
    int? fixedTarget,
    int? targetMin,
    int? targetMax,
  }) {
    _puzzleIndex = 0;
    _currentPuzzle = null;

    return _generateCurrent(
      keepTarget: keepTarget,
      fixedTarget: fixedTarget,
      targetMin: targetMin,
      targetMax: targetMax,
    );
  }

  Puzzle startNewRun({int? seed, int? targetMin, int? targetMax}) {
    reconfigure(config: _config, baseSeed: seed ?? _baseSeed, startIndex: 0);

    return currentPuzzle(targetMin: targetMin, targetMax: targetMax);
  }

  Puzzle startNewPracticeRun({int? targetMin, int? targetMax}) {
    return startNewRun(seed: PuzzleSeed.practiceSeed(), targetMin: targetMin, targetMax: targetMax);
  }

  Puzzle rerollKeepingTarget(int target, {int? targetMin, int? targetMax}) {
    return nextPuzzle(
      keepTarget: true,
      fixedTarget: target,
      targetMin: targetMin,
      targetMax: targetMax,
    );
  }

  Puzzle createRoundPuzzle({
    required bool keepTarget,
    int? fixedTarget,
    required bool wasReconfigured,
    int? targetMin,
    int? targetMax,
  }) {
    if (keepTarget) {
      return wasReconfigured
          ? currentPuzzle(
              keepTarget: true,
              fixedTarget: fixedTarget,
              targetMin: targetMin,
              targetMax: targetMax,
            )
          : rerollKeepingTarget(fixedTarget!, targetMin: targetMin, targetMax: targetMax);
    }

    return wasReconfigured
        ? currentPuzzle(targetMin: targetMin, targetMax: targetMax)
        : startNewPracticeRun(targetMin: targetMin, targetMax: targetMax);
  }

  Puzzle generateDailyPuzzle({
    required DifficultyConfig config,
    required int baseSeed,
    required int puzzleIndex,
    required int targetMin,
    required int targetMax,
    bool keepTarget = false,
    int? fixedTarget,
  }) {
    final previousConfig = _config;
    final previousBaseSeed = _baseSeed;
    final previousPuzzleIndex = _puzzleIndex;
    final previousCurrentPuzzle = _currentPuzzle;

    _config = config;
    _baseSeed = baseSeed;
    _puzzleIndex = puzzleIndex;
    _currentPuzzle = null;

    final puzzle = _generateCurrent(
      keepTarget: keepTarget,
      fixedTarget: fixedTarget,
      targetMin: targetMin,
      targetMax: targetMax,
    );

    _config = previousConfig;
    _baseSeed = previousBaseSeed;
    _puzzleIndex = previousPuzzleIndex;
    _currentPuzzle = previousCurrentPuzzle;

    return puzzle;
  }

  Random createAnimationRandom() {
    return Random(PuzzleSeed.mix(_baseSeed, _puzzleIndex));
  }

  void reset([int startIndex = 0]) {
    _puzzleIndex = startIndex;
    _currentPuzzle = null;
  }
}
