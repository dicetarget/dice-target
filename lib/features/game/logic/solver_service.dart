import 'package:dice/core/ui_op.dart';
import 'package:dice/features/game/logic/solver.dart';

class SolverCheckResult {
  final bool solvable;
  final String? fullExpression;
  final int expressionLength;
  final int? moveCount;

  const SolverCheckResult({
    required this.solvable,
    required this.fullExpression,
    required this.expressionLength,
    required this.moveCount,
  });
}

class NextMoveSuggestion {
  final List<int> selectedIndices;
  final UiOp operator;
  final int newValue;

  const NextMoveSuggestion({
    required this.selectedIndices,
    required this.operator,
    required this.newValue,
  });
}

class SolverService {
  final DiceSolver _solver;

  SolverService({DiceSolver? solver}) : _solver = solver ?? DiceSolver();

  SolverCheckResult check({required List<int> diceValues, required int target}) {
    final res = _solver.solveMulti(diceValues, target);
    final expression = res.fullExpression;

    return SolverCheckResult(
      solvable: res.solvable,
      fullExpression: expression,
      expressionLength: expression?.length ?? 0,
      moveCount: res.moveCount,
    );
  }

  NextMoveSuggestion? getNextOptimalMove({required List<int> diceValues, required int target}) {
    final result = check(diceValues: diceValues, target: target);
    if (!result.solvable) return null;

    final expression = result.fullExpression;
    if (expression == null || expression.isEmpty) return null;

    final firstMove = _extractFirstMove(expression);
    if (firstMove == null) return null;

    final indices = _findMatchingIndices(
      diceValues: diceValues,
      leftValue: firstMove.leftValue,
      rightValue: firstMove.rightValue,
    );
    if (indices == null) return null;

    final newValue = _computeNewValue(
      leftValue: firstMove.leftValue,
      rightValue: firstMove.rightValue,
      operatorSymbol: firstMove.operatorSymbol,
    );
    if (newValue == null) return null;

    final op = _mapOperator(firstMove.operatorSymbol);
    if (op == null) return null;

    return NextMoveSuggestion(selectedIndices: indices, operator: op, newValue: newValue);
  }

  _ParsedMove? _extractFirstMove(String expression) {
    // Unicode-Minus − (U+2212) statt ASCII-Minus - (U+002D)
    final match = RegExp(r'\((\d+)\s*([+−×÷])\s*(\d+)\)').firstMatch(expression);
    if (match == null) return null;

    final leftValue = int.tryParse(match.group(1) ?? '');
    final operatorSymbol = match.group(2);
    final rightValue = int.tryParse(match.group(3) ?? '');

    if (leftValue == null || operatorSymbol == null || rightValue == null) {
      return null;
    }

    return _ParsedMove(
      leftValue: leftValue,
      operatorSymbol: operatorSymbol,
      rightValue: rightValue,
    );
  }

  List<int>? _findMatchingIndices({
    required List<int> diceValues,
    required int leftValue,
    required int rightValue,
  }) {
    for (int i = 0; i < diceValues.length; i++) {
      if (diceValues[i] != leftValue) continue;

      for (int j = 0; j < diceValues.length; j++) {
        if (i == j) continue;
        if (diceValues[j] != rightValue) continue;

        return <int>[i, j];
      }
    }
    return null;
  }

  UiOp? _mapOperator(String symbol) {
    switch (symbol) {
      case '+':
        return UiOp.add;
      case '−': // Unicode-Minus U+2212
        return UiOp.sub;
      case '×':
        return UiOp.mul;
      case '÷':
        return UiOp.div;
      default:
        return null;
    }
  }

  int? _computeNewValue({
    required int leftValue,
    required int rightValue,
    required String operatorSymbol,
  }) {
    switch (operatorSymbol) {
      case '+':
        return leftValue + rightValue;
      case '−': // Unicode-Minus U+2212
        final result = leftValue - rightValue;
        return result > 0 ? result : null;
      case '×':
        return leftValue * rightValue;
      case '÷':
        if (rightValue == 0) return null;
        if (leftValue % rightValue != 0) return null;
        final result = leftValue ~/ rightValue;
        return result > 0 ? result : null;
      default:
        return null;
    }
  }
}

class _ParsedMove {
  final int leftValue;
  final String operatorSymbol;
  final int rightValue;

  const _ParsedMove({
    required this.leftValue,
    required this.operatorSymbol,
    required this.rightValue,
  });
}
