import '../../domain/behavioral/behavioral_vector.dart';
import '../../domain/engines/decision_learning_engine.dart';
import '../../domain/learning/behavior_adjustment.dart';
import '../../domain/learning/decision_execution.dart';
import '../../domain/learning/decision_lesson.dart';
import '../../domain/learning/decision_outcome.dart';
import '../../domain/learning/learning_confidence.dart';
import '../../domain/learning/learning_snapshot.dart';
import '../../domain/value_objects/ids.dart';

/// Deterministic, rule-based Decision Learning Engine.
/// No ML. No LLM. No probabilistic models.
/// Every lesson is traceable to a specific observed deviation from prediction.
class RuleBasedDecisionLearningEngine implements DecisionLearningEngine {
  const RuleBasedDecisionLearningEngine();

  static const _kVersion = 'learning-rule-v1';

  @override
  String get engineVersion => _kVersion;

  @override
  DecisionOutcome evaluateOutcome({
    required DecisionId decisionId,
    required UserId userId,
    required int predictedHealthDelta,
    required int? observedHealthDelta,
    required double? savingsRateDelta,
    required double? emergencyFundDelta,
  }) {
    if (observedHealthDelta == null) {
      return DecisionOutcome(
        decisionId: decisionId,
        userId: userId,
        observedAt: DateTime.now(),
        overallOutcome: OutcomeType.noData,
        decisionExpectationVariance: 0.0,
        baselineHealthScore: null,
        observedHealthScore: null,
        attributionConfidence: 0.0,
      );
    }

    final dev = observedHealthDelta - predictedHealthDelta;

    OutcomeType outcome;
    if (dev > 3) {
      outcome = OutcomeType.better;
    } else if (dev < -3) {
      outcome = OutcomeType.worse;
    } else {
      outcome = OutcomeType.asExpected;
    }

    // Attribution confidence: higher when outcome aligns with savings/emergency data
    double attribution = 0.40;
    if (savingsRateDelta != null && savingsRateDelta > 0) attribution += 0.20;
    if (emergencyFundDelta != null && emergencyFundDelta > 0) attribution += 0.20;
    if (observedHealthDelta.abs() > 5) attribution += 0.10;

    return DecisionOutcome(
      decisionId: decisionId,
      userId: userId,
      observedAt: DateTime.now(),
      overallOutcome: outcome,
      decisionExpectationVariance: dev.toDouble(),
      savingsRateDelta: savingsRateDelta,
      emergencyFundDelta: emergencyFundDelta,
      attributionConfidence: attribution.clamp(0.0, 1.0),
    );
  }

  @override
  DecisionLesson? extractLesson({
    required DecisionExecution execution,
    required DecisionOutcome outcome,
    required LearningSnapshot currentSnapshot,
  }) {
    if (!outcome.isSignificant) return null;

    final lessonId = LessonId(
      'lesson_${outcome.decisionId.value}_${DateTime.now().millisecondsSinceEpoch}',
    );

    // Lesson: user successfully executed and got better outcome → reinforce discipline
    if (execution.executed && outcome.overallOutcome == OutcomeType.better) {
      return DecisionLesson(
        id: lessonId,
        userId: outcome.userId,
        type: LessonType.positiveDeviation,
        extractedAt: DateTime.now(),
        confidence: LearningConfidence(
          score: (outcome.attributionConfidence * 0.80).clamp(0.0, 1.0),
          observations: 1,
          lastValidated: DateTime.now(),
        ),
        summary:
            'Following this recommendation type produced better-than-predicted outcomes.',
        evidence:
            'Health delta: ${outcome.healthDelta ?? 'unknown'} vs predicted. '
            'Savings rate delta: ${outcome.savingsRateDelta?.toStringAsFixed(2) ?? 'n/a'}. '
            'Emergency fund delta: ${outcome.emergencyFundDelta?.toStringAsFixed(1) ?? 'n/a'} months.',
        targetParameters: ['presentBias', 'statusQuoBias'],
        suggestedDeltas: {
          'presentBias': 0.03,       // slight reduction (less present-biased when they act)
          'statusQuoBias': -0.03,    // slight reduction (less resistant to change when it works)
        },
      );
    }

    // Lesson: user rejected recommendation and outcome was worse → reinforce urgency
    if (!execution.executed && outcome.overallOutcome == OutcomeType.worse) {
      return DecisionLesson(
        id: lessonId,
        userId: outcome.userId,
        type: LessonType.negativeDeviation,
        extractedAt: DateTime.now(),
        confidence: LearningConfidence(
          score: (outcome.attributionConfidence * 0.70).clamp(0.0, 1.0),
          observations: 1,
          lastValidated: DateTime.now(),
        ),
        summary:
            'Not following this recommendation type produced worse-than-predicted outcomes.',
        evidence:
            'Health delta: ${outcome.healthDelta ?? 'unknown'} vs predicted. '
            'Outcome: ${outcome.overallOutcome.name}. '
            'DEV: ${outcome.decisionExpectationVariance.toStringAsFixed(1)}.',
        targetParameters: ['presentBias', 'regretAversion'],
        suggestedDeltas: {
          'presentBias': -0.03,       // more present-biased → should act sooner
          'regretAversion': 0.02,     // increase regret awareness
        },
      );
    }

    // Lesson: user consistently rejects → possible behavioral resistance
    if (!execution.executed && outcome.overallOutcome == OutcomeType.asExpected) {
      return DecisionLesson(
        id: lessonId,
        userId: outcome.userId,
        type: LessonType.rejectionPattern,
        extractedAt: DateTime.now(),
        confidence: LearningConfidence(
          score: 0.35, // low confidence — needs more observations
          observations: 1,
          lastValidated: DateTime.now(),
        ),
        summary: 'User did not execute but outcome matched prediction anyway.',
        evidence: 'Execution skipped. DEV within ±3 — possibly circumstantial resistance.',
        targetParameters: ['statusQuoBias'],
        suggestedDeltas: {'statusQuoBias': 0.02},
      );
    }

    return null;
  }

