import 'package:firebase_analytics/firebase_analytics.dart';

final AnalyticsService analytics = AnalyticsService();

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> logDailyStart() async {
    await _analytics.logEvent(name: 'daily_start');
  }

  Future<void> logDailyComplete({required int stars}) async {
    await _analytics.logEvent(
      name: 'daily_complete',
      parameters: {'daily_stars': stars},
    );
  }

  Future<void> logRushStart() async {
    await _analytics.logEvent(name: 'rush_start');
  }

  Future<void> logRushComplete({required int score}) async {
    await _analytics.logEvent(
      name: 'rush_complete',
      parameters: {'rush_score': score},
    );
  }
}
