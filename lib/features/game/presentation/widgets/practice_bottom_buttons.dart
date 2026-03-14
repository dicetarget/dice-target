// lib/features/game/presentation/widgets/practice_bottom_buttons.dart
import 'package:flutter/material.dart';

import 'package:dice/core/theme/app_colors.dart';
import 'package:dice/core/theme/app_radius.dart';
import 'package:dice/core/theme/app_spacing.dart';
import 'package:dice/core/theme/app_text_styles.dart';

class PracticeBottomButtons extends StatelessWidget {
  final bool canPressBottom;
  final bool isPlaying;
  final bool canReset;
  final Color accentColor;
  final Color inkColor;
  final VoidCallback? onNoSolution;
  final VoidCallback? onResetDice;
  final VoidCallback? onNewGame;

  const PracticeBottomButtons({
    super.key,
    required this.canPressBottom,
    required this.isPlaying,
    required this.canReset,
    required this.accentColor,
    required this.inkColor,
    required this.onNoSolution,
    required this.onResetDice,
    required this.onNewGame,
  });

  @override
  Widget build(BuildContext context) {
    Widget bigButton({
      required String text,
      required VoidCallback? onPressed,
      bool outlined = false,
    }) {
      final shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      );

      final baseTextStyle = AppTextStyles.button.copyWith(color: accentColor);

      final style = outlined
          ? OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              shape: shape,
              side: BorderSide(
                color: inkColor.withValues(alpha: 0.35),
                width: 1,
              ),
              foregroundColor: accentColor,
              backgroundColor: AppColors.white.withValues(alpha: 0.45),
              enableFeedback: false,
            )
          : ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              shape: shape,
              elevation: 0,
              backgroundColor: AppColors.white.withValues(alpha: 0.55),
              foregroundColor: accentColor,
              enableFeedback: false,
            );

      return SizedBox(
        width: double.infinity,
        child: outlined
            ? OutlinedButton(
                onPressed: onPressed,
                style: style,
                child: Text(text, style: baseTextStyle),
              )
            : ElevatedButton(
                onPressed: onPressed,
                style: style,
                child: Text(text, style: baseTextStyle),
              ),
      );
    }

    final canNoSolution = canPressBottom && isPlaying;

    return Column(
      children: [
        bigButton(
          text: 'Show Solution',
          onPressed: canNoSolution ? onNoSolution : null,
          outlined: true,
        ),
        const SizedBox(height: AppSpacing.md),
        bigButton(
          text: 'Reset Round',
          onPressed: canReset ? onResetDice : null,
          outlined: true,
        ),
        const SizedBox(height: AppSpacing.md),
        bigButton(
          text: 'New Game',
          onPressed: canPressBottom ? onNewGame : null,
        ),
      ],
    );
  }
}
