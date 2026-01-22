import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../solver.dart';

enum Difficulty { easy, medium, hard }
enum RoundPhase { idle, revealing, ready, playing, ended }

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final _rng = Random();
  final _solver = DiceSolver();

  Difficulty _difficulty = Difficulty.easy;

  List<int> _dice = [];
  int _target = 0;

  List<int> _initialDice = [];
  int _initialTarget = 0;

  RoundPhase _phase = RoundPhase.idle;

  int? _rollingTarget;
  bool _showFinalTarget = false;

  final List<int> _displayDice = List<int>.filled(5, 1);
  bool _diceLocked = false;

  int _token = 0;

  final Set<int> _selected = <int>{};
  int _moves = 0;

  bool _won = false;
  bool _lost = false;

  // NEW: schützt vor Doppelklick/Race
  bool _busy = false;

  (int minT, int maxT) _difficultyRange(Difficulty d) {
    return switch (d) {
      Difficulty.easy => (1, 50),
      Difficulty.medium => (1, 100),
      Difficulty.hard => (1, 200),
    };
  }

  int _difficultyMax(Difficulty d) => _difficultyRange(d).$2;

  void _goIdle() {
    setState(() {
      _phase = RoundPhase.idle;
      _dice = [];
      _target = 0;

      _initialDice = [];
      _initialTarget = 0;

      _rollingTarget = null;
      _showFinalTarget = false;

      for (int i = 0; i < 5; i++) {
        _displayDice[i] = 1 + _rng.nextInt(6);
      }
      _diceLocked = false;

      _selected.clear();
      _moves = 0;
      _won = false;
      _lost = false;
      _busy = false;
    });
  }

  void _prepareRound() {
    final (minT, maxT) = _difficultyRange(_difficulty);

    _initialDice = List.generate(5, (_) => 1 + _rng.nextInt(6));
    _initialTarget = minT + _rng.nextInt(maxT - minT + 1);

    _dice = List<int>.from(_initialDice);
    _target = _initialTarget;

    _selected.clear();
    _moves = 0;
    _won = false;
    _lost = false;
    _busy = false;
  }

  Future<void> _start() async {
    final myToken = ++_token;

    setState(() {
      _prepareRound();
      _phase = RoundPhase.revealing;

      _rollingTarget = null;
      _showFinalTarget = false;

      for (int i = 0; i < 5; i++) {
        _displayDice[i] = 1 + _rng.nextInt(6);
      }
      _diceLocked = false;
    });

    // Target rolling
    const rollDuration = Duration(milliseconds: 1100);
    const rollTick = Duration(milliseconds: 90);
    final rollUntil = DateTime.now().add(rollDuration);
    final max = _difficultyMax(_difficulty);

    while (DateTime.now().isBefore(rollUntil)) {
      await Future.delayed(rollTick);
      if (!mounted || myToken != _token) return;
      setState(() => _rollingTarget = 1 + _rng.nextInt(max));
    }

    if (!mounted || myToken != _token) return;
    setState(() {
      _rollingTarget = null;
      _showFinalTarget = true;
    });

    // Dice rolling: all 5 simultaneously
    const diceRollDuration = Duration(milliseconds: 950);
    const diceTick = Duration(milliseconds: 85);
    final diceUntil = DateTime.now().add(diceRollDuration);

    while (DateTime.now().isBefore(diceUntil)) {
      await Future.delayed(diceTick);
      if (!mounted || myToken != _token) return;
      setState(() {
        for (int i = 0; i < 5; i++) {
          _displayDice[i] = 1 + _rng.nextInt(6);
        }
      });
    }

    if (!mounted || myToken != _token) return;
    setState(() {
      for (int i = 0; i < 5; i++) {
        _displayDice[i] = _initialDice[i];
      }
      _diceLocked = true;
      _phase = RoundPhase.ready;
    });
  }

  void _newGame() {
    ++_token;
    _goIdle();
  }

  void _solveStartPlaying() {
    if (_phase != RoundPhase.ready) return;
    setState(() {
      _phase = RoundPhase.playing;
      _selected.clear();
      _moves = 0;
      _won = false;
      _lost = false;
      _busy = false;
    });
  }

  void _resetDiceToStart() {
    if (_phase != RoundPhase.playing) return;
    setState(() {
      _dice = List<int>.from(_initialDice);
      _target = _initialTarget;
      _selected.clear();
      _moves = 0;
      _won = false;
      _lost = false;
      _busy = false;
    });
  }

  void _toggleSelect(int index) {
    if (_phase != RoundPhase.playing) return;
    if (_won || _lost) return;
    if (_busy) return;
    if (index < 0 || index >= _dice.length) return;

    setState(() {
      if (_selected.contains(index)) {
        _selected.remove(index);
      } else {
        _selected.add(index);
      }
    });
  }

  bool get _canUseOps => _phase == RoundPhase.playing && !_won && !_lost && _selected.length >= 2;

  void _applyOp(String op) {
    if (_busy) return;

    if (!_canUseOps) {
      _snack('Wähle mindestens 2 Würfel.');
      return;
    }

    // NEW: Auswahl validieren, bevor wir _dice[i] lesen
    final idxs = _selected.toList();
    final n = _dice.length;
    final invalid = idxs.any((i) => i < 0 || i >= n);
    if (invalid) {
      setState(() => _selected.clear());
      _snack('Auswahl wurde zurückgesetzt.');
      return;
    }

    _busy = true;
    try {
      final vals = idxs.map((i) => _dice[i]).toList();
      vals.sort((a, b) => b.compareTo(a)); // deterministic

      final reduced = _reduce(vals, op);
      if (reduced == null) {
        _snack('Ungültiger Zug.');
        return;
      }

      setState(() {
        _moves += 1;

        idxs.sort((a, b) => b.compareTo(a));
        for (final i in idxs) {
          _dice.removeAt(i);
        }
        _dice.add(reduced);

        _selected.clear();

        if (_dice.length == 1) {
          if (_dice.single == _target) {
            _won = true;
            _lost = false;
          } else {
            _won = false;
            _lost = true;
          }
          _phase = RoundPhase.ended;
        }
      });
    } finally {
      _busy = false;
    }
  }

  int? _reduce(List<int> desc, String op) {
    if (desc.length < 2) return null;

    int acc = desc[0];
    for (int i = 1; i < desc.length; i++) {
      final next = desc[i];

      switch (op) {
        case '+':
          acc = acc + next;
          break;
        case '×':
        case '*':
          acc = acc * next;
          break;
        case '−':
        case '-':
          final a = acc, b = next;
          if (a - b >= 0) {
            acc = a - b;
          } else if (b - a >= 0) {
            acc = b - a;
          } else {
            return null;
          }
          break;
        case '÷':
        case '/':
          final a = acc, b = next;
          if (b != 0 && a % b == 0) {
            acc = a ~/ b;
          } else if (a != 0 && b % a == 0) {
            acc = b ~/ a;
          } else {
            return null;
          }
          break;
        default:
          return null;
      }

      if (acc < 0) return null;
    }

    return acc;
  }

  void _pressImpossible() {
    final canPress = _phase == RoundPhase.ready || _phase == RoundPhase.playing;
    if (!canPress) return;

    final res = _solver.solve(_dice, _target);

    if (!res.solvable) {
      setState(() {
        _won = true;
        _lost = false;
        _phase = RoundPhase.ended;
      });
    } else {
      setState(() {
        _won = false;
        _lost = true;
        _phase = RoundPhase.ended;
      });

      final expr = res.fullExpression;
      if (expr != null) {
        _showSolutionSheet(expr: expr);
      }
    }
  }

  Future<void> _showSolutionSheet({required String expr}) async {
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final mq = MediaQuery.of(ctx);
        final maxHeight = mq.size.height * 0.78;

        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lösung',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Text(
                  'Startwürfel:',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _initialDice.map((v) => DiceTile(value: v, size: 52)).toList(),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Text(
                  'Gesamtausdruck',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      '$expr = $_target',
                      style: Theme.of(ctx).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Menlo',
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  double _diceSizeForWidth(double w) {
    final usable = w - 24;
    final raw = (usable - (2 * 10)) / 3;
    return raw.clamp(52.0, 74.0);
  }

  double _buttonHeightForWidth(double w) => (w * 0.11).clamp(44.0, 58.0);
  double _buttonFontForWidth(double w) => (w * 0.043).clamp(14.0, 18.0);

  @override
  Widget build(BuildContext context) {
    final diffLabel = switch (_difficulty) {
      Difficulty.easy => 'Leicht',
      Difficulty.medium => 'Mittel',
      Difficulty.hard => 'Schwierig',
    };

    final statusText = _won ? 'Gewonnen' : (_lost ? 'Verloren' : '');

    final diceToShow = (_phase == RoundPhase.revealing || (_phase != RoundPhase.idle && !_diceLocked))
        ? _displayDice
        : (_phase == RoundPhase.idle ? <int>[] : _dice);

    final w = MediaQuery.of(context).size.width;
    final diceSize = _diceSizeForWidth(w);
    final opFont = (diceSize * 0.32).clamp(16.0, 24.0);

    final btnH = _buttonHeightForWidth(w);
    final btnFont = _buttonFontForWidth(w);

    ButtonStyle bigButtonStyle() => ElevatedButton.styleFrom(
          minimumSize: Size(double.infinity, btnH),
          textStyle: TextStyle(fontSize: btnFont, fontWeight: FontWeight.w900),
        );

    ButtonStyle bigOutlinedStyle() => OutlinedButton.styleFrom(
          minimumSize: Size(double.infinity, btnH),
          textStyle: TextStyle(fontSize: btnFont, fontWeight: FontWeight.w900),
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dice Target'),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<Difficulty>(
              value: _difficulty,
              onChanged: (d) {
                if (d == null) return;
                setState(() => _difficulty = d);
                _newGame();
              },
              items: const [
                DropdownMenuItem(value: Difficulty.easy, child: Text('Leicht')),
                DropdownMenuItem(value: Difficulty.medium, child: Text('Mittel')),
                DropdownMenuItem(value: Difficulty.hard, child: Text('Schwierig')),
              ],
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _TargetCard(
                target: _showFinalTarget ? _target : null,
                rollingTarget: _rollingTarget,
                diffLabel: diffLabel,
                statusText: statusText,
                moves: _moves,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(diceToShow.length, (i) {
                  final v = diceToShow[i];

                  final isSelected =
                      (_phase == RoundPhase.playing && i < _dice.length) ? _selected.contains(i) : false;

                  final tappable = _phase == RoundPhase.playing && i < _dice.length;

                  return DiceTile(
                    value: v,
                    size: diceSize,
                    selected: isSelected,
                    enabled: tappable,
                    onTap: () => _toggleSelect(i),
                  );
                }),
              ),
              const SizedBox(height: 10),
              _OpsBar(
                enabled: _canUseOps,
                opFontSize: opFont,
                onOp: _applyOp,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    if (_phase == RoundPhase.idle) ...[
                      ElevatedButton(
                        style: bigButtonStyle(),
                        onPressed: _start,
                        child: const Text('Start'),
                      ),
                      const SizedBox(height: 10),
                    ] else ...[
                      ElevatedButton(
                        style: bigButtonStyle(),
                        onPressed: (_phase == RoundPhase.ready) ? _solveStartPlaying : null,
                        child: const Text('Solve'),
                      ),
                      const SizedBox(height: 10),
                    ],
                    ElevatedButton(
                      style: bigButtonStyle(),
                      onPressed: (_phase == RoundPhase.ready || _phase == RoundPhase.playing) ? _pressImpossible : null,
                      child: const Text('Impossible'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      style: bigOutlinedStyle(),
                      onPressed: (_phase == RoundPhase.playing) ? _resetDiceToStart : null,
                      child: const Text('Reset Dice'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      style: bigOutlinedStyle(),
                      onPressed: _newGame,
                      child: const Text('New Game'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpsBar extends StatelessWidget {
  final bool enabled;
  final double opFontSize;
  final void Function(String op) onOp;

  const _OpsBar({
    required this.enabled,
    required this.opFontSize,
    required this.onOp,
  });

  @override
  Widget build(BuildContext context) {
    final minW = 70.0;
    final minH = 46.0;

    ButtonStyle style() => FilledButton.styleFrom(
          minimumSize: Size(minW, minH),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: TextStyle(fontSize: opFontSize, fontWeight: FontWeight.w900),
        );

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        FilledButton(onPressed: enabled ? () => onOp('+') : null, style: style(), child: const Text('+')),
        FilledButton(onPressed: enabled ? () => onOp('−') : null, style: style(), child: const Text('−')),
        FilledButton(onPressed: enabled ? () => onOp('×') : null, style: style(), child: const Text('×')),
        FilledButton(onPressed: enabled ? () => onOp('÷') : null, style: style(), child: const Text('÷')),
      ],
    );
  }
}

class _TargetCard extends StatelessWidget {
  final int? target;
  final int? rollingTarget;
  final String diffLabel;
  final String statusText;
  final int moves;

  const _TargetCard({
    required this.target,
    required this.rollingTarget,
    required this.diffLabel,
    required this.statusText,
    required this.moves,
  });

  @override
  Widget build(BuildContext context) {
    final show = rollingTarget != null ? '$rollingTarget' : (target == null ? '—' : '$target');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 140),
              child: Text(
                'Zielzahl: $show',
                key: ValueKey(show),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(diffLabel, style: Theme.of(context).textTheme.titleSmall),
              Text('Züge: $moves', style: Theme.of(context).textTheme.labelMedium),
              if (statusText.isNotEmpty)
                Text(
                  statusText,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
            ],
          )
        ],
      ),
    );
  }
}

class DiceTile extends StatelessWidget {
  final int value;
  final double size;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  const DiceTile({
    super.key,
    required this.value,
    required this.size,
    this.selected = false,
    this.enabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final border = selected ? cs.primary : Colors.black.withOpacity(0.12);
    final bg = selected ? cs.primaryContainer : Colors.black.withOpacity(0.04);

    final child = (value >= 1 && value <= 6)
        ? CustomPaint(painter: _PipsPainter(value: value))
        : Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '$value',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          );

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: selected ? 2 : 1),
        ),
        child: child,
      ),
    );
  }
}

