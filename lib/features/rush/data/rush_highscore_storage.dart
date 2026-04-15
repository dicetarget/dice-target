// lib/features/rush/data/rush_highscore_storage.dart

import 'package:shared_preferences/shared_preferences.dart';

class RushHighscoreStorage {
  static const _keyGlobal = 'rush_hs_global';

  /// Key prefixes used by the old per-difficulty and highscore-mode system.
  static const _legacyPrefixes = ['rush_best_', 'rush_highscore_'];

  /// All-time best solved count across all runs.
  Future<int?> loadGlobalBest() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getInt(_keyGlobal);
    return val == null || val < 0 ? null : val;
  }

  /// Persists [score] if it beats the stored global best.
  /// Returns true if a new record was set.
  Future<bool> saveGlobalBest(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getInt(_keyGlobal) ?? -1;
    if (score > existing) {
      await prefs.setInt(_keyGlobal, score);
      return true;
    }
    return false;
  }

  /// One-time migration: removes all legacy per-difficulty and daily-highscore keys.
  Future<void> clearLegacyKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final toRemove = prefs
        .getKeys()
        .where((k) => _legacyPrefixes.any((p) => k.startsWith(p)))
        .toList();
    for (final key in toRemove) {
      await prefs.remove(key);
    }
  }
}
