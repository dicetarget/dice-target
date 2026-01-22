import '../constants/difficulty_config.dart';
import '../models/difficulty.dart'; // ggf. Pfad anpassen

extension DifficultyX on Difficulty {
  int get maxTarget => switch (this) {
        Difficulty.easy => DifficultyConfig.easyMax,
        Difficulty.medium => DifficultyConfig.mediumMax,
        Difficulty.hard => DifficultyConfig.hardMax,
      };

  String get rangeLabel => switch (this) {
        Difficulty.easy => '1–${DifficultyConfig.easyMax}',
        Difficulty.medium => '1–${DifficultyConfig.mediumMax}',
        Difficulty.hard => '1–${DifficultyConfig.hardMax}',
      };

  String get englishLabel => switch (this) {
        Difficulty.easy => 'Easy',
        Difficulty.medium => 'Medium',
        Difficulty.hard => 'Hard',
      };
}
