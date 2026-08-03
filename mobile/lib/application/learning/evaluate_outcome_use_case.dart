import '../../domain/engines/decision_learning_engine.dart';
import '../../domain/learning/decision_execution.dart';
import '../../domain/learning/decision_lesson.dart';
import '../../domain/learning/decision_outcome.dart';
import '../../domain/learning/learning_snapshot.dart';
import '../../domain/learning/twin_calibration.dart';
import '../../domain/value_objects/ids.dart';

class EvaluateOutcomeParams {
  const EvaluateOutcomeParams({
    required this.decisionId,
    required this.userId,
    required this.execution,
    required this.currentSnapshot,
    required this.predictedHealthDelta,
    this.observedHealthDelta,
    this.savingsRateDelta,
    this.emergencyFundDelta,
  });

  final DecisionId decisionId;
  final UserId userId;
  final DecisionExecution execution;
  final LearningSnapshot currentSnapshot;
  final int predictedHealthDelta;
  final int? observedHealthDelta;
  final double? savingsRateDelta;
  final double? emergencyFundDelta;
}

/// Full outcome evaluation — Steps 5→8 of the Decision Learning Loop.
/// Evaluates, extracts lesson, adjusts vector, builds updated snapshot.
class EvaluateOutcomeUseCase {
  const EvaluateOutcomeUseCase(this._engine);

  final DecisionLearningEngine _engine;

  EvaluateOutcomeResult call(EvaluateOutcomeParams params) {
    // Step 5: Evaluate
    final outcome = _engine.evaluateOutcome(
      decisionId: params.decisionId,
      userId: params.userId,
      predictedHealthDelta: params.predictedHealthDelta,
      observedHealthDelta: params.observedHealthDelta,
      savingsRateDelta: params.savingsRateDelta,
      emergencyFundDelta: params.emergencyFundDelta,
    );

    // Step 6: Learn
    final lesson = _engine.extractLesson(
      execution: params.execution,
      outcome: outcome,
      currentSnapshot: params.currentSnapshot,
    );

    if (lesson == null) {
      return EvaluateOutcomeResult(
        outcome: outcome,
        lesson: null,
        calibration: null,
        updatedSnapshot: params.currentSnapshot,
      );
    }

    // Step 7: Adjust vector
    final calibrationResult = _engine.adjustVector(
      current: params.currentSnapshot.behavioralVector,
      lesson: lesson,
      userId: params.userId,
    );

    // Step 8: Build updated snapshot
    final allLessons = [
      ...params.currentSnapshot.activeLessons,
      lesson,
    ];
    final updatedSnapshot = _engine.buildSnapshot(
      userId: params.userId,
      previous: params.currentSnapshot,
      allLessons: allLessons,
      updatedVector: calibrationResult.after,
    );

    // Emit twin calibration event (consumed by Digital Twin layer)
    TwinCalibration? twinCalibration;
    if (calibrationResult.hasChanges) {
      twinCalibration = TwinCalibration(
        userId: params.userId,
        calibratedAt: DateTime.now(),
        previousVector: calibrationResult.before,
        updatedVector: calibrationResult.after,
        adjustments: calibrationResult.adjustments,
        sourceLessonIds: [lesson.id],
        engineVersion: _engine.engineVersion,
        summary: lesson.summary,
      );
    }

    return EvaluateOutcomeResult(
      outcome: outcome,
      lesson: lesson,
      calibration: twinCalibration,
      updatedSnapshot: updatedSnapshot,
    );
  }
}

class EvaluateOutcomeResult {
  const EvaluateOutcomeResult({
    required this.outcome,
    required this.lesson,
    required this.calibration,
    required this.updatedSnapshot,
  });

  final DecisionOutcome outcome;
  final DecisionLesson? lesson;
  final TwinCalibration? calibration;
  final LearningSnapshot updatedSnapshot;

  bool get hasLesson => lesson != null;
  bool get hasTwinUpdate => calibration != null;
}
