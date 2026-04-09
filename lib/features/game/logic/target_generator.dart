import 'dart:math';

import 'package:dice/core/difficulty_config.dart';
import 'package:dice/features/game/logic/solver.dart';

class TargetGenerator {
  static const int _maxAttempts = 200;

  const TargetGenerator();

  int generateTarget({
    required List<int> dice,
    required DifficultyConfig config,
    required Random random,
  }) {
    final solver = DiceSolver();

    int? bestTarget;
    int bestScore = -1;

    for (var i = 0; i < _maxAttempts; i++) {
      final target = _randomTarget(config, random);
      final result = solver.solveMulti(dice, target);

      if (!result.solvable) {
        continue;
      }

      final expression = result.fullExpression;
      final expressionLength = expression?.length ?? 0;
      final score = _scoreTarget(target: target, expressionLength: expressionLength);

      if (score > bestScore) {
        bestScore = score;
        bestTarget = target;
      }
    }

    if (bestTarget != null) {
      return bestTarget;
    }

    while (true) {
      final target = _randomTarget(config, random);
      final result = solver.solveMulti(dice, target);

      if (result.solvable) {
        return target;
      }
    }
  }

  int _scoreTarget({required int target, required int expressionLength}) {
    var score = 0;

    score += target;
    score -= expressionLength;

    if (target >= 20) score += 20;
    if (target >= 30) score += 20;
    if (target >= 40) score += 20;

    return score;
  }

  int _randomTarget(DifficultyConfig config, Random random) {
    return random.nextInt(config.maxTarget) + 1;
  }
}
