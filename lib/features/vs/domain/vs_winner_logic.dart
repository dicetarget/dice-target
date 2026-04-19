enum VsWinner { challenger, opponent, draw }

class VsWinnerLogic {
  static VsWinner determine({
    required int challengerPuzzles,
    required int challengerTimeMs,
    required int challengerMoves,
    required int opponentPuzzles,
    required int opponentTimeMs,
    required int opponentMoves,
  }) {
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
