import '../finance/momentum.dart';
import '../finance/health_score.dart';

/// Computes financial Momentum from a time-ordered sequence of health score snapshots.
/// Requires at least 2 snapshots to compute a delta. Returns flat momentum if insufficient data.
abstract class MomentumEngine {
  String get engineVersion;

  /// [snapshots] must be time-ordered oldest→newest, minimum 2 entries.
  /// [periodDays] is the rolling window (default 30).
  Momentum compute({
    required List<HealthScore> snapshots,
    int periodDays = 30,
  });
}
