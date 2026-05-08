import 'package:dice/core/theme/app_colors.dart';
import 'package:dice/core/theme/app_spacing.dart';
import 'package:dice/core/widgets/tactile_button.dart';
import 'package:flutter/material.dart';

class PracticeBottomButtons extends StatelessWidget {
  final bool canPressBottom;
  final bool isPlaying;
  final VoidCallback? onNoSolution;
  final VoidCallback? onNewGame;

  const PracticeBottomButtons({
    super.key,
    required this.canPressBottom,
    required this.isPlaying,
    required this.onNoSolution,
    required this.onNewGame,
  });

  @override
  Widget build(BuildContext context) {
    final canNoSolution = canPressBottom && isPlaying;

    return Column(
      children: [
        TactileButton(
          variant: TactileButtonVariant.primary,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          borderRadius: BorderRadius.circular(16),
          enabled: canNoSolution,
          onPressed: canNoSolution ? onNoSolution : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.lightbulb_outline_rounded, size: 18, color: AppColors.gold),
              SizedBox(width: 8),
              Text(
                'Show Solution',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                  letterSpacing: 0.2,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TactileButton(
          variant: TactileButtonVariant.gold,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          borderRadius: BorderRadius.circular(16),
          enabled: canPressBottom,
          onPressed: canPressBottom ? onNewGame : null,
          child: const Text(
            'New Game',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.dicePip,
              letterSpacing: 0.3,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}

