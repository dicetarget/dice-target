// lib/features/rush/presentation/screens/rush_daily_result_screen.dart

import 'dart:async';

import 'package:dice/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class RushDailyResultScreen extends StatefulWidget {
  final int run1Score;
  final int run2Score;
  final int allTimeBest;

  const RushDailyResultScreen({
    super.key,
    required this.run1Score,
    required this.run2Score,
    required this.allTimeBest,
  });

  @override
  State<RushDailyResultScreen> createState() => _RushDailyResultScreenState();
}

class _RushDailyResultScreenState extends State<RushDailyResultScreen> {
  static const Color _green = Color(0xFF00E5A0);
  static const Color _greenLt = Color(0xFFD0FFF0);

  Timer? _countdownTimer;
  Duration _timeUntilNextDaily = Duration.zero;

  late final int _bestScore;
  late final bool _isNewRecord;
  late final int _delta; // run2 - run1 (positive = improved)

  @override
  void initState() {
    super.initState();
    _bestScore = widget.run1Score > widget.run2Score ? widget.run1Score : widget.run2Score;
    _isNewRecord = _bestScore > widget.allTimeBest;
    _delta = widget.run2Score - widget.run1Score;
    _updateCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(_updateCountdown);
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
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

  Widget _runCard(String label, int score, bool isBetter) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isBetter ? _green.withValues(alpha: 0.50) : AppColors.cardBr,
          width: isBetter ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 0.8,
              color: isBetter
                  ? _green.withValues(alpha: 0.70)
                  : Colors.white.withValues(alpha: 0.35),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: isBetter ? Colors.white : Colors.white.withValues(alpha: 0.50),
              letterSpacing: -1.5,
              height: 1.0,
            ),
          ),
          if (isBetter) ...[
            const SizedBox(height: 4),
            Text(
              'best',
              style: TextStyle(
                fontSize: 11,
                color: _green.withValues(alpha: 0.65),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeltaRow() {
    final String label;
    final Color color;
    final IconData icon;

    if (_delta > 0) {
      label = '+$_delta in Run 2';
      color = _green.withValues(alpha: 0.85);
      icon = Icons.trending_up_rounded;
    } else if (_delta < 0) {
      label = '${_delta} in Run 2';
      color = Colors.white.withValues(alpha: 0.35);
      icon = Icons.trending_down_rounded;
    } else {
      label = 'Same score both runs';
      color = Colors.white.withValues(alpha: 0.35);
      icon = Icons.trending_flat_rounded;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final run1Better = widget.run1Score >= widget.run2Score;
    final run2Better = widget.run2Score > widget.run1Score;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.bgTop,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                Center(
                  child: Text(
                    'Daily Complete',
                    style: TextStyle(
                      fontSize: 15,
                      letterSpacing: 0.4,
                      color: Colors.white.withValues(alpha: 0.38),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.cardBr),
                    ),
                    child: Text(
                      'DAILY · 2 RUNS',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _runCard('Run 1', widget.run1Score, run1Better)),
                    const SizedBox(width: 12),
                    Expanded(child: _runCard('Run 2', widget.run2Score, run2Better)),
                  ],
                ),
                const SizedBox(height: 10),
                _buildDeltaRow(),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isNewRecord ? _green.withValues(alpha: 0.55) : AppColors.cardBr,
                      width: _isNewRecord ? 2.0 : 1.0,
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
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (_isNewRecord) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: _green.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _green.withValues(alpha: 0.45)),
                          ),
                          child: const Text(
                            '🏆  New Daily Record!',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _greenLt,
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 6),
                        Text(
                          'All-time best: ${widget.allTimeBest}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
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
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Next daily in ${_formatCountdown(_timeUntilNextDaily)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.28),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 19),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [_green.withValues(alpha: 0.28), _green.withValues(alpha: 0.13)],
                      ),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(color: _green.withValues(alpha: 0.60), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: _green.withValues(alpha: 0.18),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Main Menu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
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
      ),
    );
  }
}
