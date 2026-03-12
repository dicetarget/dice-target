// lib/features/game/logic/target_generator.dart

import 'dart:math';

import 'package:dice/core/difficulty_config.dart';
import 'package:dice/features/game/logic/solver.dart';

class TargetGenerator {
  const TargetGenerator();

  int generateTarget({
    required List<int> dice,
    required DifficultyConfig config,
    required Random random,
  }) {
    final solver = DiceSolver();

    while (true) {
      final target = _randomTarget(config, random);
      final result = solver.solveMulti(dice, target);

      if (result.solvable) {
        return target;
      }
    }
  }

  int _randomTarget(DifficultyConfig config, Random random) {
    return random.nextInt(config.maxTarget) + 1;
  }
}
