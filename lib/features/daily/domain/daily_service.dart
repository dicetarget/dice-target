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

    final usedTargets = <int>{};

    Puzzle deduped(Puzzle p) {
      final idx = p.puzzleIndex ?? 0;
      if (usedTargets.contains(p.target)) {
        for (var offset = 1; offset <= 8; offset++) {
          final retrySeed = seed ^ (offset * 0x1F2E3D4C);
          final retryPuzzle = coordinator.generateDailyPuzzle(
            config: idx < 2
                ? DifficultyConfig.easy
                : idx < 4
                ? DifficultyConfig.medium
                : DifficultyConfig.hard,
            baseSeed: retrySeed,
            puzzleIndex: idx,
            targetMin: idx == 0
                ? 10
                : idx == 1
                ? 25
                : idx == 2
                ? 35
                : idx == 3
                ? 40
                : 55,
            targetMax: idx == 0
                ? 40
                : idx == 1
                ? 55
                : idx == 2
                ? 70
                : idx == 3
                ? 70
                : 90,
          );
          if (!usedTargets.contains(retryPuzzle.target)) {
            usedTargets.add(retryPuzzle.target);
            return retryPuzzle;
          }
        }
      }
      usedTargets.add(p.target);
      return p;
    }

    final puzzles = <Puzzle>[
      deduped(
        coordinator.generateDailyPuzzle(
          config: DifficultyConfig.easy,
          baseSeed: seed,
          puzzleIndex: 0,
          targetMin: 10,
          targetMax: 40,
        ),
      ),
      deduped(
        coordinator.generateDailyPuzzle(
          config: DifficultyConfig.easy,
          baseSeed: seed,
          puzzleIndex: 1,
          targetMin: 25,
          targetMax: 55,
        ),
      ),
      deduped(
        coordinator.generateDailyPuzzle(
          config: DifficultyConfig.medium,
          baseSeed: seed,
          puzzleIndex: 2,
          targetMin: 35,
          targetMax: 70,
        ),
      ),
      deduped(
        coordinator.generateDailyPuzzle(
          config: DifficultyConfig.medium,
          baseSeed: seed,
          puzzleIndex: 3,
          targetMin: 40,
          targetMax: 70,
        ),
      ),
      deduped(
        coordinator.generateDailyPuzzle(
          config: DifficultyConfig.hard,
          baseSeed: seed,
          puzzleIndex: 4,
          targetMin: 55,
          targetMax: 90,
        ),
      ),
    ];

    return DailyPuzzleSet(date: date, seed: seed, puzzles: puzzles);
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

  final usedTargets = <int>{};

  Puzzle deduped(Puzzle p) {
    final idx = p.puzzleIndex ?? 0;
    if (usedTargets.contains(p.target)) {
      for (var offset = 1; offset <= 8; offset++) {
        final retrySeed = seed ^ (offset * 0x1F2E3D4C);
        final retryPuzzle = coordinator.generateDailyPuzzle(
          config: idx < 2
              ? DifficultyConfig.easy
              : idx < 4
              ? DifficultyConfig.medium
              : DifficultyConfig.hard,
          baseSeed: retrySeed,
          puzzleIndex: idx,
          targetMin: idx == 0
              ? 10
              : idx == 1
              ? 25
              : idx == 2
              ? 35
              : idx == 3
              ? 40
              : 55,
          targetMax: idx == 0
              ? 40
              : idx == 1
              ? 55
              : idx == 2
              ? 70
              : idx == 3
              ? 70
              : 90,
        );
        if (!usedTargets.contains(retryPuzzle.target)) {
          usedTargets.add(retryPuzzle.target);
          return retryPuzzle;
        }
      }
    }
    usedTargets.add(p.target);
    return p;
  }

  final puzzles = <Puzzle>[
    deduped(
      coordinator.generateDailyPuzzle(
        config: DifficultyConfig.easy,
        baseSeed: seed,
        puzzleIndex: 0,
        targetMin: 10,
        targetMax: 40,
      ),
    ),
    deduped(
      coordinator.generateDailyPuzzle(
        config: DifficultyConfig.easy,
        baseSeed: seed,
        puzzleIndex: 1,
        targetMin: 25,
        targetMax: 55,
      ),
    ),
    deduped(
      coordinator.generateDailyPuzzle(
        config: DifficultyConfig.medium,
        baseSeed: seed,
        puzzleIndex: 2,
        targetMin: 35,
        targetMax: 70,
      ),
    ),
    deduped(
      coordinator.generateDailyPuzzle(
        config: DifficultyConfig.medium,
        baseSeed: seed,
        puzzleIndex: 3,
        targetMin: 40,
        targetMax: 70,
      ),
    ),
    deduped(
      coordinator.generateDailyPuzzle(
        config: DifficultyConfig.hard,
        baseSeed: seed,
        puzzleIndex: 4,
        targetMin: 55,
        targetMax: 90,
      ),
    ),
  ];

  final daily = DailyPuzzleSet(date: date, seed: seed, puzzles: puzzles);
  return daily.toJson();
}
