// lib/features/rush/presentation/screens/rush_daily_between_screen.dart

import 'package:dice/core/theme/app_colors.dart';
import 'package:dice/features/game/logic/solver_service.dart';
import 'package:flutter/material.dart';

class RushDailyBetweenScreen extends StatefulWidget {
  final int run1Score;
  final int lastPuzzleTarget;
  final List<int> lastPuzzleDice;
  final VoidCallback onStartRun2;

  const RushDailyBetweenScreen({
    super.key,
    required this.run1Score,
    required this.lastPuzzleTarget,
    required this.lastPuzzleDice,
    required this.onStartRun2,
  });

  @override
  State<RushDailyBetweenScreen> createState() => _RushDailyBetweenScreenState();
}

class _RushDailyBetweenScreenState extends State<RushDailyBetweenScreen> {
  static const Color _green = Color(0xFF00E5A0);
  static const Color _cyan = Color(0xFF3FE8FF);
  static const Color _bg = Color(0xFF0A0F1F);
  static const Color _card = Color(0xFF141A2E);

  String? _lastPuzzleSolution;
  bool _solutionComputed = false;

  @override
  void initState() {
    super.initState();
    _computeSolution();
  }

  void _computeSolution() {
    if (widget.lastPuzzleDice.isEmpty) {
      setState(() => _solutionComputed = true);
      return;
    }
    final solver = SolverService();
    final result = solver.check(diceValues: widget.lastPuzzleDice, target: widget.lastPuzzleTarget);
    if (mounted) {
      setState(() {
        _lastPuzzleSolution = result.solvable ? result.fullExpression : null;
        _solutionComputed = true;
      });
    }
  }

  void _showSolutionDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppColors.cardBr),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        title: const Text(
          'Last Puzzle — Solution',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
        ),
        content: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.bgBottom,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBr),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Target: ${widget.lastPuzzleTarget}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFD4AC0D),
                ),
              ),
              const SizedBox(height: 10),
              SelectableText(
                _lastPuzzleSolution ?? 'No solution found.',
                style: const TextStyle(
                  fontSize: 17,
                  height: 1.5,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Close',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _cyan),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Speed Run',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Text(
                  'Run 1 Complete',
                  style: TextStyle(
                    fontSize: 14,
                    letterSpacing: 0.5,
                    color: Colors.white.withValues(alpha: 0.40),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 36),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${widget.run1Score}',
                      style: const TextStyle(
                        fontSize: 80,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -2.5,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.run1Score == 1 ? 'puzzle solved' : 'puzzles solved',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.45),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_solutionComputed && widget.lastPuzzleDice.isNotEmpty)
                GestureDetector(
                  onTap: _showSolutionDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _cyan.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _cyan.withValues(alpha: 0.35), width: 1.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 17,
                          color: _cyan.withValues(alpha: 0.80),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Show Last Puzzle Solution',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _cyan.withValues(alpha: 0.80),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Can you beat it in Run 2?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.30),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: widget.onStartRun2,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_green.withValues(alpha: 0.28), _green.withValues(alpha: 0.13)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _green.withValues(alpha: 0.65), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: _green.withValues(alpha: 0.22),
                        blurRadius: 20,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Start Run 2',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
