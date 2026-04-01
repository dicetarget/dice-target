import 'package:dice/core/puzzle/puzzle.dart';

class DailyPuzzleSet {
  final DateTime date;
  final int seed;
  final List<Puzzle> puzzles;

  const DailyPuzzleSet({required this.date, required this.seed, required this.puzzles});

  String get dailyKey => date.toIso8601String().split('T').first;

  Puzzle puzzleAt(int index) {
    return puzzles[index];
  }

  int get count => puzzles.length;

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'seed': seed,
      'puzzles': puzzles.map((p) => {'target': p.target, 'dice': p.dice, 'seed': p.seed}).toList(),
    };
  }

  factory DailyPuzzleSet.fromJson(Map<String, dynamic> json) {
    final date = DateTime.parse(json['date']);
    final seed = json['seed'];

    final puzzlesJson = json['puzzles'] as List<dynamic>;

    final puzzles = puzzlesJson.map((p) {
      final map = p as Map<String, dynamic>;
      return Puzzle(target: map['target'], dice: List<int>.from(map['dice']), seed: map['seed']);
    }).toList();

    return DailyPuzzleSet(date: date, seed: seed, puzzles: puzzles);
  }
}
