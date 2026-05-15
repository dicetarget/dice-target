import 'package:dice/core/theme/app_colors.dart';
import 'package:dice/core/widgets/tactile_button.dart';
import 'package:dice/features/vs/domain/vs_challenge_model.dart';
import 'package:dice/features/vs/presentation/screens/vs_home_screen.dart';
import 'package:dice/features/vs/presentation/screens/vs_screen.dart';
import 'package:flutter/material.dart';

enum VsStartMode { challenger, opponent }

class VsStartScreen extends StatefulWidget {
  final VsStartMode mode;
  final VsChallengeModel? incomingChallenge;
  final String? friendId;
  final String? myId;
  final String? myDisplayName;
  final String? friendName;
  final String vsMode;

  const VsStartScreen({
    super.key,
    required this.mode,
    this.incomingChallenge,
    this.friendId,
    this.myId,
    this.myDisplayName,
    this.friendName,
    this.vsMode = 'rush',
  });

  @override
  State<VsStartScreen> createState() => _VsStartScreenState();
}

class _VsStartScreenState extends State<VsStartScreen> {
  int get _puzzleCount => widget.vsMode == 'speedrun_advanced' ? 5 : 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: widget.mode == VsStartMode.challenger
              ? _buildChallengerContent()
              : _buildOpponentContent(),
        ),
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
          widget.vsMode == 'rush'
              ? '90 seconds. Same seed.\nSolve as many as you can.'
              : '$_puzzleCount puzzles. Same seed.\nSolve all — fastest time wins.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.inkMuted,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.vsMode == 'rush'
              ? 'More puzzles wins — fewest moves breaks ties.'
              : 'No time limit. Pure speed.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.inkMuted,
            height: 1.5,
          ),
        ),
        const Spacer(),
        TactileButton(
          variant: TactileButtonVariant.purple,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          borderRadius: BorderRadius.circular(16),
          onPressed: () {
            if (widget.incomingChallenge == null) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => VsScreen(
                  seed: widget.incomingChallenge!.seed,
                  myId: widget.myId,
                  friendId: widget.friendId,
                  myDisplayName: widget.myDisplayName,
                  friendName: widget.friendName,
                  incomingChallenge: widget.incomingChallenge,
                  vsMode: widget.vsMode,
                ),
              ),
            );
          },
          child: const Text(
            'Start Challenge',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
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
        const SizedBox(height: 16),
        Text(
          widget.vsMode == 'rush'
              ? '90 seconds. Same seed.\nSolve as many as you can.'
              : '$_puzzleCount puzzles. Same seed.\nSolve all — fastest time wins.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.inkMuted,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.vsMode == 'rush'
              ? 'More puzzles wins — fewest moves breaks ties.'
              : 'No time limit. Pure speed.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.inkMuted,
            height: 1.5,
          ),
        ),
        const Spacer(),
        TactileButton(
          variant: TactileButtonVariant.purple,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          borderRadius: BorderRadius.circular(16),
          onPressed: () {
            if (widget.incomingChallenge == null) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => VsScreen(
                  seed: widget.incomingChallenge!.seed,
                  myId: widget.myId,
                  friendId: widget.friendId,
                  myDisplayName: widget.myDisplayName,
                  friendName: widget.friendName,
                  incomingChallenge: widget.incomingChallenge,
                  vsMode: widget.vsMode,
                ),
              ),
            );
          },
          child: const Text(
            'Accept Challenge',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildHomeButton(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildHeader(String title) {
    return Column(
      children: [
        const Text(
          'VS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.inkMuted,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Color(0xFF9060C8),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.8),
      ),
      child: Column(
        children: [
          const Text(
            "Challenger's Score",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.inkMuted,
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
              color: const Color(0xFF9060C8).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF9060C8).withValues(alpha: 0.30), width: 0.5),
            ),
            child: const Text(
              'Beat them to win!',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9060C8),
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
        const Text(
          '???',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppColors.inkMuted,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.inkMuted,
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

  Widget _buildHomeButton() {
    return TactileButton(
      variant: TactileButtonVariant.primary,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      borderRadius: BorderRadius.circular(16),
      onPressed: () => Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const VsHomeScreen()),
        (route) => route.isFirst,
      ),
      child: const Text(
        'Back to VS',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.inkMuted,
        ),
      ),
    );
  }
}
