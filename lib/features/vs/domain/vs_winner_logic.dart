enum VsWinner { challenger, opponent, draw }

class VsWinnerLogic {
  static const int _speedrunTotalPuzzles = 3;

  static VsWinner determine({
    required int challengerPuzzles,
    required int challengerTimeMs,
    required int challengerMoves,
    required int opponentPuzzles,
    required int opponentTimeMs,
    required int opponentMoves,
    String vsMode = 'rush',
  }) {
    if (vsMode == 'speedrun') {
      final cDone = challengerPuzzles >= _speedrunTotalPuzzles;
      final oDone = opponentPuzzles >= _speedrunTotalPuzzles;
      if (cDone && !oDone) return VsWinner.challenger;
      if (oDone && !cDone) return VsWinner.opponent;
      if (cDone && oDone) {
        if (challengerTimeMs != opponentTimeMs) {
          return challengerTimeMs < opponentTimeMs
              ? VsWinner.challenger
              : VsWinner.opponent;
        }
        return VsWinner.draw;
      }
      return VsWinner.draw;
    }

    // Rush logic (unchanged)
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
