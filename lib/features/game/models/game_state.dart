import 'package:flutter/foundation.dart';
import 'package:dice/features/game/models/dice_state.dart';
import 'package:dice/features/game/models/round_result.dart';
import 'package:dice/core/ui_op.dart';

@immutable
class PracticeGameState {
  final List<DiceState> dice;
  final int target;

  final UiOp? selectedOp;
  final int? selectedDieIndex;

  final int moves;
  final bool isRollingDice;
  final bool isRollingTarget;
  final bool isRoundEnded;
  final bool soundEnabled;

  final String currentExpression;
  final String? revealedSolution;

  final RoundResult? roundResult;

  const PracticeGameState({
    required this.dice,
    required this.target,
    this.selectedOp,
    this.selectedDieIndex,
    this.moves = 0,
    this.isRollingDice = false,
    this.isRollingTarget = false,
    this.isRoundEnded = false,
    this.soundEnabled = true,
    this.currentExpression = '',
    this.revealedSolution,
    this.roundResult,
  });

  factory PracticeGameState.initial() {
    return const PracticeGameState(dice: [], target: 0);
  }

  bool get isBusy => isRollingDice || isRollingTarget;

  bool get canInteract => !isBusy && !isRoundEnded;

  PracticeGameState copyWith({
    List<DiceState>? dice,
    int? target,
    UiOp? selectedOp,
    bool clearSelectedOp = false,
    int? selectedDieIndex,
    bool clearSelectedDieIndex = false,
    int? moves,
    bool? isRollingDice,
    bool? isRollingTarget,
    bool? isRoundEnded,
    bool? soundEnabled,
    String? currentExpression,
    String? revealedSolution,
    bool clearRevealedSolution = false,
    RoundResult? roundResult,
    bool clearRoundResult = false,
  }) {
    return PracticeGameState(
      dice: dice ?? this.dice,
      target: target ?? this.target,
      selectedOp: clearSelectedOp ? null : (selectedOp ?? this.selectedOp),
      selectedDieIndex: clearSelectedDieIndex
          ? null
          : (selectedDieIndex ?? this.selectedDieIndex),
      moves: moves ?? this.moves,
      isRollingDice: isRollingDice ?? this.isRollingDice,
      isRollingTarget: isRollingTarget ?? this.isRollingTarget,
      isRoundEnded: isRoundEnded ?? this.isRoundEnded,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      currentExpression: currentExpression ?? this.currentExpression,
      revealedSolution: clearRevealedSolution
          ? null
          : (revealedSolution ?? this.revealedSolution),
      roundResult: clearRoundResult ? null : (roundResult ?? this.roundResult),
    );
  }
}
