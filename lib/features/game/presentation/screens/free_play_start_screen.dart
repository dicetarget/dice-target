// lib/features/game/presentation/screens/free_play_start_screen.dart

import 'package:dice/core/audio/sfx_singleton.dart';
import 'package:dice/core/theme/app_colors.dart';
import 'package:dice/core/widgets/tactile_button.dart';
import 'package:dice/features/game/presentation/screens/practice_screen.dart';
import 'package:dice/features/rush/presentation/screens/rush_start_screen.dart';
import 'package:flutter/material.dart';

class FreePlayStartScreen extends StatefulWidget {
  const FreePlayStartScreen({super.key});

  @override
  State<FreePlayStartScreen> createState() => _FreePlayStartScreenState();
}

class _FreePlayStartScreenState extends State<FreePlayStartScreen> {
  void _openClassic() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PracticeScreen(initialTrainingMode: false),
      ),
    );
  }

  void _openRush() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RushStartScreen()),
    );
  }

  Future<void> _openTraining() async {
    final difficulty = await _showDifficultySheet();
    if (!mounted || difficulty == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticeScreen(
          initialTrainingMode: true,
          initialDifficulty: difficulty,
        ),
      ),
    );
  }

  Future<PracticeDifficulty?> _showDifficultySheet() {
    return showModalBottomSheet<PracticeDifficulty>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        const items = [
          (PracticeDifficulty.easy, 'Easy', '10 – 40'),
          (PracticeDifficulty.medium, 'Medium', '30 – 70'),
          (PracticeDifficulty.hard, 'Hard', '50 – 100'),
          (PracticeDifficulty.expert, 'Expert', '80 – 120'),
        ];

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: AppColors.gold.withValues(alpha: 0.20), width: 0.5),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Select Difficulty',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 18),
              for (final entry in items) ...[
                _DifficultyRow(
                  label: entry.$2,
                  range: entry.$3,
                  onTap: () => Navigator.of(ctx).pop(entry.$1),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        );
      },
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              _buildHeader(),
              const SizedBox(height: 8),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildClassicCard(),
                        const SizedBox(height: 12),
                        _buildRushCard(),
                        const SizedBox(height: 12),
                        _buildTrainingCard(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.inkMuted,
          enableFeedback: false,
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: 4),
        const Expanded(
          child: Text(
            'Free Play',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              letterSpacing: -0.5,
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            sfx.enabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            color: AppColors.inkMuted,
            size: 22,
          ),
          enableFeedback: false,
          onPressed: () async {
            await sfx.toggle();
            if (mounted) setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildClassicCard() {
    return TactileButton(
      variant: TactileButtonVariant.gold,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      borderRadius: BorderRadius.circular(16),
      onPressed: _openClassic,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text(
            'Classic',
            style: TextStyle(color: AppColors.dicePip, fontSize: 17, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4),
          Text(
            'Targets 1–120 · Not every puzzle has a solution',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.dicePip, fontSize: 12, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }

  Widget _buildRushCard() {
    return TactileButton(
      variant: TactileButtonVariant.primary,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      borderRadius: BorderRadius.circular(16),
      onPressed: _openRush,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text(
            'Rush',
            style: TextStyle(color: AppColors.ink, fontSize: 17, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4),
          Text(
            'Solve as many targets as possible in 90 seconds',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkMuted, fontSize: 12, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingCard() {
    return TactileButton(
      variant: TactileButtonVariant.gold,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      borderRadius: BorderRadius.circular(16),
      onPressed: _openTraining,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text(
            'Training',
            style: TextStyle(color: AppColors.dicePip, fontSize: 17, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4),
          Text(
            'Solvable puzzles by difficulty',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.dicePip, fontSize: 12, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }
}

// ── _DifficultyRow ────────────────────────────────────────────────────────────

class _DifficultyRow extends StatelessWidget {
  final String label;
  final String range;
  final VoidCallback onTap;

  const _DifficultyRow({
    required this.label,
    required this.range,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
            Text(
              range,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
