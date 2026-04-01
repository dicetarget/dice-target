import 'package:dice/features/game/hints/domain/hint.dart';
import 'package:dice/features/game/hints/domain/hint_engine.dart';
import 'package:dice/features/game/hints/domain/hint_level.dart';
import 'package:dice/features/game/hints/domain/hint_request.dart';
import 'package:dice/features/game/hints/domain/hint_result.dart';

class SolverHintEngine extends HintEngine {
  const SolverHintEngine();

  @override
  HintResult generate({required HintRequest request, required HintLevel level}) {
    switch (level) {
      case HintLevel.direction:
        return const HintResult(
          hint: Hint(level: HintLevel.direction, text: 'Try combining the larger dice first.'),
          hasSolution: true,
        );

      case HintLevel.nextStep:
        return const HintResult(
          hint: Hint(level: HintLevel.nextStep, text: 'Try building an intermediate value.'),
          hasSolution: true,
        );

      case HintLevel.fullSolution:
        return const HintResult(
          hint: Hint(
            level: HintLevel.fullSolution,
            text: 'Solution reveal will be connected to the solver later.',
          ),
          hasSolution: true,
        );
    }
  }
}
