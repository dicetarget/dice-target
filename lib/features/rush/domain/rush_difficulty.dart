// lib/features/rush/domain/rush_difficulty.dart

enum RushDifficulty { easy, medium, hard, expert }

extension RushDifficultyX on RushDifficulty {
  String get label => switch (this) {
    RushDifficulty.easy => 'Easy',
    RushDifficulty.medium => 'Medium',
    RushDifficulty.hard => 'Hard',
    RushDifficulty.expert => 'Expert',
  };

  int get targetMin => switch (this) {
    RushDifficulty.easy => 10,
    RushDifficulty.medium => 30,
    RushDifficulty.hard => 50,
    RushDifficulty.expert => 80,
  };

  int get targetMax => switch (this) {
    RushDifficulty.easy => 40,
    RushDifficulty.medium => 70,
    RushDifficulty.hard => 100,
    RushDifficulty.expert => 120,
  };

  String get storageKey => 'rush_hs_$name';
}
