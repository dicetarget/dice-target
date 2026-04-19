import 'package:flutter/material.dart';
import 'package:dice/core/theme/app_colors.dart';
import 'package:dice/features/vs/domain/vs_challenge.dart';
import 'package:dice/features/vs/presentation/screens/vs_screen.dart';

enum VsStartMode { challenger, opponent }

class VsStartScreen extends StatefulWidget {
  final VsStartMode mode;
  final VsChallenge? incomingChallenge;
  final String? friendId;
  final String? myId;

  const VsStartScreen({
    super.key,
    required this.mode,
    this.incomingChallenge,
    this.friendId,
    this.myId,
  });

  @override
  State<VsStartScreen> createState() => _VsStartScreenState();
}

class _VsStartScreenState extends State<VsStartScreen> {
  static const Color _orange = Color(0xFFFF6B00);

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
              child: widget.mode == VsStartMode.challenger
                  ? _buildChallengerContent()
                  : _buildOpponentContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengerContent() {
    return Column(
      children: [
        const SizedBox(height: 32),
        _buildHeader('Challenge a Friend'),
        const SizedBox(height: 16),
        Text(
          'Play 90 seconds. Share your result. See who wins.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.55),
            height: 1.5,
          ),
        ),
        const Spacer(),
        _buildPrimaryButton('Start Challenge', () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => VsScreen(
                seed: DateTime.now().millisecondsSinceEpoch,
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        _buildHomeButton(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildOpponentContent() {
    return Column(
      children: [
        const SizedBox(height: 32),
        _buildHeader("You've been challenged!"),
        const SizedBox(height: 32),
        _buildChallengerStatsCard(),
        const Spacer(),
        _buildPrimaryButton('Accept Challenge', () {
          Navigator.of(context).pop();
        }),
        const SizedBox(height: 12),
        _buildHomeButton(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildHeader(String title) {
    return Column(
      children: [
        Text(
          'VS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _orange.withValues(alpha: 0.70),
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
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

  Widget _buildChallengerStatsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0F1F),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _orange.withValues(alpha: 0.35),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: _orange.withValues(alpha: 0.10),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Challenger\'s Score',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.35),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatColumn('Puzzles'),
              _buildDivider(),
              _buildStatColumn('Time'),
              _buildDivider(),
              _buildStatColumn('Moves'),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: _orange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _orange.withValues(alpha: 0.35),
                width: 0.5,
              ),
            ),
            child: Text(
              'Beat them to win!',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _orange.withValues(alpha: 0.80),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label) {
    return Column(
      children: [
        Text(
          '???',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.white.withValues(alpha: 0.20),
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.30),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withValues(alpha: 0.08),
    );
  }

  Widget _buildPrimaryButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _orange.withValues(alpha: 0.22),
              _orange.withValues(alpha: 0.10),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _orange.withValues(alpha: 0.70), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _orange.withValues(alpha: 0.30),
              blurRadius: 24,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: _orange,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeButton() {
    return GestureDetector(
      onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 0.5,
          ),
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
