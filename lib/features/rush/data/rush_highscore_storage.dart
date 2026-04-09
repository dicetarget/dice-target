// lib/features/rush/data/rush_highscore_storage.dart

import 'package:dice/features/rush/domain/rush_difficulty.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RushHighscoreStorage {
  static const String _keyTotalRuns = 'rush_std_total_runs';
  static const String _keyTotalPuzzles = 'rush_std_total_puzzles';

  Future<int> load(RushDifficulty difficulty) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(difficulty.storageKey) ?? 0;
  }

  /// Speichert den Score nur wenn er besser ist.
  /// Gibt true zurück wenn ein neuer Rekord gesetzt wurde.
  Future<bool> saveIfBetter(RushDifficulty difficulty, int score) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(difficulty.storageKey) ?? 0;
    if (score > current) {
      await prefs.setInt(difficulty.storageKey, score);
      return true;
    }
    return false;
  }

  /// Zählt einen abgeschlossenen Run + gelöste Puzzles.
  Future<void> incrementStats(int puzzlesSolved) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTotalRuns, (prefs.getInt(_keyTotalRuns) ?? 0) + 1);
    await prefs.setInt(_keyTotalPuzzles, (prefs.getInt(_keyTotalPuzzles) ?? 0) + puzzlesSolved);
  }

  /// Lädt Total Runs und Total Puzzles Solved.
  Future<({int totalRuns, int totalPuzzles})> loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      totalRuns: prefs.getInt(_keyTotalRuns) ?? 0,
      totalPuzzles: prefs.getInt(_keyTotalPuzzles) ?? 0,
    );
  }
}
