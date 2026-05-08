import 'package:dice/core/theme/app_colors.dart';
import 'package:dice/features/game/presentation/widgets/die_face.dart';
import 'package:flutter/material.dart';

Future<void> showSolutionOrImpossibleDialog({
  required BuildContext context,
  required bool solvable,
  required List<int> startDiceValues,
  required int target,
  String? fullExpression,
}) async {
  final title = solvable ? 'Solution' : 'No Solution';

  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.75),
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.60),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.30),
                blurRadius: 80,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 28, 26, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: solvable ? AppColors.gold : AppColors.failed,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Starting Dice label
                    const Text(
                      'STARTING DICE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.inkMuted,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Dice
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: startDiceValues.take(5).map((v) {
                        return DieFace(value: v, selected: false);
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    Divider(color: Colors.white.withValues(alpha: 0.10), thickness: 0.5),
                    const SizedBox(height: 20),

                    if (solvable) ...[
                      const Text(
                        'FULL EXPRESSION',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkMuted,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.25),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          '${(fullExpression ?? '').trim()} = $target',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.gold,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.failed.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.failed.withValues(alpha: 0.25),
                            width: 0.8,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'No solution found',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.failed,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Target: $target',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 44),
                  ],
                ),
              ),

              // Close Button
              Positioned(
                right: 14,
                bottom: 12,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.30),
                        width: 0.8,
                      ),
                    ),
                    child: const Icon(Icons.check_rounded, size: 22, color: AppColors.gold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
