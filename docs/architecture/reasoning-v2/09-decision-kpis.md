# Decision KPIs — v2 Reasoning Architecture

**Document:** `docs/architecture/reasoning-v2/09-decision-kpis.md`
**Status:** Design Specification
**Phase:** Pre-Implementation (Pre-11A Addition)
**Depends on:** `ReasoningMemory`, `LearningSnapshot`, `DecisionExecution`, `DecisionOutcome`, `BehaviorInterpretation`, `HealthScoreReport`

---

## 1. Overview — Why Engine Observability Is a First-Class Concern

### The Measurement Gap in v1

PennyWise v1 has a `DecisionLearningEngine` that scores individual outcomes. It knows whether a specific recommendation was accepted, executed, and completed. What it does not have is an aggregated view of how well the reasoning engine is performing across all users, all decision types, and all time windows.

Without aggregate metrics, four problems are invisible:

**1. Silent degradation.** The engine's recommendation acceptance rate could be falling over three months — perhaps because a new user cohort has different behavioral profiles that the current policy engine handles poorly — and the engineering team would not know. Individual outcome records exist, but no aggregation surfaces the trend.

**2. Component attribution.** When acceptance rate falls, which component is responsible? Is the `PolicySelector` assigning wrong archetypes? Is the `UtilityEngine` producing calibration errors? Is the `ChallengeLayer` overriding too aggressively? Without component-level KPIs, diagnosis requires archaeology through raw records.

**3. Improvement measurement.** Sprint 11A ships `PolicySelector`. Sprint 11E ships `UtilityEngine`. Sprints are evaluated qualitatively ("looks correct") but not quantitatively ("acceptance rate improved 3.4% after PolicySelector shipped"). KPIs make sprint outcomes measurable.

**4. Calibration drift detection.** As the user base grows and behavioral profiles diversify, the engine's archetype priors drift out of calibration. The `UtilityEngine`'s loss-aversion parameter (λ) was set to 2.8 as an Indian market prior. With enough outcome data, we can measure whether actual acceptance behavior implies a higher or lower λ. Without KPIs, this calibration signal is invisible.

### The Design Philosophy

Decision KPIs are not a dashboard feature. They are the engine's self-monitoring layer — the feedback signal that tells the engineering team whether the reasoning pipeline is producing correct output at the population level, and the ML signal that tells future learning algorithms where to recalibrate.

KPIs are:
- **Computed, not stored inline.** They are derived from `ReasoningMemory` + `LearningSnapshot` records. They are not part of individual decision records.
- **Windowed.** The same metric at different time windows (30d, 90d, 365d) tells different stories.
- **Component-attributed.** Each KPI is linked to the pipeline component most responsible for it.
- **User-population-level.** Individual decision metrics already exist in `DecisionLearningEngine`. KPIs aggregate across the user population (or a defined cohort).

---

## 2. Research Findings

### 2.1 Recommendation System Evaluation Frameworks

Recommendation system evaluation in industry uses a standard set of metrics organized into two categories: accuracy metrics (how correct are the recommendations?) and business impact metrics (do the recommendations produce the desired outcomes?).

Netflix's recommendation system evaluation framework established the principle that optimizing for accuracy metrics (RMSE, precision@K) often diverges from optimizing for business metrics (viewing engagement). This is the "accuracy paradox": a technically correct recommendation that nobody follows has no value. PennyWise's equivalent: a high-confidence, high-utility recommendation that a user ignores is worth nothing. KPIs must measure both technical quality and behavioral impact.

Spotify's research on recommendation diversity introduced the concept of "portfolio-level metrics" — not just "did the user like recommendation 1?" but "is the portfolio of recommendations across the week producing healthy listening diversity?" PennyWise's `RecommendationPortfolio` produces ranked alternatives, not a single recommendation. Portfolio-level KPIs measure whether the diversity and ranking of the portfolio matches user preference — not just whether the top recommendation was accepted.

### 2.2 Online Learning and Bandit Problem Metrics

