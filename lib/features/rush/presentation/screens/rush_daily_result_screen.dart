// lib/features/rush/presentation/screens/rush_daily_result_screen.dart

import 'dart:async';

import 'package:dice/core/theme/app_colors.dart';
import 'package:dice/core/widgets/tactile_button.dart';
import 'package:dice/features/game/logic/solver_service.dart';
import 'package:flutter/material.dart';

class RushDailyResultScreen extends StatefulWidget {
  final int run1Score;
  final int allTimeBest;
  final int lastPuzzleTarget;
  final List<int> lastPuzzleDice;

  const RushDailyResultScreen({
    super.key,
    required this.run1Score,
    required this.allTimeBest,
    required this.lastPuzzleTarget,
    required this.lastPuzzleDice,
  });

  @override
  State<RushDailyResultScreen> createState() => _RushDailyResultScreenState();
}

class _RushDailyResultScreenState extends State<RushDailyResultScreen> {
  Timer? _countdownTimer;
  Duration _timeUntilNextDaily = Duration.zero;

  late final int _bestScore;
  late final bool _isNewRecord;

  String? _lastPuzzleSolution;
  bool _solutionComputed = false;

  @override
  void initState() {
    super.initState();
    _bestScore = widget.run1Score;
    _isNewRecord = _bestScore > widget.allTimeBest;
    _updateCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(_updateCountdown);
    });
    _computeLastPuzzleSolution();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _computeLastPuzzleSolution() {
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

  void _updateCountdown() {
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    _timeUntilNextDaily = next.difference(now);
  }

  String _formatCountdown(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _showSolutionDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          title: const Text(
            'Last Puzzle — Solution',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          content: Container(
            width: double.maxFinite,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.bgDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
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
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: 10),
                SelectableText(
                  _lastPuzzleSolution ?? 'No solution found.',
                  style: const TextStyle(
                    fontSize: 17,
                    height: 1.5,
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Close',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.gold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                const Center(
                  child: Text(
                    'Daily Complete',
                    style: TextStyle(
                      fontSize: 15,
                      letterSpacing: 0.4,
                      color: AppColors.inkMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.40),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Score',
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 0.8,
                          color: AppColors.inkMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${widget.run1Score}',
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                          color: AppColors.gold,
                          letterSpacing: -1.5,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isNewRecord
                          ? AppColors.gold.withValues(alpha: 0.55)
                          : Colors.white.withValues(alpha: 0.07),
                      width: _isNewRecord ? 1.8 : 0.8,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Best: $_bestScore',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (_isNewRecord) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.gold.withValues(alpha: 0.40)),
                          ),
                          child: const Text(
                            '🏆  New Daily Record!',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.goldLight,
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 6),
                        Text(
                          'All-time best: ${widget.allTimeBest}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.inkMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (_solutionComputed && widget.lastPuzzleDice.isNotEmpty)
                  GestureDetector(
                    onTap: _showSolutionDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lightbulb_outline_rounded,
                            size: 17,
                            color: AppColors.gold.withValues(alpha: 0.80),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Show Last Puzzle Solution',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.gold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: AppColors.inkFaint,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Next daily in ${_formatCountdown(_timeUntilNextDaily)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.inkMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                TactileButton(
                  variant: TactileButtonVariant.gold,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  borderRadius: BorderRadius.circular(16),
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  child: const Text(
                    'Main Menu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dicePip,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
