import 'package:dice/core/theme/app_colors.dart';
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

  static const double _radius = 24;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: celebrateAnimation,
      builder: (context, child) {
        final t = celebrateAnimation.value;
        final scale = 1.0 + (0.06 * t);
        return Transform.scale(
          scale: scale,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 220),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(_radius),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.55 + (0.25 * t)),
                  width: 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.22 + (0.18 * t)),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.08 + (0.10 * t)),
                    blurRadius: 48,
                    spreadRadius: 4,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.50),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'TARGET',
                    style: TextStyle(
                      color: AppColors.gold.withValues(alpha: 0.55),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3.0,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    targetText,
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2.0,
                      height: 1.0,
                      shadows: [
                        Shadow(
                          color: AppColors.gold.withValues(alpha: 0.45 + (0.25 * t)),
                          blurRadius: 20,
                        ),
                        Shadow(
                          color: AppColors.gold.withValues(alpha: 0.15 + (0.10 * t)),
                          blurRadius: 40,
                        ),
                      ],
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
