class DailySeed {
  const DailySeed._();

  static int fromDate(DateTime date) {
    return date.year * 10000 + date.month * 100 + date.day;
  }

  static String key(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static const String inProgressStateKey = 'daily_in_progress_state';

  static final DateTime numberEpoch = DateTime(2026, 3, 17);
}
