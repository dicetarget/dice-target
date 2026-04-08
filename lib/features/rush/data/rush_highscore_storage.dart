// lib/features/rush/data/rush_highscore_storage.dart

import 'package:dice/features/rush/domain/rush_difficulty.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RushHighscoreStorage {
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
}
