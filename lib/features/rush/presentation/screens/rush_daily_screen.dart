// lib/features/rush/presentation/screens/rush_daily_screen.dart

import 'dart:async';

import 'package:dice/core/audio/sfx_singleton.dart';
import 'package:dice/core/theme/app_colors.dart';
import 'package:dice/core/ui_op.dart';
import 'package:dice/features/rush/domain/rush_state.dart';
import 'package:dice/features/rush/presentation/controllers/rush_controller.dart';
import 'package:flutter/material.dart';

class RushDailyScreen extends StatefulWidget {
  /// 1 = erster Run des Tages, 2 = zweiter Run.
  final int runNumber;

  /// Score aus Run 1 (nur relevant wenn runNumber == 2, sonst -1).
  final int run1Score;

  const RushDailyScreen({super.key, required this.runNumber, required this.run1Score});

  @override
  State<RushDailyScreen> createState() => _RushDailyScreenState();
}

class _RushDailyScreenState extends State<RushDailyScreen> with TickerProviderStateMixin {
  static const Color _green = Color(0xFF4CAF82);
  static const Color _muted = Color(0xFF4A5568);

  late final RushController _controller;
  StreamSubscription<RushEvent>? _eventSub;

  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  late final AnimationController _flashCtrl;
  late final Animation<double> _flashOpacity;

