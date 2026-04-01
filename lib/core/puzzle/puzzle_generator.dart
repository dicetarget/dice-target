import 'dart:math';

import 'package:dice/core/difficulty_config.dart';
import 'package:dice/core/puzzle/game_mode.dart';
import 'package:dice/core/puzzle/puzzle.dart';
import 'package:dice/core/puzzle/puzzle_seed.dart';
import 'package:dice/features/game/logic/dice_generator.dart';
import 'package:dice/features/game/logic/solver_service.dart';
import 'package:dice/features/game/logic/target_generator.dart';

class PuzzleGenerator {
  static const int _maxGuaranteedAttempts = 40;

  // Pool A: Puzzles 0-2 (tiefe Targets 20-50) — 2, 3 oder 4 Moves möglich
  static List<int> _generateDailyMoveTargets(int baseSeed) {
    for (var attempt = 0; attempt < 1000; attempt++) {
      final rng = Random(baseSeed ^ (attempt * 0x9E3779B9));
      final moves = List.generate(5, (_) => 2 + rng.nextInt(3));
      final counts = <int, int>{};
      for (final m in moves) {
        counts[m] = (counts[m] ?? 0) + 1;
      }
      if (counts.values.every((c) => c < 3)) return moves;
    }
    return [2, 3, 4, 3, 2]; // garantiert valider Fallback
  }

  static int dailyMoveTarget(int baseSeed, int puzzleIndex) {
    return _generateDailyMoveTargets(baseSeed)[puzzleIndex];
  }

  final DiceGenerator _diceGenerator;
  final TargetGenerator _targetGenerator;
  final SolverService _solverService;

  PuzzleGenerator({
    DiceGenerator? diceGenerator,
    TargetGenerator? targetGenerator,
    SolverService? solverService,
  }) : _diceGenerator = diceGenerator ?? const DiceGenerator(),
       _targetGenerator = targetGenerator ?? const TargetGenerator(),
       _solverService = solverService ?? SolverService();

  Puzzle generate({
    required GameMode mode,
    required DifficultyConfig config,
    required int seed,
    int puzzleIndex = 0,
    bool keepTarget = false,
    int? fixedTarget,
    int? targetMin,
    int? targetMax,
  }) {
    switch (mode) {
      case GameMode.practice:
        final practiceSeed = PuzzleSeed.mix(seed, puzzleIndex);
        return _generatePracticePuzzle(
          config: config,
          seed: practiceSeed,
          puzzleIndex: puzzleIndex,
          keepTarget: keepTarget,
          fixedTarget: fixedTarget,
          targetMin: targetMin,
          targetMax: targetMax,
        );

      case GameMode.daily:
      case GameMode.vs:
        return _generateGuaranteedPuzzle(
          mode: mode,
          config: config,
          baseSeed: seed,
          puzzleIndex: puzzleIndex,
          keepTarget: keepTarget,
          fixedTarget: fixedTarget,
          targetMin: targetMin,
          targetMax: targetMax,
        );
    }
  }

  Puzzle _generatePracticePuzzle({
    required DifficultyConfig config,
    required int seed,
    required int puzzleIndex,
    required bool keepTarget,
    required int? fixedTarget,
    required int? targetMin,
    required int? targetMax,
  }) {
    final random = Random(seed);

    final dice = keepTarget
        ? _diceGenerator.generateDiceKeepTarget(random)
        : _diceGenerator.generateDice(random);

    final target = keepTarget && fixedTarget != null
        ? fixedTarget
        : _randomTarget(config, random, targetMin: targetMin, targetMax: targetMax);

    return Puzzle(
      target: target,
      dice: dice,
      seed: seed,
      isGuaranteedSolvable: false,
      puzzleIndex: puzzleIndex,
    );
  }

