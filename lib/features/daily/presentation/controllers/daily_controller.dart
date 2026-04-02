import 'package:flutter/material.dart';

import '../../data/daily_repository.dart';
import '../../domain/daily_progress.dart';
import '../../domain/daily_puzzle_result.dart';
import '../../domain/daily_puzzle_set.dart';
import '../../domain/daily_seed.dart';

class DailyController extends ChangeNotifier {
  final DailyRepository repository;

  DailyPuzzleSet? daily;
  DailyProgress? progress;

  bool isLoading = false;

  int dailyStreak = 0;

  DateTime? _runStartTime;

  DailyController({required this.repository});

  Future<void> loadToday() async {
    isLoading = true;
    notifyListeners();

    final today = DateTime.now();
    final key = DailySeed.key(today);

    // Progress sofort laden (schnell)
    final stored = await repository.loadProgress(key);
    progress = stored ?? DailyProgress.initial(key);

    dailyStreak = await repository.loadDailyStreak();

    notifyListeners(); // UI kann schon anzeigen

    // Daily im Hintergrund laden (langsam)
    final loadedDaily = await repository.loadOrCreateDaily(today);

    daily = loadedDaily;

    if (daily != null) {
      progress = _normalizedProgress(progress!, daily!.puzzles.length);

      if (stored != null) {
        await repository.saveProgress(progress!);
      }
    }

    isLoading = false;
    notifyListeners();
  }

  DailyProgress _normalizedProgress(DailyProgress progress, int totalPuzzles) {
    final sortedResults = List<DailyPuzzleResult>.from(progress.puzzleResults)
      ..sort((a, b) => a.puzzleIndex.compareTo(b.puzzleIndex));

    final validResults = sortedResults
        .where((r) => r.puzzleIndex >= 0 && r.puzzleIndex < totalPuzzles)
        .toList();

    final solvedResultsCount = validResults.where((r) => r.solved).length;
    final gaveUpExists = validResults.any((r) => r.gaveUp);

    final safeSolvedCount = progress.solvedCount.clamp(0, totalPuzzles);
    final mergedSolvedCount = solvedResultsCount > safeSolvedCount
        ? solvedResultsCount
        : safeSolvedCount;

    final safeCurrentIndex = progress.currentPuzzleIndex.clamp(0, totalPuzzles);
    final minCurrentIndex = mergedSolvedCount.clamp(0, totalPuzzles);
    final mergedCurrentIndex = safeCurrentIndex < minCurrentIndex
        ? minCurrentIndex
        : safeCurrentIndex;

    final completed = progress.isCompleted || mergedSolvedCount >= totalPuzzles;
    final endedByGiveUp = !completed && (progress.gaveUp || gaveUpExists);

    return progress.copyWith(
      dailyKey: progress.dailyKey.isEmpty ? DailySeed.key(DateTime.now()) : progress.dailyKey,
      solved: completed,
      solvedCount: completed ? totalPuzzles : mergedSolvedCount,
      currentPuzzleIndex: completed ? totalPuzzles : mergedCurrentIndex,
      isCompleted: completed,
      gaveUp: endedByGiveUp,
      puzzleResults: validResults,
    );
  }

  Future<void> syncPuzzleResults(List<DailyPuzzleResult> results) async {
    if (progress == null) return;

    final sorted = List<DailyPuzzleResult>.from(results)
      ..sort((a, b) => a.puzzleIndex.compareTo(b.puzzleIndex));

    progress = progress!.copyWith(puzzleResults: sorted);

    await repository.saveProgress(progress!);
    notifyListeners();
  }

  Future<void> recordPuzzleResult({
    required int puzzleIndex,
    required bool solved,
    required bool gaveUp,
    required int moves,
    required Duration elapsed,
    int? optimalMoves,
    String? fullExpression,
  }) async {
    if (progress == null || daily == null) return;

    final existing = List<DailyPuzzleResult>.from(progress!.puzzleResults);

    existing.removeWhere((e) => e.puzzleIndex == puzzleIndex);

    existing.add(
      DailyPuzzleResult(
        puzzleIndex: puzzleIndex,
        solved: solved,
        gaveUp: gaveUp,
        moves: moves,
        elapsed: elapsed,
        optimalMoves: optimalMoves,
        fullExpression: fullExpression,
      ),
    );

    existing.sort((a, b) => a.puzzleIndex.compareTo(b.puzzleIndex));

    progress = progress!.copyWith(puzzleResults: existing);

    await repository.saveProgress(progress!);
    notifyListeners();
  }

