// lib/features/game/logic/round_evaluator.dart

import 'package:dice/core/game_rules.dart';

class RoundEvaluator {
  const RoundEvaluator();

  GameState evaluate({
    required int target,
    required int finalValue,
    required GameRules rules,
  }) {
    return rules.checkResult(finalValue);
  }
}
