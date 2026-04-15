// lib/features/rush/data/rush_highscore_storage.dart

import 'package:shared_preferences/shared_preferences.dart';

class RushHighscoreStorage {
  static const _keyGlobal = 'rush_hs_global';
  static const _keyTodayBest = 'rush_today_best';
  static const _keyTodayDate = 'rush_today_date';

  /// Key prefixes used by the old per-difficulty and highscore-mode system.
  static const _legacyPrefixes = ['rush_best_', 'rush_highscore_'];

  String _todayDateString() {
    final now = DateTime.now();
    return '${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}';
  }

  /// Returns today's best score, or 0 if no score has been saved today.
  /// Automatically resets stored values when the date has changed.
  Future<int> loadTodayBest() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_keyTodayDate);
    final today = _todayDateString();
    if (savedDate != today) {
      await prefs.remove(_keyTodayBest);
      await prefs.remove(_keyTodayDate);
      return 0;
    }
    return prefs.getInt(_keyTodayBest) ?? 0;
  }

  /// Saves [score] as today's best only if it exceeds the current today's best.
  Future<void> saveTodayBest(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_keyTodayDate);
    final today = _todayDateString();
    final existing = savedDate == today ? (prefs.getInt(_keyTodayBest) ?? 0) : 0;
    if (score > existing) {
      await prefs.setInt(_keyTodayBest, score);
      await prefs.setString(_keyTodayDate, today);
    }
  }

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
