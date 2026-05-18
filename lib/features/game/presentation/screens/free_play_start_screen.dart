// lib/features/game/presentation/screens/free_play_start_screen.dart

import 'package:dice/core/theme/app_colors.dart';
import 'package:dice/core/widgets/mode_screen_header.dart';
import 'package:dice/features/game/presentation/screens/practice_screen.dart';
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
                  color: Colors.white,
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
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildClassicCard(),
              const SizedBox(height: 12),
              _buildTrainingCard(),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return ModeScreenHeader(
      title: 'Free Play',
      titleColor: AppColors.modeFreePlay,
      showSound: true,
      onSoundToggle: () => setState(() {}),
    );
  }

  Widget _buildClassicCard() {
    return GestureDetector(
      onTap: _openClassic,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.modeFreePlay.withValues(alpha: 0.30),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.modeFreePlay.withValues(alpha: 0.08),
              blurRadius: 20,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.modeFreePlay.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.casino_rounded,
                color: AppColors.modeFreePlay,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Classic',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.modeFreePlay,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Solo or pass-and-play with friends',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.modeFreePlay.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.modeFreePlay.withValues(alpha: 0.25),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      'Targets 1–120',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.modeFreePlay,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.modeFreePlay.withValues(alpha: 0.50),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingCard() {
    return GestureDetector(
      onTap: _openTraining,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.modeFreePlay.withValues(alpha: 0.30),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.modeFreePlay.withValues(alpha: 0.08),
              blurRadius: 20,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.modeFreePlay.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.track_changes_rounded,
                color: AppColors.modeFreePlay,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Training',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.modeFreePlay,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Practice solvable puzzles by difficulty',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.modeFreePlay.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.modeFreePlay.withValues(alpha: 0.25),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      'Easy · Medium · Hard · Expert',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.modeFreePlay,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.modeFreePlay.withValues(alpha: 0.50),
              size: 24,
            ),
          ],
        ),
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
                  color: Colors.white,
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