  @override
  VectorCalibrationResult adjustVector({
    required BehavioralVector current,
    required DecisionLesson lesson,
    required UserId userId,
  }) {
    if (!lesson.isActionable) {
      return VectorCalibrationResult(
        before: current,
        after: current,
        adjustments: const [],
        calibratedAt: DateTime.now(),
      );
    }

    final adjustments = <BehaviorAdjustment>[];
    var updated = current;
    final now = DateTime.now();

    for (final entry in lesson.suggestedDeltas.entries) {
      final param = entry.key;
      final delta = entry.value * lesson.confidence.score;
      double oldVal;
      double newVal;

      switch (param) {
        case 'lossAversion':
          oldVal = updated.lossAversion;
          newVal = (oldVal + delta).clamp(1.0, 3.0);
          updated = updated.copyWith(lossAversion: newVal);
        case 'presentBias':
          oldVal = updated.presentBias;
          newVal = (oldVal + delta).clamp(0.1, 1.0);
          updated = updated.copyWith(presentBias: newVal);
        case 'statusQuoBias':
          oldVal = updated.statusQuoBias;
          newVal = (oldVal + delta).clamp(0.0, 1.0);
          updated = updated.copyWith(statusQuoBias: newVal);
        case 'regretAversion':
          oldVal = updated.regretAversion;
          newVal = (oldVal + delta).clamp(0.0, 1.0);
          updated = updated.copyWith(regretAversion: newVal);
        case 'impulseVolatility':
          oldVal = updated.impulseVolatility;
          newVal = (oldVal + delta).clamp(0.0, 1.0);
          updated = updated.copyWith(impulseVolatility: newVal);
        default:
          continue; // Unknown parameter — skip safely
      }

      adjustments.add(BehaviorAdjustment(
        userId: userId,
        sourceLessonId: lesson.id,
        appliedAt: now,
        parameter: param,
        oldValue: oldVal,
        newValue: newVal,
        rationale: lesson.summary,
      ));
    }

    return VectorCalibrationResult(
      before: current,
      after: updated,
      adjustments: adjustments,
      calibratedAt: now,
    );
  }

  @override
  LearningSnapshot buildSnapshot({
    required UserId userId,
    required LearningSnapshot previous,
    required List<DecisionLesson> allLessons,
    required BehavioralVector updatedVector,
  }) {
    final activeLessons = allLessons
        .where((l) => !l.confidence.isStale || l.confidence.effectiveScore > 0.10)
        .toList();

    final completedCycles = previous.completedCycles + 1;
    final outcomesObserved = previous.outcomesObserved + 1;

    // Maturity: 0.0 to 1.0 — approaches 1.0 asymptotically over ~50 cycles
    final maturity = 1.0 - (1.0 / (1.0 + completedCycles / 10.0));

    return LearningSnapshot(
      userId: userId,
      snapshotAt: DateTime.now(),
      behavioralVector: updatedVector,
      activeLessons: activeLessons,
      completedCycles: completedCycles,
      outcomesObserved: outcomesObserved,
      maturity: maturity.clamp(0.0, 1.0),
    );
  }

  @override
  List<DecisionLesson> getActiveLessons(LearningSnapshot snapshot) =>
      snapshot.activeLessons
          .where((l) => l.confidence.effectiveScore > 0.0)
          .toList();
}
