import 'package:dice/core/theme/app_radius.dart';
import 'package:dice/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

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

  static const _undoActive = Color(0xFFFFFFFF);
  static const _undoInactive = Color(0xFF555555);

  @override
  Widget build(BuildContext context) {
    final color = enabled ? _undoActive : _undoInactive;

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: enabled ? onUndo : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: 50,
              decoration: BoxDecoration(
                color: enabled
                    ? _undoActive.withValues(alpha: 0.07)
                    : Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: Border.all(
                  color: enabled
                      ? _undoActive.withValues(alpha: 0.28)
                      : Colors.white.withValues(alpha: 0.08),
                  width: 0.5,
                ),
                // Kein boxShadow — Undo ist sekundäre Aktion
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.undo_rounded, size: 20, color: color),
                  const SizedBox(width: 7),
                  Text(
                    'Undo',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color,
                      height: 1,
                      // Kein Shadow
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