The multi-armed bandit problem — how to balance exploration (trying new recommendation strategies) and exploitation (using known good strategies) — is directly applicable to the `PolicySelector`. The policy engine selects an archetype for each user; the KPI question is whether the selected archetype produces better outcomes than alternatives would have.

Standard bandit evaluation uses two metrics: cumulative regret (how much better would the optimal arm have done?) and policy gradient signal (how should the arm selection probability change given the observed outcome?). PennyWise's `averageRegretScore` (from `UtilityEngine`) combined with `policyGraduationRate` (how often users graduate to the next policy tier) provides both signals.

### 2.3 Calibration Metrics in Probabilistic Forecasting

Weather forecasting introduced the gold standard for calibration measurement: "a forecast is well-calibrated if, among all cases where you predicted 70% probability of rain, it actually rained roughly 70% of the time." The equivalent for PennyWise: when the confidence aggregator assigns 0.72 compound confidence to a recommendation, that recommendation should be accepted and completed successfully approximately 72% of the time.

The `calibrationError` KPI measures this: the mean absolute difference between predicted compound confidence and observed success rate, binned by confidence decile. A well-calibrated engine has calibration error near zero. An overconfident engine (assigning 0.80 confidence to recommendations that succeed only 50% of the time) has high calibration error. This KPI directly measures whether the compound confidence formula in Phase 10 is producing meaningful probabilities.

### 2.4 Health Outcome Measurement in Financial Coaching

