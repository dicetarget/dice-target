import 'package:dice/core/theme/app_colors.dart';
import 'package:dice/core/theme/app_radius.dart';
import 'package:dice/core/theme/app_spacing.dart';
import 'package:dice/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class PracticeTopControlsBar extends StatelessWidget {
  final Color cardColor;
  final Color accentColor;
  final Color inkColor;
  final bool soundOn;
  final VoidCallback onToggleSound;
  final bool isDailyMode;
  final int? dailyPuzzleNumber;
  final int? dailyPuzzleCount;
  final int? dailyMoves;
  final bool showMerged;
  final VoidCallback onToggleMerged;
  final int? freePlayMoves;
  final String? rightLabel;

  const PracticeTopControlsBar({
    super.key,
    required this.cardColor,
    required this.accentColor,
    required this.inkColor,
    required this.soundOn,
    required this.onToggleSound,
    this.isDailyMode = false,
    this.dailyPuzzleNumber,
    this.dailyPuzzleCount,
    this.dailyMoves,
    required this.showMerged,
    required this.onToggleMerged,
    this.freePlayMoves,
    this.rightLabel,
  });

  static const Color _barBg = AppColors.surface;
  static const Color _textPrimary = AppColors.ink;
  static const Color _textSecondary = AppColors.inkMuted;
  static const Color _accent = AppColors.gold;

  @override
  Widget build(BuildContext context) {
    if (isDailyMode) return _buildDailyBar();
    return _buildFreePlayBar();
  }

  BoxDecoration get _barDecoration => BoxDecoration(
    color: _barBg,
    borderRadius: BorderRadius.circular(AppRadius.button),
    border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.28),
        blurRadius: 10,
        offset: const Offset(0, 5),
      ),
    ],
  );

  // ── Daily Bar: [Puzzle N/5] [Moves] [empty] ───────────────────────────────
  Widget _buildDailyBar() {
    final number = dailyPuzzleNumber ?? 1;
    final total = dailyPuzzleCount ?? 3;
    final moves = dailyMoves;

    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: _barDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Links: Puzzle Progress
          SizedBox(
            width: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Puzzle',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _textSecondary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$number / $total',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _textPrimary,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),

          // Mitte: Moves
          Expanded(
            child: Center(
              child: moves != null
                  ? Text(
                      '$moves ${moves == 1 ? 'Move' : 'Moves'}',
                      style: AppTextStyles.body.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _accent.withValues(alpha: 0.90),
                        height: 1,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),

          // Rechts: leer (Sound ist in AppBar)
          const SizedBox(width: 80),
        ],
      ),
    );
  }

  // ── Free Play / Training Bar: [Merged] [Moves] [empty] ───────────────────
  Widget _buildFreePlayBar() {
    final moves = freePlayMoves;

    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: _barDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Links: Merged Toggle
          SizedBox(
            width: 80,
            child: GestureDetector(
              onTap: onToggleMerged,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    showMerged ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                    size: 16,
                    color: showMerged ? _accent : _textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Merged',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: showMerged ? _accent : _textSecondary,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Mitte: Moves
          Expanded(
            child: Center(
              child: moves != null
                  ? Text(
                      '$moves ${moves == 1 ? 'Move' : 'Moves'}',
                      style: AppTextStyles.body.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _accent.withValues(alpha: 0.90),
                        height: 1,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),

          // Rechts: mode label (Random / difficulty)
          SizedBox(
            width: 80,
            child: rightLabel != null
                ? Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      rightLabel!,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _textSecondary,
                        height: 1,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
