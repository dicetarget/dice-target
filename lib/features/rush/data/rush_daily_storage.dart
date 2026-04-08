// lib/features/rush/data/rush_daily_storage.dart

import 'package:shared_preferences/shared_preferences.dart';

// ──────────────────────────────────────────────────────────────────────────────
// State model
// ──────────────────────────────────────────────────────────────────────────────
class RushDailyState {
  final int run1; // -1 = not played
  final int run2; // -1 = not played
  final int allTimeBest;

  const RushDailyState({required this.run1, required this.run2, required this.allTimeBest});

  bool get run1Played => run1 >= 0;
  bool get run2Played => run2 >= 0;
  bool get isCompleted => run1Played && run2Played;
  bool get canStartRun1 => !run1Played;
  bool get canStartRun2 => run1Played && !run2Played;

  /// Best of the two played runs (-1 if neither played).
  int get bestRunScore {
    if (run1Played && run2Played) return run1 > run2 ? run1 : run2;
    if (run1Played) return run1;
    return -1;
  }

  bool get isNewAllTimeBest => bestRunScore > 0 && bestRunScore >= allTimeBest;
}

// ──────────────────────────────────────────────────────────────────────────────
// Storage
// ──────────────────────────────────────────────────────────────────────────────
class RushDailyStorage {
  static const _keyDate = 'rush_daily_date';
  static const _keyRun1 = 'rush_daily_run1';
  static const _keyRun2 = 'rush_daily_run2';
  static const _keyHs = 'rush_daily_hs';

  // ── Seed ────────────────────────────────────────────────────────────────────

  /// Deterministic seed based on today's date.
  /// Both runs share the same seed → identical puzzle sequence.
  static int dailySeed() {
    final now = DateTime.now();
    return now.year * 10000 + now.month * 100 + now.day;
  }

  // ── Date helpers ────────────────────────────────────────────────────────────

  static String _todayString() {
    final now = DateTime.now();
    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  // ── Load ────────────────────────────────────────────────────────────────────

  Future<RushDailyState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_keyDate) ?? '';
    final today = _todayString();

    if (saved != today) {
      // New day → reset runs (keep all-time best)
      await prefs.setString(_keyDate, today);
      await prefs.setInt(_keyRun1, -1);
      await prefs.setInt(_keyRun2, -1);
    }

    return RushDailyState(
      run1: prefs.getInt(_keyRun1) ?? -1,
      run2: prefs.getInt(_keyRun2) ?? -1,
      allTimeBest: prefs.getInt(_keyHs) ?? 0,
    );
  }

  // ── Save ────────────────────────────────────────────────────────────────────

  Future<RushDailyState> saveRun1(int score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyRun1, score);
    await _updateHs(prefs, score);
    return RushDailyState(
      run1: score,
      run2: prefs.getInt(_keyRun2) ?? -1,
      allTimeBest: prefs.getInt(_keyHs) ?? 0,
    );
  }

  Future<RushDailyState> saveRun2(int score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyRun2, score);
    await _updateHs(prefs, score);
    return RushDailyState(
      run1: prefs.getInt(_keyRun1) ?? -1,
      run2: score,
      allTimeBest: prefs.getInt(_keyHs) ?? 0,
    );
  }

  Future<void> _updateHs(SharedPreferences prefs, int score) async {
    final current = prefs.getInt(_keyHs) ?? 0;
    if (score > current) await prefs.setInt(_keyHs, score);
  }
}
