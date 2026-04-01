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
  // NEU:
  final bool showMerged;
  final VoidCallback onToggleMerged;
  final int? freePlayMoves;

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
  });

  static const Color _barBg = Color(0xFF0D1F35);
  static const Color _barBorder = Color(0x1A3FE8FF);
  static const Color _textPrimary = Color(0xFFEEEAF6);
  static const Color _textSecondary = Color(0xFF6B8CAE);
  static const Color _neonAccent = Color(0xFF3FE8FF);
  static const Color _neonAccentLt = Color(0xFF90D5F0);

  @override
  Widget build(BuildContext context) {
    if (isDailyMode) return _buildDailyBar();
    return _buildFreePlayBar();
  }

  Widget _buildFreePlayBar() {
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: _barBg,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: _barBorder, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Links: Merged Toggle
          GestureDetector(
            onTap: onToggleMerged,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  showMerged ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                  size: 16,
                  color: showMerged ? _neonAccentLt : _textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Merged',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: showMerged ? _neonAccentLt : _textSecondary,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          // NEU:
          const Spacer(),
          // Mitte: Moves
          if (freePlayMoves != null)
            Text(
              '$freePlayMoves ${freePlayMoves == 1 ? 'Move' : 'Moves'}',
              style: AppTextStyles.body.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _neonAccentLt.withValues(alpha: 0.85),
                height: 1,
              ),
            ),
          const Spacer(),
          // Rechts: Sound Iconer(),
          // Rechts: Sound Icon
          GestureDetector(
            onTap: onToggleSound,
            child: Icon(
              soundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              size: 20,
              color: soundOn ? _neonAccentLt : _textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Daily: [Calendar icon + puzzle N/total] [Sound icon] ──────────────────
  Widget _buildDailyBar() {
    final number = dailyPuzzleNumber ?? 1;
    final total = dailyPuzzleCount ?? 3;

    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: _barBg,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: _barBorder, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _neonAccent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: _neonAccent.withValues(alpha: 0.30), width: 0.5),
            ),
            child: Icon(Icons.calendar_today_rounded, size: 15, color: _neonAccentLt),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Daily Puzzle',
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
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: _textPrimary,
                    height: 1,
                  ),
                ),
                if (dailyMoves != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '$dailyMoves moves',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _neonAccent.withValues(alpha: 0.75),
                      height: 1,
                    ),
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: onToggleSound,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
              child: Icon(
                soundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                size: 20,
                color: soundOn ? _neonAccentLt : _textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
