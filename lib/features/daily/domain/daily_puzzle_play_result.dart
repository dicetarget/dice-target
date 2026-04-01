import 'daily_puzzle_result.dart';

class DailyPuzzlePlayResult {
  final bool solved;
  final bool gaveUp;
  final int moves;
  final Duration elapsed;
  final int solvedCount;
  final int currentPuzzleIndex;
  final int puzzleIndex;
  final List<DailyPuzzleResult> puzzleResults;

  const DailyPuzzlePlayResult({
    required this.solved,
    this.gaveUp = false,
    required this.moves,
    required this.elapsed,
    required this.solvedCount,
    required this.currentPuzzleIndex,
    required this.puzzleIndex,
    required this.puzzleResults,
  });
}
