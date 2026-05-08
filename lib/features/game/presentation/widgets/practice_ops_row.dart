import 'package:dice/core/theme/app_colors.dart';
import 'package:dice/core/ui_op.dart';
import 'package:dice/core/widgets/tactile_button.dart';
import 'package:flutter/material.dart';

class PracticeOpsRow extends StatelessWidget {
  final bool canInteractGameplay;
  final List<UiOp> allowedOps;
  final UiOp? pendingOp;
  final Color accentColor;
  final Color inkColor;
  final void Function(UiOp op) onApplyOp;

  const PracticeOpsRow({
    super.key,
    required this.canInteractGameplay,
    required this.allowedOps,
    required this.pendingOp,
    required this.accentColor,
    required this.inkColor,
    required this.onApplyOp,
  });

  Color _colorFor(UiOp op) {
    switch (op) {
      case UiOp.add: return AppColors.opAdd;
      case UiOp.sub: return AppColors.opSubtract;
      case UiOp.mul: return AppColors.opMultiply;
      case UiOp.div: return AppColors.opDivide;
    }
  }

  Color _fgColorFor(UiOp op) {
    switch (op) {
      case UiOp.add: return AppColors.opPlusForeground;
      case UiOp.sub: return AppColors.opMinusForeground;
      case UiOp.mul: return AppColors.opTimesForeground;
      case UiOp.div: return AppColors.opDivForeground;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget opButton(UiOp op) {
      final enabled = canInteractGameplay && allowedOps.contains(op);
      final isSelected = pendingOp == op;

      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: TactileButton(
            variant: TactileButtonVariant.primary,
            customColor: _colorFor(op),
            selected: isSelected,
            enabled: enabled,
            onPressed: enabled ? () => onApplyOp(op) : null,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: Text(
                uiOpSymbol(op),
                style: TextStyle(
                  color: _fgColorFor(op),
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [opButton(UiOp.add), opButton(UiOp.sub), opButton(UiOp.mul), opButton(UiOp.div)],
    );
  }
}
