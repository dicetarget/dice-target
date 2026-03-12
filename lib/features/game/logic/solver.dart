// lib/features/game/logic/solver.dart
//
// Solver für "Dice Target" gemäss deinen Regeln:
// - Move: wähle 2..n Werte, sortiere DESC, reduziere links->rechts
// - + und × immer
// - −: pro Schritt Richtung automatisch (kein negatives Zwischenergebnis), bei beiden möglich: größeres Ergebnis
// - ÷: pro Schritt Richtung automatisch, nur ohne Rest; wenn beide möglich: a/b bevorzugt
//
// Ergebnis liefert:
// - solvable
// - fullExpression: komplett geklammerter Ausdruck wie im Screenshot

class DiceSolveResult {
  final bool solvable;
  final String? fullExpression;

  const DiceSolveResult({required this.solvable, this.fullExpression});
}

class DiceSolver {
  DiceSolveResult solveMulti(List<int> diceValues, int target) {
    final nodes = diceValues.map((v) => _Node(v, v.toString())).toList();
    final seen = <String>{};

    final expr = _dfs(nodes, target, seen);
    if (expr == null) return const DiceSolveResult(solvable: false);
    return DiceSolveResult(solvable: true, fullExpression: expr);
  }

  String? _dfs(List<_Node> nodes, int target, Set<String> seen) {
    // memo by multiset of values (sorted)
    final key = (nodes.map((n) => n.value).toList()..sort()).join(',');
    if (seen.contains(key)) return null;
    seen.add(key);

    if (nodes.length == 1) {
      return nodes[0].value == target ? nodes[0].expr : null;
    }

    final n = nodes.length;

    // choose subset size 2..n
    for (int k = 2; k <= n; k++) {
      final combos = _combinations(n, k);
      for (final idxs in combos) {
        // build chosen subset nodes
        final chosen = [for (final i in idxs) nodes[i]];

        // try each op
        for (final op in _Op.values) {
          final merged = _reduceSubset(chosen, op);
          if (merged == null) continue;

          // new state: remove chosen indices, add merged
          final next = <_Node>[];
          for (int i = 0; i < n; i++) {
            if (!idxs.contains(i)) next.add(nodes[i]);
          }
          next.add(merged);

          final res = _dfs(next, target, seen);
          if (res != null) return res;
        }
      }
    }

    return null;
  }

  _Node? _reduceSubset(List<_Node> subset, _Op op) {
    // sort DESC by value as rule
    subset = List<_Node>.from(subset)
      ..sort((a, b) => b.value.compareTo(a.value));

    var acc = subset.first;
    for (int i = 1; i < subset.length; i++) {
      final next = subset[i];
      final combined = _combineStep(acc, next, op);
      if (combined == null) return null;
      acc = combined;
    }
    return acc;
  }

  _Node? _combineStep(_Node a, _Node b, _Op op) {
    switch (op) {
      case _Op.add:
        return _Node(a.value + b.value, '(${a.expr} + ${b.expr})');

      case _Op.mul:
        return _Node(a.value * b.value, '(${a.expr} × ${b.expr})');

      case _Op.sub:
        // same logic as your _applyStepAuto:
        final r1 = a.value - b.value;
        final r2 = b.value - a.value;
        final ok1 = r1 >= 0;
        final ok2 = r2 >= 0;

        if (ok1 && !ok2) {
          return _Node(r1, '(${a.expr} − ${b.expr})');
        }
        if (!ok1 && ok2) {
          return _Node(r2, '(${b.expr} − ${a.expr})');
        }
        if (ok1 && ok2) {
          // pick bigger (tie -> r1)
          if (r1 >= r2) {
            return _Node(r1, '(${a.expr} − ${b.expr})');
          } else {
            return _Node(r2, '(${b.expr} − ${a.expr})');
          }
        }
        return null;

      case _Op.div:
        // same logic as your _applyStepAuto:
        // prefer a/b if divisible, else b/a
        if (b.value != 0 && a.value % b.value == 0) {
          return _Node(a.value ~/ b.value, '(${a.expr} ÷ ${b.expr})');
        }
        if (a.value != 0 && b.value % a.value == 0) {
          return _Node(b.value ~/ a.value, '(${b.expr} ÷ ${a.expr})');
        }
        return null;
    }
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
  const _Node(this.value, this.expr);
}
