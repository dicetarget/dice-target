import 'dart:math';
import 'package:flutter/material.dart';

import 'package:dice/core/extensions/difficulty_extensions.dart';

enum RoundPhase { idle, ready, playing, ended }

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final Random _rng = Random();

  Difficulty _difficulty = Difficulty.easy;

  RoundPhase _phase = RoundPhase.idle;

  List<int> _dice = [];
  int _target = 0;

  bool _busy = false;

  // UI helper
  String _infoText = '';

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  int _rollTarget(Difficulty difficulty) {
    // 1..maxTarget (Hard uses 150 from DifficultyConfig)
    return _rng.nextInt(difficulty.maxTarget) + 1;
  }

  List<int> _rollDice({int count = 5}) {
    return List<int>.generate(count, (_) => _rng.nextInt(6) + 1);
  }

  void _newRound() {
    if (_busy) return;
    setState(() {
      _busy = true;

      _phase = RoundPhase.ready;
      _dice = _rollDice(count: 5);
      _target = _rollTarget(_difficulty);

      _infoText = '';
      _busy = false;
    });
  }

  void _setDifficulty(Difficulty d) {
    if (_busy) return;
    setState(() {
      _difficulty = d;
    });
    _newRound();
  }

  void _giveUp() {
    if (_busy) return;
    setState(() {
      _phase = RoundPhase.ended;
      _infoText = 'Give up. (Solver integration comes later.)';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _difficultySection(),
            const SizedBox(height: 16),

            _targetSection(),
            const SizedBox(height: 16),

            _diceSection(),
            const SizedBox(height: 16),

            if (_infoText.isNotEmpty) ...[
              Text(
                _infoText,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
            ],

            _actions(),
          ],
        ),
      ),
    );
  }

  Widget _difficultySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Difficulty', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text('${Difficulty.easy.label} (${Difficulty.easy.rangeText})'),
                  selected: _difficulty == Difficulty.easy,
                  onSelected: (_) => _setDifficulty(Difficulty.easy),
                ),
                ChoiceChip(
                  label: Text('${Difficulty.medium.label} (${Difficulty.medium.rangeText})'),
                  selected: _difficulty == Difficulty.medium,
                  onSelected: (_) => _setDifficulty(Difficulty.medium),
                ),
                ChoiceChip(
                  label: Text('${Difficulty.hard.label} (${Difficulty.hard.rangeText})'),
                  selected: _difficulty == Difficulty.hard,
                  onSelected: (_) => _setDifficulty(Difficulty.hard),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _targetSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Text('Target:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            Text(
              '$_target',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              _phase.name,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _diceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dice', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _dice
                  .map(
                    (d) => Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$d',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actions() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _busy ? null : _newRound,
          child: const Text('New round'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _busy ? null : _giveUp,
          child: const Text('Give up'),
        ),
      ],
    );
  }
}
