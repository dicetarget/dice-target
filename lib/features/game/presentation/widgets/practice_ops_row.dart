// lib/features/game/presentation/widgets/practice_ops_row.dart
import 'package:flutter/material.dart';

import 'package:dice/core/theme/app_colors.dart';
import 'package:dice/core/theme/app_durations.dart';
import 'package:dice/core/theme/app_radius.dart';
import 'package:dice/core/theme/app_spacing.dart';
import 'package:dice/core/theme/app_text_styles.dart';
import 'package:dice/core/ui_op.dart';

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

  @override
  Widget build(BuildContext context) {
    Widget opButton(UiOp op) {
      final enabled = canInteractGameplay && allowedOps.contains(op);
      final isSelected = pendingOp == op;

      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7),
          child: AnimatedOpacity(
            opacity: enabled ? 1 : 0.55,
            duration: AppDurations.medium,
            child: AnimatedScale(
              scale: isSelected ? 1.05 : 1,
              duration: AppDurations.fast,
              curve: Curves.easeOut,
              child: ElevatedButton(
                onPressed: enabled ? () => onApplyOp(op) : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    side: isSelected
                        ? BorderSide(color: accentColor, width: 2)
                        : BorderSide.none,
                  ),
                  backgroundColor: isSelected
                      ? accentColor.withValues(alpha: 0.15)
                      : AppColors.white.withValues(alpha: 0.65),
                  foregroundColor: inkColor,
                  disabledBackgroundColor: AppColors.white.withValues(
                    alpha: 0.35,
                  ),
                  disabledForegroundColor: inkColor.withValues(alpha: 0.35),
                  elevation: isSelected ? 2 : 0,
                ),
                child: Text(
                  uiOpSymbol(op),
                  style: AppTextStyles.button.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: inkColor,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        opButton(UiOp.add),
        opButton(UiOp.sub),
        opButton(UiOp.mul),
        opButton(UiOp.div),
      ],
    );
  }
}
