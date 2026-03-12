// lib/features/game/logic/move_engine.dart

import 'package:dice/core/ui_op.dart';
import 'package:dice/features/game/logic/move_validator.dart';

class MoveEngine {
  const MoveEngine();

  int? combineValues(List<int> values, UiOp op) {
    if (values.length < 2) return null;

    final sorted = List<int>.from(values)..sort((a, b) => b.compareTo(a));

    var acc = sorted.first;

    for (int i = 1; i < sorted.length; i++) {
      final next = sorted[i];

      final step = const MoveValidator().applyStepStrict(acc, next, op);
      if (step == null) return null;

      acc = step;
    }

    return acc;
  }
}
