// lib/features/game/presentation/widgets/practice_top_controls_bar.dart
import 'package:flutter/material.dart';

import 'package:dice/core/theme/app_colors.dart';
import 'package:dice/core/theme/app_radius.dart';
import 'package:dice/core/theme/app_spacing.dart';
import 'package:dice/core/theme/app_text_styles.dart';

class PracticeTopControlsBar extends StatelessWidget {
  final Color cardColor;
  final Color accentColor;
  final Color inkColor;
  final String difficultyLabel;
  final bool soundOn;
  final VoidCallback onToggleSound;

  const PracticeTopControlsBar({
    super.key,
    required this.cardColor,
    required this.accentColor,
    required this.inkColor,
    required this.difficultyLabel,
    required this.soundOn,
    required this.onToggleSound,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(AppRadius.button),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      size: AppSpacing.xxl,
                      color: accentColor.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Difficulty: $difficultyLabel',
                      style: AppTextStyles.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: inkColor.withValues(alpha: 0.85),
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Container(
                      width: 1,
                      height: AppSpacing.xxl,
                      color: inkColor.withValues(alpha: 0.12),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      onTap: onToggleSound,
                      enableFeedback: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              soundOn
                                  ? Icons.volume_up_rounded
                                  : Icons.volume_off_rounded,
                              size: AppSpacing.xxl,
                              color: soundOn
                                  ? accentColor.withValues(alpha: 0.9)
                                  : inkColor.withValues(alpha: 0.45),
                            ),
                            const SizedBox(width: AppSpacing.s),
                            Text(
                              soundOn ? 'Sound' : 'Muted',
                              style: AppTextStyles.body.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: soundOn
                                    ? inkColor.withValues(alpha: 0.85)
                                    : inkColor.withValues(alpha: 0.55),
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
