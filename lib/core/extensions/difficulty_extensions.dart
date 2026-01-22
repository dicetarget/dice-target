import '../constants/difficulty_config.dart';

enum Difficulty { easy, medium, hard }

extension DifficultyX on Difficulty {
  int get maxTarget {
    switch (this) {
      case Difficulty.easy:
        return DifficultyConfig.easyMax;
      case Difficulty.medium:
        return DifficultyConfig.mediumMax;
      case Difficulty.hard:
        return DifficultyConfig.hardMax; // 150
    }
  }

  String get label {
    switch (this) {
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.medium:
        return 'Medium';
      case Difficulty.hard:
        return 'Hard';
    }
  }

  String get rangeText => '1–$maxTarget';
}
