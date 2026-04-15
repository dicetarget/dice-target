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

  /// Stage-based target range driven by solved count (replaces time-based phaseRange).
  /// Stage 1 (20–40):  puzzles 1–5   (solvedCount 0–4)
  /// Stage 2 (30–60):  puzzles 6–12  (solvedCount 5–11)
  /// Stage 3 (50–90):  puzzle 13+    (solvedCount 12+)
  static (int, int) stageRange(int solvedCount) {
    if (solvedCount >= 12) return (50, 90);
    if (solvedCount >= 5) return (30, 60);
    return (20, 40);
  }
}
