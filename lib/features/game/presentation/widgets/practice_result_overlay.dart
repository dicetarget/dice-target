import 'package:dice/core/theme/app_colors.dart';
import 'package:dice/core/theme/app_radius.dart';
import 'package:dice/core/theme/app_spacing.dart';
import 'package:dice/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

Future<void> showPracticeResultOverlay({
  required BuildContext context,
  required String title,
  required int target,
  required int finalValue,
  required int delta,
  required int moves,
  required String timeText,
  required bool isSolved,
  VoidCallback? onRetry,
  VoidCallback? onNewGame,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.70),
    builder: (context) {
      final statusColor = isSolved ? const Color(0xFF4CAF82) : const Color(0xFFE57373);
      final statusBg = isSolved
          ? const Color(0xFF4CAF82).withValues(alpha: 0.12)
          : const Color(0xFFE57373).withValues(alpha: 0.12);

      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xxl,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF131628),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10), width: 0.5),
            boxShadow: [
              BoxShadow(
                blurRadius: 32,
                offset: const Offset(0, 14),
                color: Colors.black.withValues(alpha: 0.50),
              ),
              BoxShadow(blurRadius: 20, color: const Color(0xFF7B5FE0).withValues(alpha: 0.12)),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: statusColor.withValues(alpha: 0.30), width: 0.5),
                  ),
                  child: Text(
                    isSolved ? 'Solved' : 'Not Solved',
                    style: AppTextStyles.bodyStrong.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Target: $target',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: AppColors.ink.withValues(alpha: 0.50),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _MetricBlock(label: 'Time', value: timeText),
                    ),
                    Container(width: 0.5, height: 52, color: Colors.white.withValues(alpha: 0.10)),
                    Expanded(
                      child: _MetricBlock(label: 'Moves', value: '$moves'),
                    ),
                  ],
                ),
              ),
              if (!isSolved) ...[
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SmallMetric(label: 'Final', value: '$finalValue'),
                      ),
                      Container(
                        width: 0.5,
                        height: 44,
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                      Expanded(
                        child: _SmallMetric(label: 'Off by', value: '$delta'),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: onRetry == null
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              onRetry();
                            },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(AppRadius.button),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                            width: 0.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Retry',
                            style: AppTextStyles.buttonMedium.copyWith(
                              color: onRetry != null
                                  ? AppColors.ink.withValues(alpha: 0.80)
                                  : AppColors.muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (onNewGame != null) ...[
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          onNewGame();
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(AppRadius.button),
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.50),
                              width: 0.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'New Game',
                              style: AppTextStyles.buttonOnAccent.copyWith(
                                color: AppColors.accentLt,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _MetricBlock extends StatelessWidget {
  final String label;
  final String value;
  const _MetricBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyStrong.copyWith(
            color: AppColors.ink.withValues(alpha: 0.45),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          textAlign: TextAlign.center,
          style: AppTextStyles.sheetTitle.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 26,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _SmallMetric extends StatelessWidget {
  final String label;
  final String value;
  const _SmallMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyStrong.copyWith(
            color: AppColors.ink.withValues(alpha: 0.45),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyStrong.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}