  Puzzle _generateGuaranteedPuzzle({
    required GameMode mode,
    required DifficultyConfig config,
    required int baseSeed,
    required int puzzleIndex,
    required bool keepTarget,
    required int? fixedTarget,
    required int? targetMin,
    required int? targetMax,
  }) {
    final modeSalt = _modeSalt(mode);
    final indexedBaseSeed = PuzzleSeed.mix(baseSeed ^ modeSalt, puzzleIndex);
    final int? dailyTargetMoves = mode == GameMode.daily && puzzleIndex < 5
        ? dailyMoveTarget(baseSeed, puzzleIndex)
        : null;

    Puzzle? bestPuzzle;
    int bestScore = -1;

    for (var attempt = 0; attempt < _maxGuaranteedAttempts; attempt++) {
      final candidateSeed = PuzzleSeed.mix(indexedBaseSeed, attempt);
      final random = Random(candidateSeed);

      final puzzle = _buildGuaranteedCandidate(
        config: config,
        random: random,
        seed: candidateSeed,
        puzzleIndex: puzzleIndex,
        keepTarget: keepTarget,
        fixedTarget: fixedTarget,
        targetMin: targetMin,
        targetMax: targetMax,
      );

      final result = _solverService.check(diceValues: puzzle.dice, target: puzzle.target);

      if (!result.solvable) {
        continue;
      }

      if (mode == GameMode.daily) {
        final moveCount = result.moveCount;

        if (moveCount == null) {
          continue;
        }

        if (moveCount == 1) {
          continue;
        }

        if (moveCount > 4) {
          continue;
        }

        if (result.expressionLength < 7) {
          continue;
        }

        final bool shouldFallbackToRangeOnly = attempt >= (_maxGuaranteedAttempts - 20);

        if (!shouldFallbackToRangeOnly &&
            dailyTargetMoves != null &&
            moveCount != dailyTargetMoves) {
          continue;
        }

        return puzzle.copyWith(isGuaranteedSolvable: true);
      }

      final score = _scoreGuaranteedPuzzle(
        puzzle: puzzle,
        expressionLength: result.expressionLength,
      );

      if (score > bestScore) {
        bestScore = score;
        bestPuzzle = puzzle;
      }
    }

    if (bestPuzzle != null) {
      return bestPuzzle.copyWith(isGuaranteedSolvable: true);
    }

    throw StateError(
      'No solvable puzzle found for mode=$mode, seed=$baseSeed, puzzleIndex=$puzzleIndex '
      'after $_maxGuaranteedAttempts attempts.',
    );
  }

  Puzzle _buildGuaranteedCandidate({
    required DifficultyConfig config,
    required Random random,
    required int seed,
    required int puzzleIndex,
    required bool keepTarget,
    required int? fixedTarget,
    required int? targetMin,
    required int? targetMax,
  }) {
    if (keepTarget && fixedTarget != null) {
      final dice = _diceGenerator.generateDiceKeepTarget(random);

      return Puzzle(
        target: fixedTarget,
        dice: dice,
        seed: seed,
        isGuaranteedSolvable: false,
        puzzleIndex: puzzleIndex,
      );
    }

    final dice = _diceGenerator.generateDice(random);

    final target = targetMin != null && targetMax != null
        ? _randomTargetInRange(random, min: targetMin, max: targetMax)
        : _targetGenerator.generateTarget(dice: dice, config: config, random: random);

    return Puzzle(
      target: target,
      dice: dice,
      seed: seed,
      isGuaranteedSolvable: false,
      puzzleIndex: puzzleIndex,
    );
  }

  int _scoreGuaranteedPuzzle({required Puzzle puzzle, required int expressionLength}) {
    final uniqueDiceCount = puzzle.dice.toSet().length;
    final diceSum = puzzle.dice.fold<int>(0, (sum, value) => sum + value);
    final distanceFromSum = (puzzle.target - diceSum).abs();

    var score = 0;

    score += uniqueDiceCount * 100;
    score += min(distanceFromSum, 200);
    score -= expressionLength;

    if (puzzle.target >= 20) score += 25;
    if (puzzle.target >= 30) score += 25;
    if (puzzle.target >= 40) score += 25;

    return score;
  }

  int _randomTarget(DifficultyConfig config, Random random, {int? targetMin, int? targetMax}) {
    if (targetMin != null && targetMax != null) {
      return _randomTargetInRange(random, min: targetMin, max: targetMax);
    }

    return random.nextInt(config.maxTarget) + 1;
  }

  int _randomTargetInRange(Random random, {required int min, required int max}) {
    if (max < min) {
      throw ArgumentError('targetMax must be >= targetMin');
    }

    return min + random.nextInt(max - min + 1);
  }

  int _modeSalt(GameMode mode) {
    switch (mode) {
      case GameMode.practice:
        return 0x13579BDF;
      case GameMode.daily:
        return 0x2468ACE1;
      case GameMode.vs:
        return 0x10293847;
    }
  }
}