The financial coaching literature distinguishes between behavioral proxies (did the user follow the advice?) and outcome measures (did the user's financial health actually improve?). A recommendation to "start a SIP" that the user follows for two months and then cancels is a behavioral success (accepted + executed) but an outcome failure (no lasting health improvement).

PennyWise's `averageHealthScoreDelta` and `averageSavingsRateDelta` KPIs measure outcome, not just behavior. This distinction is architecturally important: the `DecisionLearningEngine` measures per-recommendation outcomes; the KPI layer aggregates them into population-level health signals that measure whether PennyWise's advice is actually making users financially healthier.

---

## 3. KPI Taxonomy

KPIs are organized into five categories, each attributed to the primary pipeline component responsible for the metric.

### Category 1: Funnel Metrics (Reception Quality)

These measure how recommendations move through the acceptance funnel. They aggregate across all decision records in the time window.

| KPI | Formula | Component Attributed | Target |
|-----|---------|----------------------|--------|
| `recommendationAcceptanceRate` | accepted / shown | PolicySelector + CandidateGenerator | ≥ 0.55 |
| `recommendationCompletionRate` | executed / accepted | UtilityEngine (resistance model) | ≥ 0.70 |
| `recommendationSuccessRate` | reviewed-as-success / executed | Full pipeline | ≥ 0.65 |
| `funnelDropoffByDecisionType` | acceptance rate split by ActionType | CandidateGenerator | top 3 types ≥ 0.50 |

**Interpretation:** If `recommendationAcceptanceRate` drops below 0.50 over 30 days, the `PolicySelector` is likely mis-archetype-ing users (assigning goals they find irrelevant). If `recommendationCompletionRate` drops while `recommendationAcceptanceRate` stays flat, the `UtilityEngine`'s resistance model is underestimating behavioral friction.

### Category 2: Engine Health Metrics (Component Quality)

These measure each component's internal performance, derived from `ReasoningMemory`.

| KPI | Formula | Component Attributed |
|-----|---------|----------------------|
| `beliefAccuracyRate` | beliefs-confirmed-by-outcome / total-activated-beliefs | BeliefInferenceEngine |
| `policyGraduationRate` | users who advanced policy tier in 90d / total active users | PolicySelector |
| `constitutionViolationRate` | hard-violations-per-run / candidates-generated-per-run | ConstitutionChecker |
| `challengeOverrideRate` | runs-where-challenge-overrode / total-runs | ChallengeLayer |
| `candidateViabilityRate` | viable-candidates / generated-candidates (after context pruning) | CandidateGenerator |
| `utilityMarginTop2` | utility(rank1) − utility(rank2) | UtilityEngine |

**Interpretation:** `beliefAccuracyRate` below 0.60 signals that belief thresholds are too permissive — the engine is activating beliefs that outcomes do not confirm. `challengeOverrideRate` above 0.30 signals the `UtilityEngine` has a systematic bias that the `ChallengeLayer` must correct — indicating the utility formula needs recalibration, not that the challenge layer is working correctly.

### Category 3: Confidence Calibration Metrics (Accuracy Quality)

These measure whether the compound confidence score is a meaningful probability estimate.

| KPI | Formula | Component Attributed |
|-----|---------|----------------------|
| `calibrationError` | mean(|predictedConfidence − observedSuccessRate|) by confidence decile | ConfidenceAggregator |
| `averageCompoundConfidence` | mean(compoundConfidence) across all runs in window | Full pipeline |
| `confidenceStabilityRate` | runs-where-confidence-changed < 0.05 on consecutive-day runs / total-runs | Full pipeline |
| `overconfidenceRate` | runs-where-confidence > 0.28 but outcome was failure / total high-confidence runs | Full pipeline |

**Interpretation:** `calibrationError` above 0.15 indicates the confidence formula is not producing probabilistic predictions. `confidenceStabilityRate` below 0.80 indicates the pipeline is too sensitive to minor input variations — recommendations change every day without meaningful input changes.

### Category 4: User Impact Metrics (Outcome Quality)

These are the ultimate measure of whether PennyWise's recommendations produce financial improvement.

| KPI | Formula | Component Attributed |
|-----|---------|----------------------|
| `averageHealthScoreDelta` | mean(healthScore[+90d] − healthScore[recommendation-day]) for accepted recs | Full pipeline |
| `averageSavingsRateDelta` | mean(savingsRate[+90d] − savingsRate[recommendation-day]) for startSip/stepUpSip recs | Full pipeline |
| `averageGoalSuccessRateDelta` | mean(goalOnTrackRate[+90d] − goalOnTrackRate[recommendation-day]) | GoalImpact axis |
| `behaviorImprovementRate` | users whose BehaviorInterpretation improved in 90d / users who accepted recs | BehaviorAxis |
| `financialResilienceGainRate` | users whose ResilienceIndex improved in 90d / total active users | Full pipeline |

**Interpretation:** `averageHealthScoreDelta` is the north star outcome metric. A positive mean across 90 days confirms PennyWise's advice is making users financially healthier. A negative mean is a critical signal requiring pipeline audit. Target: +2.0 points over 90 days for users who accepted at least one recommendation.

### Category 5: Portfolio Quality Metrics (v2-Specific)

These are unique to v2's `RecommendationPortfolio` output and cannot be measured with v1.

| KPI | Formula | Component Attributed |
|-----|---------|----------------------|
| `alternativeSelectionRate` | users who chose rank 2–4 / users who saw portfolio | RecommendationPortfolio |
| `portfolioConsistencyRate` | runs-where-portfolio-order-unchanged-from-yesterday / total-runs | Full pipeline |
| `counterfactualEngagementRate` | users who expanded counterfactual narration / users shown counterfactual | CounterfactualEngine |
| `constitutionRuleActivationRate` | runs-where-at-least-1-constitution-rule-fired / total-runs | ConstitutionChecker |

**Interpretation:** `alternativeSelectionRate` measures whether the portfolio feature adds value. If users only ever choose rank 1, the portfolio display is cosmetic. A rate above 0.20 confirms that alternatives are genuinely informative. `constitutionRuleActivationRate` below 0.05 suggests either the constitution is under-populated (users have not declared rules) or the candidates are never violating it — both warrant investigation.

---

## 4. Domain Type Specification

### 4.1 Core Types

```dart
/// Aggregated engine performance metrics over a defined time window.
/// Computed from ReasoningMemory + LearningSnapshot records.
/// Not stored inline with decisions — computed on demand or on schedule.
@immutable
class DecisionKPIs {
  final String userId;       // null = population-level KPIs (Phase 12 cohort analysis)
  final DateTime windowStart;
  final DateTime windowEnd;
  final KPIWindow window;    // thirtyDays | ninetyDays | oneYear | allTime
  final int sampleSize;      // number of pipeline runs in window
  final DateTime computedAt;

  // ── Category 1: Funnel Metrics ───────────────────────────────────────────
  final double recommendationAcceptanceRate;  // 0.0–1.0
  final double recommendationCompletionRate;
  final double recommendationSuccessRate;
  final Map<String, double> funnelDropoffByDecisionType; // ActionType label → rate

  // ── Category 2: Engine Health ────────────────────────────────────────────
  final double beliefAccuracyRate;
  final double policyGraduationRate;
  final double constitutionViolationRate;
  final double challengeOverrideRate;
  final double candidateViabilityRate;
  final double utilityMarginTop2;             // average margin

  // ── Category 3: Confidence Calibration ──────────────────────────────────
  final double calibrationError;              // mean absolute error, 0.0–1.0
  final double averageCompoundConfidence;
  final double confidenceStabilityRate;
  final double overconfidenceRate;

  // ── Category 4: User Impact ──────────────────────────────────────────────
  final double averageHealthScoreDelta;       // positive = improving
  final double averageSavingsRateDelta;
  final double averageGoalSuccessRateDelta;
  final double behaviorImprovementRate;
  final double financialResilienceGainRate;

  // ── Category 5: Portfolio Quality (v2 only) ──────────────────────────────
  final double alternativeSelectionRate;
  final double portfolioConsistencyRate;
  final double counterfactualEngagementRate;
  final double constitutionRuleActivationRate;

  // ── Derived Signals ──────────────────────────────────────────────────────
  /// Overall engine health grade: A (excellent) through F (critical)
  String get engineHealthGrade;

  /// Human-readable summary of the most concerning KPI for engineering review.
  String get topConcern;

  /// Whether the pipeline is within acceptable bounds on all Category 4 metrics.
  bool get isPositivelyImpacting;
}

enum KPIWindow {
  thirtyDays,
  ninetyDays,
  oneYear,
  allTime;

  String get label => switch (this) {
    KPIWindow.thirtyDays => '30 days',
    KPIWindow.ninetyDays => '90 days',
    KPIWindow.oneYear    => '1 year',
    KPIWindow.allTime    => 'All time',
  };

  Duration get duration => switch (this) {
    KPIWindow.thirtyDays  => const Duration(days: 30),
    KPIWindow.ninetyDays  => const Duration(days: 90),
    KPIWindow.oneYear     => const Duration(days: 365),
    KPIWindow.allTime     => const Duration(days: 36500), // 100 years sentinel
  };
}

/// Lightweight snapshot of the most critical KPIs for dashboard display.
@immutable
class DecisionKPISnapshot {
  final double acceptanceRate;
  final double averageConfidence;
  final double healthScoreDelta;
  final String engineHealthGrade;
  final KPIWindow window;
  final DateTime computedAt;
}
```

### 4.2 KPI Engine Interface

```dart
abstract class DecisionKPIEngine {
  /// Compute full KPIs for a user over a given window.
  /// Reads from ReasoningMemory + LearningSnapshot.
  DecisionKPIs compute({
    required String userId,
    required KPIWindow window,
  });

  /// Lightweight snapshot — faster to compute, suitable for dashboard tile.
  DecisionKPISnapshot snapshot({
    required String userId,
    KPIWindow window = KPIWindow.ninetyDays,
  });

  /// Population-level KPIs — Phase 12, requires cohort data.
  /// Returns null in single-user mode (Phase 11H and earlier).
  DecisionKPIs? computePopulation({
    required KPIWindow window,
    String? archetypeFilter,
  });
}
```

### 4.3 KPI Computation Engine

The `RuleBasedDecisionKPIEngine` implements computation from stored records. Key computations:

```dart
// Acceptance rate: requires DecisionExecution records from LearningSnapshot
double _computeAcceptanceRate(List<DecisionExecution> executions) {
  if (executions.isEmpty) return 0.0;
  final accepted = executions.where((e) => e.wasAccepted).length;
  return accepted / executions.length;
}

// Calibration error: bin memories by confidence decile, compare to success rate
double _computeCalibrationError(
  List<ReasoningMemory> memories,
  List<DecisionOutcome> outcomes,
) {
  final bins = <int, _CalibrationBin>{};
  for (final memory in memories) {
    final decile = (memory.compoundConfidence * 10).floor().clamp(0, 9);
    bins.putIfAbsent(decile, () => _CalibrationBin());
    bins[decile]!.predictions++;
    final outcome = outcomes.firstWhere(
      (o) => o.decisionId == memory.decisionId,
      orElse: () => null, // skip unresolved
    );
    if (outcome != null && outcome.wasSuccessful) bins[decile]!.successes++;
  }
  if (bins.isEmpty) return 0.0;
  return bins.values
    .where((b) => b.predictions >= 5) // minimum sample per bin
    .map((b) => (b.predictions / 10 - b.successes / b.predictions).abs())
    .fold(0.0, (sum, err) => sum + err) / bins.length;
}

// Health score delta: requires HealthScoreReport snapshots bracketing recommendation
double _computeHealthScoreDelta(
  List<DecisionExecution> acceptedExecutions,
  List<HealthScoreSnapshot> healthSnapshots,
) {
  if (acceptedExecutions.isEmpty) return 0.0;
  final deltas = <double>[];
  for (final execution in acceptedExecutions) {
    final before = healthSnapshots.lastWhere(
      (s) => s.computedAt.isBefore(execution.executedAt),
      orElse: () => null,
    );
    final after = healthSnapshots.firstWhere(
      (s) => s.computedAt.isAfter(
        execution.executedAt.add(const Duration(days: 90))),
      orElse: () => null,
    );
    if (before != null && after != null) {
      deltas.add(after.overallScore - before.overallScore);
    }
  }
  if (deltas.isEmpty) return 0.0;
  return deltas.reduce((a, b) => a + b) / deltas.length;
}
```

---

## 5. Engine Health Grading

The `DecisionKPIs.engineHealthGrade` derived getter provides a quick summary for engineering review:

```
Grade A (Excellent):
  - acceptanceRate ≥ 0.60
  - calibrationError ≤ 0.10
  - averageHealthScoreDelta ≥ +2.0
  - challengeOverrideRate ≤ 0.20

Grade B (Good):
  - acceptanceRate ≥ 0.50
  - calibrationError ≤ 0.15
  - averageHealthScoreDelta ≥ +1.0
  - challengeOverrideRate ≤ 0.25

Grade C (Acceptable):
  - acceptanceRate ≥ 0.40
  - calibrationError ≤ 0.20
  - averageHealthScoreDelta ≥ 0.0
  - No single KPI at critical threshold

Grade D (Needs Attention):
  - Any Category 4 metric is negative
  - calibrationError > 0.20
  - acceptanceRate < 0.40

Grade F (Critical — Engineering Review Required):
  - averageHealthScoreDelta < -1.0 (advice actively harming users)
  - calibrationError > 0.30 (confidence scores meaningless)
  - acceptanceRate < 0.25 (recommendations systematically rejected)
```

---

## 6. Relationship to Existing Domain Objects

### 6.1 Not a Replacement for DecisionLearningEngine

The `DecisionLearningEngine` produces per-recommendation learning outcomes: `DecisionLesson`, `BehaviorAdjustment`, `TwinCalibration`. These are individual feedback signals for one user and one decision.

`DecisionKPIs` aggregates across users and decisions. The two are complementary:

```
DecisionLearningEngine:
  Input: one DecisionExecution + one DecisionOutcome
  Output: DecisionLesson (what should change for this user?)

DecisionKPIEngine:
  Input: all ReasoningMemory + all DecisionOutcome records in window
  Output: DecisionKPIs (how is the engine performing across all users?)
```

### 6.2 KPIs as Policy Evolution Signal

The `PolicySelector` in Sprint 11A implements `PolicyEvolutionRule` — rules that trigger when a user should graduate to a more advanced policy tier (e.g., Survive → Stabilize). The `policyGraduationRate` KPI measures whether this evolution is working correctly at the population level.

A `policyGraduationRate` below 0.05 over 90 days indicates one of two problems: either the evolution rules are too strict (users who should graduate aren't being graduated), or the platform isn't generating enough accepted recommendations to trigger evolution. This KPI closes the feedback loop on `PolicyEvolutionRule` design.

### 6.3 KPIs as Utility Calibration Signal

The `UtilityEngine` uses an Indian loss-aversion prior of λ = 2.5–3.2. The `calibrationError` KPI, when examined by `utilityArchetypeLabel`, reveals whether the λ value for a given archetype is correctly calibrated.

Concretely: if recommendations scored with λ = 2.8 (LossAvoider archetype) have a 0.72 compound confidence but only a 0.45 observed success rate, `calibrationError` = 0.27 for that archetype. This signals that LossAvoider users are more resistant to execution than the λ parameter predicts. The correct remediation is raising λ to 3.0 or 3.2 — not lowering the confidence threshold.

---

## 7. Integration with the v2 Pipeline

KPI computation is a read-only operation that does not affect the pipeline. It is invoked by:

1. **`GetDashboardKPIsUseCase`** (new, Sprint 11H) — called by engineering monitoring dashboard or operator tools. Not user-facing in Phase 11H.
2. **`PolicyEvolutionEngine`** (Phase 12) — calls `snapshot()` before selecting policy evolution candidates.
3. **`ML Training Export`** (Phase 12) — calls `computePopulation()` to generate cohort-level training signals.

No component in the reasoning pipeline calls `DecisionKPIEngine`. KPIs are derived from pipeline outputs; they do not influence pipeline inputs.

---

## 8. Sprint 11H Deliverables

`DecisionKPIs` is delivered in Sprint 11H.

**New files:**
- `mobile/lib/domain/reasoning/kpi/decision_kpis.dart` — `DecisionKPIs`, `DecisionKPISnapshot`, `KPIWindow`
- `mobile/lib/domain/engines/decision_kpi_engine.dart` — abstract interface
- `mobile/lib/infrastructure/engines/rule_based_decision_kpi_engine.dart` — implementation
- `mobile/lib/application/reasoning/get_decision_kpis_use_case.dart`

**Updated files:**
- `mobile/lib/core/di/injection.dart` — registers `DecisionKPIEngine`, `GetDecisionKPIsUseCase`

**Acceptance criteria:**
- `calibrationError` returns 0.0 for an empty record set (edge case test)
- `engineHealthGrade` returns `'F'` when `averageHealthScoreDelta < -1.0` regardless of other metrics (Grade F dominance test)
- `funnelDropoffByDecisionType` contains no entries where denominator == 0 (division safety test)
- KPI computation completes in < 100ms for 500 memory records (performance test)
- `policyGraduationRate` denominator is `activeUsersInWindow`, not `total pipeline runs` (denominator correctness test)
- `flutter analyze`: 0 errors

---

## 9. Alerting Thresholds (Future — Phase 12)

Phase 12 can wire KPI thresholds to push notifications for engineering monitoring:

| KPI | Alert Threshold | Severity |
|-----|----------------|----------|
| `recommendationAcceptanceRate` | < 0.35 over 14 days | Critical |
| `averageHealthScoreDelta` | < 0.0 over 30 days | Critical |
| `calibrationError` | > 0.25 over 30 days | High |
| `challengeOverrideRate` | > 0.35 over 14 days | High |
| `beliefAccuracyRate` | < 0.50 over 30 days | Medium |
| `policyGraduationRate` | < 0.02 over 90 days | Medium |

These thresholds are not implemented in Sprint 11H. They are design intent for Phase 12's monitoring layer. The domain types designed here must accommodate them without schema changes.

---

*This document defines Decision KPIs as the engine observability layer for PennyWise Financial Reasoning Engine v2. KPIs are computed from `ReasoningMemory` and `LearningSnapshot` records; they do not alter any pipeline step. They are the quantitative feedback mechanism that closes the loop between what the engine reasons and whether that reasoning produces financial improvement in users' lives.*
