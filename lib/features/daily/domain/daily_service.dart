import 'package:dice/core/difficulty_config.dart';
import 'package:dice/core/puzzle/game_mode.dart';
import 'package:dice/core/puzzle/puzzle.dart';
import 'package:dice/core/puzzle/puzzle_coordinator.dart';
import 'package:dice/core/puzzle/puzzle_generator.dart';
import 'package:flutter/foundation.dart';

import 'daily_puzzle_set.dart';
import 'daily_seed.dart';

class DailyService {
  final PuzzleCoordinator coordinator;

  const DailyService({required this.coordinator});

  DailyPuzzleSet buildDaily(DateTime date) {
    final seed = DailySeed.fromDate(date);
    final puzzles = _generateDeduplicated(seed);
    return DailyPuzzleSet(date: date, seed: seed, puzzles: puzzles);
  }

  List<Puzzle> _generateDeduplicated(int seed) {
    // Target-Ranges pro Puzzle-Index
    final configs = [
      (config: DifficultyConfig.easy, min: 20, max: 35),
      (config: DifficultyConfig.easy, min: 25, max: 40),
      (config: DifficultyConfig.medium, min: 30, max: 50),
      (config: DifficultyConfig.medium, min: 40, max: 65),
      (config: DifficultyConfig.hard, min: 50, max: 90),
    ];

    final usedTargets = <int>{};
    final puzzles = <Puzzle>[];

    for (var i = 0; i < configs.length; i++) {
      final cfg = configs[i];
      Puzzle puzzle;
      var attempt = 0;

      // Versuche bis zu 8 Mal einen eindeutigen Target zu finden
      do {
        // Leicht abweichender Seed bei jedem Retry
        final retrySeed = attempt == 0 ? seed : seed ^ (attempt * 0x9E3779B9 + i * 0x6C62272E);
        puzzle = coordinator.generateDailyPuzzle(
          config: cfg.config,
          baseSeed: retrySeed,
          puzzleIndex: i,
          targetMin: cfg.min,
          targetMax: cfg.max,
        );
        attempt++;
      } while (usedTargets.contains(puzzle.target) && attempt < 8);

      usedTargets.add(puzzle.target);
      puzzles.add(puzzle);
    }

    return puzzles;
  }

  Future<DailyPuzzleSet> buildDailyAsync(DateTime date) async {
    final json = await compute(_buildDailyJson, date.toIso8601String());
    return DailyPuzzleSet.fromJson(json);
  }
}

Map<String, dynamic> _buildDailyJson(String isoDate) {
  final date = DateTime.parse(isoDate);
  final seed = DailySeed.fromDate(date);

  final generator = PuzzleGenerator();
  final coordinator = PuzzleCoordinator(
    generator: generator,
    mode: GameMode.daily,
    config: DifficultyConfig.easy,
    baseSeed: 0,
  );

  final configs = [
    (config: DifficultyConfig.easy, min: 20, max: 35),
    (config: DifficultyConfig.easy, min: 25, max: 40),
    (config: DifficultyConfig.medium, min: 30, max: 50),
    (config: DifficultyConfig.medium, min: 40, max: 65),
    (config: DifficultyConfig.hard, min: 50, max: 90),
  ];

  final usedTargets = <int>{};
  final puzzles = <Puzzle>[];

  for (var i = 0; i < configs.length; i++) {
    final cfg = configs[i];
    Puzzle puzzle;
    var attempt = 0;

    do {
      final retrySeed = attempt == 0 ? seed : seed ^ (attempt * 0x9E3779B9 + i * 0x6C62272E);
      puzzle = coordinator.generateDailyPuzzle(
        config: cfg.config,
        baseSeed: retrySeed,
        puzzleIndex: i,
        targetMin: cfg.min,
        targetMax: cfg.max,
      );
      attempt++;
    } while (usedTargets.contains(puzzle.target) && attempt < 8);

    usedTargets.add(puzzle.target);
    puzzles.add(puzzle);
  }

  final daily = DailyPuzzleSet(date: date, seed: seed, puzzles: puzzles);
  return daily.toJson();
}
