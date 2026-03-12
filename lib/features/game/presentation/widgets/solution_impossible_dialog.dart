// lib/features/game/presentation/widgets/solution_impossible_dialog.dart
import 'package:flutter/material.dart';
import 'package:dice/features/game/presentation/widgets/die_face.dart';

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
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      backgroundColor: const Color(0xFFF3F1F6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 22, 26, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Starting Dice:',
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: startDiceValues.take(5).map((v) {
                      return DieFace(value: v, selected: false);
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  Divider(
                    color: Colors.black.withValues(alpha: 0.18),
                    thickness: 2,
                  ),
                  const SizedBox(height: 22),
                  if (solvable) ...[
                    const Text(
                      'Full Expression',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '${(fullExpression ?? '').trim()} = $target',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'No solution found',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Target: $target',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 42),
                ],
              ),
            ),
            Positioned(
              right: 14,
              bottom: 12,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => Navigator.of(context).pop(),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.check,
                    size: 28,
                    color: Colors.black.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
