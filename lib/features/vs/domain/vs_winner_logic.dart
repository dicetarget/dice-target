enum VsWinner { challenger, opponent, draw }

class VsWinnerLogic {
  static VsWinner determine({
    required int challengerPuzzles,
    required int challengerTimeMs,
    required int challengerMoves,
    required int opponentPuzzles,
    required int opponentTimeMs,
    required int opponentMoves,
    required String vsMode,
    int totalPuzzles = 3,
  }) {
    if (vsMode == 'speedrun' || vsMode == 'speedrun_advanced') {
      final cDone = challengerPuzzles >= totalPuzzles;
      final oDone = opponentPuzzles >= totalPuzzles;
      if (cDone && !oDone) return VsWinner.challenger;
      if (oDone && !cDone) return VsWinner.opponent;
      if (!cDone && !oDone) return VsWinner.draw;
      // both finished → time tiebreak, then moves
      if (challengerTimeMs != opponentTimeMs) {
        return challengerTimeMs < opponentTimeMs
            ? VsWinner.challenger
            : VsWinner.opponent;
      }
      if (challengerMoves != opponentMoves) {
        return challengerMoves < opponentMoves
            ? VsWinner.challenger
            : VsWinner.opponent;
      }
      return VsWinner.draw;
    }

    // Rush logic
    if (challengerPuzzles != opponentPuzzles) {
      return challengerPuzzles > opponentPuzzles
          ? VsWinner.challenger
          : VsWinner.opponent;
    }
    if (challengerTimeMs != opponentTimeMs) {
      return challengerTimeMs < opponentTimeMs
          ? VsWinner.challenger
          : VsWinner.opponent;
    }
    if (challengerMoves != opponentMoves) {
      return challengerMoves < opponentMoves
          ? VsWinner.challenger
          : VsWinner.opponent;
    }
    return VsWinner.draw;
  }
}
