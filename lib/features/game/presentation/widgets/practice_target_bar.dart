import 'package:dice/core/theme/app_spacing.dart';
import 'package:dice/core/widgets/neon_container.dart';
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

        const cyan = Color(0xFF3FE8FF);
        const goldTop = Color(0xFFFFFAD0);
        const goldMid = Color(0xFFFFD54A);
        const goldBottom = Color(0xFFFF9F00);

        return Transform.scale(
          scale: scale,
          child: NeonContainer(
            glowColor: cyan,
            intensity: NeonIntensity.strong,
            selected: false,
            enabled: true,
            borderRadius: BorderRadius.circular(_radius),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.xl),
            backgroundGradient: const LinearGradient(
              colors: [Color(0xFF000508), Color(0xFF00080F), Color(0xFF000305)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.50, 1.0],
            ),
            borderColor: cyan.withValues(alpha: 0.90),
            borderWidth: 2.2,
            customShadows: [
              BoxShadow(color: cyan.withValues(alpha: 0.70 + (0.18 * t)), blurRadius: 4),
              BoxShadow(
                color: cyan.withValues(alpha: 0.38 + (0.14 * t)),
                blurRadius: 16,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: cyan.withValues(alpha: 0.22 + (0.10 * t)),
                blurRadius: 32,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.65),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: cyan.withValues(alpha: 0.10 + (0.06 * t)),
                blurRadius: 60,
                spreadRadius: 4,
              ),
            ],
            innerHighlightGradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.05),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.18),
              ],
              stops: const [0.0, 0.25, 1.0],
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'TARGET:',
                    style: TextStyle(
                      color: cyan.withValues(alpha: 0.88),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                      height: 1.0,
                      shadows: [Shadow(color: cyan.withValues(alpha: 0.50), blurRadius: 12)],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 110,
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Text(
                          targetText,
                          style: TextStyle(
                            color: goldBottom.withValues(alpha: 0.35),
                            fontSize: 50,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.5,
                            height: 1.0,
                            shadows: [
                              Shadow(
                                color: goldBottom.withValues(alpha: 0.55 + (0.20 * t)),
                                blurRadius: 24,
                              ),
                            ],
                          ),
                        ),
                        ShaderMask(
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [goldTop, goldMid, goldBottom],
                              stops: const [0.0, 0.45, 1.0],
                            ).createShader(bounds);
                          },
                          child: Text(
                            targetText,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 50,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.5,
                              height: 1.0,
                              shadows: [
                                Shadow(
                                  color: goldMid.withValues(alpha: 0.60 + (0.20 * t)),
                                  blurRadius: 16,
                                ),
                                Shadow(
                                  color: Colors.white.withValues(alpha: 0.20 + (0.10 * t)),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ), // schliesst Stack
                  ), // schliesst SizedBox
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
