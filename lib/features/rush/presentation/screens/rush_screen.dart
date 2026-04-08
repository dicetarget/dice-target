// lib/features/rush/presentation/screens/rush_screen.dart

import 'dart:async';

import 'package:dice/core/audio/sfx_singleton.dart';
import 'package:dice/core/difficulty_config.dart';
import 'package:dice/core/game_rules.dart';
import 'package:dice/core/puzzle/game_mode.dart';
import 'package:dice/core/puzzle/puzzle_coordinator.dart';
import 'package:dice/core/puzzle/puzzle_generator.dart';
import 'package:dice/core/ui_op.dart';
import 'package:dice/features/game/logic/move_application_service.dart';
import 'package:dice/features/game/logic/round_evaluator.dart';
import 'package:dice/features/game/models/dice_state.dart';
import 'package:dice/features/rush/domain/rush_difficulty.dart';
import 'package:dice/features/rush/presentation/screens/rush_result_screen.dart';
import 'package:flutter/material.dart';

// ──────────────────────────────────────────────────────────────────────────────
// RushRunClock — eigene Klasse, NICHT aus practice_screen importiert
// ──────────────────────────────────────────────────────────────────────────────
class RushRunClock {
  final Duration total;

  const RushRunClock(this.total);

  bool isExpired(Duration elapsed) => elapsed >= total;
}

// ──────────────────────────────────────────────────────────────────────────────
// Undo-Snapshot
// ──────────────────────────────────────────────────────────────────────────────
class _UndoSnapshot {
  final List<DiceState> dice;
  final int moves;

  const _UndoSnapshot({required this.dice, required this.moves});
}

// ──────────────────────────────────────────────────────────────────────────────
// RushScreen
// ──────────────────────────────────────────────────────────────────────────────
class RushScreen extends StatefulWidget {
  final RushDifficulty difficulty;
  final int personalBest;

  const RushScreen({super.key, required this.difficulty, required this.personalBest});

  @override
  State<RushScreen> createState() => _RushScreenState();
}

enum _RunPhase { running, ended }

class _RushScreenState extends State<RushScreen> {
  static const Duration _runDuration = Duration(seconds: 90);
  static const int _maxUndo = 4;

  // Farben
  static const Color _green = Color(0xFF00E5A0);
  static const Color _bg = Color(0xFF0A0F1F);
  static const Color _card = Color(0xFF141A2E);

  // Services
  final RushRunClock _clock = const RushRunClock(_runDuration);
  final GameRules _gameRules = GameRules();
  final RoundEvaluator _roundEvaluator = const RoundEvaluator();
  final MoveApplicationService _moveService = const MoveApplicationService();
  late final PuzzleCoordinator _coordinator;

  // Run-State
  _RunPhase _phase = _RunPhase.running;
  List<DiceState> _dice = [];
  int _target = 0;
  int _score = 0;
  int _pb = 0;
  Duration _remaining = _runDuration;
  Timer? _timer;

  // Interaktion
  final Set<int> _selected = {};
  UiOp? _selectedOp;
  final List<_UndoSnapshot> _undoStack = [];

  // Visuelles Feedback
  bool _solvedFlash = false;

  static const List<UiOp> _ops = [UiOp.add, UiOp.sub, UiOp.mul, UiOp.div];

