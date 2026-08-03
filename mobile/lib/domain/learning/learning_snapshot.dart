import 'package:flutter/foundation.dart';
import '../value_objects/ids.dart';
import '../behavioral/behavioral_vector.dart';
import 'decision_lesson.dart';

/// Point-in-time accumulation of all learning for a user.
/// Consumed by the Decision Engine to improve future recommendations.
/// Replaces the static BehavioralVector.uncalibrated as the system matures.
@immutable
class LearningSnapshot {
  final UserId userId;
  final DateTime snapshotAt;

  /// Current calibrated BehavioralVector (starts as uncalibrated, improves over time).
  final BehavioralVector behavioralVector;

  /// All active lessons (not stale, confidence > 0.0).
  final List<DecisionLesson> activeLessons;

  /// Total number of decisions that completed the full learning cycle.
  final int completedCycles;

  /// Total number of outcomes observed (may exceed completedCycles — not all lead to lessons).
  final int outcomesObserved;

  /// Overall learning maturity (0.0–1.0) — function of completedCycles and confidence.
  final double maturity;

  const LearningSnapshot({
    required this.userId,
    required this.snapshotAt,
    required this.behavioralVector,
    required this.activeLessons,
    required this.completedCycles,
    required this.outcomesObserved,
    required this.maturity,
  }) : assert(maturity >= 0.0 && maturity <= 1.0);

  /// Empty snapshot before any learning has occurred.
  factory LearningSnapshot.empty(UserId userId) => LearningSnapshot(
        userId: userId,
        snapshotAt: DateTime.now(),
        behavioralVector: BehavioralVector.uncalibrated,
        activeLessons: const [],
        completedCycles: 0,
        outcomesObserved: 0,
        maturity: 0.0,
      );

  bool get isCalibrated => completedCycles >= 3;

  /// Lessons that are both high-confidence and not stale.
  List<DecisionLesson> get actionableLessons =>
      activeLessons.where((l) => l.isActionable).toList();

  /// Human-readable calibration label for UI display.
  String get calibrationLabel {
    if (completedCycles == 0) return 'Uncalibrated';
    if (completedCycles < 3) return 'Learning';
    if (maturity < 0.40) return 'Early Calibration';
    if (maturity < 0.70) return 'Calibrating';
    return 'Well Calibrated';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LearningSnapshot &&
          other.userId == userId &&
          other.snapshotAt == snapshotAt);

  @override
  int get hashCode => Object.hash(userId, snapshotAt);

  @override
  String toString() =>
      'LearningSnapshot(user: $userId, cycles: $completedCycles, '
      'maturity: ${maturity.toStringAsFixed(2)}, label: $calibrationLabel)';
}
