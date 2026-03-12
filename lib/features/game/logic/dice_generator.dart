// lib/features/game/logic/dice_generator.dart

import 'dart:math';

class DiceGenerator {
  const DiceGenerator();

  /// Generates a completely new set of dice
  List<int> generateDice(Random random) {
    return List.generate(5, (_) => random.nextInt(6) + 1);
  }

  /// Generates new dice but keeps the existing target
  /// (used when only dice should re-roll)
  List<int> generateDiceKeepTarget(Random random) {
    return List.generate(5, (_) => random.nextInt(6) + 1);
  }
}
