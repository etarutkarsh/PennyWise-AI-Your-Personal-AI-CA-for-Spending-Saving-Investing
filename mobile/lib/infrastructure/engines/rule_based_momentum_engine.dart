import '../../domain/engines/momentum_engine.dart';
import '../../domain/finance/health_score.dart';
import '../../domain/finance/momentum.dart';

/// Computes financial Momentum from sequential HealthScore snapshots.
/// Requires at least 2 snapshots. Returns flat momentum if insufficient data.
class RuleBasedMomentumEngine implements MomentumEngine {
  const RuleBasedMomentumEngine();

  static const _kVersion = 'momentum-rule-v1';

  @override
  String get engineVersion => _kVersion;

  @override
  Momentum compute({
    required List<HealthScore> snapshots,
    int periodDays = 30,
  }) {
    if (snapshots.length < 2) {
      return Momentum(
        delta: 0,
        direction: MomentumDirection.flat,
        periodDays: periodDays,
        dimensionDeltas: const {},
        label: 'Insufficient History',
        computedAt: DateTime.now(),
      );
    }

    // Use the oldest and newest within the period window
    final sorted = List<HealthScore>.from(snapshots)
      ..sort((a, b) => a.computedAt.compareTo(b.computedAt));

    final oldest = sorted.first;
    final newest = sorted.last;
    final delta = newest.score - oldest.score;

    // Per-dimension deltas
    final dimensionDeltas = <HealthDimension, int>{};
    for (final dim in HealthDimension.values) {
      final oldScore = oldest.dimensions[dim]?.score;
      final newScore = newest.dimensions[dim]?.score;
      if (oldScore != null && newScore != null) {
        dimensionDeltas[dim] = newScore - oldScore;
      }
    }

    final direction = delta > 2
        ? MomentumDirection.accelerating
        : delta < -2
            ? MomentumDirection.decelerating
            : MomentumDirection.flat;

    final label = _label(delta, direction);

    return Momentum(
      delta: delta,
      direction: direction,
      periodDays: periodDays,
      dimensionDeltas: dimensionDeltas,
      label: label,
      computedAt: DateTime.now(),
    );
  }

  String _label(int delta, MomentumDirection direction) {
    if (direction == MomentumDirection.flat) return 'Stable';
    if (delta >= 10) return 'Strong Growth';
    if (delta >= 5) return 'Building';
    if (delta > 0) return 'Improving';
    if (delta <= -10) return 'Sharp Decline';
    if (delta <= -5) return 'Declining';
    return 'Slight Decline';
  }
}
