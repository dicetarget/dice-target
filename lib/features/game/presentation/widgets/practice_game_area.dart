import 'package:dice/core/theme/app_spacing.dart';
import 'package:dice/core/ui_op.dart';
import 'package:dice/features/game/presentation/widgets/dice_row_widget.dart';
import 'package:dice/features/game/presentation/widgets/practice_dice_row.dart';
import 'package:dice/features/game/presentation/widgets/round_controls_widget.dart';
import 'package:flutter/material.dart';

class PracticeGameArea extends StatelessWidget {
  final bool showDice;
  final bool isRolling;
  final bool isPlaying;
  final bool busy;
  final bool showMergedResults;
  final int mergePopKey;
  final Set<int> selectedIndices;
  final Color accentColor;
  final Color inkColor;
  final Animation<double> shakeAnimation;
  final ValueNotifier<List<int>> rollingDiceListenable;
  final bool rollingTargetLocked;
  final List<PracticeDieData> dice;
  final bool canInteractGameplay;
  final List<UiOp> allowedOps;
  final UiOp? pendingOp;
  final bool undoEnabled;
  final void Function(int index) onToggleSelect;
  final void Function(UiOp op) onApplyOp;
  final VoidCallback onUndo;

  const PracticeGameArea({
    super.key,
    required this.showDice,
    required this.isRolling,
    required this.isPlaying,
    required this.busy,
    required this.showMergedResults,
    required this.mergePopKey,
    required this.selectedIndices,
    required this.accentColor,
    required this.inkColor,
    required this.shakeAnimation,
    required this.rollingDiceListenable,
    required this.rollingTargetLocked,
    required this.dice,
    required this.canInteractGameplay,
    required this.allowedOps,
    required this.pendingOp,
    required this.undoEnabled,
    required this.onToggleSelect,
    required this.onApplyOp,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showDice) ...[
          DiceRowWidget(
            showDice: showDice,
            isRolling: isRolling,
            isPlaying: isPlaying,
            busy: busy,
            showMergedResults: showMergedResults,
            mergePopKey: mergePopKey,
            selectedIndices: selectedIndices,
            accentColor: accentColor,
            shakeAnimation: shakeAnimation,
            rollingDiceListenable: rollingDiceListenable,
            rollingTargetLocked: rollingTargetLocked,
            dice: dice,
            pendingOp: pendingOp,
            onToggleSelect: onToggleSelect,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        RoundControlsWidget(
          canInteractGameplay: canInteractGameplay,
          allowedOps: allowedOps,
          pendingOp: pendingOp,
          undoEnabled: undoEnabled,
          accentColor: accentColor,
          inkColor: inkColor,
          onApplyOp: onApplyOp,
          onUndo: onUndo,
        ),
      ],
    );
  }
}
