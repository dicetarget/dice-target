enum DailyMedal { platinum, gold, silver, bronze, none }

class DailyPuzzleResult {
  final int puzzleIndex;
  final bool solved;
  final bool gaveUp;
  final int moves;
  final Duration elapsed;
  final int? optimalMoves;
  final String? fullExpression;

  const DailyPuzzleResult({
    required this.puzzleIndex,
    required this.solved,
    required this.gaveUp,
    required this.moves,
    required this.elapsed,
    this.optimalMoves,
    this.fullExpression,
  });

  DailyPuzzleResult copyWith({
    int? puzzleIndex,
    bool? solved,
    bool? gaveUp,
    int? moves,
    Duration? elapsed,
    int? optimalMoves,
    String? fullExpression,
  }) {
    return DailyPuzzleResult(
      puzzleIndex: puzzleIndex ?? this.puzzleIndex,
      solved: solved ?? this.solved,
      gaveUp: gaveUp ?? this.gaveUp,
      moves: moves ?? this.moves,
      elapsed: elapsed ?? this.elapsed,
      optimalMoves: optimalMoves ?? this.optimalMoves,
      fullExpression: fullExpression ?? this.fullExpression,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'puzzleIndex': puzzleIndex,
      'solved': solved,
      'gaveUp': gaveUp,
      'moves': moves,
      'elapsedMs': elapsed.inMilliseconds,
      'optimalMoves': optimalMoves,
      'fullExpression': fullExpression,
    };
  }

  factory DailyPuzzleResult.fromJson(Map<String, dynamic> json) {
    return DailyPuzzleResult(
      puzzleIndex: (json['puzzleIndex'] as num?)?.toInt() ?? 0,
      solved: json['solved'] as bool? ?? false,
      gaveUp: json['gaveUp'] as bool? ?? false,
      moves: (json['moves'] as num?)?.toInt() ?? 0,
      elapsed: Duration(milliseconds: (json['elapsedMs'] as num?)?.toInt() ?? 0),
      optimalMoves: (json['optimalMoves'] as num?)?.toInt(),
      fullExpression: json['fullExpression'] as String?,
    );
  }

  DailyMedal get medal {
    if (!solved || gaveUp) return DailyMedal.none;
    if (optimalMoves == null) return DailyMedal.none;

    final diff = moves - optimalMoves!;

    if (diff <= 0) return DailyMedal.platinum;
    if (diff == 1) return DailyMedal.gold;
    if (diff == 2) return DailyMedal.silver;
    return DailyMedal.bronze;
  }
}
