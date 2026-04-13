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

  /// Basis-Zielbereich pro Schwierigkeit.
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

  /// Phasen-angepasster Range basierend auf verbleibender Zeit.
  /// Early (>70s): untere 60% des Ranges → leichtere Targets
  /// Mid  (20–70s): voller Range
  /// Late (<20s):  obere 60% des Ranges → schwerere Targets
  (int, int) phaseRange(int timeRemaining) {
    final size = targetMax - targetMin;
    if (timeRemaining > 70) {
      return (targetMin, targetMin + (size * 0.6).round());
    } else if (timeRemaining > 20) {
      return (targetMin, targetMax);
    } else {
      return (targetMin + (size * 0.4).round(), targetMax);
    }
  }
}
