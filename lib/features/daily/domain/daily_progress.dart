import 'daily_puzzle_result.dart';

class DailyProgress {
  static const Object _unset = Object();

  final String dailyKey;
  final bool solved;
  final int solvedCount;
  final int currentPuzzleIndex;
  final bool isCompleted;
  final bool gaveUp;
  final List<DailyPuzzleResult> puzzleResults;

  // In-progress puzzle state for resume
  final List<int>? currentDiceValues;
  final List<String?>? currentMaskLabels;
  final int? currentMoves;
  final bool hintUsed;
  final String? currentSeed;

  // Run timing & integrity
  final int totalTimeSeconds;
  final bool runInterrupted;

  const DailyProgress({
    required this.dailyKey,
    required this.solved,
    required this.solvedCount,
    required this.currentPuzzleIndex,
    required this.isCompleted,
    required this.gaveUp,
    required this.puzzleResults,
    this.currentDiceValues,
    this.currentMaskLabels,
    this.currentMoves,
    required this.hintUsed,
    this.currentSeed,
    this.totalTimeSeconds = 0,
    this.runInterrupted = false,
  });

  factory DailyProgress.initial(String dailyKey) {
    return DailyProgress(
      dailyKey: dailyKey,
      solved: false,
      solvedCount: 0,
      currentPuzzleIndex: 0,
      isCompleted: false,
      gaveUp: false,
      puzzleResults: const [],
      currentDiceValues: null,
      currentMaskLabels: null,
      currentMoves: null,
      hintUsed: false,
      currentSeed: null,
      totalTimeSeconds: 0,
      runInterrupted: false,
    );
  }

  DailyProgress copyWith({
    String? dailyKey,
    bool? solved,
    int? solvedCount,
    int? currentPuzzleIndex,
    bool? isCompleted,
    bool? gaveUp,
    List<DailyPuzzleResult>? puzzleResults,
    Object? currentDiceValues = _unset,
    Object? currentMaskLabels = _unset,
    Object? currentMoves = _unset,
    bool? hintUsed,
    Object? currentSeed = _unset,
    int? totalTimeSeconds,
    bool? runInterrupted,
  }) {
    return DailyProgress(
      dailyKey: dailyKey ?? this.dailyKey,
      solved: solved ?? this.solved,
      solvedCount: solvedCount ?? this.solvedCount,
      currentPuzzleIndex: currentPuzzleIndex ?? this.currentPuzzleIndex,
      isCompleted: isCompleted ?? this.isCompleted,
      gaveUp: gaveUp ?? this.gaveUp,
      puzzleResults: puzzleResults ?? this.puzzleResults,
      currentDiceValues: identical(currentDiceValues, _unset)
          ? this.currentDiceValues
          : currentDiceValues as List<int>?,
      currentMaskLabels: identical(currentMaskLabels, _unset)
          ? this.currentMaskLabels
          : currentMaskLabels as List<String?>?,
      currentMoves: identical(currentMoves, _unset) ? this.currentMoves : currentMoves as int?,
      hintUsed: hintUsed ?? this.hintUsed,
      currentSeed: identical(currentSeed, _unset) ? this.currentSeed : currentSeed as String?,
      totalTimeSeconds: totalTimeSeconds ?? this.totalTimeSeconds,
      runInterrupted: runInterrupted ?? this.runInterrupted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailyKey': dailyKey,
      'solved': solved,
      'solvedCount': solvedCount,
      'currentPuzzleIndex': currentPuzzleIndex,
      'isCompleted': isCompleted,
      'gaveUp': gaveUp,
      'puzzleResults': puzzleResults.map((e) => e.toJson()).toList(),
      'currentDiceValues': currentDiceValues,
      'currentMaskLabels': currentMaskLabels,
      'currentMoves': currentMoves,
      'hintUsed': hintUsed,
      'currentSeed': currentSeed,
      'totalTimeSeconds': totalTimeSeconds,
      'runInterrupted': runInterrupted,
    };
  }

  factory DailyProgress.fromJson(Map<String, dynamic> json) {
    final rawResults = json['puzzleResults'] as List<dynamic>? ?? const [];

    return DailyProgress(
      dailyKey: json['dailyKey'] as String? ?? '',
      solved: json['solved'] as bool? ?? false,
      solvedCount: (json['solvedCount'] as num?)?.toInt() ?? 0,
      currentPuzzleIndex: (json['currentPuzzleIndex'] as num?)?.toInt() ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      gaveUp: json['gaveUp'] as bool? ?? false,
      puzzleResults:
          rawResults
              .map((e) => DailyPuzzleResult.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList()
            ..sort((a, b) => a.puzzleIndex.compareTo(b.puzzleIndex)),
      currentDiceValues: (json['currentDiceValues'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
      currentMaskLabels: (json['currentMaskLabels'] as List<dynamic>?)
          ?.map((e) => e as String?)
          .toList(),
      currentMoves: (json['currentMoves'] as num?)?.toInt(),
      hintUsed: json['hintUsed'] == true,
      currentSeed: json['currentSeed'] as String?,
      totalTimeSeconds: (json['totalTimeSeconds'] as num?)?.toInt() ?? 0,
      runInterrupted: json['runInterrupted'] as bool? ?? false,
    );
  }

  bool get isRunEnded => isCompleted || gaveUp;

  bool get hasStarted => solvedCount > 0 || currentPuzzleIndex > 0 || puzzleResults.isNotEmpty;

  bool get canContinue => hasStarted && !isRunEnded;

  bool get hasInProgressPuzzle =>
      currentDiceValues != null && currentMaskLabels != null && currentMoves != null && !isRunEnded;

  int get completedPuzzleCount => puzzleResults.where((r) => r.solved).length;

  int get totalMoves =>
      puzzleResults.where((r) => r.solved && !r.gaveUp).fold<int>(0, (sum, r) => sum + r.moves);
}
