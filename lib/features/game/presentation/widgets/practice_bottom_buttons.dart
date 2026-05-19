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
        // Show Solution — schwach, outlined, kein TactileButton
        AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: canNoSolution ? 1.0 : 0.35,
          child: GestureDetector(
            onTap: canNoSolution ? onNoSolution : null,
            child: Container(
              width: double.infinity,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.inkHint.withValues(alpha: 0.30),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 14,
                    color: AppColors.inkHint,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Show Solution',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkHint,
                      height: 1,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // New Game — ghost outlined gold
        TactileButton(
          variant: TactileButtonVariant.ghost,
          width: double.infinity,
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          borderRadius: BorderRadius.circular(14),
          enabled: canPressBottom,
          onPressed: canPressBottom ? onNewGame : null,
          child: const Text(
            'New Game',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.gold,
              letterSpacing: 0.3,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}
