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
                    ? _undoActive.withValues(alpha: 0.14)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: Border.all(
                  color: enabled
                      ? _undoActive.withValues(alpha: 0.70)
                      : Colors.white.withValues(alpha: 0.12),
                ),
                boxShadow: enabled
                    ? [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.12),
                          blurRadius: 14,
                          spreadRadius: 1,
                          offset: Offset.zero,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
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
                      fontWeight: FontWeight.w800,
                      color: color,
                      height: 1,
                      shadows: enabled
                          ? [Shadow(color: _undoActive.withValues(alpha: 0.50), blurRadius: 8)]
                          : null,
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
