import 'package:flutter/foundation.dart';
import 'health_score.dart';

enum MomentumDirection { accelerating, decelerating, flat }

/// Health score trajectory over a rolling window.
/// People respond to momentum more than absolute scores —
/// +7 feels better to someone at 58 than being at 65 with -4 trend.
@immutable
class Momentum {
  /// Net health score change over the measurement period.
  final int delta;

  final MomentumDirection direction;

  /// Rolling window in days (default: 30).
  final int periodDays;

  /// Per-dimension deltas — shows which dimensions drove the change.
  final Map<HealthDimension, int> dimensionDeltas;

  /// Narrative label for UI: 'Building', 'Declining', 'Stable', etc.
  final String label;

  final DateTime computedAt;

  const Momentum({
    required this.delta,
    required this.direction,
    required this.periodDays,
    required this.dimensionDeltas,
    required this.label,
    required this.computedAt,
  });

  bool get isPositive => delta > 0;
  bool get isNegative => delta < 0;
  bool get isFlat => delta == 0;

  /// Display string: '+7' or '-12' or '0'.
  String get displayDelta => delta > 0 ? '+$delta' : '$delta';

  /// Top contributing dimension (most positive or negative delta).
  HealthDimension? get topContributor {
    if (dimensionDeltas.isEmpty) return null;
    return dimensionDeltas.entries
        .reduce((a, b) => a.value.abs() > b.value.abs() ? a : b)
        .key;
  }

  @override
  String toString() =>
      'Momentum(delta: $displayDelta, direction: $direction, period: ${periodDays}d)';
}
