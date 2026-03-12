import 'package:flutter/material.dart';

import 'package:dice/core/theme/app_colors.dart';
import 'package:dice/core/theme/app_durations.dart';
import 'package:dice/core/theme/app_radius.dart';
import 'package:dice/core/theme/app_spacing.dart';
import 'package:dice/core/theme/app_text_styles.dart';

class ResultDialog extends StatefulWidget {
  final String title;
  final int target;

  final int finalValue;
  final int delta;

  final int moves;
  final String timeText;
  final bool isSolved;

  final String? bestTimeText;
  final int? rank;
  final bool isNewRecord;
  final VoidCallback? onRetry;

  const ResultDialog({
    super.key,
    required this.title,
    required this.target,
    required this.finalValue,
    required this.delta,
    required this.moves,
    required this.timeText,
    required this.isSolved,
    this.bestTimeText,
    this.rank,
    this.isNewRecord = false,
    this.onRetry,
  });

  @override
  State<ResultDialog> createState() => _ResultDialogState();
}

class _ResultDialogState extends State<ResultDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: AppDurations.slow);

    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  ButtonStyle _primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      elevation: 0,
      backgroundColor: AppColors.white.withValues(alpha: 0.55),
      foregroundColor: AppColors.accent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      textStyle: AppTextStyles.button,
    );
  }

  ButtonStyle _secondaryButtonStyle() {
    return OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      foregroundColor: AppColors.accent,
      backgroundColor: AppColors.white.withValues(alpha: 0.45),
      side: BorderSide(color: AppColors.ink.withValues(alpha: 0.35), width: 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      textStyle: AppTextStyles.button,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.94,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screen,
              vertical: 34,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.dialog),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.title, style: AppTextStyles.resultTitle),
                const SizedBox(height: AppSpacing.xxl),
                if (widget.isSolved) ...[
                  Text(
                    'Target: ${widget.target}',
                    style: AppTextStyles.resultValue,
                  ),
                ] else ...[
                  Text(
                    'Final Value: ${widget.finalValue}',
                    style: AppTextStyles.resultValue,
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    'Target: ${widget.target}',
                    style: AppTextStyles.resultValue,
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Text('Δ: ${widget.delta}', style: AppTextStyles.resultValue),
                ],
                if (widget.isSolved) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Text('Time: ${widget.timeText}', style: AppTextStyles.timer),
                  const SizedBox(height: AppSpacing.xl),
                ] else ...[
                  const SizedBox(height: AppSpacing.s),
                ],
                if (widget.isNewRecord) ...[
                  Text(
                    'NEW RECORD',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (widget.bestTimeText != null) ...[
                  Text(
                    'Best: ${widget.bestTimeText}',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (widget.rank != null) ...[
                  Text(
                    'Rank: #${widget.rank}',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                Text(
                  'Moves: ${widget.moves}',
                  style: AppTextStyles.resultValue,
                ),
                const SizedBox(height: AppSpacing.section),
                if (widget.onRetry == null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: _primaryButtonStyle(),
                      child: const Text('OK'),
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: _secondaryButtonStyle(),
                          child: const Text('Close'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: widget.onRetry,
                          style: _primaryButtonStyle(),
                          child: const Text('Retry'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
