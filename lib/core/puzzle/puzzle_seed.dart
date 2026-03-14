class PuzzleSeed {
  const PuzzleSeed._();

  static int dailySeed(DateTime dateUtc) {
    final y = dateUtc.year;
    final m = dateUtc.month;
    final d = dateUtc.day;
    return (y * 10000) + (m * 100) + d;
  }

  static int todayDailySeedUtc() {
    final now = DateTime.now().toUtc();
    return dailySeed(now);
  }

  static int matchSeed(String matchId) {
    var hash = 0x811C9DC5;
    for (final code in matchId.codeUnits) {
      hash ^= code;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash & 0x7fffffff;
  }

  static int practiceSeed() {
    return DateTime.now().microsecondsSinceEpoch & 0x7fffffff;
  }

  static int mix(int seed, int puzzleIndex) {
    var value = seed & 0x7fffffff;
    value ^= (puzzleIndex + 1) * 0x9E3779B9;
    value = (value ^ (value >> 16)) & 0x7fffffff;
    return value;
  }
}
