import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/daily_progress.dart';
import '../domain/daily_puzzle_set.dart';
import '../domain/daily_seed.dart';

class DailyLocalStorage {
  static const _progressPrefix = 'daily_progress_';
  static const _dailyPrefix = 'daily_puzzle_';

  static const _streakCountKey = 'daily_streak_count';
  static const _lastCompletedDayKey = 'daily_last_completed_day';

  static const _lastSeenUtcMillisKey = 'daily_last_seen_utc_millis';
  static const _lastSeenDayKey = 'daily_last_seen_day_key';

  Future<DailyProgress?> loadProgress(String dailyKey) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('$_progressPrefix$dailyKey');

    if (jsonString == null) return null;

    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    return DailyProgress.fromJson(jsonMap);
  }

  Future<void> saveProgress(DailyProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(progress.toJson());

    await prefs.setString('$_progressPrefix${progress.dailyKey}', jsonString);
  }

  Future<DailyPuzzleSet?> loadDaily(String dailyKey) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('$_dailyPrefix$dailyKey');

    if (jsonString == null) return null;

    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    return DailyPuzzleSet.fromJson(jsonMap);
  }

  Future<void> saveDaily(DailyPuzzleSet daily) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(daily.toJson());

    await prefs.setString('$_dailyPrefix${daily.dailyKey}', jsonString);
  }

  Future<DateTime?> loadLastSeenUtc() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(_lastSeenUtcMillisKey);
    if (millis == null) return null;

    return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
  }

  Future<String?> loadLastSeenDayKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastSeenDayKey);
  }

  Future<void> updateTrustedClock(DateTime now) async {
    final prefs = await SharedPreferences.getInstance();

    final nowUtcMillis = now.toUtc().millisecondsSinceEpoch;
    final nowDayKey = DailySeed.key(now);

    final storedUtcMillis = prefs.getInt(_lastSeenUtcMillisKey);
    final storedDayKey = prefs.getString(_lastSeenDayKey);

    if (storedUtcMillis == null || nowUtcMillis > storedUtcMillis) {
      await prefs.setInt(_lastSeenUtcMillisKey, nowUtcMillis);
    }

    if (storedDayKey == null || nowDayKey.compareTo(storedDayKey) > 0) {
      await prefs.setString(_lastSeenDayKey, nowDayKey);
    }
  }

  // =========================
  // 🔥 DAILY STREAK
  // =========================

  Future<int> loadDailyStreak({DateTime? referenceDate}) async {
    final prefs = await SharedPreferences.getInstance();

    final streak = prefs.getInt(_streakCountKey) ?? 0;
    final lastDay = prefs.getString(_lastCompletedDayKey);

    if (lastDay == null) return 0;

    final baseDate = referenceDate ?? DateTime.now();
    final todayKey = DailySeed.key(baseDate);
    final yesterdayKey = DailySeed.key(baseDate.subtract(const Duration(days: 1)));

    if (lastDay == todayKey || lastDay == yesterdayKey) {
      return streak;
    }

    return 0;
  }

  Future<int> registerCompletedDaily(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();

    await updateTrustedClock(date);

    final todayKey = DailySeed.key(date);
    final yesterdayKey = DailySeed.key(date.subtract(const Duration(days: 1)));

    final lastDay = prefs.getString(_lastCompletedDayKey);
    final currentStreak = prefs.getInt(_streakCountKey) ?? 0;

    int newStreak;

    if (lastDay == todayKey) {
      newStreak = currentStreak == 0 ? 1 : currentStreak;
    } else if (lastDay == yesterdayKey) {
      newStreak = currentStreak + 1;
    } else {
      newStreak = 1;
    }

    await prefs.setString(_lastCompletedDayKey, todayKey);
    await prefs.setInt(_streakCountKey, newStreak);

    return newStreak;
  }

  // =========================
  // 🧹 CLEAR IN-PROGRESS STATE
  // =========================

  Future<void> clearInProgressState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(DailySeed.inProgressStateKey);
  }
}
