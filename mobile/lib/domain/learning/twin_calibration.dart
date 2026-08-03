import 'package:flutter/foundation.dart';
import '../value_objects/ids.dart';
import '../behavioral/behavioral_vector.dart';
import 'behavior_adjustment.dart';

/// Domain event: the Financial Digital Twin was recalibrated with new learning.
/// Emitted after BehavioralVector adjustments — consumed by the Twin layer
/// to update its predictive model for future decisions.
@immutable
class TwinCalibration {
  final UserId userId;
  final DateTime calibratedAt;
  final BehavioralVector previousVector;
  final BehavioralVector updatedVector;
  final List<BehaviorAdjustment> adjustments;

  /// The lessons that triggered this calibration.
  final List<LessonId> sourceLessonIds;

  /// Version of the calibration engine that produced this event.
  final String engineVersion;

  /// Human-readable summary for the Financial Journal AAR card.
  final String summary;

  const TwinCalibration({
    required this.userId,
    required this.calibratedAt,
    required this.previousVector,
    required this.updatedVector,
    required this.adjustments,
    required this.sourceLessonIds,
    required this.engineVersion,
    required this.summary,
  });

  bool get hasChanges => adjustments.isNotEmpty;
  int get parametersAffected => adjustments.map((a) => a.parameter).toSet().length;

  @override
  String toString() =>
      'TwinCalibration(user: $userId, parameters: $parametersAffected, '
      'at: $calibratedAt)';
}
