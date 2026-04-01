import 'package:dice/features/game/presentation/widgets/die_face.dart';
import 'package:flutter/material.dart';

Future<void> showSolutionOrImpossibleDialog({
  required BuildContext context,
  required bool solvable,
  required List<int> startDiceValues,
  required int target,
  String? fullExpression,
}) async {
  const Color bg = Color(0xFF0D2040);
  const Color border = Color(0x333FE8FF);
  const Color muted = Color(0xFF6B9AB8);
  const Color cyan = Color(0xFF3FE8FF);
  const Color accent = Color(0xFF90D5F0);
  const Color divider = Color(0x1AFFFFFF);

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
            color: bg,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: border, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.65),
                blurRadius: 48,
                offset: const Offset(0, 20),
              ),
              BoxShadow(
                color: cyan.withValues(alpha: 0.20),
                blurRadius: 40,
                spreadRadius: 2,
                offset: const Offset(0, 0),
              ),
              BoxShadow(
                color: cyan.withValues(alpha: 0.08),
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
                    // Titel
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: solvable ? cyan : const Color(0xFFE57373),
                        letterSpacing: -0.5,
                        shadows: solvable
                            ? [Shadow(color: cyan.withValues(alpha: 0.40), blurRadius: 12)]
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Starting Dice Label
                    Text(
                      'STARTING DICE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: muted,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Würfel
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: startDiceValues.take(5).map((v) {
                        return DieFace(value: v, selected: false);
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    Divider(color: divider, thickness: 0.5),
                    const SizedBox(height: 20),

                    if (solvable) ...[
                      Text(
                        'FULL EXPRESSION',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: muted,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cyan.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: cyan.withValues(alpha: 0.22), width: 0.5),
                        ),
                        child: Text(
                          '${(fullExpression ?? '').trim()} = $target',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: cyan,
                            height: 1.4,
                            shadows: [Shadow(color: cyan.withValues(alpha: 0.35), blurRadius: 8)],
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE57373).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFE57373).withValues(alpha: 0.25),
                            width: 0.5,
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
                                color: Color(0xFFE57373),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Target: $target',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: muted,
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
                      color: cyan.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cyan.withValues(alpha: 0.30), width: 0.5),
                    ),
                    child: Icon(Icons.check_rounded, size: 22, color: accent),
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
