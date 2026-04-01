// lib/features/daily/domain/daily_stats.dart
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class DailyStats {
  final int totalPlayed;
  final int totalCompleted;
  final int total3Star;
  final int total2Star;
  final int total1Star;
  final int bestStreak;
  final int totalMoves;
  final int totalOptimalMoves;

  const DailyStats({
    required this.totalPlayed,
    required this.totalCompleted,
    required this.total3Star,
    required this.total2Star,
    required this.total1Star,
    required this.bestStreak,
    required this.totalMoves,
    required this.totalOptimalMoves,
  });

  const DailyStats.empty()
    : totalPlayed = 0,
      totalCompleted = 0,
      total3Star = 0,
      total2Star = 0,
      total1Star = 0,
      bestStreak = 0,
      totalMoves = 0,
      totalOptimalMoves = 0;

  double get completionRate => totalPlayed == 0 ? 0 : totalCompleted / totalPlayed;

  double get starRate3 => totalCompleted == 0 ? 0 : total3Star / totalCompleted;

  double get avgMoveDiff =>
      totalCompleted == 0 ? 0 : (totalMoves - totalOptimalMoves) / totalCompleted;

  Map<String, dynamic> toJson() => {
    'totalPlayed': totalPlayed,
    'totalCompleted': totalCompleted,
    'total3Star': total3Star,
    'total2Star': total2Star,
    'total1Star': total1Star,
    'bestStreak': bestStreak,
    'totalMoves': totalMoves,
    'totalOptimalMoves': totalOptimalMoves,
  };

  factory DailyStats.fromJson(Map<String, dynamic> json) => DailyStats(
    totalPlayed: (json['totalPlayed'] as num?)?.toInt() ?? 0,
    totalCompleted: (json['totalCompleted'] as num?)?.toInt() ?? 0,
    total3Star: (json['total3Star'] as num?)?.toInt() ?? 0,
    total2Star: (json['total2Star'] as num?)?.toInt() ?? 0,
    total1Star: (json['total1Star'] as num?)?.toInt() ?? 0,
    bestStreak: (json['bestStreak'] as num?)?.toInt() ?? 0,
    totalMoves: (json['totalMoves'] as num?)?.toInt() ?? 0,
    totalOptimalMoves: (json['totalOptimalMoves'] as num?)?.toInt() ?? 0,
  );

  DailyStats copyWith({
    int? totalPlayed,
    int? totalCompleted,
    int? total3Star,
    int? total2Star,
    int? total1Star,
    int? bestStreak,
    int? totalMoves,
    int? totalOptimalMoves,
  }) => DailyStats(
    totalPlayed: totalPlayed ?? this.totalPlayed,
    totalCompleted: totalCompleted ?? this.totalCompleted,
    total3Star: total3Star ?? this.total3Star,
    total2Star: total2Star ?? this.total2Star,
    total1Star: total1Star ?? this.total1Star,
    bestStreak: bestStreak ?? this.bestStreak,
    totalMoves: totalMoves ?? this.totalMoves,
    totalOptimalMoves: totalOptimalMoves ?? this.totalOptimalMoves,
  );
}

class DailyStatsStorage {
  static const _key = 'daily_stats_v1';

  Future<DailyStats> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const DailyStats.empty();
    try {
      return DailyStats.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const DailyStats.empty();
    }
  }

  Future<void> save(DailyStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(stats.toJson()));
  }

  Future<DailyStats> recordRun({
    required bool completed,
    required int stars,
    required int currentStreak,
    required int totalMoves,
    required int totalOptimalMoves,
  }) async {
    final current = await load();

    final newBestStreak = currentStreak > current.bestStreak ? currentStreak : current.bestStreak;

    final updated = current.copyWith(
      totalPlayed: current.totalPlayed + 1,
      totalCompleted: completed ? current.totalCompleted + 1 : null,
      total3Star: (completed && stars == 3) ? current.total3Star + 1 : null,
      total2Star: (completed && stars == 2) ? current.total2Star + 1 : null,
      total1Star: (completed && stars == 1) ? current.total1Star + 1 : null,
      bestStreak: newBestStreak,
      totalMoves: completed ? current.totalMoves + totalMoves : null,
      totalOptimalMoves: completed ? current.totalOptimalMoves + totalOptimalMoves : null,
    );

    await save(updated);
    return updated;
  }
}
