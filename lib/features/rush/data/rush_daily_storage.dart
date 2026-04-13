// lib/features/rush/data/rush_daily_storage.dart

import 'package:shared_preferences/shared_preferences.dart';

/// Zustand des heutigen Daily-Speed-Runs.
class RushDailyState {
  final int run1;
  final int run2;
  final bool run1Played;
  final bool run2Played;
  final String dateKey;

  const RushDailyState({
    required this.run1,
    required this.run2,
    required this.run1Played,
    required this.run2Played,
    required this.dateKey,
  });

  bool get canStartRun2 => run1Played && !run2Played;
  bool get isCompleted => run1Played && run2Played;

  /// -1 wenn noch kein Run gespielt.
  int get bestRunScore {
    if (!run1Played && !run2Played) return -1;
    if (run1Played && !run2Played) return run1;
    if (!run1Played && run2Played) return run2;
    return run1 > run2 ? run1 : run2;
  }
}

class RushDailyStorage {
  static const _keyDate = 'rush_daily_date';
  static const _keyRun1 = 'rush_daily_run1';
  static const _keyRun2 = 'rush_daily_run2';
  static const _keyRun1Played = 'rush_daily_run1_played';
  static const _keyRun2Played = 'rush_daily_run2_played';

  static String _todayDateKey() {
    final now = DateTime.now();
    final y = now.year.toString();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${y}_${m}_$d';
  }

  Future<RushDailyState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = _todayDateKey();
    final savedDate = prefs.getString(_keyDate) ?? '';

    // Datum gewechselt → frischer Start
    if (savedDate != todayKey) {
      return RushDailyState(
        run1: 0,
        run2: 0,
        run1Played: false,
        run2Played: false,
        dateKey: todayKey,
      );
    }

    return RushDailyState(
      run1: prefs.getInt(_keyRun1) ?? 0,
      run2: prefs.getInt(_keyRun2) ?? 0,
      run1Played: prefs.getBool(_keyRun1Played) ?? false,
      run2Played: prefs.getBool(_keyRun2Played) ?? false,
      dateKey: todayKey,
    );
  }

  Future<void> saveRun1(int score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDate, _todayDateKey());
    await prefs.setInt(_keyRun1, score);
    await prefs.setBool(_keyRun1Played, true);
  }

  Future<void> saveRun2(int score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyRun2, score);
    await prefs.setBool(_keyRun2Played, true);
  }
}
