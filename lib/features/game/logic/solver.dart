// lib/features/game/logic/solver.dart
//
// Solver für "Dice Target" gemäss deinen Regeln:
// - Move: wähle 2..n Werte, sortiere DESC, reduziere links->rechts
// - + und × immer
// - −: pro Schritt Richtung automatisch, aber nur mit POSITIVEM Ergebnis (> 0)
// - ÷: pro Schritt Richtung automatisch, nur ohne Rest und nur mit POSITIVEM Ergebnis (> 0)
// - 0 und negative Zwischenergebnisse sind verboten
//
// Ergebnis liefert:
// - solvable
// - fullExpression: komplett geklammerter Ausdruck wie im Screenshot
// - moveCount: Anzahl tatsächlicher Merges/Spielzüge der besten gefundenen Lösung

class DiceSolveResult {
  final bool solvable;
  final String? fullExpression;
  final int? moveCount;

  const DiceSolveResult({required this.solvable, this.fullExpression, this.moveCount});
}

class DiceSolver {
  static const int _maxMoves = 4;

  DiceSolveResult solveMulti(List<int> diceValues, int target) {
    final nodes = diceValues.map((v) => _Node(v, v.toString(), 0)).toList();
    final memo = <String, _Node?>{};

    final bestNode = _dfs(nodes, target, memo);
    if (bestNode == null) {
      return const DiceSolveResult(solvable: false);
    }

    return DiceSolveResult(
      solvable: true,
      fullExpression: bestNode.expr,
      moveCount: bestNode.moves,
    );
  }

  _Node? _dfs(List<_Node> nodes, int target, Map<String, _Node?> memo) {
    if (nodes.isEmpty) return null;

    final currentMovesSpent = nodes.fold<int>(0, (sum, n) => sum + n.moves);

    if (currentMovesSpent > _maxMoves) return null;
    if (nodes.length > 1 && currentMovesSpent >= _maxMoves) return null;

    final key = _stateKey(nodes, target);
    if (memo.containsKey(key)) {
      return memo[key];
    }

    if (nodes.length == 1) {
      final result = nodes[0].value == target ? nodes[0] : null;
      memo[key] = result;
      return result;
    }

    final n = nodes.length;
    _Node? bestSolution;
    int? bestMoves;

    for (int k = 2; k <= n; k++) {
      final combos = _combinations(n, k);

      for (final idxs in combos) {
        final chosen = [for (final i in idxs) nodes[i]];

        for (final op in _Op.values) {
          final merged = _reduceSubset(chosen, op);
          if (merged == null) continue;
          if (merged.value <= 0) continue;
          if (merged.moves > _maxMoves) continue;
          if (bestMoves != null && merged.moves >= bestMoves) continue;

          final next = <_Node>[];
          for (int i = 0; i < n; i++) {
            if (!idxs.contains(i)) next.add(nodes[i]);
          }
          next.add(merged);

          final nextMovesSpent = next.fold<int>(0, (sum, node) => sum + node.moves);
          if (nextMovesSpent > _maxMoves) continue;
          if (next.length > 1 && nextMovesSpent >= _maxMoves) continue;

          final candidate = _dfs(next, target, memo);
          if (candidate == null) continue;

          if (bestMoves != null && candidate.moves >= bestMoves) continue;

          if (_isBetterSolution(candidate, bestSolution)) {
            bestSolution = candidate;
            bestMoves = candidate.moves;
          }
        }
      }
    }

    memo[key] = bestSolution;
    return bestSolution;
  }

  bool _isBetterSolution(_Node candidate, _Node? currentBest) {
    if (currentBest == null) return true;

    if (candidate.moves != currentBest.moves) {
      return candidate.moves < currentBest.moves;
    }

    return candidate.expr.length < currentBest.expr.length;
  }

  _Node? _reduceSubset(List<_Node> subset, _Op op) {
    subset = List<_Node>.from(subset)..sort((a, b) => b.value.compareTo(a.value));

    var acc = subset.first;
    for (int i = 1; i < subset.length; i++) {
      final next = subset[i];
      final combined = _combineStep(acc, next, op);
      if (combined == null) return null;
      if (combined.value <= 0) return null;
      acc = combined;
    }

    final previousMoves = subset.fold<int>(0, (sum, node) => sum + node.moves);
    final totalMoves = previousMoves + 1;

    if (totalMoves > _maxMoves) return null;

    return _Node(acc.value, acc.expr, totalMoves);
  }

  _Node? _combineStep(_Node a, _Node b, _Op op) {
    switch (op) {
      case _Op.add:
        final result = a.value + b.value;
        return result > 0 ? _Node(result, '(${a.expr} + ${b.expr})', 0) : null;

      case _Op.mul:
        final result = a.value * b.value;
        return result > 0 ? _Node(result, '(${a.expr} × ${b.expr})', 0) : null;

      case _Op.sub:
        final r1 = a.value - b.value;
        final r2 = b.value - a.value;
        final ok1 = r1 > 0;
        final ok2 = r2 > 0;

        if (ok1 && !ok2) {
          return _Node(r1, '(${a.expr} − ${b.expr})', 0);
        }
        if (!ok1 && ok2) {
          return _Node(r2, '(${b.expr} − ${a.expr})', 0);
        }
        if (ok1 && ok2) {
          if (r1 >= r2) {
            return _Node(r1, '(${a.expr} − ${b.expr})', 0);
          } else {
            return _Node(r2, '(${b.expr} − ${a.expr})', 0);
          }
        }
        return null;

      case _Op.div:
        if (b.value != 0 && a.value % b.value == 0) {
          final result = a.value ~/ b.value;
          if (result > 0) {
            return _Node(result, '(${a.expr} ÷ ${b.expr})', 0);
          }
        }
        if (a.value != 0 && b.value % a.value == 0) {
          final result = b.value ~/ a.value;
          if (result > 0) {
            return _Node(result, '(${b.expr} ÷ ${a.expr})', 0);
          }
        }
        return null;
    }
  }

  String _stateKey(List<_Node> nodes, int target) {
    final parts = nodes.map((n) => '${n.value}|${n.moves}|${n.expr}').toList()..sort();
    return '$target::${parts.join(',')}';
  }

  List<List<int>> _combinations(int n, int k) {
    final result = <List<int>>[];

    void rec(int start, List<int> cur) {
      if (cur.length == k) {
        result.add(List<int>.from(cur));
        return;
      }
      for (int i = start; i < n; i++) {
        cur.add(i);
        rec(i + 1, cur);
        cur.removeLast();
      }
    }

    rec(0, []);
    return result;
  }
}

enum _Op { add, sub, mul, div }

class _Node {
  final int value;
  final String expr;
  final int moves;

  const _Node(this.value, this.expr, this.moves);
}
