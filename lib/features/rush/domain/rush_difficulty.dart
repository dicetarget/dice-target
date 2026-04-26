// lib/features/rush/domain/rush_difficulty.dart

enum RushDifficulty {
  easy,
  medium,
  hard,
  expert;

  String get label {
    switch (this) {
      case RushDifficulty.easy:
        return 'Easy';
      case RushDifficulty.medium:
        return 'Medium';
      case RushDifficulty.hard:
        return 'Hard';
      case RushDifficulty.expert:
        return 'Expert';
    }
  }

  int get targetMin {
    switch (this) {
      case RushDifficulty.easy:
        return 10;
      case RushDifficulty.medium:
        return 30;
      case RushDifficulty.hard:
        return 50;
      case RushDifficulty.expert:
        return 80;
    }
  }

  int get targetMax {
    switch (this) {
      case RushDifficulty.easy:
        return 40;
      case RushDifficulty.medium:
        return 70;
      case RushDifficulty.hard:
        return 100;
      case RushDifficulty.expert:
        return 120;
    }
  }

  /// Stage-based target range driven by solved count.
  /// Stage 1 (10–40):  solvedCount 0–3
  /// Stage 2 (30–70):  solvedCount 4–9
  /// Stage 3 (50–100): solvedCount 10+
  static (int, int) stageRange(int solvedCount) {
    if (solvedCount >= 10) return (50, 100);
    if (solvedCount >= 4) return (30, 70);
    return (10, 40);
  }

  /// VS puzzle difficulty range based on puzzle index (0-based).
  /// speedrun (3 puzzles): all Easy (10–40)
  /// speedrun_advanced (5 puzzles):
  ///   index 0–1: Easy (10–40), index 2–3: Medium (30–70), index 4: Medium-Hard (40–100)
  static (int, int) vsPuzzleRange(String vsMode, int puzzleIndex) {
    if (vsMode == 'speedrun') return (10, 40);
    if (puzzleIndex <= 1) return (10, 40);
    if (puzzleIndex <= 3) return (30, 70);
    return (40, 100);
  }
}