  @override
  void initState() {
    super.initState();

    _controller = RushController(
      isDailyMode: true,
      dailyRunNumber: widget.runNumber,
      runDuration: RushController.dailyDuration,
      forcedTargetMin: 15,
      forcedTargetMax: 55,
    );

    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeOut));

    _flashCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _flashOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.35).chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.35, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 75,
      ),
    ]).animate(_flashCtrl);

    _eventSub = _controller.events.listen(_handleEvent);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.startRun();
    });
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _shakeCtrl.dispose();
    _flashCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleEvent(RushEvent event) {
    if (!mounted) return;
    switch (event) {
      case RushEventShake():
        _shakeCtrl.forward(from: 0);
      case RushEventSolveFlash():
        _flashCtrl.forward(from: 0);
      case RushEventFinished():
        _navigateToResult();
    }
  }

  void _navigateToResult() {
    if (!mounted) return;
    final state = _controller.state;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => _RushDailyResultScreen(
          runNumber: widget.runNumber,
          score: state.score,
          run1Score: widget.run1Score,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgTop,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: Colors.white.withValues(alpha: 0.60),
          onPressed: () => Navigator.of(context).maybePop(),
          enableFeedback: false,
        ),
        title: Text(
          'Daily Speed · Run ${widget.runNumber}',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _green),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              sfx.enabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              size: 22,
              color: Colors.white.withValues(alpha: 0.45),
            ),
            onPressed: () {
              sfx.toggle();
              setState(() {});
            },
            enableFeedback: false,
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A1628), Color(0xFF060B14), Color(0xFF020408)],
                stops: [0.0, 0.5, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                final state = _controller.state;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      _buildTimerRow(state),
                      const SizedBox(height: 16),
                      _buildScoreRow(state),
                      const SizedBox(height: 20),
                      _buildTarget(state),
                      const SizedBox(height: 24),
                      Expanded(child: _buildDiceArea(state)),
                      const SizedBox(height: 20),
                      _buildOpButtons(state),
                      const SizedBox(height: 14),
                      _buildUndoButton(state),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
          ),
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _flashOpacity,
              builder: (_, child) =>
                  Container(color: _green.withValues(alpha: _flashOpacity.value)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _buildTimerRow(RushState state) {
    final t = state.timeRemaining;
    final Color timerColor = t > 40
        ? _green
        : t > 15
        ? const Color(0xFFFFB347)
        : const Color(0xFFFF6B6B);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
          decoration: BoxDecoration(
            color: timerColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: timerColor.withValues(alpha: t > 40 ? 0.25 : 0.55),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: timerColor.withValues(alpha: t > 40 ? 0.05 : 0.20),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Text(
            '$t',
            style: TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w900,
              color: timerColor,
              letterSpacing: -2,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreRow(RushState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          children: [
            Text(
              '${state.score}',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Score',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.30),
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        if (widget.runNumber == 2 && widget.run1Score >= 0) ...[
          const SizedBox(width: 24),
          Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.08)),
          const SizedBox(width: 24),
          Column(
            children: [
              Text(
                '${widget.run1Score}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: _green,
                  letterSpacing: -1,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Run 1',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.30),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTarget(RushState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0F1F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _green.withValues(alpha: 0.30), width: 1.5),
        boxShadow: [
          BoxShadow(color: _green.withValues(alpha: 0.08), blurRadius: 20, spreadRadius: 1),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Target',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.35),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${state.target}',
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -2,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiceArea(RushState state) {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (context, child) =>
          Transform.translate(offset: Offset(_shakeAnim.value, 0), child: child),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < state.dice.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                _DailyDie(
                  value: state.dice[i],
                  isSelected: state.selectedIndices.contains(i),
                  onTap: () => _controller.onToggleSelect(i),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOpButtons(RushState state) {
    const ops = [UiOp.add, UiOp.sub, UiOp.mul, UiOp.div];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: ops
          .map(
            (op) => _DailyOpButton(
              op: op,
              isSelected: state.selectedOp == op,
              onTap: () => _controller.onApplyOp(op),
            ),
          )
          .toList(),
    );
  }

  Widget _buildUndoButton(RushState state) {
    final canUndo = state.canUndo && state.isRunning;
    final remaining = RushController.maxUndoDepth - state.undoStackDepth;

    return GestureDetector(
      onTap: canUndo ? _controller.onUndo : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: 46,
        decoration: BoxDecoration(
          color: canUndo
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: canUndo
                ? Colors.white.withValues(alpha: 0.20)
                : Colors.white.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.undo_rounded,
              size: 18,
              color: canUndo ? Colors.white.withValues(alpha: 0.75) : _muted,
            ),
            const SizedBox(width: 8),
            Text(
              'Undo',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: canUndo ? Colors.white.withValues(alpha: 0.75) : _muted,
              ),
            ),
            if (canUndo) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$remaining',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Dice & Op Buttons (Daily-Variante) ────────────────────────────────────────

class _DailyDie extends StatelessWidget {
  static const Color _green = Color(0xFF4CAF82);

  final int value;
  final bool isSelected;
  final VoidCallback onTap;

  const _DailyDie({required this.value, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: isSelected ? _green.withValues(alpha: 0.18) : const Color(0xFF0D0F1F),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? _green.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.15),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: _green.withValues(alpha: 0.30), blurRadius: 12, spreadRadius: 1)]
              : [],
        ),
        child: Center(
          child: Text(
            '$value',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isSelected ? _green : Colors.white,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyOpButton extends StatelessWidget {
  static const Color _green = Color(0xFF4CAF82);

  final UiOp op;
  final bool isSelected;
  final VoidCallback onTap;

  const _DailyOpButton({required this.op, required this.isSelected, required this.onTap});

  String get _symbol {
    switch (op) {
      case UiOp.add:
        return '+';
      case UiOp.sub:
        return '−';
      case UiOp.mul:
        return '×';
      case UiOp.div:
        return '÷';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 68,
        height: 56,
        decoration: BoxDecoration(
          color: isSelected ? _green.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? _green.withValues(alpha: 0.75)
                : Colors.white.withValues(alpha: 0.12),
            width: isSelected ? 1.5 : 0.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: _green.withValues(alpha: 0.25), blurRadius: 10)]
              : [],
        ),
        child: Center(
          child: Text(
            _symbol,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: isSelected ? _green : Colors.white.withValues(alpha: 0.70),
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Daily Result Screen ───────────────────────────────────────────────────────

class _RushDailyResultScreen extends StatelessWidget {
  final int runNumber;
  final int score;
  final int run1Score;

  const _RushDailyResultScreen({
    required this.runNumber,
    required this.score,
    required this.run1Score,
  });

  static const Color _green = Color(0xFF4CAF82);

  @override
  Widget build(BuildContext context) {
    final bool isRun2 = runNumber == 2;
    final bool isNewBest = isRun2 && score > run1Score;
    final bool isCompleted = isRun2;

    return Scaffold(
      backgroundColor: AppColors.bgTop,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A1628), Color(0xFF060B14), Color(0xFF020408)],
                stops: [0.0, 0.5, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  Text(
                    isCompleted ? 'Daily Speed\nComplete!' : 'Run $runNumber\nComplete!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.8,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Score Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D0F1F),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _green.withValues(alpha: 0.35), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Run $runNumber Score',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$score',
                          style: const TextStyle(
                            fontSize: 80,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -4,
                            height: 0.9,
                          ),
                        ),
                        if (isNewBest) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: _green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _green.withValues(alpha: 0.50), width: 0.5),
                            ),
                            child: const Text(
                              '🏆  New Daily Best!',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _green,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isRun2 && run1Score >= 0) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Run 1 Score',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.45),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '$run1Score',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [_green.withValues(alpha: 0.20), _green.withValues(alpha: 0.09)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _green.withValues(alpha: 0.65), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: _green.withValues(alpha: 0.22), blurRadius: 20),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Back to Home',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: _green,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