  Future<void> syncRunProgress({required int solvedCount, required int currentPuzzleIndex}) async {
    if (progress == null || daily == null) return;
    if (progress!.isRunEnded) return;

    final totalPuzzles = daily!.puzzles.length;
    final savedSolvedResults = progress!.puzzleResults.where((r) => r.solved).length;

    final safeSolvedCount = solvedCount.clamp(0, totalPuzzles);
    final mergedSolvedCount = savedSolvedResults > safeSolvedCount
        ? savedSolvedResults
        : safeSolvedCount;

    final safeCurrentIndex = currentPuzzleIndex.clamp(0, totalPuzzles);
    final mergedCurrentIndex = safeCurrentIndex < mergedSolvedCount
        ? mergedSolvedCount
        : safeCurrentIndex;

    progress = progress!.copyWith(
      solved: false,
      solvedCount: mergedSolvedCount,
      currentPuzzleIndex: mergedCurrentIndex,
      isCompleted: false,
      gaveUp: false,
    );

    await repository.saveProgress(progress!);
    notifyListeners();
  }

  Future<void> markPuzzleSolved(int index) async {
    if (progress == null || daily == null) return;
    if (progress!.isRunEnded) return;

    final totalPuzzles = daily!.puzzles.length;
    final newSolvedCount = (progress!.solvedCount + 1).clamp(0, totalPuzzles);
    final completed = newSolvedCount >= totalPuzzles;

    final nextIndex = completed ? totalPuzzles : (index + 1).clamp(0, totalPuzzles - 1);

    progress = progress!.copyWith(
      solved: completed,
      solvedCount: newSolvedCount,
      currentPuzzleIndex: nextIndex,
      isCompleted: completed,
      gaveUp: false,
    );

    await repository.saveProgress(progress!);
    notifyListeners();
  }

  Future<void> markRunCompleted() async {
    if (progress == null || daily == null) return;

    await pauseRunTimer();

    final total = daily!.puzzles.length;

    progress = progress!.copyWith(
      solved: true,
      solvedCount: total,
      currentPuzzleIndex: total,
      isCompleted: true,
      gaveUp: false,
    );

    await repository.saveProgress(progress!);

    await registerDailyCompleted();

    notifyListeners();
  }

  Future<void> registerDailyCompleted() async {
    dailyStreak = await repository.registerCompletedDaily(DateTime.now());
    notifyListeners();
  }

  Future<void> markGiveUp() async {
    if (progress == null || daily == null) return;
    if (progress!.isRunEnded) return;

    await pauseRunTimer();

    final totalPuzzles = daily!.puzzles.length;
    final safeSolvedCount = progress!.solvedCount.clamp(0, totalPuzzles);

    progress = progress!.copyWith(
      solved: false,
      solvedCount: safeSolvedCount,
      currentPuzzleIndex: progress!.currentPuzzleIndex,
      isCompleted: false,
      gaveUp: true,
    );

    await repository.saveProgress(progress!);
    notifyListeners();
  }

  Future<void> markHintUsed() async {
    final currentProgress = progress;
    if (currentProgress == null) return;
    if (currentProgress.hintUsed) return;

    final updated = currentProgress.copyWith(hintUsed: true);

    progress = updated;
    await repository.saveProgress(updated);
    notifyListeners();
  }

  DailyPuzzleResult? resultForPuzzle(int puzzleIndex) {
    final currentProgress = progress;
    if (currentProgress == null) return null;

    for (final result in currentProgress.puzzleResults) {
      if (result.puzzleIndex == puzzleIndex) return result;
    }
    return null;
  }

