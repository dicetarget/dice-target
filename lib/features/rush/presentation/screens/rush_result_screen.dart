// lib/features/rush/presentation/screens/rush_result_screen.dart

import 'package:dice/core/theme/app_colors.dart';
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
  static const Color _green = Color(0xFF4CAF82);

  int _newPb = 0;
  bool _isNewBest = false;

  @override
  void initState() {
    super.initState();
    _newPb = widget.score > widget.previousPb ? widget.score : widget.previousPb;
    _isNewBest = widget.score > widget.previousPb;
    _saveIfNewBest();
  }

  Future<void> _saveIfNewBest() async {
    if (!_isNewBest) return;
    await RushHighscoreStorage().saveGlobalBest(widget.score);
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
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildScoreCard(),
                  const SizedBox(height: 16),
                  _buildPbCard(),
                  const Spacer(),
                  _buildPlayAgainButton(),
                  const SizedBox(height: 12),
                  _buildHomeButton(context),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'SPEED RUN',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _green.withValues(alpha: 0.70),
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Run complete!',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.white,
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
        color: const Color(0xFF0D0F1F),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _green.withValues(alpha: _isNewBest ? 0.60 : 0.25),
          width: _isNewBest ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: _green.withValues(alpha: _isNewBest ? 0.18 : 0.06),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          if (_isNewBest)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _green.withValues(alpha: 0.50), width: 0.5),
              ),
              child: const Text(
                '🏆  New Best!',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _green),
              ),
            ),
          Text(
            'Puzzles solved',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.35),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.score}',
            style: const TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.w900,
              color: Colors.white,
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
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _isNewBest ? 'New all-time best' : 'All-time best',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),
          Text(
            '$_newPb',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayAgainButton() {
    return GestureDetector(
      onTap: _playAgain,
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_green.withValues(alpha: 0.22), _green.withValues(alpha: 0.10)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _green.withValues(alpha: 0.70), width: 1.5),
          boxShadow: [
            BoxShadow(color: _green.withValues(alpha: 0.30), blurRadius: 24, spreadRadius: 1),
          ],
        ),
        child: const Center(
          child: Text(
            'Play Again',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: _green),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 0.5),
        ),
        child: Center(
          child: Text(
            'Home',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),
        ),
      ),
    );
  }
}
