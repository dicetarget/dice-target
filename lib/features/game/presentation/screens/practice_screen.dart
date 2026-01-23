import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:dice/core/extensions/difficulty_extensions.dart';
import 'package:dice/features/game/logic/solver.dart';
import 'package:dice/features/game/presentation/widgets/die_face.dart';

enum RoundPhase { preStart, rolling, ready, playing, ended }

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final Random _rng = Random();
  final DiceSolver _solver = DiceSolver();

  Difficulty _difficulty = Difficulty.easy;
  RoundPhase _phase = RoundPhase.preStart;

  // Game state
  List<int> _dice = [];
  int _target = 0;

  // For Reset Dice + for "show initial dice on impossible lose"
  List<int> _initialDice = [];
  int _initialTarget = 0;

  // Selection: allow 2..n
  final Set<int> _selected = <int>{};

  // Moves
  int _moves = 0;

  // Rolling animation state
  bool _busy = false;
  int _rollingTarget = 0;
  List<int> _rollingDice = List<int>.filled(5, 1);
  Timer? _rollTimer;
  Timer? _endTimer;

  @override
  void initState() {
    super.initState();
    _goToPreStart();
  }

  @override
  void dispose() {
    _rollTimer?.cancel();
    _endTimer?.cancel();
    super.dispose();
  }

  // ---------- Phase helpers ----------
  bool get _isPreStart => _phase == RoundPhase.preStart;
  bool get _isRolling => _phase == RoundPhase.rolling;
  bool get _isReady => _phase == RoundPhase.ready;
  bool get _isPlaying => _phase == RoundPhase.playing;

  void _goToPreStart() {
    _rollTimer?.cancel();
    _endTimer?.cancel();

    setState(() {
      _busy = false;
      _phase = RoundPhase.preStart;

      _target = 0;
      _dice = [];

      _initialTarget = 0;
      _initialDice = [];

      _selected.clear();
      _moves = 0;

      _rollingTarget = 0;
      _rollingDice = List<int>.filled(5, 1);
    });
  }

  // ---------- Difficulty ----------
  void _setDifficulty(Difficulty d) {
    if (_busy) return;
    setState(() => _difficulty = d);
    _goToPreStart();
  }

  // ---------- Start / New Game ----------
  void _start() {
    if (_busy) return;
    _startRollingThenFinalize();
  }

  void _newGame() {
    if (_busy) return;
    _startRollingThenFinalize();
  }

  void _startRollingThenFinalize() {
    _busy = true;
    _selected.clear();
    _moves = 0;

    final maxTarget = _difficulty.maxTarget; // Hard = 150

    setState(() {
      _phase = RoundPhase.rolling;
      _rollingTarget = _rng.nextInt(maxTarget) + 1;
      _rollingDice = List<int>.generate(5, (_) => _rng.nextInt(6) + 1);
    });

    _rollTimer?.cancel();
    _endTimer?.cancel();

    _rollTimer = Timer.periodic(const Duration(milliseconds: 60), (_) {
      setState(() {
        _rollingTarget = _rng.nextInt(maxTarget) + 1;
        _rollingDice = List<int>.generate(5, (_) => _rng.nextInt(6) + 1);
      });
    });

    _endTimer = Timer(const Duration(milliseconds: 1200), () {
      _rollTimer?.cancel();

      final finalTarget = _rng.nextInt(maxTarget) + 1;
      final finalDice = List<int>.generate(5, (_) => _rng.nextInt(6) + 1);

      setState(() {
        _target = finalTarget;
        _dice = finalDice;

        _initialTarget = finalTarget;
        _initialDice = List<int>.from(finalDice);

        // After rolling, show Solve but not playable until Solve pressed
        _phase = RoundPhase.ready;
        _busy = false;
      });
    });
  }

  // ---------- Solve = activate actual playing ----------
  void _solve() {
    if (_busy) return;
    if (_isPreStart) {
      _showInfo('Press Start first.');
      return;
    }
    setState(() {
      _phase = RoundPhase.playing;
      _selected.clear();
    });
  }

  // ---------- Reset ----------
  void _resetDice() {
    if (_busy) return;

    if (_initialDice.isEmpty || _initialTarget == 0) {
      _goToPreStart();
      return;
    }

    setState(() {
      _dice = List<int>.from(_initialDice);
      _target = _initialTarget;
      _selected.clear();
      _moves = 0;
      _phase = RoundPhase.ready; // must press Solve again
    });
  }

  // ---------- Impossible (REAL logic + solution expression) ----------
  void _impossible() async {
    if (_busy) return;

    if (_isPreStart) {
      _showInfo('Press Start first.');
      return;
    }

    // Use multi-dice solver to match rule: select 2..n dice per move
    final res = _solver.solveMulti(List<int>.from(_dice), _target);

    if (!res.solvable) {
      // Impossible correct => WIN
      await _showDialog(
        title: 'You won!',
        body:
            'No solution exists for the current dice.\n\n'
            'Target: $_target\n'
            'Dice: ${_dice.join(', ')}',
      );
      if (mounted) setState(() => _phase = RoundPhase.ended);
      return;
    }

    // Solution exists => LOSE + show initial dice and full expression
    final expr = res.fullExpression ?? '(solution found, expression unavailable)';
    final initDiceText = _initialDice.isNotEmpty ? _initialDice.join(', ') : _dice.join(', ');

    await _showDialog(
      title: 'You lost',
      body:
          'A solution exists.\n\n'
          'Start dice: $initDiceText\n'
          'Target: $_target\n\n'
          '$expr',
    );
    if (mounted) setState(() => _phase = RoundPhase.ended);
  }

  // ---------- Selection ----------
  void _toggleSelect(int index) {
    if (_busy) return;
    if (!_isPlaying) return; // selectable only after Solve
    if (index < 0 || index >= _dice.length) return;

    setState(() {
      if (_selected.contains(index)) {
        _selected.remove(index);
      } else {
        _selected.add(index);
      }
    });
  }

  bool get _canApplyOp => !_busy && _isPlaying && _selected.length >= 2;

  // ---------- Apply operation (2..n, descending, left-to-right reduction) ----------
  void _applyOp(Op op) {
    if (!_canApplyOp) return;

    final selectedIdx = _selected.toList()..sort();
    final selectedVals = selectedIdx.map((i) => _dice[i]).toList()
      ..sort((a, b) => b.compareTo(a)); // descending

    int acc = selectedVals.first;

    for (var k = 1; k < selectedVals.length; k++) {
      final next = selectedVals[k];
      final step = _applyStep(acc, next, op);
      if (step == null) {
        _showInfo('Invalid move.');
        return; // no state changes
      }
      acc = step;
    }

    setState(() {
      // remove selected dice by index descending, then add result
      final toRemove = selectedIdx.toList()..sort((a, b) => b.compareTo(a));
      for (final i in toRemove) {
        _dice.removeAt(i);
      }
      _dice.add(acc);

      _selected.clear();
      _moves += 1;
    });

    _checkEnd();
  }

  // One reduction step with auto-direction for sub/div and whole division.
  int? _applyStep(int a, int b, Op op) {
    switch (op) {
      case Op.add:
        return a + b;

      case Op.mul:
        return a * b;

      case Op.sub:
        final r1 = a - b;
        final r2 = b - a;
        final ok1 = r1 >= 0;
        final ok2 = r2 >= 0;

        if (ok1 && !ok2) return r1;
        if (!ok1 && ok2) return r2;
        if (ok1 && ok2) return max(r1, r2);
        return null;

      case Op.div:
        if (b != 0 && a % b == 0) return a ~/ b;
        if (a != 0 && b % a == 0) return b ~/ a;
        return null;
    }
  }

  void _checkEnd() async {
    if (_dice.length != 1) return;

    final finalVal = _dice.first;
    if (finalVal == _target) {
      await _showDialog(title: 'You won!', body: 'Moves: $_moves\n\nTarget: $_target');
    } else {
      await _showDialog(title: 'You lost', body: 'Final value: $finalVal\nTarget: $_target');
    }

    if (mounted) setState(() => _phase = RoundPhase.ended);
  }

  // ---------- UI helpers ----------
  Future<void> _showDialog({required String title, required String body}) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showInfo(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(milliseconds: 1200)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final targetDisplay = _isPreStart
        ? '—'
        : (_isRolling ? '$_rollingTarget' : '$_target');

    final diceToShow = _isRolling ? _rollingDice : _dice;
    final showDice = !_isPreStart;

    final difficultyLabel = _difficulty.label;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dice Target'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          PopupMenuButton<Difficulty>(
            onSelected: _setDifficulty,
            itemBuilder: (_) => const [
              PopupMenuItem(value: Difficulty.easy, child: Text('Easy')),
              PopupMenuItem(value: Difficulty.medium, child: Text('Medium')),
              PopupMenuItem(value: Difficulty.hard, child: Text('Hard')),
            ],
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Row(
                children: [
                  Text(difficultyLabel),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            _targetBar(targetText: targetDisplay, difficulty: difficultyLabel, moves: _moves),
            const SizedBox(height: 18),

            if (showDice) ...[
              _diceGrid(diceToShow),
              const SizedBox(height: 18),
            ],

            _opsRow(),
            const Spacer(),

            _bottomButtons(),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _targetBar({required String targetText, required String difficulty, required int moves}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Text(
                'Target: $targetText',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(difficulty, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('Moves: $moves', style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _diceGrid(List<int> diceValues) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: List.generate(diceValues.length, (i) {
        final selected = _selected.contains(i) && _isPlaying && !_busy;
        return GestureDetector(
          onTap: () => _toggleSelect(i),
          child: DieFace(
            value: diceValues[i].clamp(1, 6),
            selected: selected,
          ),
        );
      }),
    );
  }

  Widget _opsRow() {
    Widget opButton(Op op) {
      final enabled = _canApplyOp;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: ElevatedButton(
            onPressed: enabled ? () => _applyOp(op) : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              backgroundColor: Colors.black.withValues(alpha: 0.07),
              foregroundColor: Colors.black87,
              elevation: 0,
            ),
            child: Text(opSymbol(op), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          ),
        ),
      );
    }

    return Row(
      children: [
        opButton(Op.add),
        opButton(Op.sub),
        opButton(Op.mul),
        opButton(Op.div),
      ],
    );
  }

  Widget _bottomButtons() {
    Widget bigButton({
      required String text,
      required VoidCallback? onPressed,
      bool outlined = false,
    }) {
      final style = outlined
          ? OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            )
          : ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 0,
            );

      final child = Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600));

      return SizedBox(
        width: double.infinity,
        child: outlined
            ? OutlinedButton(onPressed: onPressed, style: style, child: child)
            : ElevatedButton(onPressed: onPressed, style: style, child: child),
      );
    }

    final allowPress = !_busy;

    final showStart = _isPreStart;
    final showSolve = !_isPreStart;

    return Column(
      children: [
        bigButton(
          text: showStart ? 'Start' : (showSolve ? 'Solve' : 'Solve'),
          onPressed: !allowPress ? null : (showStart ? _start : _solve),
          outlined: true,
        ),
        const SizedBox(height: 10),
        bigButton(
          text: 'Impossible',
          onPressed: allowPress ? _impossible : null,
          outlined: true,
        ),
        const SizedBox(height: 10),
        bigButton(
          text: 'Reset Dice',
          onPressed: allowPress ? _resetDice : null,
          outlined: true,
        ),
        const SizedBox(height: 10),
        bigButton(
          text: 'New Game',
          onPressed: allowPress ? _newGame : null,
        ),
      ],
    );
  }
}
