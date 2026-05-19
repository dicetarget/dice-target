import 'package:dice/core/theme/app_radius.dart';
import 'package:dice/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class PracticeSmallActionsRow extends StatelessWidget {
  final bool enabled;
  final Color accentColor;
  final Color inkColor;
  final VoidCallback? onUndo;
  final bool resetEnabled;
  final VoidCallback? onResetPuzzle;

  const PracticeSmallActionsRow({
    super.key,
    required this.enabled,
    required this.accentColor,
    required this.inkColor,
    required this.onUndo,
    required this.resetEnabled,
    required this.onResetPuzzle,
  });

  static const _undoActive = Color(0xFFFFFFFF);
  static const _undoInactive = Color(0xFF8A8A8A);
  static const _resetColor = Color(0xFFB85C5C);
  static const _resetColorLt = Color(0xFFFFB3B3);

  @override
  Widget build(BuildContext context) {
    final color = enabled ? _undoActive : _undoInactive;

    return Column(
      children: [
        const SizedBox(height: 8),
        Row(
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
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    border: Border.all(
                      color: enabled
                          ? _undoActive.withValues(alpha: 0.28)
                          : Colors.white.withValues(alpha: 0.14),
                      width: 0.5,
                    ),
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
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 160),
                opacity: resetEnabled ? 1.0 : 0.35,
                child: GestureDetector(
                  onTap: resetEnabled ? onResetPuzzle : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    height: 50,
                    decoration: BoxDecoration(
                      color: _resetColor.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      border: Border.all(
                        color: _resetColor.withValues(alpha: 0.30),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: 16,
                          color: _resetColorLt.withValues(alpha: 0.70),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          'Reset Puzzle',
                          style: AppTextStyles.body.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _resetColorLt.withValues(alpha: 0.70),
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