  int puzzleStarsForResult(DailyPuzzleResult result) {
    if (!result.solved || result.gaveUp) return 0;
    if (result.optimalMoves == null) return 0;

    final diff = result.moves - result.optimalMoves!;

    if (diff <= 0) return 2;
    if (diff <= 2) return 1;
    return 0;
  }

  int puzzleStarsForIndex(int puzzleIndex) {
    final result = resultForPuzzle(puzzleIndex);
    if (result == null) return 0;
    return puzzleStarsForResult(result);
  }

  int totalOptimalMoves() {
    final currentProgress = progress;
    if (currentProgress == null) return 0;

    return currentProgress.puzzleResults
        .where((r) => r.solved && !r.gaveUp && r.optimalMoves != null)
        .fold<int>(0, (sum, r) => sum + r.optimalMoves!);
  }

  int totalActualMoves() {
    final currentProgress = progress;
    if (currentProgress == null) return 0;

    return currentProgress.puzzleResults
        .where((r) => r.solved && !r.gaveUp)
        .fold<int>(0, (sum, r) => sum + r.moves);
  }

  int runTotalDiff() {
    final currentProgress = progress;
    if (currentProgress == null) return 0;

    return currentProgress.puzzleResults
        .where((r) => r.solved && !r.gaveUp && r.optimalMoves != null)
        .fold<int>(0, (sum, r) => sum + (r.moves - r.optimalMoves!));
  }

  Future<void> saveInProgressPuzzleState({
    required int puzzleIndex,
    required List<int> diceValues,
    required List<String?> maskLabels,
    required int moves,
    required bool hintUsed,
    required String seed,
  }) async {
    if (progress == null) return;

    final currentProgress = progress!;
    final effectiveHintUsed = currentProgress.hintUsed || hintUsed;

    progress = currentProgress.copyWith(
      currentPuzzleIndex: puzzleIndex,
      currentDiceValues: List<int>.from(diceValues),
      currentMaskLabels: List<String?>.from(maskLabels),
      currentMoves: moves,
      currentSeed: seed,
      hintUsed: effectiveHintUsed,
    );

    await repository.saveProgress(progress!);
    notifyListeners();
  }

  Future<void> clearInProgressPuzzleState() async {
    if (progress == null) return;

    progress = progress!.copyWith(
      currentDiceValues: null,
      currentMaskLabels: null,
      currentMoves: null,
      currentSeed: null,
    );

    await repository.saveProgress(progress!);
    notifyListeners();
  }

  // =========================
  // ⏱ TIMER
  // =========================

  void startRunTimer() {
    if (progress == null || progress!.isRunEnded) return;
    _runStartTime = DateTime.now();
  }

  Future<void> pauseRunTimer() async {
    final start = _runStartTime;
    if (start == null || progress == null) return;

    final elapsed = DateTime.now().difference(start).inSeconds;
    _runStartTime = null;

    final updated = progress!.copyWith(totalTimeSeconds: progress!.totalTimeSeconds + elapsed);
    progress = updated;
    await repository.saveProgress(updated);
    notifyListeners();
  }

  Future<void> markRunInterrupted() async {
    if (progress == null || progress!.isRunEnded) return;

    await pauseRunTimer();

    if (progress!.runInterrupted) return;

    final updated = progress!.copyWith(runInterrupted: true);
    progress = updated;
    await repository.saveProgress(updated);
    notifyListeners();
  }

  String getSpeedRank(int totalTimeSeconds) {
    if (totalTimeSeconds <= 150) return 'S';
    if (totalTimeSeconds <= 240) return 'A';
    if (totalTimeSeconds <= 360) return 'B';
    return 'C';
  }

  String formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  int runStars() {
    final currentProgress = progress;
    if (currentProgress == null) return 0;

    if (currentProgress.gaveUp || !currentProgress.isCompleted) {
      return 0;
    }

    final totalDiff = runTotalDiff();
    final hintUsed = currentProgress.hintUsed;

    if (totalDiff == 0 && !hintUsed) return 3;
    if (totalDiff <= 3) return 2;
    return 1;
  }
}
