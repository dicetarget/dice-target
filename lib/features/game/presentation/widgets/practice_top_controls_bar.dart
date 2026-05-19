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
  static const Color _accent = AppColors.gold;
  // dim: für Merged / Random / Puzzle-Label
  static const Color _dim = AppColors.inkHint;

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

  @override
  Widget build(BuildContext context) {
    if (isDailyMode) return _buildDailyBar();
    return _buildFreePlayBar();
  }

  // ── Daily Bar ─────────────────────────────────────────────────────────────
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
          // Links: Puzzle N/total — warm gold family
          SizedBox(
            width: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Puzzle',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: _accent.withValues(alpha: 0.50),
                    letterSpacing: 0.6,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '$number / $total',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _accent.withValues(alpha: 0.65),
                    height: 1,
                  ),
                ),
              ],
            ),
          ),

          // Mitte: Moves — dominant
          Expanded(
            child: Center(
              child: moves != null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$moves',
                          style: AppTextStyles.body.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: _accent,
                            height: 1,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          moves == 1 ? 'MOVE' : 'MOVES',
                          style: AppTextStyles.body.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: _dim.withValues(alpha: 0.70),
                            letterSpacing: 1.2,
                            height: 1,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ),

          SizedBox(
            width: 80,
            child: Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'MODE',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: _accent.withValues(alpha: 0.50),
                      letterSpacing: 0.6,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'ONE RUN',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _accent.withValues(alpha: 0.65),
                      height: 1,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Free Play / Training Bar ───────────────────────────────────────────────
  Widget _buildFreePlayBar() {
    final moves = freePlayMoves;

    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: _barDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Links: Merged toggle — warm gold/amber family
          SizedBox(
            width: 80,
            child: GestureDetector(
              onTap: onToggleMerged,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        showMerged
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        size: 12,
                        color: _accent.withValues(alpha: 0.50),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Merged',
                        style: AppTextStyles.body.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: _accent.withValues(alpha: 0.50),
                          letterSpacing: 0.5,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    showMerged ? 'On' : 'Off',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: showMerged
                          ? _accent.withValues(alpha: 0.70)
                          : _accent.withValues(alpha: 0.30),
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Mitte: Moves — dominant gold, MOVES label warm-dim
          Expanded(
            child: Center(
              child: moves != null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$moves',
                          style: AppTextStyles.body.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: _accent,
                            height: 1,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          moves == 1 ? 'MOVE' : 'MOVES',
                          style: AppTextStyles.body.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: _accent.withValues(alpha: 0.45),
                            letterSpacing: 1.2,
                            height: 1,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ),

          // Rechts: Random / Difficulty — warm gold/amber family
          SizedBox(
            width: 80,
            child: rightLabel != null
                ? Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Mode',
                          style: AppTextStyles.body.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: _accent.withValues(alpha: 0.50),
                            letterSpacing: 0.5,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rightLabel!,
                          style: AppTextStyles.body.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _accent.withValues(alpha: 0.65),
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
