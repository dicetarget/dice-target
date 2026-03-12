// lib/features/game/logic/move_validator.dart

import 'package:dice/core/ui_op.dart';

class MoveValidator {
  const MoveValidator();

  int? applyStepStrict(int a, int b, UiOp op) {
    switch (op) {
      case UiOp.add:
        return a + b;

      case UiOp.mul:
        return a * b;

      case UiOp.sub:
        final r1 = a - b;
        final r2 = b - a;
        final ok1 = r1 >= 0;
        final ok2 = r2 >= 0;

        if (ok1 && !ok2) return r1;
        if (!ok1 && ok2) return r2;
        if (ok1 && ok2) {
          return (r1 >= r2) ? r1 : r2;
        }
        return null;

      case UiOp.div:
        if (b != 0 && a % b == 0) return a ~/ b;
        if (a != 0 && b % a == 0) return b ~/ a;
        return null;
    }
  }
}
