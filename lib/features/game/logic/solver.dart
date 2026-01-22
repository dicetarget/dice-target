enum Op { add, sub, mul, div }

String opSymbol(Op op) => switch (op) {
      Op.add => '+',
      Op.sub => '-',
      Op.mul => '×',
      Op.div => '÷',
    };

class SolveStep {
  final List<int> before;
  final List<int> after;
  final List<int> usedIndicesBefore;
  final int resultIndexAfter;

  final int a;
  final int b;
  final Op op;
  final int r;

  final String exprA;
  final String exprB;
  final String exprR;

  const SolveStep({
    required this.before,
    required this.after,
    required this.usedIndicesBefore,
    required this.resultIndexAfter,
    required this.a,
    required this.b,
    required this.op,
    required this.r,
    required this.exprA,
    required this.exprB,
    required this.exprR,
  });
}

class SolveResult {
  final bool solvable;
  final List<SolveStep> steps;
  final String? fullExpression;

  const SolveResult({
    required this.solvable,
    required this.steps,
    this.fullExpression,
  });
}

/// Regeln:
/// - +, -, ×, ÷
/// - Division nur ohne Rest
/// - keine negativen Zwischenergebnisse
/// - Ziel erreicht: genau 1 Zahl übrig und == target
class DiceSolver {
  final int maxStates;
  DiceSolver({this.maxStates = 140000});

  SolveResult solve(List<int> dice, int target) {
    final startVals = List<int>.from(dice);
    final startExpr = dice.map((v) => v.toString()).toList();

    final queue = <_Node>[
      _Node(values: startVals, exprs: startExpr, steps: const [])
    ];
    final seen = <String>{_keyOf(startVals)};

    int visited = 0;
    while (queue.isNotEmpty) {
      final node = queue.removeAt(0);
      visited++;
      if (visited > maxStates) break;

      final values = node.values;
      final exprs = node.exprs;

      if (values.length == 1 && values[0] == target) {
        return SolveResult(
          solvable: true,
          steps: node.steps,
          fullExpression: exprs[0],
        );
      }

      for (int i = 0; i < values.length; i++) {
        for (int j = i + 1; j < values.length; j++) {
          final a = values[i];
          final b = values[j];
          final ea = exprs[i];
          final eb = exprs[j];

          final candidates = <_Cand>[];

          // +, ×
          candidates.add(_Cand(op: Op.add, a: a, b: b, r: a + b, exprR: '($ea + $eb)'));
          candidates.add(_Cand(op: Op.mul, a: a, b: b, r: a * b, exprR: '($ea × $eb)'));

          // - (beide Richtungen), keine negativen Ergebnisse
          if (a - b >= 0) candidates.add(_Cand(op: Op.sub, a: a, b: b, r: a - b, exprR: '($ea - $eb)'));
          if (b - a >= 0) candidates.add(_Cand(op: Op.sub, a: b, b: a, r: b - a, exprR: '($eb - $ea)'));

          // ÷ (beide Richtungen), nur wenn teilbar
          if (b != 0 && a % b == 0) candidates.add(_Cand(op: Op.div, a: a, b: b, r: a ~/ b, exprR: '($ea ÷ $eb)'));
          if (a != 0 && b % a == 0) candidates.add(_Cand(op: Op.div, a: b, b: a, r: b ~/ a, exprR: '($eb ÷ $ea)'));

          for (final c in candidates) {
            final nextVals = <int>[];
            final nextExpr = <String>[];

            for (int k = 0; k < values.length; k++) {
              if (k == i || k == j) continue;
              nextVals.add(values[k]);
              nextExpr.add(exprs[k]);
            }
            nextVals.add(c.r);
            nextExpr.add(c.exprR);

            final key = _keyOf(nextVals);
            if (seen.contains(key)) continue;
            seen.add(key);

            final before = List<int>.from(values);
            final after = List<int>.from(nextVals);

            final step = SolveStep(
              before: before,
              after: after,
              usedIndicesBefore: [i, j],
              resultIndexAfter: after.length - 1,
              a: c.a,
              b: c.b,
              op: c.op,
              r: c.r,
              exprA: ea,
              exprB: eb,
              exprR: c.exprR,
            );

            queue.add(_Node(values: nextVals, exprs: nextExpr, steps: [...node.steps, step]));
          }
        }
      }
    }

    return const SolveResult(solvable: false, steps: []);
  }

  String _keyOf(List<int> vals) {
    final s = List<int>.from(vals)..sort();
    return s.join(',');
  }
}

class _Node {
  final List<int> values;
  final List<String> exprs;
  final List<SolveStep> steps;
  _Node({required this.values, required this.exprs, required this.steps});
}

class _Cand {
  final Op op;
  final int a;
  final int b;
  final int r;
  final String exprR;
  _Cand({required this.op, required this.a, required this.b, required this.r, required this.exprR});
}
