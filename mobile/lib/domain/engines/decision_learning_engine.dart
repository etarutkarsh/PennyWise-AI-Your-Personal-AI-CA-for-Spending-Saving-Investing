import '../learning/behavior_adjustment.dart';
import '../learning/decision_execution.dart';
import '../learning/decision_lesson.dart';
import '../learning/decision_outcome.dart';
import '../learning/learning_snapshot.dart';
import '../behavioral/behavioral_vector.dart';
import '../value_objects/ids.dart';

/// Engine that closes the Decision Learning Loop.
/// Deterministic and explainable — no ML, no LLM, no probabilistic models.
/// Extracts lessons from observed outcomes, calibrates the BehavioralVector,
/// and accumulates learning into a LearningSnapshot consumed by future decisions.
abstract class DecisionLearningEngine {
  String get engineVersion;

  /// Step 5 — Evaluate: classify outcome against prediction.
  DecisionOutcome evaluateOutcome({
    required DecisionId decisionId,
    required UserId userId,
    required int predictedHealthDelta,
    required int? observedHealthDelta,
    required double? savingsRateDelta,
    required double? emergencyFundDelta,
  });

  /// Step 6 — Learn: extract a lesson from a significant outcome.
  /// Returns null if the outcome is not significant enough to learn from.
  DecisionLesson? extractLesson({
    required DecisionExecution execution,
    required DecisionOutcome outcome,
    required LearningSnapshot currentSnapshot,
  });

  /// Step 7 — Update: apply an actionable lesson to the BehavioralVector.
  /// Returns VectorCalibrationResult with before/after and individual adjustments.
  VectorCalibrationResult adjustVector({
    required BehavioralVector current,
    required DecisionLesson lesson,
    required UserId userId,
  });

  /// Step 8 — Calibrate: build an updated LearningSnapshot from all active lessons.
  LearningSnapshot buildSnapshot({
    required UserId userId,
    required LearningSnapshot previous,
    required List<DecisionLesson> allLessons,
    required BehavioralVector updatedVector,
  });

  /// Returns all active (non-stale, any confidence) lessons for a user.
  List<DecisionLesson> getActiveLessons(LearningSnapshot snapshot);
}
