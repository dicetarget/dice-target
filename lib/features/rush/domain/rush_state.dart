// lib/features/rush/domain/rush_state.dart

import 'package:dice/core/ui_op.dart';
import 'package:dice/features/rush/domain/rush_difficulty.dart';
import 'package:flutter/foundation.dart';

@immutable
class RushState {
  final List<int> dice;
  final List<int> initialDice;
  final int target;
  final int score;
  final int timeRemaining;
  final bool isRunning;
  final bool isFinished;
  final Set<int> selectedIndices;
  final UiOp? selectedOp;

  /// Wie viele Undos in diesem Puzzle noch verfügbar sind (0–4).
  final int undoStackDepth;

  /// Heutiger Highscore (geladen vor Run-Start). Null = noch kein Score heute.
  final int? todayBest;

  /// Wird nach _finishRun() gesetzt – war dieser Score ein neuer Tagesbest?
  final bool isNewBest;

  /// Nur für Standard-Mode gesetzt. Für Daily-Mode null.
  final RushDifficulty? difficulty;

  const RushState({
    required this.dice,
    required this.initialDice,
    required this.target,
    required this.score,
    required this.timeRemaining,
    required this.isRunning,
    required this.isFinished,
    required this.selectedIndices,
    this.selectedOp,
    required this.undoStackDepth,
    this.todayBest,
    this.isNewBest = false,
    this.difficulty,
  });

  factory RushState.initial({RushDifficulty? difficulty, int runDuration = 90}) {
    return RushState(
      dice: const [],
      initialDice: const [],
      target: 0,
      score: 0,
      timeRemaining: runDuration,
      isRunning: false,
      isFinished: false,
      selectedIndices: const {},
      undoStackDepth: 0,
      difficulty: difficulty,
    );
  }

  bool get canUndo => undoStackDepth > 0;

  RushState copyWith({
    List<int>? dice,
    List<int>? initialDice,
    int? target,
    int? score,
    int? timeRemaining,
    bool? isRunning,
    bool? isFinished,
    Set<int>? selectedIndices,
    UiOp? selectedOp,
    bool clearSelectedOp = false,
    int? undoStackDepth,
    int? todayBest,
    bool? isNewBest,
    RushDifficulty? difficulty,
  }) {
    return RushState(
      dice: dice ?? this.dice,
      initialDice: initialDice ?? this.initialDice,
      target: target ?? this.target,
      score: score ?? this.score,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      isRunning: isRunning ?? this.isRunning,
      isFinished: isFinished ?? this.isFinished,
      selectedIndices: selectedIndices ?? this.selectedIndices,
      selectedOp: clearSelectedOp ? null : (selectedOp ?? this.selectedOp),
      undoStackDepth: undoStackDepth ?? this.undoStackDepth,
      todayBest: todayBest ?? this.todayBest,
      isNewBest: isNewBest ?? this.isNewBest,
      difficulty: difficulty ?? this.difficulty,
    );
  }
}
