import 'package:dice/features/game/logic/solver.dart';

class SolverCheckResult {
  final bool solvable;
  final String? fullExpression;

  const SolverCheckResult({
    required this.solvable,
    required this.fullExpression,
  });
}

class SolverService {
  final DiceSolver _solver;

  SolverService({DiceSolver? solver}) : _solver = solver ?? DiceSolver();

  SolverCheckResult check({
    required List<int> diceValues,
    required int target,
  }) {
    final res = _solver.solveMulti(diceValues, target);

    return SolverCheckResult(
      solvable: res.solvable,
      fullExpression: res.fullExpression,
    );
  }
}
