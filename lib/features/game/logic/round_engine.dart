// lib/features/game/logic/round_engine.dart

import 'dart:math';

import 'package:dice/core/difficulty_config.dart';
import 'package:dice/features/game/logic/dice_generator.dart';
import 'package:dice/features/game/logic/game_round.dart';
import 'package:dice/features/game/logic/target_generator.dart';

class RoundEngine {
  final DiceGenerator _diceGenerator;
  final TargetGenerator _targetGenerator;

  const RoundEngine({
    DiceGenerator diceGenerator = const DiceGenerator(),
    TargetGenerator targetGenerator = const TargetGenerator(),
  }) : _diceGenerator = diceGenerator,
       _targetGenerator = targetGenerator;

  GameRound startRound({
    required DifficultyConfig config,
    required Random random,
  }) {
    final dice = _diceGenerator.generateDice(random);

    final target = _targetGenerator.generateTarget(
      dice: dice,
      config: config,
      random: random,
    );

    return GameRound(
      target: target,
      dice: dice,
      moves: 0,
      status: RoundStatus.playing,
      endReason: null,
    );
  }

  GameRound rerollDiceKeepTarget({
    required GameRound round,
    required Random random,
  }) {
    final newDice = _diceGenerator.generateDiceKeepTarget(random);

    return round.copyWith(dice: newDice);
  }
}
