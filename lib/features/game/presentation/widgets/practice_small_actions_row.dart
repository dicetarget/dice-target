// lib/features/game/presentation/widgets/practice_small_actions_row.dart
import 'package:flutter/material.dart';

import 'package:dice/core/theme/app_colors.dart';
import 'package:dice/core/theme/app_radius.dart';
import 'package:dice/core/theme/app_spacing.dart';
import 'package:dice/core/theme/app_text_styles.dart';

class PracticeSmallActionsRow extends StatelessWidget {
  final bool enabled;
  final Color accentColor;
  final Color inkColor;
  final VoidCallback? onUndo;

  const PracticeSmallActionsRow({
    super.key,
    required this.enabled,
    required this.accentColor,
    required this.inkColor,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: enabled ? onUndo : null,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              side: BorderSide(
                color: inkColor.withValues(alpha: 0.28),
                width: 1,
              ),
              foregroundColor: accentColor,
              backgroundColor: AppColors.white.withValues(alpha: 0.35),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.undo,
                  size: AppSpacing.xxl,
                  color: enabled
                      ? accentColor
                      : inkColor.withValues(alpha: 0.35),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Undo',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: enabled
                        ? accentColor
                        : inkColor.withValues(alpha: 0.35),
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
