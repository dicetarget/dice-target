import 'dart:math';

import 'package:dice/core/difficulty_config.dart';
import 'package:dice/core/extensions/difficulty_extensions.dart';
import 'package:dice/core/puzzle/puzzle.dart';
import 'package:dice/core/theme/app_durations.dart';
import 'package:dice/features/game/presentation/animations/dice_roll_controller.dart';
import 'package:dice/features/game/presentation/animations/target_roll_controller.dart';

class PracticeRoundFlowCoordinator {
  final TargetRollController targetRollController;
  final DiceRollController diceRollController;

  const PracticeRoundFlowCoordinator({
    required this.targetRollController,
    required this.diceRollController,
  });

  Future<Puzzle?> rollPuzzle({
    required Puzzle puzzle,
    required Difficulty difficulty,
    required DifficultyConfig config,
    required Random random,
    required bool keepTarget,
    required bool Function() isActive,
    required void Function({
      required bool isRollingTarget,
      required bool isRollingDice,
      int? target,
    })
    onUiState,
  }) async {
    if (!keepTarget) {
      await targetRollController.roll(
        random: random,
        config: config,
        finalTarget: puzzle.target,
        lockDelay: AppDurations.rollStart,
        intervalMs: _targetRollIntervalMs(difficulty),
      );

      if (!isActive()) return null;

      onUiState(
        target: puzzle.target,
        isRollingTarget: false,
        isRollingDice: true,
      );
    } else {
      targetRollController.startIdle(initialValue: puzzle.target);

      if (!isActive()) return null;

      onUiState(
        target: puzzle.target,
        isRollingTarget: false,
        isRollingDice: true,
      );
    }

    await diceRollController.roll(
      random: random,
      finalDice: puzzle.dice,
      duration: keepTarget ? AppDurations.rollDice : AppDurations.rollTarget,
      intervalMs: _diceRollIntervalMs(difficulty),
    );

    if (!isActive()) return null;

    targetRollController.startIdle(initialValue: puzzle.target);
    diceRollController.startIdle(initialDice: List<int>.from(puzzle.dice));

    return puzzle;
  }

  void resetToIdle({
    required int initialTarget,
    required List<int> initialDice,
  }) {
    targetRollController.startIdle(initialValue: initialTarget);
    diceRollController.startIdle(initialDice: initialDice);
  }

  int _targetRollIntervalMs(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return 40;
      case Difficulty.medium:
        return 40;
      case Difficulty.hard:
        return 40;
    }
  }

  int _diceRollIntervalMs(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return 55;
      case Difficulty.medium:
        return 55;
      case Difficulty.hard:
        return 55;
    }
  }
}
