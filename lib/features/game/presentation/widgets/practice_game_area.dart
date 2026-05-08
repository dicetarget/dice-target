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
  final FinalDiceState finalDiceState;
  final bool undoEnabled;
  final bool resetEnabled;
  final void Function(int index) onToggleSelect;
  final void Function(UiOp op) onApplyOp;
  final VoidCallback onUndo;
  final VoidCallback? onResetPuzzle;
  final MainAxisAlignment mainAxisAlignment;
  final double diceTopOffset;
  final double controlsGap;

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
    required this.finalDiceState,
    required this.undoEnabled,
    required this.resetEnabled,
    required this.onToggleSelect,
    required this.onApplyOp,
    required this.onUndo,
    required this.onResetPuzzle,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.diceTopOffset = 32,
    this.controlsGap = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: diceTopOffset),
          if (showDice)
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
              finalDiceState: finalDiceState,
              onToggleSelect: onToggleSelect,
            ),
          SizedBox(height: controlsGap),
          RoundControlsWidget(
            canInteractGameplay: canInteractGameplay,
            allowedOps: allowedOps,
            pendingOp: pendingOp,
            undoEnabled: undoEnabled,
            resetEnabled: resetEnabled,
            accentColor: accentColor,
            inkColor: inkColor,
            onApplyOp: onApplyOp,
            onUndo: onUndo,
            onResetPuzzle: onResetPuzzle,
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
