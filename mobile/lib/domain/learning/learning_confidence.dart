import 'package:flutter/foundation.dart';

/// Confidence metadata for a learned lesson.
/// Tracks how many observations support the lesson and when it was last validated.
/// Only high-confidence lessons (>= 0.70) materially alter the BehavioralVector.
@immutable
class LearningConfidence {
  /// Aggregate confidence score (0.0–1.0).
  final double score;

  /// Number of distinct decision outcomes that contributed to this lesson.
  final int observations;

  /// When this lesson was last validated against a new outcome.
  final DateTime lastValidated;

  const LearningConfidence({
    required this.score,
    required this.observations,
    required this.lastValidated,
  }) : assert(score >= 0.0 && score <= 1.0);

  /// A lesson must cross this threshold before it materially adjusts the BehavioralVector.
  static const double kCalibrationThreshold = 0.70;

  bool get isHighConfidence => score >= kCalibrationThreshold;
  bool get isLowConfidence => score < 0.40;

  /// Staleness threshold — lessons older than 180 days lose authority.
  bool get isStale =>
      DateTime.now().difference(lastValidated).inDays > 180;

  /// Effective score after staleness decay — decays 20% per 90 days past 180 days.
  double get effectiveScore {
    if (!isStale) return score;
    final daysStale = DateTime.now().difference(lastValidated).inDays - 180;
    final decay = (daysStale / 90) * 0.20;
    return (score - decay).clamp(0.0, 1.0);
  }

  LearningConfidence withNewObservation({
    required double outcomeConfidence,
    required DateTime observedAt,
  }) {
    final newObservations = observations + 1;
    // Running weighted average — later observations weighted slightly more
    final newScore = ((score * observations) + outcomeConfidence) / newObservations;
    return LearningConfidence(
      score: newScore.clamp(0.0, 1.0),
      observations: newObservations,
      lastValidated: observedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LearningConfidence &&
          other.score == score &&
          other.observations == observations);

  @override
  int get hashCode => Object.hash(score, observations);

  @override
  String toString() =>
      'LearningConfidence(score: ${score.toStringAsFixed(2)}, '
      'observations: $observations, stale: $isStale)';
}
