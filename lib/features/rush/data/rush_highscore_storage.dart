// lib/features/rush/data/rush_highscore_storage.dart

import 'package:dice/features/rush/domain/rush_difficulty.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RushHighscoreStorage {
  static String _todayKey(RushDifficulty difficulty) {
    final now = DateTime.now();
    final y = now.year.toString();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return 'rush_best_${y}_${m}_${d}_${difficulty.name}';
  }

  /// Gibt den heutigen Tages-Highscore zurück. Null = noch kein Eintrag.
  Future<int?> loadTodayBest(RushDifficulty difficulty) async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getInt(_todayKey(difficulty));
    return val == null || val < 0 ? null : val;
  }

  /// Speichert Score wenn besser als bisheriger Tagesbest.
  /// Gibt true zurück wenn es ein neuer Tagesbest ist.
  Future<bool> saveTodayBest(RushDifficulty difficulty, int score) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _todayKey(difficulty);
    final existing = prefs.getInt(key) ?? -1;
    if (score > existing) {
      await prefs.setInt(key, score);
      return true;
    }
    return false;
  }

  // ── Highscore-Modus (fixer Range 20–80, kein Difficulty-Key) ─────────────

  static String _todayHighscoreKey() {
    final now = DateTime.now();
    final y = now.year.toString();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return 'rush_highscore_${y}_${m}_$d';
  }

  Future<int?> loadTodayHighscore() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getInt(_todayHighscoreKey());
    return val == null || val < 0 ? null : val;
  }

  Future<bool> saveTodayHighscore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _todayHighscoreKey();
    final existing = prefs.getInt(key) ?? -1;
    if (score > existing) {
      await prefs.setInt(key, score);
      return true;
    }
    return false;
  }
}
