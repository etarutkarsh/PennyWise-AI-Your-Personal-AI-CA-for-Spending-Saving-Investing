import 'package:flutter/foundation.dart';
import '../value_objects/ids.dart';
import 'learning_confidence.dart';

enum LessonType {
  /// User consistently follows recommendations of this type.
  behaviorPattern,

  /// User rejects a certain recommendation type repeatedly.
  rejectionPattern,

  /// Specific outcomes significantly better than predicted.
  positiveDeviation,

  /// Specific outcomes significantly worse than predicted.
  negativeDeviation,

  /// Seasonal pattern detected (e.g., spends more before festivals).
  seasonalPattern,

  /// A recommendation type consistently improves health score.
  healthImpact,

  /// The predicted timeline was consistently wrong (too optimistic/pessimistic).
  timelineMiscalibration,
}

/// An extracted behavioral lesson from observed decision outcomes.
/// Each lesson targets one or more BehavioralVector parameters for future calibration.
@immutable
class DecisionLesson {
  final LessonId id;
  final UserId userId;
  final LessonType type;
  final DateTime extractedAt;
  final LearningConfidence confidence;

  /// Human-readable lesson summary.
  final String summary;

  /// The data that supports this lesson (for XAI display).
  final String evidence;

  /// The BehavioralVector parameter(s) this lesson targets.
  final List<String> targetParameters;

  /// Suggested delta for each target parameter (-1.0 to +1.0).
  final Map<String, double> suggestedDeltas;

  /// Optional seasonality context (e.g., 'pre-diwali', 'year-end').
  final String? seasonalContext;

  const DecisionLesson({
    required this.id,
    required this.userId,
    required this.type,
    required this.extractedAt,
    required this.confidence,
    required this.summary,
    required this.evidence,
    required this.targetParameters,
    required this.suggestedDeltas,
    this.seasonalContext,
  });

  /// Only apply this lesson to the BehavioralVector if confidence is high enough.
  bool get isActionable => confidence.isHighConfidence && !confidence.isStale;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DecisionLesson && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'DecisionLesson(id: $id, type: $type, confidence: ${confidence.score.toStringAsFixed(2)}, '
      'actionable: $isActionable)';
}
