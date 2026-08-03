import 'package:flutter/foundation.dart';
import '../value_objects/ids.dart';
import '../behavioral/behavioral_vector.dart';

/// A single targeted adjustment to one BehavioralVector parameter.
/// Produced by the Decision Learning Engine when a lesson is actionable.
@immutable
class BehaviorAdjustment {
  final UserId userId;
  final LessonId sourceLessonId;
  final DateTime appliedAt;

  /// The BehavioralVector parameter field name being adjusted.
  final String parameter;

  final double oldValue;
  final double newValue;

  /// The magnitude of change.
  final double delta;

  /// Human-readable explanation of why this parameter changed.
  final String rationale;

  const BehaviorAdjustment({
    required this.userId,
    required this.sourceLessonId,
    required this.appliedAt,
    required this.parameter,
    required this.oldValue,
    required this.newValue,
    required this.rationale,
  }) : delta = newValue - oldValue;

  bool get isIncrease => delta > 0;
  bool get isDecrease => delta < 0;

  /// Large adjustments (>0.1) are flagged for review — the engine should rarely
  /// move a parameter more than 0.1 in a single lesson cycle.
  bool get isLargeAdjustment => delta.abs() > 0.1;

  @override
  String toString() =>
      'BehaviorAdjustment($parameter: ${oldValue.toStringAsFixed(3)} → '
      '${newValue.toStringAsFixed(3)}, Δ${delta > 0 ? '+' : ''}${delta.toStringAsFixed(3)})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BehaviorAdjustment &&
          other.userId == userId &&
          other.sourceLessonId == sourceLessonId &&
          other.parameter == parameter);

  @override
  int get hashCode => Object.hash(userId, sourceLessonId, parameter);
}

/// The complete result of applying one lesson to the BehavioralVector.
/// Contains the updated vector plus the list of individual adjustments for audit.
@immutable
class VectorCalibrationResult {
  final BehavioralVector before;
  final BehavioralVector after;
  final List<BehaviorAdjustment> adjustments;
  final DateTime calibratedAt;

  const VectorCalibrationResult({
    required this.before,
    required this.after,
    required this.adjustments,
    required this.calibratedAt,
  });

  bool get hasChanges => adjustments.isNotEmpty;

  @override
  String toString() =>
      'VectorCalibrationResult(adjustments: ${adjustments.length}, '
      'calibratedAt: $calibratedAt)';
}
