import 'package:flutter/foundation.dart';

@immutable
class RoundResult {
  final bool isSolved;
  final int target;
  final int finalValue;
  final int delta;
  final int moves;
  final String timeText;

  const RoundResult({
    required this.isSolved,
    required this.target,
    required this.finalValue,
    required this.delta,
    required this.moves,
    required this.timeText,
  });
}
