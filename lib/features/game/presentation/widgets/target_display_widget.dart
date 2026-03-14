import 'package:flutter/material.dart';

import 'package:dice/features/game/presentation/widgets/practice_target_bar.dart';

class TargetDisplayWidget extends StatelessWidget {
  final bool isPreStart;
  final bool isRolling;
  final int target;
  final Color cardColor;
  final Color accentColor;
  final Color inkColor;
  final ValueNotifier<int> rollingTargetListenable;
  final Animation<double> celebrateAnimation;

  const TargetDisplayWidget({
    super.key,
    required this.isPreStart,
    required this.isRolling,
    required this.target,
    required this.cardColor,
    required this.accentColor,
    required this.inkColor,
    required this.rollingTargetListenable,
    required this.celebrateAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: rollingTargetListenable,
      builder: (context, rollingTarget, child) {
        final targetDisplay = isPreStart
            ? '—'
            : (isRolling ? '$rollingTarget' : '$target');

        return PracticeTargetBar(
          cardColor: cardColor,
          accentColor: accentColor,
          inkColor: inkColor,
          targetText: targetDisplay,
          celebrateAnimation: celebrateAnimation,
        );
      },
    );
  }
}
