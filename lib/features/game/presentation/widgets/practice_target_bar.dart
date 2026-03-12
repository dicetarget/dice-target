// lib/features/game/presentation/widgets/practice_target_bar.dart
import 'package:flutter/material.dart';

import 'package:dice/core/theme/app_colors.dart';
import 'package:dice/core/theme/app_radius.dart';
import 'package:dice/core/theme/app_spacing.dart';
import 'package:dice/core/theme/app_text_styles.dart';

class PracticeTargetBar extends StatelessWidget {
  final Color cardColor;
  final Color accentColor;
  final Color inkColor;
  final String targetText;
  final Animation<double> celebrateAnimation;

  const PracticeTargetBar({
    super.key,
    required this.cardColor,
    required this.accentColor,
    required this.inkColor,
    required this.targetText,
    required this.celebrateAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final hasNumericTarget = int.tryParse(targetText) != null;

    final numberWidget = AnimatedBuilder(
      animation: celebrateAnimation,
      builder: (context, _) {
        final t = hasNumericTarget ? celebrateAnimation.value : 0.0;

        final scale = 1.0 + (0.055 * t);
        final glowOpacity = 0.42 * t;
        final blur = 26.0 * t;
        final spread = 6.0 * t;

        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.s,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.medium),
              boxShadow: t <= 0.001
                  ? const []
                  : [
                      BoxShadow(
                        color: accentColor.withValues(alpha: glowOpacity),
                        blurRadius: blur,
                        spreadRadius: spread,
                        offset: const Offset(0, 10),
                      ),
                    ],
            ),
            child: SizedBox(
              width: 104,
              child: Center(
                child: Text(
                  targetText,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.targetNumber.copyWith(
                    shadows: t <= 0.001
                        ? null
                        : [
                            Shadow(
                              color: accentColor.withValues(alpha: 0.18 * t),
                              blurRadius: 10 * t,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.section,
        vertical: 20,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: RichText(
          text: TextSpan(
            style: AppTextStyles.targetNumber.copyWith(color: inkColor),
            children: [
              const TextSpan(text: 'Target: '),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: numberWidget,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
