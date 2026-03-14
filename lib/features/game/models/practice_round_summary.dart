import 'package:flutter/foundation.dart';

@immutable
class PracticeRoundSummary {
  final String title;
  final int target;
  final int finalValue;
  final int delta;
  final int moves;
  final String timeText;
  final bool isSolved;

  const PracticeRoundSummary({
    required this.title,
    required this.target,
    required this.finalValue,
    required this.delta,
    required this.moves,
    required this.timeText,
    required this.isSolved,
  });
}
