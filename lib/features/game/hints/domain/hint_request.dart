import 'package:dice/core/difficulty_config.dart';
import 'package:dice/core/puzzle/puzzle.dart';

class HintRequest {
  final Puzzle puzzle;
  final DifficultyConfig difficulty;

  const HintRequest({required this.puzzle, required this.difficulty});
}
