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
// RushRunClock — standalone, NOT imported from practice_screen
// ──────────────────────────────────────────────────────────────────────────────
class RushRunClock {
  final Duration total;

  const RushRunClock(this.total);

  bool isExpired(Duration elapsed) => elapsed >= total;
}

// ──────────────────────────────────────────────────────────────────────────────
// Undo snapshot
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

class _RushScreenState extends State<RushScreen> with TickerProviderStateMixin {
  static const Duration _runDuration = Duration(seconds: 90);
  static const int _maxUndo = 4;

  static const Color _green = Color(0xFF00E5A0);
  static const Color _bg = Color(0xFF0A0F1F);
  static const Color _card = Color(0xFF141A2E);

  // ── Services ──────────────────────────────────────────────────────────────────
  final GameRules _gameRules = GameRules();
  final RoundEvaluator _roundEvaluator = const RoundEvaluator();
  final MoveApplicationService _moveService = const MoveApplicationService();
  late final PuzzleCoordinator _coordinator;

  // ── Run state ─────────────────────────────────────────────────────────────────
  _RunPhase _phase = _RunPhase.running;
  List<DiceState> _dice = [];
  int _target = 0;
  int _score = 0;
  int _pb = 0;
  Duration _remaining = _runDuration;
  Timer? _timer;

  // ── Interaction ───────────────────────────────────────────────────────────────
  final Set<int> _selected = {};
  UiOp? _selectedOp;
  final List<_UndoSnapshot> _undoStack = [];

  // ── (C) Dice transition key ────────────────────────────────────────────────────
  int _puzzleKey = 0;

  // ── (A) Timer pulse ────────────────────────────────────────────────────────────
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseScale;
  bool _pulseStarted = false;

  // ── (B+D) Solve animations ────────────────────────────────────────────────────
  late final AnimationController _solveCtrl;
  late final Animation<double> _targetScale;
  late final Animation<double> _plusOneOpacity;
  late final Animation<double> _plusOneOffset;

  static const List<UiOp> _ops = [UiOp.add, UiOp.sub, UiOp.mul, UiOp.div];

  @override
  void initState() {
    super.initState();
    _pb = widget.personalBest;

    // (A) Pulse — started later when ≤10s
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
    _pulseScale = Tween<double>(
      begin: 1.0,
      end: 1.07,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // (B+D) Solve animations
    _solveCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    // (D) Target: 1.0 → 1.13 → 1.0, then holds at 1.0
    _targetScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.13), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.13, end: 1.0), weight: 25),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _solveCtrl, curve: Curves.easeOut));
    // (B) +1 opacity: holds, then fades
    _plusOneOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 55),
    ]).animate(_solveCtrl);
    // (B) +1 drift upward
    _plusOneOffset = Tween<double>(
      begin: 0.0,
      end: -56.0,
    ).animate(CurvedAnimation(parent: _solveCtrl, curve: Curves.easeOut));

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
    _pulseCtrl.dispose();
    _solveCtrl.dispose();
    super.dispose();
  }

  // ── Timer ─────────────────────────────────────────────────────────────────────

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remaining -= const Duration(seconds: 1);

        // (A) + (E) simplified: start pulse at ≤10s, check ≤0 directly
        if (_remaining.inSeconds <= 10 && !_pulseStarted) {
          _pulseStarted = true;
          _pulseCtrl.repeat(reverse: true);
        }

        if (_remaining <= Duration.zero) {
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
    _puzzleKey++; // (C) triggers AnimatedSwitcher

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
    setState(() => _selectedOp = (_selectedOp == op) ? null : op);
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

    if (_undoStack.length >= _maxUndo) _undoStack.removeAt(0);
    _undoStack.add(_UndoSnapshot(dice: List.from(_dice), moves: _gameRules.moves));

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

    if (result.willEndAfterMove) _checkSolve();
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
    setState(() => _score++);
    sfx.win();
    _solveCtrl.forward(from: 0); // (B+D)

    Future.delayed(const Duration(milliseconds: 520), () {
      if (!mounted || _phase == _RunPhase.ended) return;
      setState(() => _loadPuzzle()); // (C) _puzzleKey++ inside
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

  // ── End run ───────────────────────────────────────────────────────────────────

  void _endRun() {
    if (_phase == _RunPhase.ended) return;
    _pulseCtrl.stop();
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

  // ── Helpers ───────────────────────────────────────────────────────────────────

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
        child: Stack(
          children: [
            Padding(
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
            _buildPlusOneOverlay(), // (B)
          ],
        ),
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────────

  Widget _buildStatusRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
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
              'Now: $_score',
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
        // (A) pulse wraps the timer container
        ScaleTransition(
          scale: _pulseScale,
          child: AnimatedContainer(
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
        ),
      ],
    );
  }

  Widget _buildTargetCard() {
    // (D) scale on solve
    return ScaleTransition(
      scale: _targetScale,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'TARGET',
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
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1.5,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiceRow() {
    // (C) fade + scale on puzzle change
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 0.88,
            end: 1.0,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
      child: Row(
        key: ValueKey(_puzzleKey),
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
      ),
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

  // (B) +1 popup
  Widget _buildPlusOneOverlay() {
    return AnimatedBuilder(
      animation: _solveCtrl,
      builder: (context, _) {
        if (_solveCtrl.value == 0.0) return const SizedBox.shrink();
        return Positioned(
          top: 180 + _plusOneOffset.value,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Center(
              child: Opacity(
                opacity: _plusOneOpacity.value.clamp(0.0, 1.0),
                child: Text(
                  '+1',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: _green,
                    shadows: [Shadow(color: _green.withValues(alpha: 0.55), blurRadius: 14)],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
