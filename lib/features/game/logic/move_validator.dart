// lib/features/game/logic/move_validator.dart

import 'package:dice/core/ui_op.dart';

class MoveValidator {
  const MoveValidator();

  int? applyStepStrict(int a, int b, UiOp op) {
    switch (op) {
      case UiOp.add:
        final result = a + b;
        return result > 0 ? result : null;

      case UiOp.mul:
        final result = a * b;
        return result > 0 ? result : null;

      case UiOp.sub:
        final r1 = a - b;
        final r2 = b - a;

        // nur strikt positive Ergebnisse erlaubt
        final ok1 = r1 > 0;
        final ok2 = r2 > 0;

        if (ok1 && !ok2) return r1;
        if (!ok1 && ok2) return r2;
        if (ok1 && ok2) {
          return (r1 >= r2) ? r1 : r2;
        }
        return null;

      case UiOp.div:
        if (b != 0 && a % b == 0) {
          final result = a ~/ b;
          if (result > 0) return result;
        }

        if (a != 0 && b % a == 0) {
          final result = b ~/ a;
          if (result > 0) return result;
        }

        return null;
    }
  }
}
