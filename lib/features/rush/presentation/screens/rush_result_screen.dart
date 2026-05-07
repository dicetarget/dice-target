// lib/features/rush/presentation/screens/rush_result_screen.dart

import 'package:dice/core/theme/app_colors.dart';
import 'package:dice/core/widgets/tactile_button.dart';
import 'package:dice/features/rush/data/rush_highscore_storage.dart';
import 'package:dice/features/rush/presentation/screens/rush_screen.dart';
import 'package:flutter/material.dart';

class RushResultScreen extends StatefulWidget {
  final int score;
  final int previousPb;
  final int lastPuzzleTarget;
  final List<int> lastPuzzleDice;

  const RushResultScreen({
    super.key,
    required this.score,
    required this.previousPb,
    required this.lastPuzzleTarget,
    required this.lastPuzzleDice,
  });

  @override
  State<RushResultScreen> createState() => _RushResultScreenState();
}

class _RushResultScreenState extends State<RushResultScreen> {
  int _newPb = 0;
  bool _isNewBest = false;
  int _todayBest = 0;

  @override
  void initState() {
    super.initState();
    _newPb = widget.score > widget.previousPb ? widget.score : widget.previousPb;
    _isNewBest = widget.score > widget.previousPb;
    _initScores();
  }

  Future<void> _initScores() async {
    final storage = RushHighscoreStorage();
    if (_isNewBest) {
      await storage.saveGlobalBest(widget.score);
    }
    await storage.saveTodayBest(widget.score);
    final todayBest = await storage.loadTodayBest();
    if (mounted) setState(() => _todayBest = todayBest);
  }

  Future<void> _playAgain() async {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => RushScreen(personalBest: _newPb),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 32),
              _buildHeader(),
              const SizedBox(height: 32),
              _buildScoreCard(),
              const SizedBox(height: 16),
              _buildPbCard(),
              const Spacer(),
              TactileButton(
                variant: TactileButtonVariant.gold,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                borderRadius: BorderRadius.circular(16),
                onPressed: _playAgain,
                child: const Text(
                  'Play Again',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dicePip,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TactileButton(
                variant: TactileButtonVariant.primary,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                borderRadius: BorderRadius.circular(16),
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text(
                  'Home',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkMuted,
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

  Widget _buildHeader() {
    return Column(
      children: [
        const Text(
          'RUSH',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.inkMuted,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Run complete!',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
            letterSpacing: -0.8,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isNewBest
              ? AppColors.gold.withValues(alpha: 0.60)
              : Colors.white.withValues(alpha: 0.08),
          width: _isNewBest ? 1.8 : 0.8,
        ),
        boxShadow: _isNewBest
            ? [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.18),
                  blurRadius: 24,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: Column(
        children: [
          if (_isNewBest)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.40), width: 0.5),
              ),
              child: const Text(
                '🏆  New Best!',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.gold),
              ),
            ),
          const Text(
            'Puzzles solved',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.inkMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.score}',
            style: const TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.w900,
              color: AppColors.gold,
              letterSpacing: -4,
              height: 0.9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPbCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07), width: 0.8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's best",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkMuted,
                ),
              ),
              Text(
                '$_todayBest',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isNewBest ? 'New all-time best' : 'All-time best',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkMuted,
                ),
              ),
              Text(
                '$_newPb',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
