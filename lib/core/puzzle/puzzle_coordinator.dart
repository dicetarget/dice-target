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

  void reconfigure({
    required DifficultyConfig config,
    required int baseSeed,
    int startIndex = 0,
  }) {
    _config = config;
    _baseSeed = baseSeed;
    _puzzleIndex = startIndex;
    _currentPuzzle = null;
  }

  void reconfigureIfNeeded({
    required DifficultyConfig config,
    int? seed,
    int? puzzleIndex,
  }) {
    if (seed == null && puzzleIndex == null && config == _config) {
      return;
    }

    reconfigure(
      config: config,
      baseSeed: seed ?? _baseSeed,
      startIndex: puzzleIndex ?? _puzzleIndex,
    );
  }

  Puzzle _generateCurrent({bool keepTarget = false, int? fixedTarget}) {
    final puzzle = _generator.generate(
      mode: mode,
      config: _config,
      seed: _baseSeed,
      puzzleIndex: _puzzleIndex,
      keepTarget: keepTarget,
      fixedTarget: fixedTarget,
    );

    _currentPuzzle = puzzle;
    return puzzle;
  }

  Puzzle currentPuzzle({bool keepTarget = false, int? fixedTarget}) {
    if (_currentPuzzle != null && !keepTarget && fixedTarget == null) {
      return _currentPuzzle!;
    }

    return _generateCurrent(keepTarget: keepTarget, fixedTarget: fixedTarget);
  }

  Puzzle nextPuzzle({bool keepTarget = false, int? fixedTarget}) {
    _puzzleIndex++;
    return _generateCurrent(keepTarget: keepTarget, fixedTarget: fixedTarget);
  }

  Puzzle resetAndGetFirstPuzzle({bool keepTarget = false, int? fixedTarget}) {
    _puzzleIndex = 0;
    _currentPuzzle = null;
    return _generateCurrent(keepTarget: keepTarget, fixedTarget: fixedTarget);
  }

  Puzzle startNewRun({int? seed}) {
    reconfigure(config: _config, baseSeed: seed ?? _baseSeed, startIndex: 0);

    return currentPuzzle();
  }

  Puzzle startNewPracticeRun() {
    return startNewRun(seed: PuzzleSeed.practiceSeed());
  }

  Puzzle rerollKeepingTarget(int target) {
    return nextPuzzle(keepTarget: true, fixedTarget: target);
  }

  Puzzle createRoundPuzzle({
    required bool keepTarget,
    int? fixedTarget,
    required bool wasReconfigured,
  }) {
    if (keepTarget) {
      return wasReconfigured
          ? currentPuzzle(keepTarget: true, fixedTarget: fixedTarget)
          : rerollKeepingTarget(fixedTarget!);
    }

    return wasReconfigured ? currentPuzzle() : startNewPracticeRun();
  }

  Random createAnimationRandom() {
    return Random(PuzzleSeed.mix(_baseSeed, _puzzleIndex));
  }

  void reset([int startIndex = 0]) {
    _puzzleIndex = startIndex;
    _currentPuzzle = null;
  }
}