  @override
  void initState() {
    super.initState();
    _pb = widget.personalBest;
    _coordinator = PuzzleCoordinator(
      generator: PuzzleGenerator(),
      mode: GameMode.rush,
      config: DifficultyConfig.easy,
      baseSeed: DateTime.now().millisecondsSinceEpoch,
    );
    _loadPuzzle(first: true);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ── Timer ─────────────────────────────────────────────────────────────────────

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remaining -= const Duration(seconds: 1);
        if (_clock.isExpired(_runDuration - _remaining)) {
          _remaining = Duration.zero;
          _timer?.cancel();
          _endRun();
        }
      });
    });
  }

  // ── Puzzle ────────────────────────────────────────────────────────────────────

  void _loadPuzzle({bool first = false}) {
    final puzzle = first
        ? _coordinator.startNewRun(
            targetMin: widget.difficulty.targetMin,
            targetMax: widget.difficulty.targetMax,
          )
        : _coordinator.nextPuzzle(
            targetMin: widget.difficulty.targetMin,
            targetMax: widget.difficulty.targetMax,
          );

    _target = puzzle.target;
    _dice = puzzle.dice.map((v) => DiceState(value: v)).toList();
    _undoStack.clear();
    _selected.clear();
    _selectedOp = null;

    _gameRules.reset();
    _gameRules.start(_target);
  }

  // ── Moves ─────────────────────────────────────────────────────────────────────

  void _toggleSelect(int index) {
    if (_phase != _RunPhase.running) return;
    setState(() {
      if (_selected.contains(index)) {
        _selected.remove(index);
      } else {
        _selected.add(index);
      }
    });
    _tryApply();
  }

  void _setOp(UiOp op) {
    if (_phase != _RunPhase.running) return;
    setState(() {
      _selectedOp = (_selectedOp == op) ? null : op;
    });
    _tryApply();
  }

  void _tryApply() {
    if (_selectedOp == null || _selected.length < 2) return;

    final result = _moveService.buildMove(
      diceValues: _dice.map((d) => d.value).toList(),
      selectedIndices: _selected.toList(),
      op: _selectedOp!,
      gameMode: GameMode.rush,
    );

    if (result == null) {
      sfx.invalid();
      return;
    }

    // Undo-Snapshot speichern (FIFO bei max)
    if (_undoStack.length >= _maxUndo) _undoStack.removeAt(0);
    _undoStack.add(_UndoSnapshot(dice: List.from(_dice), moves: _gameRules.moves));

    // Move anwenden
    final newValues = _moveService.applyToDiceValues(
      diceValues: _dice.map((d) => d.value).toList(),
      removeIndicesDesc: result.removeIndicesDesc,
      mergedValue: result.mergedValue,
    );

    _gameRules.registerMove();

    setState(() {
      _dice = newValues.map((v) => DiceState(value: v)).toList();
      _selected.clear();
      _selectedOp = null;
    });

    sfx.valid();

    if (result.willEndAfterMove) {
      _checkSolve();
    }
  }

  void _checkSolve() {
    if (_dice.isEmpty) return;
    final gs = _roundEvaluator.evaluate(
      target: _target,
      finalValue: _dice.last.value,
      rules: _gameRules,
    );
    if (gs == GameState.solved) _onSolve();
  }

  void _onSolve() {
    setState(() {
      _score++;
      _solvedFlash = true;
    });
    sfx.win();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted || _phase == _RunPhase.ended) return;
      setState(() {
        _solvedFlash = false;
        _loadPuzzle();
      });
    });
  }

  void _skip() {
    if (_phase != _RunPhase.running) return;
    sfx.click();
    setState(_loadPuzzle);
  }

  void _undo() {
    if (_phase != _RunPhase.running || _undoStack.isEmpty) return;
    final snapshot = _undoStack.removeLast();
    _gameRules.moves = snapshot.moves;
    setState(() {
      _dice = List.from(snapshot.dice);
      _selected.clear();
      _selectedOp = null;
    });
    sfx.click();
  }

  // ── Run beenden ───────────────────────────────────────────────────────────────

  void _endRun() {
    if (_phase == _RunPhase.ended) return;
    setState(() => _phase = _RunPhase.ended);
    sfx.dailyComplete();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            RushResultScreen(difficulty: widget.difficulty, score: _score, previousPb: _pb),
      ),
    );
  }

  // ── Hilfsmethoden ─────────────────────────────────────────────────────────────

  String _opLabel(UiOp op) => switch (op) {
    UiOp.add => '+',
    UiOp.sub => '−',
    UiOp.mul => '×',
    UiOp.div => '÷',
  };

  Color _timerColor() {
    final s = _remaining.inSeconds;
    if (s <= 10) return Colors.redAccent;
    if (s <= 20) return const Color(0xFFFFAA00);
    return _green;
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
          onPressed: () {
            _timer?.cancel();
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Speed Run',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              sfx.enabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: Colors.white38,
            ),
            onPressed: () async {
              await sfx.toggle();
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 8),
              _buildStatusRow(),
              const SizedBox(height: 20),
              _buildTargetCard(),
              const SizedBox(height: 28),
              _buildDiceRow(),
              const SizedBox(height: 24),
              _buildOpsRow(),
              const Spacer(),
              _buildBottomButtons(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Score + PB
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PB: $_pb',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.38),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Jetzt: $_score',
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const Spacer(),
        // Timer
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: _timerColor().withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _timerColor().withValues(alpha: 0.45), width: 1.5),
          ),
          child: Text(
            '${_remaining.inSeconds}s',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: _timerColor(),
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTargetCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        color: _solvedFlash ? _green.withValues(alpha: 0.18) : _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _solvedFlash
              ? _green.withValues(alpha: 0.80)
              : Colors.white.withValues(alpha: 0.07),
          width: _solvedFlash ? 2.0 : 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'ZIEL',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 2.0,
              color: Colors.white.withValues(alpha: 0.30),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$_target',
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w900,
              color: _solvedFlash ? _green : Colors.white,
              letterSpacing: -1.5,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiceRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(_dice.length, (i) {
        final isSelected = _selected.contains(i);
        return GestureDetector(
          onTap: () => _toggleSelect(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 110),
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: isSelected ? _green.withValues(alpha: 0.20) : _card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? _green : Colors.white.withValues(alpha: 0.12),
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: _green.withValues(alpha: 0.28),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                '${_dice[i].value}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? _green : Colors.white,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildOpsRow() {
    return Row(
      children: _ops.map((op) {
        final isSelected = _selectedOp == op;
        return Expanded(
          child: GestureDetector(
            onTap: () => _setOp(op),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 110),
              margin: const EdgeInsets.symmetric(horizontal: 5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSelected ? _green.withValues(alpha: 0.18) : _card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? _green : Colors.white.withValues(alpha: 0.10),
                  width: isSelected ? 2.0 : 1.0,
                ),
              ),
              child: Center(
                child: Text(
                  _opLabel(op),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? _green : Colors.white60,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomButtons() {
    final canUndo = _undoStack.isNotEmpty && _phase == _RunPhase.running;
    final canSkip = _phase == _RunPhase.running;

    return Row(
      children: [
        // Skip
        Expanded(
          child: GestureDetector(
            onTap: canSkip ? _skip : null,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.skip_next_rounded, color: Colors.white38, size: 20),
                  SizedBox(width: 6),
                  Text(
                    'Skip',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Undo
        Expanded(
          child: GestureDetector(
            onTap: canUndo ? _undo : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: canUndo
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: canUndo
                      ? Colors.white.withValues(alpha: 0.22)
                      : Colors.white.withValues(alpha: 0.06),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.undo_rounded,
                    color: canUndo ? Colors.white60 : Colors.white.withValues(alpha: 0.18),
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    canUndo ? 'Undo (${_undoStack.length})' : 'Undo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: canUndo ? Colors.white60 : Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
