import '../domain/daily_progress.dart';
import '../domain/daily_puzzle_set.dart';
import '../domain/daily_seed.dart';
import '../domain/daily_service.dart';
import 'daily_local_storage.dart';

class DailyRepository {
  final DailyService service;
  final DailyLocalStorage storage;

  const DailyRepository({required this.service, required this.storage});

  Future<DailyPuzzleSet> loadOrCreateDaily(DateTime date) async {
    final dailyKey = DailySeed.key(date);

    final cachedDaily = await storage.loadDaily(dailyKey);
    if (cachedDaily != null) {
      return cachedDaily;
    }

    final daily = await service.buildDailyAsync(date);
    await storage.saveDaily(daily);
    return daily;
  }

  Future<DailyProgress?> loadProgress(String dailyKey) {
    return storage.loadProgress(dailyKey);
  }

  Future<void> saveProgress(DailyProgress progress) {
    return storage.saveProgress(progress);
  }

  Future<int> loadDailyStreak() {
    return storage.loadDailyStreak();
  }

  Future<int> registerCompletedDaily(DateTime date) {
    return storage.registerCompletedDaily(date);
  }

  Future<void> clearInProgressState() {
    return storage.clearInProgressState();
  }
}