class _PipsPainter extends CustomPainter {
  final int value;
  _PipsPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.85);
    Offset p(double x, double y) => Offset(size.width * x, size.height * y);
    final r = size.shortestSide * 0.06;

    final spots = <Offset>[];
    switch (value) {
      case 1:
        spots.add(p(0.5, 0.5));
        break;
      case 2:
        spots.addAll([p(0.25, 0.25), p(0.75, 0.75)]);
        break;
      case 3:
        spots.addAll([p(0.25, 0.25), p(0.5, 0.5), p(0.75, 0.75)]);
        break;
      case 4:
        spots.addAll([p(0.25, 0.25), p(0.75, 0.25), p(0.25, 0.75), p(0.75, 0.75)]);
        break;
      case 5:
        spots.addAll([p(0.25, 0.25), p(0.75, 0.25), p(0.5, 0.5), p(0.25, 0.75), p(0.75, 0.75)]);
        break;
      case 6:
        spots.addAll([
          p(0.25, 0.22),
          p(0.25, 0.5),
          p(0.25, 0.78),
          p(0.75, 0.22),
          p(0.75, 0.5),
          p(0.75, 0.78),
        ]);
        break;
    }

    for (final s in spots) {
      canvas.drawCircle(s, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PipsPainter oldDelegate) => oldDelegate.value != value;
}
