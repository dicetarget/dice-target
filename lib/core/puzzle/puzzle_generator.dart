import 'dart:math';

import 'package:dice/core/difficulty_config.dart';
import 'package:dice/core/puzzle/game_mode.dart';
import 'package:dice/core/puzzle/puzzle.dart';
import 'package:dice/core/puzzle/puzzle_seed.dart';
import 'package:dice/features/game/logic/dice_generator.dart';
import 'package:dice/features/game/logic/solver_service.dart';
import 'package:dice/features/game/logic/target_generator.dart';

class PuzzleGenerator {
  static const int _maxGuaranteedAttempts = 500;

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
        );
    }
  }

  Puzzle _generatePracticePuzzle({
    required DifficultyConfig config,
    required int seed,
    required int puzzleIndex,
    required bool keepTarget,
    required int? fixedTarget,
  }) {
    final random = Random(seed);

    final dice = keepTarget
        ? _diceGenerator.generateDiceKeepTarget(random)
        : _diceGenerator.generateDice(random);

    final target = keepTarget && fixedTarget != null
        ? fixedTarget
        : _randomTarget(config, random);

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
  }) {
    final modeSalt = _modeSalt(mode);
    final indexedBaseSeed = PuzzleSeed.mix(baseSeed ^ modeSalt, puzzleIndex);

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
      );

      final result = _solverService.check(
        diceValues: puzzle.dice,
        target: puzzle.target,
      );

      if (result.solvable) {
        return puzzle.copyWith(isGuaranteedSolvable: true);
      }
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
    final target = _targetGenerator.generateTarget(
      dice: dice,
      config: config,
      random: random,
    );

    return Puzzle(
      target: target,
      dice: dice,
      seed: seed,
      isGuaranteedSolvable: false,
      puzzleIndex: puzzleIndex,
    );
  }

  int _randomTarget(DifficultyConfig config, Random random) {
    return random.nextInt(config.maxTarget) + 1;
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
