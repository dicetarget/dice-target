import 'dart:math';

import 'package:dice/core/difficulty_config.dart';
import 'package:dice/core/puzzle/game_mode.dart';
import 'package:dice/core/puzzle/puzzle.dart';
import 'package:dice/core/puzzle/puzzle_seed.dart';
import 'package:dice/features/game/logic/dice_generator.dart';
import 'package:dice/features/game/logic/solver_service.dart';
import 'package:dice/features/game/logic/target_generator.dart';

class PuzzleGenerator {
  static const int _maxGuaranteedAttempts = 60;
  static const List<int> _movePool = [2, 3, 4];

  /// Generiert eine tägliche Move-Target Verteilung per Seed.
  /// Kein Wert darf mehr als 2x vorkommen.
  static List<int> _dailyMoveTargets(int seed) {
    final rng = Random(seed ^ 0xABCDE123);
    final pool = List<int>.from(_movePool);
    final counts = <int, int>{};
    final result = <int>[];

    for (var i = 0; i < 5; i++) {
      pool.shuffle(rng);
      int? chosen;
      for (final candidate in pool) {
        if ((counts[candidate] ?? 0) < 2) {
          chosen = candidate;
          break;
        }
      }
      chosen ??= pool.first;
      counts[chosen] = (counts[chosen] ?? 0) + 1;
      result.add(chosen);
    }
    return result;
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

      case GameMode.rush:
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
    // Training-Modus: Range gesetzt → Solvability garantieren
    final bool guaranteeTraining = targetMin != null && targetMax != null && !keepTarget;

    if (guaranteeTraining) {
      for (var attempt = 0; attempt < _maxGuaranteedAttempts; attempt++) {
        final candidateSeed = PuzzleSeed.mix(seed, attempt);
        final random = Random(candidateSeed);
        final dice = _diceGenerator.generateDice(random);
        final target = _randomTargetInRange(random, min: targetMin, max: targetMax);
        final result = _solverService.check(diceValues: dice, target: target);
        if (!result.solvable) continue;
        return Puzzle(
          target: target,
          dice: dice,
          seed: candidateSeed,
          isGuaranteedSolvable: true,
          puzzleIndex: puzzleIndex,
        );
      }
      // Fallback: letzter Kandidat auch wenn unlösbar (sollte nie passieren)
    }

    // Free Play: kein Guarantee — original Logik
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
    final moveTargets = _dailyMoveTargets(baseSeed);
    final int? dailyTargetMoves = mode == GameMode.daily && puzzleIndex < moveTargets.length
        ? moveTargets[puzzleIndex]
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

      if (!result.solvable) continue; // ← erst prüfen

      if (mode == GameMode.rush) {
        return puzzle.copyWith(isGuaranteedSolvable: true); // ← dann zurückgeben
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
      case GameMode.rush:
        return 0xC0FFEE01;
    }
  }
}
