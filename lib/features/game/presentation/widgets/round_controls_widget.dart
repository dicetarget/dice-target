import 'package:flutter/material.dart';

import 'package:dice/core/theme/app_spacing.dart';
import 'package:dice/core/ui_op.dart';
import 'package:dice/features/game/presentation/widgets/practice_ops_row.dart';
import 'package:dice/features/game/presentation/widgets/practice_small_actions_row.dart';

class RoundControlsWidget extends StatelessWidget {
  final bool canInteractGameplay;
  final List<UiOp> allowedOps;
  final UiOp? pendingOp;
  final bool undoEnabled;
  final bool resetEnabled;
  final Color accentColor;
  final Color inkColor;
  final void Function(UiOp op) onApplyOp;
  final VoidCallback onUndo;
  final VoidCallback? onResetPuzzle;

  const RoundControlsWidget({
    super.key,
    required this.canInteractGameplay,
    required this.allowedOps,
    required this.pendingOp,
    required this.undoEnabled,
    required this.resetEnabled,
    required this.accentColor,
    required this.inkColor,
    required this.onApplyOp,
    required this.onUndo,
    required this.onResetPuzzle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PracticeOpsRow(
          canInteractGameplay: canInteractGameplay,
          allowedOps: allowedOps,
          pendingOp: pendingOp,
          accentColor: accentColor,
          inkColor: inkColor,
          onApplyOp: onApplyOp,
        ),
        const SizedBox(height: AppSpacing.xl),
        PracticeSmallActionsRow(
          enabled: undoEnabled,
          accentColor: accentColor,
          inkColor: inkColor,
          onUndo: onUndo,
          resetEnabled: resetEnabled,
          onResetPuzzle: onResetPuzzle,
        ),
      ],
    );
  }
}
