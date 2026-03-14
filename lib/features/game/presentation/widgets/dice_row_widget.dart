import 'package:flutter/material.dart';

import 'package:dice/features/game/presentation/widgets/practice_dice_row.dart';

class DiceRowWidget extends StatelessWidget {
  final bool showDice;
  final bool isRolling;
  final bool isPlaying;
  final bool busy;
  final bool showMergedResults;
  final int mergePopKey;
  final Set<int> selectedIndices;
  final Color accentColor;
  final Animation<double> shakeAnimation;
  final ValueNotifier<List<int>> rollingDiceListenable;
  final bool rollingTargetLocked;
  final List<PracticeDieData> dice;
  final void Function(int index) onToggleSelect;

  const DiceRowWidget({
    super.key,
    required this.showDice,
    required this.isRolling,
    required this.isPlaying,
    required this.busy,
    required this.showMergedResults,
    required this.mergePopKey,
    required this.selectedIndices,
    required this.accentColor,
    required this.shakeAnimation,
    required this.rollingDiceListenable,
    required this.rollingTargetLocked,
    required this.dice,
    required this.onToggleSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (!showDice) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(shakeAnimation.value, 0),
          child: child,
        );
      },
      child: ValueListenableBuilder<List<int>>(
        valueListenable: rollingDiceListenable,
        builder: (context, rollingDice, child) {
          return PracticeDiceRow(
            isRolling: isRolling,
            isPlaying: isPlaying,
            busy: busy,
            showMergedResults: showMergedResults,
            rollingTargetLocked: rollingTargetLocked,
            mergePopKey: mergePopKey,
            rollingDice: rollingDice,
            dice: dice,
            selectedIndices: selectedIndices,
            accentColor: accentColor,
            onToggleSelect: onToggleSelect,
          );
        },
      ),
    );
  }
}
