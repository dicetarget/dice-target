import 'package:flutter/material.dart';

import 'package:dice/features/game/presentation/widgets/die_face.dart';

class PracticeDieData {
  final int value;
  final String? maskLabel;

  const PracticeDieData({required this.value, required this.maskLabel});
}

class PracticeDiceRow extends StatelessWidget {
  final bool isRolling;
  final bool isPlaying;
  final bool busy;
  final bool showMergedResults;
  final bool rollingTargetLocked;
  final int mergePopKey;
  final List<int> rollingDice;
  final List<PracticeDieData> dice;
  final Set<int> selectedIndices;
  final Color accentColor;
  final void Function(int index) onToggleSelect;

  const PracticeDiceRow({
    super.key,
    required this.isRolling,
    required this.isPlaying,
    required this.busy,
    required this.showMergedResults,
    required this.rollingTargetLocked,
    required this.mergePopKey,
    required this.rollingDice,
    required this.dice,
    required this.selectedIndices,
    required this.accentColor,
    required this.onToggleSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (isRolling) {
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: List.generate(rollingDice.length, (i) {
          final idle = !rollingTargetLocked;
          return AnimatedOpacity(
            opacity: idle ? 0.38 : 1,
            duration: const Duration(milliseconds: 140),
            child: DieFace(value: rollingDice[i], selected: false),
          );
        }),
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: List.generate(dice.length, (i) {
        final selected = selectedIndices.contains(i) && isPlaying && !busy;
        final overlay = showMergedResults ? null : dice[i].maskLabel;

        final dieWidget = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onToggleSelect(i),
          child: AnimatedScale(
            scale: selected ? 1.03 : 1,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.18),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : const [],
              ),
              child: DieFace(
                value: dice[i].value,
                selected: selected,
                overlayText: overlay,
              ),
            ),
          ),
        );

        final isLast = i == dice.length - 1;

        if (isLast) {
          return TweenAnimationBuilder<double>(
            key: ValueKey(mergePopKey),
            tween: Tween(begin: 1.10, end: 1.0),
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: dieWidget,
          );
        }

        return dieWidget;
      }),
    );
  }
}
