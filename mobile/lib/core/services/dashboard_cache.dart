import '../../data/repositories/health_score_repository.dart';

/// In-memory cache for dashboard data that changes infrequently.
/// Lives for the app session; TTL prevents stale data on long sessions.
class DashboardCache {
  DashboardCache._();

  static HealthScoreModel? healthScore;
  static String dailyTip = '';
  static DateTime? _lastFetch;

  static const _ttl = Duration(minutes: 30);

  static bool get isStale =>
      _lastFetch == null ||
      DateTime.now().difference(_lastFetch!) > _ttl;

  static void set(HealthScoreModel? score, String tip) {
    healthScore = score;
    dailyTip = tip;
    _lastFetch = DateTime.now();
  }

  static void invalidate() {
    _lastFetch = null;
  }
}
