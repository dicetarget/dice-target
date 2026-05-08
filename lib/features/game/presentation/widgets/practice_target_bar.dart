import 'package:dice/core/theme/app_colors.dart';
import 'package:dice/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

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

  static const double _radius = 22;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: celebrateAnimation,
      builder: (context, child) {
        final t = celebrateAnimation.value;
        final scale = 1 + (0.05 * t);

        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(_radius),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.55 + (0.20 * t)),
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.25 + (0.15 * t)),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.lg,
              horizontal: AppSpacing.xl,
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'TARGET:',
                    style: TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 110,
                    child: Text(
                      targetText,
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 50,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.5,
                        height: 1.0,
                        shadows: [
                          Shadow(
                            color: AppColors.gold.withValues(alpha: 0.40 + (0.20 * t)),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
