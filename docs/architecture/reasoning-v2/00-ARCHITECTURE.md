# PennyWise Financial Reasoning Engine v2 — Master Architecture

**Status:** Design-Complete — Ready for Sprint 11A  
**Authored:** 2026-08-05  
**Supersedes:** `RuleBasedFinancialReasoningEngine` (v1) single-pass axis scorer  
**Implements:** Phase 9–12 Intelligence Roadmap — Decision Engine v3  
**Component specs:** `01-decision-policy-engine.md` through `09-decision-kpis.md`  
**Pre-11A additions:** `08-reasoning-memory.md` (ReasoningMemory chain-of-reasoning storage), `09-decision-kpis.md` (engine observability KPIs) — delivered in Sprint 11H

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [The Complete v2 Reasoning Pipeline](#2-the-complete-v2-reasoning-pipeline)
3. [Complete Domain Model](#3-complete-domain-model)
4. [Updated FinancialReasoningContext](#4-updated-financialreasoningcontext)
5. [Bounded Contexts and Dependency Graph](#5-bounded-contexts-and-dependency-graph)
6. [Key Interfaces](#6-key-interfaces)
7. [Global Invariants](#7-global-invariants)
8. [Confidence Propagation Model](#8-confidence-propagation-model)
9. [The v2 Output: RecommendationPortfolio](#9-the-v2-output-recommendationportfolio)
10. [Migration Strategy from v1](#10-migration-strategy-from-v1)
11. [Sprint-by-Sprint Implementation Plan](#11-sprint-by-sprint-implementation-plan)
12. [Testing Strategy](#12-testing-strategy)
13. [Extension Points](#13-extension-points)
14. [What v2 Enables That v1 Cannot](#14-what-v2-enables-that-v1-cannot)

---

## 1. Executive Summary

### What v2 Is

PennyWise Financial Reasoning Engine v2 replaces the single-pass, static-weight axis scorer in v1 (`RuleBasedFinancialReasoningEngine`) with a seven-component reasoning pipeline that produces a ranked `RecommendationPortfolio` instead of a single `DecisionType`. Every recommendation carries a counterfactual pair, a utility score, a challenge verdict, and a constitution compliance statement.

### Why It Exists

The v1 engine answers "How confident are we about this recommendation?" It cannot answer "Out of all possible financial actions, which produces the most value for this specific person today — and how do we know we chose correctly?" This gap produces four observable failure modes: (1) it cannot return ranked alternatives, (2) it cannot explain what it considered and rejected, (3) it does not enforce prerequisite ordering fiduciarily, and (4) it applies the same axis weights to a 22-year-old student and a 55-year-old pre-retiree.

### The Nine Components and Their Theses

| #   | Component                        | Pipeline Step | One-Sentence Thesis                                                                                                                                                                                              |
| --- | -------------------------------- | ------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | **Decision Policy Engine**       | Step 1        | Replaces static axis weights with a `DecisionPolicy` selected per user archetype and financial maturity state, making weights explainable and evolvable.                                                         |
| 2   | **Belief Engine**                | Step 2        | Inserts a named, confidence-tagged interpretation layer between raw `FinancialFacts` and the decision engines, eliminating redundant threshold logic and enabling semantic explainability.                       |
| 3   | **Decision Candidate Generator** | Step 3        | Enumerates all 27 financially applicable actions before scoring begins, enabling prerequisite pruning, ranked portfolios, and "why not that?" explainability.                                                    |
| 4   | **Financial Constitution**       | Step 4        | Enforces inviolable financial rules as hard constraints applied **before** utility scoring, ensuring no constitutionally prohibited candidate is ever scored.                                                    |
| 5   | **Utility Engine**               | Step 5        | Scores each constitution-permissible candidate against a personalized preference model (loss aversion, present bias, behavioral resistance, regret, complexity) rather than population averages.                 |
| 6   | **Counterfactual Engine**        | Step 6        | Projects each surviving candidate forward in time with five scenario types, converting abstract recommendations into concrete rupee stakes ("₹12L less if you wait 6 months").                                   |
| 7   | **Challenge Layer**              | Step 7        | Runs six adversarial challenges against the top-ranked candidate before it exits the engine — the pipeline's internal devil's advocate.                                                                          |
| 8   | **Reasoning Memory**             | Side-output   | Stores the full chain of reasoning per pipeline execution — beliefs activated, candidates generated and rejected, utility breakdowns, challenge results — for explainability, ML training, and regulatory audit. |
| 9   | **Decision KPIs**                | Post-pipeline | Aggregates per-recommendation outcomes into windowed engine observability metrics, measuring whether the pipeline is producing financial improvement at the population level.                                    |

### What v2 Enables That v1 Cannot

- A ranked portfolio of 3–5 recommendations with full explanations for each
- Counterfactual narration: "Waiting 6 months costs you ₹12L in compounded growth"
- Constitution enforcement: "This recommendation conflicts with your rule: Never reduce emergency fund below 12 months"
- Differentiated advice: a freelancer in Survive state and a salaried professional in Optimize state receive structurally different recommendations from the same income level
- Full explainability of what was considered and rejected — with reasons
- Complete reasoning chain stored per decision: every belief activated, every candidate scored, every challenge verdict — for user explainability, ML training, and regulatory audit
- Engine observability: aggregated KPIs measure whether the pipeline is producing real financial improvement at the population level

---

## 2. The Complete v2 Reasoning Pipeline

The pipeline is synchronous, pure-functional, and has no I/O. All inputs arrive via `FinancialReasoningContext`. The same context always produces the same output.

```
╔══════════════════════════════════════════════════════════════════════════╗
║                    FinancialReasoningContext (input)                     ║
║  facts + dataConfidence + policy + beliefs + behavior + learning         ║
║  + goals + constitution                                                  ║
╚═══════════════════════════════╦══════════════════════════════════════════╝
                                │
                    ┌───────────▼────────────┐
         STEP 1     │    PolicySelector       │  Component: 01
                    │  UserArchetype × SMRT   │
                    │  → DecisionPolicy       │
                    │    (AxisWeightProfile   │
                    │   + PolicyThresholds    │
                    │   + EvolutionRules)     │
                    └───────────┬────────────┘
                                │ DecisionPolicy
                    ┌───────────▼────────────┐
         STEP 2     │  BeliefInferenceEngine  │  Component: 02
                    │  26 rules × 7 categories│
                    │  → BeliefSet            │
                    │    (confidence-tagged   │
                    │    financial beliefs    │
                    │    with evidence)       │
                    └───────────┬────────────┘
                                │ BeliefSet
                    ┌───────────▼────────────┐
         STEP 3     │  CandidateGenerator    │  Component: 03
                    │  27 ActionTypes        │
                    │  → CandidateSet        │
                    │    (viable + pruned,   │
                    │    pyramid-sorted)     │
                    └───────────┬────────────┘
                                │ CandidateSet (viable list)
                    ┌───────────▼────────────┐
         STEP 4     │  ConstitutionChecker   │  Component: 07
                    │  System + User + Goal  │
                    │  hard rules → prune    │
                    │  → permissibleCandidates│
                    │    + ConstitutionViolations│
                    └───────────┬────────────┘
                                │ permissibleCandidates (hard violations removed)
                    ┌───────────▼────────────┐
         STEP 5     │  UtilityEngine         │  Component: 04
                    │  EB − EC − R − BR      │
                    │  − Rg − C − LL         │
                    │  → UtilityScore per    │
                    │    candidate           │
                    └───────────┬────────────┘
                                │ ScoredCandidateSet (ranked by netUtility × compoundConfidence)
                    ┌───────────▼────────────┐
         STEP 6     │  CounterfactualEngine  │  Component: 05
                    │  5 scenario types:     │
                    │  Action / Delay /      │
                    │  Magnitude / Shock /   │
                    │  Commitment            │
                    │  → CounterfactualSet   │
                    │    per top candidate   │
                    └───────────┬────────────┘
                                │ CounterfactualSet (top 3 candidates)
                    ┌───────────▼────────────┐
         STEP 7     │  ChallengeLayer        │  Component: 06
                    │  6 challenges:         │
                    │  Liquidity / Debt /    │
                    │  Behavior / Tax /      │
                    │  Timing / Risk         │
                    │  → ChallengeLayerResult│
                    │    (confirmed / replaced│
                    │    / modified)         │
                    └───────────┬────────────┘
                                │ finalCandidate + ChallengeLayerResult
                    ┌───────────▼────────────┐
         STEP 8     │  ConfidenceAggregator  │  Synthesizes all components
                    │  compoundConfidence    │
                    │  × calibrationConf     │
                    │  + challengeDelta      │
                    │  → ConfidenceGraph     │
                    └───────────┬────────────┘
                                │ ConfidenceGraph
                    ┌───────────▼────────────┐
         STEP 9     │  ExplainabilityEngine  │  Existing + extended
                    │  policy reason +       │
                    │  belief evidence +     │
                    │  utility narrative +   │
                    │  counterfactual narr.  │
                    │  + challenge reasons   │
                    │  → ExplanationData     │
                    └───────────┬────────────┘
                                │ ExplanationData
                    ┌───────────▼────────────┐
         STEP 10    │  RecommendationPortfolio│  Final assembly
                    │  rank 1 (full)          │
                    │  ranks 2–4 (condensed) │
                    │  + ConfidenceGraph      │
                    │  + ConstitutionStatement│
                    │  + ChallengeVerdict     │
                    └───────────┬────────────┘
                                │
                    ╔═══════════▼════════════╗
                    ║  RecommendationPortfolio║
                    ║  (assembles into        ║
                    ║   DecisionResponse v2)  ║
                    ╚════════════════════════╝
```

### Step-by-Step Reference Table

| Step | Name                    | Input                                                                                            | Output Domain Type                                                                                                       | Component Doc                        |
| ---- | ----------------------- | ------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------ | ------------------------------------ |
| 1    | PolicySelector          | `FinancialReasoningContext` (`facts`, `behavior`, `userArchetype`)                               | `DecisionPolicy` (`AxisWeightProfile` + `PolicyThresholds` + evolution rules)                                            | `01-decision-policy-engine.md`       |
| 2    | BeliefInferenceEngine   | `FinancialFacts`, `BehaviorInterpretation?`, `List<GoalSnapshot>`, `DataConfidenceReport`        | `BeliefSet` (26 named beliefs, 7 categories, each with confidence + evidence)                                            | `02-belief-engine.md`                |
| 3    | CandidateGenerator      | `FinancialReasoningContext` (facts + goals + learning)                                           | `CandidateSet` (viable `List<DecisionCandidate>` pyramid-sorted + pruned list with rejection reasons)                    | `03-decision-candidate-generator.md` |
| 4    | ConstitutionChecker     | `CandidateSet.viable`, `FinancialConstitution`                                                   | `permissibleCandidates` (hard violations removed), `List<ConstitutionViolation>` for audit                               | `07-financial-constitution.md`       |
| 5    | UtilityEngine           | `permissibleCandidates`, `FinancialReasoningContext`, `DecisionConfidenceReport`, `UtilityModel` | `UtilityScore` per candidate; `ScoredCandidateSet` ranked by `rankingScore = netUtility × min(1, compoundConf/0.20)`     | `04-utility-engine.md`               |
| 6    | CounterfactualEngine    | Top 3 scored candidates, `FinancialFacts`, `List<GoalSnapshot>`                                  | `CounterfactualSet` per candidate (action + delay + magnitude + shock + commitment scenarios)                            | `05-counterfactual-engine.md`        |
| 7    | ChallengeLayer          | Top candidate + `FinancialReasoningContext` + `FinancialPolicy` + `DecisionConfidenceReport`     | `ChallengeLayerResult` (6 `ChallengeResult` objects; `finalCandidate`; `totalConfidenceDelta`)                           | `06-challenge-layer.md`              |
| 8    | ConfidenceAggregator    | All prior step outputs                                                                           | `ConfidenceGraph` (multi-dimensional confidence breakdown — data, reasoning, behavioral, historical, challenge-adjusted) | This document                        |
| 9    | ExplainabilityEngine    | `ConfidenceGraph`, `BeliefSet`, `UtilityScore`, `CounterfactualSet`, `ChallengeLayerResult`      | `ExplanationData` (because[], evidence[], alternatives[], limitations[], confidence drivers)                             | Extended from v1                     |
| 10   | RecommendationPortfolio | All above                                                                                        | `RecommendationPortfolio` → assembled into `DecisionResponse` v2                                                         | This document                        |

---

## 3. Complete Domain Model

### 3.1 Policy Context

**Package:** `mobile/lib/domain/reasoning/policy/`

#### `DecisionPolicy`

```
id:                 PolicyId        — e.g., "freelancer_survive_v1"
name:               String          — "Freelancer — Survive"
archetype:          UserArchetype
financialState:     FinancialState  — survive | stabilize | build | optimize
lifecycleStage:     LifecycleStage
weights:            AxisWeightProfile
thresholds:         PolicyThresholds
evolutionRules:     List<PolicyEvolutionRule>   — non-empty always
selectionReason:    String
schemaVersion:      String
effectiveAt:        DateTime
```

- **Invariants:** `weights.sum == 1.0 ± 0.001`; no weight < 0.02 or > 0.55; `evolutionRules` non-empty.
- **Pipeline:** Produced at Step 1 (PolicySelector), consumed at Steps 2–5 (axis analyzers read `thresholds`; utility engine reads `weights`).

#### `AxisWeightProfile`

```
cashFlow:         double  — 0.02–0.55
liquidity:        double
goalImpact:       double
behavior:         double
taxes:            double
opportunityCost:  double
```

- **Invariants:** All six sum to 1.0. Covers only the 6 decision axes — `dataConfidence` and `historicalAccuracy` are structural multipliers, never weighted.
- **Pipeline:** Produced inside `DecisionPolicy` at Step 1; applied at Step 5 (UtilityEngine ranking weights).

#### `PolicyThresholds`

```
emergencyFundTargetMonths:   double  — 3.0 (student) to 24.0 (retired)
minSavingsRate:              double
safeDebtRatio:               double
criticalDebtRatio:           double
taxEfficiencyTarget:         double
minOpportunityCostRate:      double
behaviorMinimumConsistency:  double
```

- **Pipeline:** Consumed at Step 2 (axis analyzers score against these thresholds, not hardcoded constants) and Step 7 (Challenge triggers use `safeDebtRatio`, `emergencyFundTargetMonths`).

#### `UserArchetype` (enum)

```
student | youngProfessional | salariedWithFamily | freelancer | businessOwner | preRetiree | retiree
```

#### `LifecycleStage` (enum)

```
foundation(18–30) | growth(30–45) | peak(45–55) | preRetirement(55–60) | retirement(60+)
```

#### `PolicyEvolutionRule`

```
triggerId:       String
fromPolicy:      PolicyId
toPolicy:        PolicyId
conditions:      List<PolicyCondition>   — each checks a FinancialFact key + threshold + operator
evaluationMode:  AllConditions | AnyCondition
sustainDuration: Duration?              — 30 days for forward, 7 days for protective downgrade
graduationLabel: String
```

- **Pipeline:** Evaluated by `PolicyEvolutionEngine` (application layer use case) after each reasoning cycle.

#### `PolicyModifier` (behavioral overlay)

```
id:                ModifierId
name:              String
weightDeltas:      Map<DecisionAxis, double>   — deltas sum to zero
thresholdOverrides: Map<String, double>
condition:         String
```

- **Invariant:** `weightDeltas` values sum to zero (preserving weight pool total = 1.0).

#### `PolicyStateRecord` (persisted via infrastructure)

```
userId:           UserId
activePolicyId:   PolicyId
activatedAt:      DateTime
previousPolicyId: PolicyId?
overrideActive:   bool
```

---

### 3.2 Belief Context

**Package:** `mobile/lib/domain/reasoning/beliefs/`

#### `FinancialBeliefType` (enum — 26 values)

Seven categories: Liquidity (5), Debt (5), Investment (5), Insurance (5), Behavioral (5), Life Stage (5), plus per-goal beliefs via `GoalBeliefType`.

#### `FinancialBelief`

```
type:                  FinancialBeliefType
category:              BeliefCategory
confidence:            double     — 0.0–1.0, capped by min(fact confidences)
uncertainty:           double     — 0.0–1.0, orthogonal to confidence
magnitude:             BeliefMagnitude   — severe | moderate | mild | neutral | positive | strong
supportingFacts:       List<FinancialFactKey>   — at least 1 required
contradictingFacts:    List<FinancialFactKey>
supportingEvidence:    List<BeliefEvidenceItem>
contradictingEvidence: List<BeliefEvidenceItem>
derivedAt:             DateTime
expiresAt:             DateTime   — derivedAt + 24h (SMS/AA connected) or 72h (manual)
inferenceRuleId:       String     — e.g., "LQ-001"
engineVersion:         String
```

- **Computed:** `effectiveConfidence = confidence × decayFactor` (−0.10/day after 36h, floor 0.20); `isActionable = confidence >= 0.50 && !isExpired`.
- **Pipeline:** Produced at Step 2 (BeliefInferenceEngine); consumed at Steps 3 (CandidateGenerator uses beliefs for applicability), 5 (UtilityEngine), 6 (CounterfactualEngine context), 9 (ExplainabilityEngine uses `supportingEvidence.narrative`).

#### `BeliefEvidenceItem`

```
factKey:   FinancialFactKey
observed:  String    — "2.1 months"
threshold: String    — "target: 3 months"
narrative: String    — "Emergency fund covers 2.1 months — target is 3"
direction: BeliefEvidenceDirection   — supporting | contradicting
```

#### `GoalBelief`

```
goalId:                       GoalId
type:                         GoalBeliefType
confidence:                   double
monthsToDeadline:             int
requiredMonthlyContribution:  double
actualMonthlyContribution:    double
fundingRatio:                 double   — actual / required
```

#### `BeliefSet`

```
userId:            UserId
liquidity:         FinancialBelief?
debt:              FinancialBelief?
investment:        FinancialBelief?
insurance:         FinancialBelief?
behavioral:        FinancialBelief?
lifeStage:         FinancialBelief?   — composite, derived last
goalBeliefs:       Map<GoalId, GoalBelief>
allBeliefs:        List<FinancialBelief>
computedAt:        DateTime
overallConfidence: double   — bounded by DataConfidenceReport.recommendationConfidenceCap
```

- **Invariants:** No two beliefs with same `type`; `lifeStage` derived after all others; `overallConfidence ≤ recommendationConfidenceCap`; `BeliefSet.empty()` always safe to consume.
- **Pipeline:** Produced at Step 2; attached to `FinancialReasoningContext.beliefs`; consumed at Steps 3, 5, 6, 9.

#### `BeliefInferenceRule`

```
ruleId:         String   — e.g., "LQ-001"
targetBelief:   FinancialBeliefType
requiredFacts:  List<FinancialFactKey>
optionalFacts:  List<FinancialFactKey>
ruleVersion:    String
thresholdBasis: String   — references FinancialPolicy constant
```

---

### 3.3 Candidate Context

**Package:** `mobile/lib/domain/reasoning/candidates/`

#### `ActionType` (enum — 27 values)

```
Liquidity (4):    buildEmergencyFund, increaseShortTermSavings,
                  reduceFixedCommitments, startRecurringDeposit

Investment (8):   startSip, increaseSip, stepUpSip, rebalancePortfolio,
                  startElss, openPpf, openNps, optimizeRegimeSelection

Debt (3):         accelerateDebtRepayment, consolidateDebt, refinanceLoan

Protection (3):   getTermInsurance, getHealthInsurance, reviewInsurance

Tax (2):          maximize80C, maximize80CCD
                  (optimizeRegimeSelection shared with Investment)

Behavioral (3):   cancelUnusedSubscription, reduceDiscretionarySpending,
                  negotiateRecurringBill

Goal (4):         createGoal, increaseGoalContribution,
                  extendGoalTimeline, prioritizeGoal
```

#### `DecisionCandidate`

```
actionType:             ActionType
family:                 ActionFamily
headline:               String
rationale:              String
suggestedMagnitude:     CandidateMagnitude
magnitudeConfidence:    double         — 0.0–1.0
goalAlignment:          List<String>   — GoalSnapshot IDs
riskClass:              RiskClass      — reducesRisk | neutral | incrementalRisk | moderateRisk | highRisk
behaviorDifficulty:     BehaviorDifficulty — veryEasy | easy | moderate | hard | veryHard
prerequisiteBelief:     PrerequisiteBelief
applicabilitySignals:   List<String>
pyramidLayer:           int            — 1 | 2 | 3 (CFP pyramid)
dataRequirements:       List<String>
missingData:            List<String>
rejectionReason:        String?        — non-null only for pruned candidates
estimatedGoalAcceleration: int?
annualTaxSaving:        double?
```

- **Invariants:** `rejectionReason` non-empty on all pruned candidates; Layer 3 candidates absent when any Layer 1 is critical; no duplicate `ActionType` in `viable`.
- **Pipeline:** Produced at Step 3; hard-violation candidates removed at Step 4; scored at Step 5; projected at Step 6; top candidate challenged at Step 7.

#### `CandidateMagnitude`

```
monthlyAmount:  double?
targetAmount:   double?
horizon:        int     — months
basis:          MagnitudeBasis   — surplusBased | gapBased | formulaBased | ruleOfThumb | userHistoryBased
```

#### `CandidateSet`

```
viable:              List<DecisionCandidate>   — passed eligibility, pyramid-sorted
pruned:              List<DecisionCandidate>   — rejected with rejectionReason
generatedAt:         DateTime
generatorVersion:    String
dataCompleteness:    double   — from FinancialFacts.completeness
```

- **Invariant:** `viable.length >= 2` always (fallback to ruleOfThumb defaults if needed).

---

### 3.4 Utility Context

**Package:** `mobile/lib/domain/reasoning/utility/`

#### `UtilityModel`

```
userId:                      UserId
lossAversionCoefficient:     double   — λ, Indian prior 2.5, range 1.0–4.0
timeDiscountRate:            double   — annual δ, default 0.10
presentBiasCoefficient:      double   — β, default 0.70
liquidityPreference:         double   — 0.0–1.0
complexityTolerance:         double   — 0.0–1.0
regretSensitivity:           double   — 0.0–1.0 (ρ)
growthOrientation:           double   — 0.0–1.0
behavioralConsistencyScore:  double
archetype:                   UtilityArchetype
calibrationSource:           UtilityCalibrationSource   — QUESTIONNAIRE | INFERRED | LEARNED
learningRate:                double   — default 0.15, decreases as LearningSnapshot.maturity increases
```

- **5 archetypes:** GrowthMaximizer, LossAvoider, LiquidityPreserver, TaxOptimizer, BalancedGrowth.
- **Pipeline:** Consumed at Step 5; parameters updated by DecisionLearningEngine after each completed cycle.

#### `UtilityScore`

```
candidateId:                  String
netUtility:                   double   — ∈ [−1.0, 1.0], after calibrationConfidence adjustment
rawUtility:                   double   — EB − EC − R − BR − Rg − C − LL
calibrationConfidence:        double   — 0.5×(1−behaviorUncertainty) + 0.5×learningMaturity
expectedBenefit:              double   — INR/month before normalization
expectedCost:                 double
riskPenalty:                  double
behavioralResistancePenalty:  double
regretPenalty:                double
complexityPenalty:            double
liquidityLossPenalty:         double
percentileRank:               double   — 0.0–1.0 relative to session candidates
rank:                         int
topBenefit:                   String
topCostFactor:                String
utilityNarrative:             String   — mandatory, never null
sensitivityToLossAversion:    double
stateModifierApplied:         bool
stateModifierReason:          String?
```

- **Pipeline:** Produced at Step 5 for each permissible candidate; used at Step 8 (ConfidenceAggregator) and Step 9 (ExplainabilityEngine).

---

### 3.5 Counterfactual Context

**Package:** `mobile/lib/domain/simulation/`

#### `CounterfactualType` (enum)

```
ACTION | DELAY | MAGNITUDE | SHOCK | COMMITMENT
```

#### `ProjectionPoint`

```
month:               int      — 0 = today
value:               double   — INR corpus / EF balance at this month
cumulativeSavings:   double
event:               String?  — "SIP target reached"
```

#### `ScenarioProjection`

```
points:      List<ProjectionPoint>
finalValue:  double
horizon:     int     — months
assumption:  String  — mandatory, non-empty
returnRate:  double
confidence:  double  — see 4-factor confidence model in Section 8
```

#### `CounterfactualDelta`

```
rupees:     double   — alternativeProjection.finalValue − baselineProjection.finalValue
months:     int?     — for goal timeline comparisons
percentage: double
direction:  DeltaDirection   — BETTER | WORSE | NEUTRAL
label:      String           — "₹12L less" / "3 months sooner"
```

#### `CounterfactualScenario`

```
id:                     String
type:                   CounterfactualType
decisionId:             String?
description:            String
baselineProjection:     ScenarioProjection   — "current trajectory"
alternativeProjection:  ScenarioProjection
delta:                  CounterfactualDelta
narration:              String   — from NarrationEngine, mandatory
confidence:             double   — ≤ parent FinancialFacts overall confidence
assumptions:            List<String>   — at least 1
limitations:            List<String>   — at least 1 when confidence < 0.80
generatedAt:            DateTime
```

#### `CounterfactualPair`

```
baseline:     CounterfactualScenario
alternative:  CounterfactualScenario
headline:     String
callToAction: String
```

#### `CounterfactualSet`

```
decisionId:                  String
actionCounterfactual:        CounterfactualPair?
delayCounterfactuals:        List<CounterfactualPair>   — today, +3mo, +6mo, +12mo
magnitudeCounterfactuals:    List<CounterfactualPair>   — min, recommended, max
shockCounterfactuals:        List<CounterfactualPair>   — INCOME_DROP_20/30/50, MEDICAL_2L/5L
commitmentCounterfactuals:   List<CounterfactualPair>
overallConfidence:           double
```

- **Invariants:** `baseline` always represents current trajectory (accept today); `delta.rupees = alt.finalValue − base.finalValue`; `confidence ≤ parent FinancialFacts.overallConfidence`; `assumptions` non-empty.
- **Pipeline:** Produced at Step 6 for top 3 candidates; narration consumed at Step 9 (ExplainabilityEngine); `CounterfactualPair` surfaces in `RankedRecommendation`.

---

### 3.6 Challenge Context

**Package:** `mobile/lib/domain/reasoning/challenge/`

#### `ChallengeType` (enum)

```
liquidity | debt | behavior | tax | timing | risk
```

#### `ChallengeOutcome` (enum)

```
confirmed | replaced | modified
```

#### `ChallengeResult`

```
challenger:           ChallengeType
outcome:              ChallengeOutcome
proposedReplacement:  DecisionType?    — null when confirmed
reason:               String           — user-readable, mandatory
confidenceDelta:      double           — ∈ [−1.0, 0.0] except tax (+0.05 allowed)
triggeringAxisScore:  double
evidence:             List<String>
```

#### `ChallengeLayerResult`

```
originalCandidate:  DecisionType
finalCandidate:     DecisionType
results:            List<ChallengeResult>   — always 6 (one per ChallengeType)
wasChanged:         bool   — computed: any result.outcome != confirmed
totalConfidenceDelta: double   — sum of all confidenceDeltas
activeResults:      List<ChallengeResult>   — non-confirmed results
challengeReasons:   List<String>
```

- **Invariants:** Always 6 results; at most 1 replacement accepted (priority: Liquidity > Debt > Risk > Behavior > Tax > Timing); replacement requires demonstrated utility differential; `totalConfidenceDelta ≤ 0.05`; all results recorded regardless of outcome.
- **Pipeline:** Produced at Step 7; `totalConfidenceDelta` applied at Step 8; `challengeReasons` surfaced in `ExplanationData.alternatives[]` at Step 9.

---

### 3.7 Constitution Context

**Package:** `mobile/lib/domain/reasoning/constitution/`

#### `ConstitutionLevel` (enum)

```
system | user | goal
```

#### `RuleCategory` (enum)

```
ethicalScreen | safetyFloor | assetProtection | debtConstraint | quantitativeCeiling | custom
```

#### `ViolationSeverity` (enum)

```
hard   — candidate eliminated from pipeline
soft   — warning added to Explanation.limitations[]
```

#### `ConstitutionRule`

```
ruleId:             String   — ULID
level:              ConstitutionLevel
category:           RuleCategory
description:        String
constraint:         ConstitutionConstraint   — function: (candidate, context) → bool (true = violation)
violationSeverity:  ViolationSeverity
violationMessage:   String   — user-readable
protectedGoalId:    String?  — null for system and user rules
createdAt:          DateTime
expiresAt:          DateTime?
isActive:           bool
```

#### `ConstitutionViolation`

```
rule:               ConstitutionRule
violatingCandidate: String
violationDetail:    String
severity:           ViolationSeverity
detectedAt:         DateTime
```

#### `FinancialConstitution`

```
userId:   String
rules:    List<ConstitutionRule>
```

- **Accessors:** `systemRules`, `userRules`, `rulesForGoal(goalId)`, `hardRules`, `softRules`.
- **Pipeline:** Loaded into `FinancialReasoningContext.constitution` before Step 1; consumed at Step 4 (candidate pruning); consumed again at Step 9 (partner program constitution check).

#### `ConstitutionCheckResult`

```
candidate:      DecisionType
isPermissible:  bool   — false if any hard violation
violations:     List<ConstitutionViolation>
warningMessages: List<String>   — from soft violations, for Explanation.limitations[]
```

- **Invariants:** `reviewPastDecision` always passes all system rules; system rules always apply even when `constitution` is null; hard-violated candidates never receive utility scores; all violations audited in `DecisionAudit.constitutionViolations[]`.

---

### 3.8 Output Context

**Package:** `mobile/lib/domain/reasoning/output/`

#### `ConfidenceGraph`

```
dataConfidenceFactor:          double   — from DataConfidenceReport.recommendationConfidenceCap
decisionConfidenceFactor:      double   — weighted avg of 6 decision axis scores (v1 preserved)
behaviorConfidenceFactor:      double   — from BehaviorInterpretation.overallConfidence
historicalAccuracyFactor:      double   — from LearningSnapshot.maturity
compoundConfidence:            double   — product of 4 factors (v1 formula, unchanged)
calibrationConfidence:         double   — 0.5×(1−behaviorUncertainty) + 0.5×learningMaturity
netUtility:                    double   — top candidate utility score
rankingScore:                  double   — netUtility × min(1, compoundConf/0.20)
challengeAdjustedConfidence:   double   — compoundConfidence + ChallengeLayerResult.totalConfidenceDelta
policyId:                      String   — which policy was active
policyLabel:                   String   — "Salaried — Build Phase"
policyReason:                  String   — why this policy was selected
beliefSetConfidence:           double   — BeliefSet.overallConfidence
counterfactualConfidence:      double   — CounterfactualSet.overallConfidence
constitutionCompliant:         bool
constitutionStatement:         String   — "All 8 system rules passed. 0 user rules triggered."
```

#### `RankedRecommendation`

```
rank:               int                 — 1 = primary
candidate:          DecisionCandidate
utilityScore:       UtilityScore
counterfactualSet:  CounterfactualSet?  — full for rank 1, condensed for ranks 2–4
explanation:        ExplanationData?    — full for rank 1, headline-only for ranks 2–4
challengeResult:    ChallengeLayerResult? — only for rank 1
```

#### `RecommendationPortfolio`

```
primary:                  RankedRecommendation   — rank 1, fully hydrated
alternatives:             List<RankedRecommendation>   — ranks 2–4, condensed
consideredButRejected:    List<DecisionCandidate>   — CandidateSet.pruned
constitutionStatement:    String
confidenceGraph:          ConfidenceGraph
generatedAt:              DateTime
engineVersion:            String
```

---

## 4. Updated FinancialReasoningContext

The v2 context adds four new fields. Three are optional (null-safe for v1 backward compatibility). One (`policy`) becomes required in Sprint 11C (Phase 3 of migration).

```dart
@immutable
class FinancialReasoningContext {
  const FinancialReasoningContext({
    required this.facts,
    required this.dataConfidence,
    // ── v2 additions ──────────────────────────────────────────────────
    this.policy,           // NEW: required in Sprint 11C; optional in 11A–11B
    this.beliefs,          // NEW: optional; populated by BeliefInferenceEngine
    this.constitution,     // NEW: optional; null means system rules only
    // ── existing fields (unchanged) ───────────────────────────────────
    this.behavior,
    this.learningSnapshot,
    this.goals = const [],
    this.contextLabel,
  });

  // Existing (v1 — unchanged)
  final FinancialFacts facts;
  final DataConfidenceReport dataConfidence;
  final BehaviorInterpretation? behavior;
  final LearningSnapshot? learningSnapshot;
  final List<GoalSnapshot> goals;
  final String? contextLabel;

  // New (v2)
  final DecisionPolicy? policy;                // null → fallback to DecisionAxis.weight (Sprint 11A–11B)
  final BeliefSet? beliefs;                    // null → engines use v1 threshold logic
  final FinancialConstitution? constitution;   // null → system rules only applied

  // Convenience accessors
  BeliefSet get beliefSetOrEmpty => beliefs ?? BeliefSet.empty();
  FinancialConstitution get effectiveConstitution =>
      constitution ?? FinancialConstitution.systemOnly();
}
```

### What Is New vs v1

| Field            | v1          | v2 Status                         | Effect When Null                                            |
| ---------------- | ----------- | --------------------------------- | ----------------------------------------------------------- |
| `policy`         | Not present | Optional → Required in Sprint 11C | Fallback to `DecisionAxis.weight` static constants          |
| `beliefs`        | Not present | Optional                          | Engines use v1 threshold logic directly on `FinancialFacts` |
| `constitution`   | Not present | Optional                          | Only system rules (`SYS-001` through `SYS-008`) applied     |
| All other fields | Present     | Unchanged                         | —                                                           |

The null-safety design means that a v1 call site that constructs `FinancialReasoningContext` without the new fields compiles and behaves identically to v1. No existing use case, widget, or test breaks at Sprint 11A entry.

---

## 5. Bounded Contexts and Dependency Graph

```
 PURE CONTEXTS (no external dependencies — domain layer only)
 ┌─────────────────────────────────────────────────────────────────┐
 │                                                                 │
 │   FinancialFacts ──────────────────────────────────────────┐   │
 │   (14 raw facts, FinancialFact<T> with provenance)         │   │
 │                                                             │   │
 │   FinancialPolicy ─────────────────────────────────────┐   │   │
 │   (constants: EMI limit, SIP rates, 80C limit, etc.)   │   │   │
 │                                                         │   │   │
 └─────────────────────────────────────────────────────────┼───┼───┘
                                                           │   │
         ╔═══════════╗                                     │   │
         ║  POLICY   ║◄────────────────────────────────────┘   │
         ║  CONTEXT  ║                                          │
         ║           ║  Reads: FinancialFacts, FinancialPolicy  │
         ║ DecisionPolicy                                       │
         ║ AxisWeightProfile                                    │
         ║ PolicyThresholds                                     │
         ╚═══════╦═══╝                                          │
                 │                                              │
         ╔═══════▼═══╗                                          │
         ║  BELIEF   ║◄─────────────────────────────────────────┘
         ║  CONTEXT  ║
         ║           ║  Reads: FinancialFacts, FinancialPolicy,
         ║ BeliefSet ║          PolicyThresholds (via policy),
         ║ FinancialBelief       BehaviorInterpretation
         ╚═══════╦═══╝
                 │
         ╔═══════▼════════╗     ╔═══════════════════╗
         ║  CANDIDATE     ║◄────║  CONSTITUTION     ║
         ║  CONTEXT       ║     ║  CONTEXT          ║
         ║                ║     ║                   ║
         ║ CandidateSet   ║     ║ FinancialConstitution
         ║ DecisionCandidate    ║ ConstitutionRule  ║
         ║ ActionType     ║     ╚═══════════════════╝
         ╚═══════╦════════╝
                 │  (permissible candidates only)
         ╔═══════▼════════╗
         ║  UTILITY       ║
         ║  CONTEXT       ║
         ║                ║  Reads: CandidateSet, PolicyWeights,
         ║ UtilityModel   ║         BeliefSet, BehaviorInterpretation,
         ║ UtilityScore   ║         LearningSnapshot, BehaviorState
         ╚═══════╦════════╝
                 │
        ┌────────┴────────┐
        │                 │
╔═══════▼══════╗  ╔═══════▼══════╗
║ COUNTERFACTUAL  ║  CHALLENGE   ║
║ CONTEXT      ║  ║  CONTEXT     ║
║              ║  ║              ║
║ CounterfactualSet  ChallengeLayerResult
║ ScenarioProjection  ChallengeResult
║ CounterfactualDelta             ║
╚══════════════╝  ╚══════════════╝
        │                 │
        └────────┬────────┘
                 │
         ╔═══════▼════════╗
         ║  OUTPUT        ║
         ║  CONTEXT       ║
         ║                ║
         ║ ConfidenceGraph║
         ║ RecommendationPortfolio
         ║ RankedRecommendation    ║
         ╚════════════════╝

DEPENDENCY ARROWS (→ means "depends on / reads from"):
  Policy       → FinancialFacts, FinancialPolicy
  Belief       → FinancialFacts, FinancialPolicy, PolicyThresholds, BehaviorInterpretation
  Candidate    → FinancialFacts, BeliefSet, GoalSnapshots, LearningSnapshot
  Constitution → (self-contained rule set loaded from persistence)
  Utility      → CandidateSet, PolicyWeights, BeliefSet, BehaviorInterpretation, LearningSnapshot
  Counterfactual → FinancialFacts, GoalSnapshots (pure math — no engine dependencies)
  Challenge    → CandidateSet (top candidate), FinancialReasoningContext, FinancialPolicy
  Output       → All prior contexts

PURE CONTEXTS (no Flutter, no I/O, no infrastructure imports):
  Policy, Belief, Candidate, Constitution, Utility, Counterfactual, Challenge, Output

COMPOSITE CONTEXTS (read from multiple pure contexts):
  Output (reads all)
  Challenge (reads Candidate + Policy + Belief)
  Utility (reads Candidate + Policy + Belief + Behavioral)
```

---

## 6. Key Interfaces

All interfaces live in `mobile/lib/domain/engines/` and follow the canonical PennyWise architecture invariant: domain interfaces, infrastructure implementations.

### 6.1 PolicySelector

```
interface PolicySelector {
  // Selects the appropriate DecisionPolicy for this user context.
  // MUST return a valid policy — never null. Falls back to SalariedBuildPolicy
  // when facts are insufficient for precise selection.
  //
  // Invariants:
  //   - Never returns a policy with weights.sum != 1.0 (± 0.001)
  //   - ageYears >= 60 ALWAYS returns RetiredPolicy
  //   - emergencyFundMonths < 1.0 ALWAYS returns a Survive-category policy
  //   - No side effects — pure function of inputs
  DecisionPolicy select(
    FinancialFacts facts,
    BehaviorInterpretation? behavior,
    UserArchetype archetype,
    PolicyStateRecord? existingRecord,
  )
}
```

### 6.2 BeliefInferenceEngine

```
interface BeliefInferenceEngine {
  // Infers named financial beliefs from raw facts and behavioral signals.
  // Returns BeliefSet.empty() when required facts are absent (never throws).
  //
  // Invariants:
  //   - All beliefs have effectiveConfidence >= 0.10
  //   - No two beliefs with same FinancialBeliefType in output
  //   - lifeStage belief derived last (after all category beliefs computed)
  //   - BeliefSet.overallConfidence <= DataConfidenceReport.recommendationConfidenceCap
  //   - Never reads from repositories, network, or storage
  BeliefSet infer(
    FinancialFacts facts,
    BehaviorInterpretation? behavior,
    List<GoalSnapshot> goals,
    DataConfidenceReport dataConfidence,
    FinancialFactSnapshot? priorSnapshot,   // for DT-005 trending rule
  )
}
```

### 6.3 CandidateGenerator

```
interface CandidateGenerator {
  // Generates all applicable decision candidates and prunes ineligible ones.
  // Returns CandidateSet with viable.length >= 2 always.
  //
  // Invariants:
  //   - Synchronous and pure — no I/O, no async, same context = same output
  //   - viable contains no duplicate ActionType values
  //   - Layer 3 candidates absent when any Layer 1 candidate is critical
  //   - All pruned candidates carry non-empty rejectionReason
  //   - Fallback to ruleOfThumb candidates if viable.length < 2
  CandidateSet generate(FinancialReasoningContext ctx)
}
```

### 6.4 ConstitutionChecker

```
interface ConstitutionChecker {
  // Evaluates all active constitution rules against each candidate.
  // Hard violations eliminate candidates; soft violations add warnings.
  //
  // Invariants:
  //   - System rules always applied even when constitution is null
  //   - reviewPastDecision always passes system rules
  //   - Hard-violated candidates NEVER appear in returned permissible list
  //   - All violations audited in ConstitutionCheckResult
  //   - No side effects — does not modify constitution or candidates
  List<ConstitutionCheckResult> check(
    List<DecisionCandidate> candidates,
    FinancialReasoningContext context,
    FinancialConstitution? userConstitution,
  )
}
```

### 6.5 UtilityEngine

```
interface UtilityEngine {
  // Scores each permissible candidate with personalized utility formula:
  //   rawUtility = EB - EC - Risk - BehavioralResistance - Regret - Complexity - LiquidityLoss
  //   netUtility = clamp(rawUtility / monthlyIncome × calibrationConfidence, -1.0, 1.0)
  //
  // Invariants:
  //   - netUtility ∈ [-1.0, 1.0] for all candidates
  //   - All terms expressed in INR/month before normalization
  //   - calibrationConfidence ∈ [0.0, 1.0]; ≤ 0.10 for new users
  //   - Every UtilityScore has a non-null utilityNarrative
  //   - A candidate with netUtility < 0 is only selected if ALL candidates < 0
  ScoredCandidateSet score(
    List<DecisionCandidate> permissibleCandidates,
    FinancialReasoningContext ctx,
    DecisionConfidenceReport confidenceReport,
    UtilityModel utilityModel,
  )
}
```

### 6.6 CounterfactualEngine

```
interface CounterfactualEngine {
  // Generates projection scenarios for each candidate.
  // Returns CounterfactualSet with up to 12 scenarios (1 action + 4 delay + 3 magnitude
  // + 3 shock + 1 commitment).
  //
  // Invariants:
  //   - Synchronous — completes in < 50ms per candidate
  //   - No I/O — all inputs via FinancialFacts and GoalSnapshots
  //   - baseline always represents current trajectory (accept today)
  //   - confidence <= parent FinancialFacts.overallConfidence
  //   - assumptions non-empty; limitations non-empty when confidence < 0.80
  //   - Only surfaces scenarios where confidence >= 0.30 and |delta.rupees| >= 10,000
  CounterfactualSet generate(
    DecisionCandidate candidate,
    FinancialFacts facts,
    List<GoalSnapshot> goals,
    double behaviorFactor,   // 1.0 until BehavioralEngine calibrated
  )
}
```

### 6.7 ChallengeLayer

```
interface ChallengeLayer {
  // Runs 6 adversarial challenges against the top-ranked candidate.
  // May replace, modify, or confirm the candidate.
  //
  // Invariants:
  //   - Always runs exactly 6 challenges (one per ChallengeType)
  //   - At most 1 replacement accepted (priority: Liquidity > Debt > Risk > Behavior > Tax > Timing)
  //   - Replacement requires demonstrated utility differential (exception: EF < 1 month)
  //   - totalConfidenceDelta <= +0.05 (challenges are critics, not amplifiers, except tax deadline)
  //   - All 6 ChallengeResult objects recorded regardless of outcome
  //   - ChallengeResult.reason always user-readable
  ChallengeLayerResult challenge(
    DecisionCandidate candidate,
    FinancialReasoningContext context,
    DecisionConfidenceReport confidenceReport,
  )
}
```

### 6.8 ConfidenceAggregator

```
interface ConfidenceAggregator {
  // Synthesizes all pipeline stage outputs into a single ConfidenceGraph.
  //
  // Invariants:
  //   - compoundConfidence preserved exactly from v1 formula
  //     (dataConf × decisionConf × behaviorConf × historicalAcc)
  //   - challengeAdjustedConfidence = compoundConfidence + totalConfidenceDelta,
  //     clamped to [0.03, 1.0]
  //   - rankingScore = netUtility × min(1, compoundConf / 0.20)
  //   - constitutionCompliant = true only when zero hard violations detected
  ConfidenceGraph aggregate(
    DecisionConfidenceReport v1Report,
    UtilityScore topCandidateScore,
    ChallengeLayerResult challengeResult,
    BeliefSet beliefSet,
    CounterfactualSet counterfactuals,
    DecisionPolicy policy,
    List<ConstitutionViolation> violations,
  )
}
```

---

## 7. Global Invariants

These invariants span ALL components. Any implementation violating them is incorrect regardless of individual component correctness.

### I-1: Pipeline Always Produces at Least One Recommendation

```
assert(portfolio.primary != null,
  'RecommendationPortfolio must always have a primary recommendation. '
  'Fallback: reviewPastDecision is constitutionally permissible under all system rules.')
```

When all candidates are constitution-blocked: emit `reviewPastDecision`. When all candidates have negative utility: emit "stay the course" recommendation. The pipeline never returns empty.

### I-2: Every Primary Recommendation Has a Counterfactual

```
assert(portfolio.primary.counterfactualSet != null,
  'Primary recommendation must have a CounterfactualSet. '
  'Minimum viable: one ACTION type scenario with confidence >= 0.30.')
```

A recommendation without a counterfactual cannot fulfill the behavioral mission ("tell them what will be true depending on what they do next").

### I-3: Constitution Violations Never Reach the User

```
assert(
  portfolio.primary.candidate.rejectionReason == null,
  'A constitutionally hard-violated candidate must never appear as primary or alternative.')
assert(
  portfolio.alternatives.every((r) =>
    !constitutionViolations.any((v) => v.violatingCandidate == r.candidate.actionType.name)),
  'Hard-violated candidates must not appear in alternatives either.')
```

### I-4: Confidence Never Exceeds the Data Cap

```
assert(
  confidenceGraph.compoundConfidence <=
    dataConfidenceReport.recommendationConfidenceCap,
  'compoundConfidence must be bounded by the data quality cap.')
assert(
  beliefSet.overallConfidence <=
    dataConfidenceReport.recommendationConfidenceCap,
  'BeliefSet overallConfidence must be bounded by the data quality cap.')
```

### I-5: No Component Performs I/O

```
// All 8 engines (PolicySelector, BeliefInferenceEngine, CandidateGenerator,
// ConstitutionChecker, UtilityEngine, CounterfactualEngine, ChallengeLayer,
// ConfidenceAggregator) must be:
//   - Synchronous
//   - Pure functions of their inputs (same input → same output)
//   - Free of repository calls, network requests, file reads, or side effects
//
// Violation category: infrastructure (I/O) leaking into domain logic.
// Consequence: non-deterministic behavior, untestable engines, broken DDD invariant.
```

### I-6: All Pipeline Steps Are Synchronous and Pure

The entire pipeline from Step 1 (PolicySelector) to Step 10 (RecommendationPortfolio assembly) executes synchronously. Any future async requirement (e.g., Monte Carlo in Phase 11) must be wrapped at the use case layer — not introduced into engine interfaces.

### I-7: Axis Weights Always Sum to 1.0

```
assert(
  (policy.weights.cashFlow + policy.weights.liquidity + policy.weights.goalImpact +
   policy.weights.behavior + policy.weights.taxes + policy.weights.opportunityCost
  - 1.0).abs() < 0.001,
  'AxisWeightProfile must sum to 1.0 (±0.001).')
```

### I-8: No Single Axis Weight Below 0.02 or Above 0.55

Prevents both degenerate single-axis collapse and effectively silenced axes that lose explainability.

### I-9: CandidateSet.viable Always Has >= 2 Entries

Ensures the pipeline always has at least two ranked alternatives, preserving the portfolio contract.

### I-10: UtilityScore.utilityNarrative Is Always Non-Null

A recommendation without a human-readable utility explanation violates Trust Law 1 (Explainability Before Action).

### I-11: Challenge Layer Runs Exactly 6 Challenges

`ChallengeLayerResult.results.length == 6` always. Confirmed results are included — they are evidence the recommendation survived scrutiny.

### I-12: Retirement Policy Overrides All User Selections

When `ageYears >= 60` or `lifecycleStage == retirement`: `RetiredPolicy` is selected regardless of user profile, declared archetype, or manual override.

---

## 8. Confidence Propagation Model

Confidence flows through the pipeline in four distinct layers, compounding downward (never upward beyond what data quality permits).

### Layer 1: Fact → Belief Confidence

```
BeliefConfidence = RuleBaseConfidence × ProductOf(FactConfidences) × DecayFactor

Where:
  RuleBaseConfidence = confidence computed by the inference rule (0.60–0.90 depending on rule)
  ProductOf(FactConfidences) = min(fact_1.confidence, ..., fact_n.confidence)
    — the weakest required fact caps the entire belief
  DecayFactor = max(0.20 / rawConfidence, 1.0 - (0.10 × hoursOverDecayStart / 24))
    — starts at 36h, floors effective confidence at 0.20, expires at 24h (SMS/AA) or 72h (manual)
```

A belief derived from a fact with confidence 0.35 (limited transaction history) cannot have confidence above 0.35, regardless of how cleanly the rule fired.

### Layer 2: Belief → Candidate Applicability Confidence

Candidates carry `magnitudeConfidence` derived from the confidence of the facts they depend on:

```
magnitudeConfidence = min(requiredFact_1.confidence, requiredFact_2.confidence, ...)
```

Candidates generated via `MagnitudeBasis.ruleOfThumb` have `magnitudeConfidence ≤ 0.30` regardless of fact quality.

### Layer 3: Utility Score Confidence

```
calibrationConfidence = 0.5 × (1 − behaviorUncertainty) + 0.5 × learningMaturity

Where:
  behaviorUncertainty = BehaviorInterpretation.dimensions[presentBias].uncertainty
                        (proxy for overall behavioral parameter uncertainty)
  learningMaturity = LearningSnapshot.maturity (0.0 new user → 1.0 fully calibrated)

For new users (learningMaturity = 0, behaviorUncertainty = 0.95):
  calibrationConfidence ≈ 0.5 × 0.05 + 0.5 × 0.0 = 0.025
  → Very conservative utility estimates for uncalibrated users

finalUtility = rawUtility × calibrationConfidence (clamped to [-1.0, 1.0])
```

### Layer 4: Counterfactual Confidence

Four-factor model:

```
scenarioConfidence = dataCoverage × assumptionStability × horizonPenalty × behaviorPrior

dataCoverage:        0.10 (no source) → 0.90 (AA data with full coverage)
assumptionStability: 0.65–0.95 depending on which facts are estimated vs. verified
horizonPenalty:      0.95 (1–5yr) × 0.90 (5–10yr) × 0.80 (10–20yr) × 0.70 (20+yr)
behaviorPrior:       0.50 if BehavioralEngine uncalibrated; BehaviorConfidence.overall otherwise
```

### Layer 5: Challenge Confidence Delta

```
challengeAdjustedConfidence = compoundConfidence + ChallengeLayerResult.totalConfidenceDelta

totalConfidenceDelta ≤ 0.05 (challenges only reduce confidence except for tax deadline +0.05)
floor: max(0.03, challengeAdjustedConfidence)
```

### ConfidenceGraph Structure (Multi-Dimensional)

The `ConfidenceGraph` preserves the v1 `compoundConfidence` scalar exactly (backward compatible) and adds new v2 dimensions alongside it:

```
v1 (preserved):
  dataConfidenceFactor          — input quality
  decisionConfidenceFactor      — financial health across 6 axes
  behaviorConfidenceFactor      — behavioral calibration quality
  historicalAccuracyFactor      — learning history quality
  compoundConfidence            — product of all four (0.00–0.45 typical range)
  strength                      — RecommendationStrength label

v2 additions:
  calibrationConfidence         — utility model calibration quality
  netUtility                    — personalized value score for top candidate
  rankingScore                  — netUtility × min(1, compoundConf/0.20)
  challengeAdjustedConfidence   — after challenge layer delta applied
  policyId / policyLabel / policyReason
  beliefSetConfidence           — BeliefSet.overallConfidence
  counterfactualConfidence      — CounterfactualSet.overallConfidence
  constitutionCompliant         — hard rules passed
  constitutionStatement         — audit summary
```

The v1 `compoundConfidence` formula is **not replaced** by v2. It remains the source of the user-facing confidence label ("High Confidence", "Moderate Confidence"). The `netUtility` is a ranking signal and narration input — it is never shown as a raw number to users.

---

## 9. The v2 Output: RecommendationPortfolio

### Primary Recommendation (Fully Hydrated)

```
primary: RankedRecommendation {
  rank: 1
  candidate: DecisionCandidate {
    actionType: startSip
    family: investment
    headline: "Start a ₹2,000/month SIP for your retirement goal"
    rationale: "Your emergency fund is funded (6.5 months) and you have ₹8,000 surplus available."
    suggestedMagnitude: CandidateMagnitude {
      monthlyAmount: 2000
      targetAmount: 1_15_00_000   // ₹1.15 Cr
      horizon: 240                // 20 years
      basis: formulaBased
    }
    magnitudeConfidence: 0.78
    riskClass: incrementalRisk
    behaviorDifficulty: moderate
    pyramidLayer: 2
    applicabilitySignals: ["EF >= 3 months", "Goal horizon > 36 months", "Surplus >= ₹500"]
  }
  utilityScore: UtilityScore {
    netUtility: 0.41
    rawUtility: 0.53
    calibrationConfidence: 0.31
    expectedBenefit: 4241.0     // INR/month equivalent
    behavioralResistancePenalty: 2280.0
    complexityPenalty: 1500.0
    utilityNarrative: "Strongest long-term value action given your 20-year horizon;
                       behavioral resistance is the primary cost factor."
  }
  counterfactualSet: CounterfactualSet {
    actionCounterfactual: CounterfactualPair {
      headline: "₹1.15Cr retirement corpus in 20 years vs. ₹0 from investing today"
      callToAction: "Start ₹2,000 SIP today"
    }
    delayCounterfactuals: [
      { description: "Wait 6 months", delta: { rupees: -1200000, label: "₹12L less" } }
      { description: "Wait 12 months", delta: { rupees: -2600000, label: "₹26L less" } }
    ]
    shockCounterfactuals: [
      { description: "If income drops 30%", delta: { label: "SIP sustainable — ₹2,000 < ₹4,200 surplus after shock" } }
    ]
  }
  explanation: ExplanationData {
    because: [
      "Emergency fund covers 6.5 months — above the 6-month target."
      "Monthly surplus of ₹8,000 comfortably supports ₹2,000 SIP."
      "Retirement goal has 240 months horizon — equity returns at 10% justified."
    ]
    alternatives: [
      "Liquidity Challenge: confirmed — emergency fund is adequate."
      "Debt Challenge: confirmed — no debt present."
      "Behavior Challenge: moderate resistance detected; one-step setup recommended."
    ]
    limitations: [
      "Behavioral calibration is early — utility estimate will improve after 3 completed cycles."
      "Return rate (10% p.a.) is an estimate; actual returns will vary."
    ]
    confidenceDrivers: ["Policy: Salaried — Build Phase", "Belief: Safety Net Strong (0.87 confidence)"]
  }
  challengeResult: ChallengeLayerResult {
    originalCandidate: startSip
    finalCandidate: startSip   // confirmed by all 6 challenges
    wasChanged: false
    totalConfidenceDelta: -0.05   // behavior challenge applied mild penalty
  }
}
```

### 2nd and 3rd Ranked Alternatives (Condensed)

```
alternatives: [
  RankedRecommendation {
    rank: 2
    candidate: { actionType: maximize80C, headline: "Maximize your 80C tax saving" }
    utilityScore: { netUtility: 0.29, utilityNarrative: "₹18,000 direct tax saving; Q4 urgency applies." }
    counterfactualSet: (condensed — action counterfactual only)
    // challengeResult: omitted for alternatives
  },
  RankedRecommendation {
    rank: 3
    candidate: { actionType: stepUpSip, headline: "Enable 10% annual SIP step-up" }
    utilityScore: { netUtility: 0.19, utilityNarrative: "Low friction; high long-term compounding gain." }
  }
]
```

### Considered But Rejected

```
consideredButRejected: [
  DecisionCandidate {
    actionType: rebalancePortfolio
    rejectionReason: "layer_1_critical: emergency fund must be addressed first"
  }
]
```

### Confidence Graph and Constitution Statement

```
confidenceGraph: ConfidenceGraph {
  compoundConfidence: 0.28
  challengeAdjustedConfidence: 0.23
  netUtility: 0.41
  rankingScore: 0.38
  policyLabel: "Salaried — Build Phase"
  beliefSetConfidence: 0.81
  constitutionCompliant: true
  constitutionStatement: "8 system rules passed. 2 user rules checked — 0 triggered."
}
```

---

## 10. Migration Strategy from v1

The migration is strictly additive. No existing behavior changes until explicitly enabled. The v1 `RuleBasedFinancialReasoningEngine` remains in production throughout Phases A–D.

### Phase A — Add Domain Types (Sprint 11A)

**What changes:**

- All new domain types added to `mobile/lib/domain/reasoning/` sub-packages (policy, beliefs, candidates, utility, constitution, output)
- `FinancialReasoningContext` gains `policy?`, `beliefs?`, `constitution?` as nullable fields
- `BeliefSet.empty()`, `DecisionPolicy.default()`, `FinancialConstitution.systemOnly()` factory constructors ensure null-safe consumption
- `PolicySelector` implemented — selects correct policy but not yet wired into any engine
- New test suites for all domain invariants

**What does NOT change:**

- `RuleBasedFinancialReasoningEngine` — zero modification
- `DecisionAxis.weight` static constants — kept as fallback
- All use cases, widgets, DI registrations
- `flutter analyze` must pass with zero errors

**Verification:** All existing golden tests pass. All new domain invariant tests pass. No behavioral change in production.

---

### Phase B — Shadow Mode (Sprint 11B–11D)

**What changes:**

- `BeliefInferenceEngine` runs on every `GetDashboardFeedUseCase` call but output is logged only
- `PolicyAwareReasoningEngine` created — reads from `ctx.policy.weights` when `policy != null`, falls back to `DecisionAxis.weight` when null
- `CandidateGenerator` runs in parallel — output observable in debug logs
- `UtilityEngine` computes `UtilityScore` for all candidates — stored in decision record for retrospective analysis but does not influence ranking
- DI: `sl.registerLazySingleton<FinancialReasoningEngine>(() => PolicyAwareReasoningEngine(...))`

**What does NOT change:**

- Recommendation selection — still uses v1 axis-score ranking
- All widget behavior unchanged
- `DecisionAxis.weight` still provides fallback weights

**Verification:** Correlation between v1 `compoundConfidence` and v2 `netUtility` measured. If they agree on top candidate in >= 85% of cases, Phase C proceeds.

---

### Phase C — v2 Ranking Active (Sprint 11E–11G)

**What changes:**

- Ranking signal becomes `rankingScore = netUtility × min(1, compoundConf/0.20)` when `utilityEngineOverrideEnabled = true` (feature flag)
- `FinancialReasoningContext.policy` becomes required (non-nullable)
- `ConstitutionChecker` active — hard-violation candidates removed before scoring
- `ChallengeLayer` active behind `EngineFlag.challengeLayerEnabled`
- `CounterfactualSet` attached to top candidate in `DecisionResponse`
- `DecisionConfidenceReport` gains `policyId`, `policyLabel`, `policyReason` fields

**What does NOT change:**

- `RuleBasedFinancialReasoningEngine` available via feature flag as fallback
- `DecisionAxis.weight` deprecated (`@Deprecated`) but not yet removed

**Verification:** v2 recommendations show measurably higher acceptance rate than v1 (statistically significant at 90% confidence) across >= 30 completed decision cycles.

---

### Phase D — A/B Test v2 on Percentage of Users (Sprint 11H+)

**What changes:**

- v2 engine is the default path
- `RecommendationPortfolio` replaces single `Decision` in dashboard rendering
- `BankProgramSlider` renamed to "Execution Options" sourced from `portfolio.primary`
- `CandidatePortfolio.considered` populates explainability panel ("We also considered...")

**What does NOT change:**

- `DecisionResponse` envelope remains backward compatible (new fields are additive)
- Java backend `DecisionResponse` unchanged — Flutter `TodayDecisionModel` parses both formats

---

### Phase E — v1 Deprecated, v2 Canonical (Post-Sprint 11H)

**What changes:**

- `DecisionAxis.weight` getter removed
- `RuleBasedFinancialReasoningEngine` removed from production DI (retained in test utilities as reference)
- `FinancialReasoningContext.policy` is non-nullable and required at all call sites

**Regression requirement before Phase E:** v2 top recommendation type must match v1 type in >= 92% of synthetic test profiles.

### Migration Compatibility Matrix

| Component                           | Phase A     | Phase B              | Phase C        | Phase D        | Phase E        |
| ----------------------------------- | ----------- | -------------------- | -------------- | -------------- | -------------- |
| `DecisionAxis.weight`               | unchanged   | unchanged            | @Deprecated    | @Deprecated    | removed        |
| `RuleBasedFinancialReasoningEngine` | unchanged   | available            | fallback flag  | fallback flag  | removed        |
| `PolicyAwareReasoningEngine`        | domain only | available, fallback  | default        | default        | only option    |
| `BeliefInferenceEngine`             | domain only | shadow logs          | active         | active         | active         |
| `CandidateGenerator`                | domain only | shadow logs          | active         | active         | active         |
| `ConstitutionChecker`               | domain only | domain only          | active         | active         | active         |
| `UtilityEngine`                     | domain only | shadow mode          | ranking signal | primary        | primary        |
| `CounterfactualEngine`              | domain only | domain only          | top candidate  | all top 3      | all top 3      |
| `ChallengeLayer`                    | domain only | domain only          | flagged        | active         | active         |
| `FinancialReasoningContext.policy`  | not present | optional (null safe) | required       | required       | required       |
| `RecommendationPortfolio`           | not present | not present          | optional field | primary output | primary output |
| `ReasoningMemory`                   | not present | not present          | not present    | stored         | stored         |
| `DecisionKPIs`                      | not present | not present          | not present    | computed       | computed       |
| `flutter analyze` errors            | 0           | 0                    | 0              | 0              | 0              |

---

## 11. Sprint-by-Sprint Implementation Plan

Each sprint is self-contained: the codebase compiles and `flutter analyze` passes with zero errors at every commit. Each sprint has acceptance criteria verified before the next sprint begins.

---

### Sprint 11A — Decision Policy Engine

**Prerequisite:** Architecture Milestone 07 complete (Sprint 7 decision learning loop done).

**Deliverables:**

- `mobile/lib/domain/reasoning/policy/decision_policy.dart` — `DecisionPolicy`, `AxisWeightProfile`, `PolicyThresholds`
- `mobile/lib/domain/reasoning/policy/policy_evolution_rule.dart` — `PolicyEvolutionRule`, `PolicyCondition`, `PolicyModifier`
- `mobile/lib/domain/reasoning/policy/policy_selector.dart` — `PolicySelector` (domain interface + rule-based implementation)
- `mobile/lib/domain/reasoning/policy/user_archetype.dart` — `UserArchetype` enum
- `mobile/lib/domain/reasoning/policy/lifecycle_stage.dart` — `LifecycleStage` enum
- `mobile/lib/infrastructure/repositories/policy_repository.dart` — `PolicyStateRecord` persistence
- `FinancialReasoningContext` updated: `policy?` field added (nullable)
- `DecisionConfidenceReport` updated: `policyId?`, `policyLabel?`, `policyReason?` added (nullable)
- All 14 named policies configured with weight tables from `01-decision-policy-engine.md` Section 6

**Acceptance criteria:**

- All named policy weight tables sum to 1.0 (verified by golden test)
- `PolicySelector.select()` returns `RetiredPolicy` for `ageYears >= 60` (invariant test)
- `PolicySelector.select()` returns Survive-category policy when `emergencyFundMonths < 1.0` (invariant test)
- `AxisWeightProfile.validated()` throws typed exceptions on weight violations
- Behavioral state modifiers sum to zero delta (invariant test)
- `flutter analyze`: 0 errors

**Estimated new files:** 8 domain files, 2 infrastructure files, 4 test files

---

### Sprint 11B — Belief Engine

**Prerequisite:** Sprint 11A complete.

**Deliverables:**

- `mobile/lib/domain/reasoning/beliefs/financial_belief.dart` — `FinancialBelief`, `BeliefSet`, `GoalBelief`, `BeliefEvidenceItem`
- `mobile/lib/domain/reasoning/beliefs/belief_inference_rule.dart` — `BeliefInferenceRule`, `BeliefInferenceResult`
- `mobile/lib/domain/engines/belief_inference_engine.dart` — interface
- `mobile/lib/infrastructure/engines/rule_based_belief_inference_engine.dart` — 26 inference rules (LQ-001 through LS-005) from `02-belief-engine.md` Section 5
- DI: `sl.registerLazySingleton<BeliefInferenceEngine>(() => RuleBasedBeliefInferenceEngine())`
- `FinancialReasoningContext` updated: `beliefs?` field added (nullable)
- Shadow mode: beliefs computed on every `GetDashboardFeedUseCase` call, logged but not consumed

**Acceptance criteria:**

- All 26 rule confidences respect the fact confidence cap invariant
- `BeliefSet.empty()` consumed by any engine without null-pointer errors
- `lifeStage` belief derived after all category beliefs (verified by execution order test)
- `BeliefSet.overallConfidence <= DataConfidenceReport.recommendationConfidenceCap` (invariant test)
- HealthScoreEngine equivalence: belief-based and v1 fact-based scores agree within ±2 points for 100 synthetic profiles
- `flutter analyze`: 0 errors

**Estimated new files:** 6 domain files, 2 infrastructure files, 5 test files

---

### Sprint 11C — Candidate Generator

**Prerequisite:** Sprint 11B complete.

**Deliverables:**

- `mobile/lib/domain/reasoning/candidates/action_type.dart` — 27-value `ActionType` enum
- `mobile/lib/domain/reasoning/candidates/decision_candidate.dart` — `DecisionCandidate`, `CandidateMagnitude`, `CandidateSet`
- `mobile/lib/domain/reasoning/candidates/candidate_enums.dart` — `ActionFamily`, `RiskClass`, `BehaviorDifficulty`, `MagnitudeBasis`, `PrerequisiteBelief`
- `mobile/lib/domain/engines/candidate_generator.dart` — interface
- `mobile/lib/infrastructure/engines/rule_based_candidate_generator.dart` — all 27 generation rules + 7 pruning rules from `03-decision-candidate-generator.md`
- `DecisionType` → `ActionType` backward-compatibility alias
- DI: `sl.registerLazySingleton<CandidateGenerator>(() => RuleBasedCandidateGenerator())`

**Acceptance criteria:**

- `CandidateSet.viable.length >= 2` for any valid `FinancialReasoningContext` (invariant test)
- No duplicate `ActionType` in `viable` (invariant test)
- Layer 3 candidates absent when Layer 1 critical (pyramid invariant test)
- All pruned candidates have `rejectionReason != null` (invariant test)
- `BuildEmergencyFund` is position 1 when `emergencyFundMonths < 3.0` (CFP fiduciary test)
- `flutter analyze`: 0 errors

**Estimated new files:** 6 domain files, 2 infrastructure files, 5 test files

---

### Sprint 11D — Financial Constitution

**Prerequisite:** Sprint 11C complete.

**Rationale for placement:** The Financial Constitution runs at **pipeline Step 4** — immediately after candidate generation and before utility scoring. This is not cosmetic sequencing. It means: constitutionally excluded candidates are never scored, never counterfactually projected, and never challenged. The utility engine receives only permissible candidates. This matches the hard-constraint semantics of the constitution (see `07-financial-constitution.md` Section 2.2) and eliminates wasted computation on ineligible candidates. Sprint order must match pipeline step order.

**Deliverables:**

- `mobile/lib/domain/reasoning/constitution/` — all constitution domain types from `07-financial-constitution.md` Section 4
- `mobile/lib/domain/engines/constitution_engine.dart` — interface
- `mobile/lib/infrastructure/engines/rule_based_constitution_engine.dart` — system rules `SYS-001` through `SYS-008` hardcoded; user rules from `FinancialConstitution`
- `FinancialReasoningContext` updated: `constitution?` field active
- Constitution Check wired at Step 4 (before Utility Engine) in pipeline
- Partner program constitution check wired at Step 9 (partner matching phase)
- `mobile/lib/infrastructure/repositories/constitution_repository.dart` — persistence
- Constitution onboarding flow (schema only, UI in post-sprint)

**Acceptance criteria:**

- `reviewPastDecision` passes all system rules under all conditions (invariant test)
- System rules apply even when `constitution` is null (invariant test)
- Hard-violated candidates never appear in `permissibleCandidates` (invariant test)
- All violations recorded in `DecisionAudit.constitutionViolations[]` (audit invariant test)
- Soft violation messages appear in `ExplanationData.limitations[]` (visibility test)
- Empty-set fallback: when all candidates eliminated, `reviewPastDecision` is returned (fallback test)
- `flutter analyze`: 0 errors

**Estimated new files:** 6 domain files, 2 infrastructure files, 2 repository files, 5 test files

---

### Sprint 11E — Utility Engine

**Prerequisite:** Sprint 11D complete.

**Note:** Receives only constitution-permissible candidates from Step 4. The utility formula is applied exclusively to the filtered candidate set — not to all generated candidates.

**Deliverables:**

- `mobile/lib/domain/reasoning/utility/utility_model.dart` — `UtilityModel`, `UtilityArchetype`
- `mobile/lib/domain/reasoning/utility/utility_score.dart` — `UtilityScore`
- `mobile/lib/domain/engines/utility_engine.dart` — interface
- `mobile/lib/infrastructure/engines/rule_based_utility_engine.dart` — 7-term formula from `04-utility-engine.md` Section 3
- `mobile/lib/infrastructure/engines/behavioral_resistance_calculator.dart` — 6-adjustment resistance model from Section 7
- Shadow mode: utility scores computed on every `GetDashboardFeedUseCase` call; stored in decision record; do not influence ranking yet
- Feature flag: `UTILITY_ENGINE_ENABLED` in `FinancialPolicy` (or feature flags config)

**Acceptance criteria:**

- `netUtility ∈ [-1.0, 1.0]` for all candidates (invariant test — worked example from Section 12 of `04-utility-engine.md`)
- `calibrationConfidence <= 0.10` for new users with `learningMaturity == 0` (invariant test)
- `utilityNarrative` always non-null (invariant test)
- GrowthMaximizer archetype produces higher utility for equity SIP than LossAvoider for identical facts (archetype differentiation test)
- `resistanceScore ∈ [0.05, 0.95]` (clamp invariant test)
- `flutter analyze`: 0 errors

**Estimated new files:** 5 domain files, 3 infrastructure files, 6 test files

---

### Sprint 11F — Counterfactual Engine

**Prerequisite:** Sprint 11E complete.

**Deliverables:**

- `mobile/lib/domain/simulation/counterfactual_scenario.dart` — `CounterfactualScenario`, `CounterfactualPair`, `CounterfactualSet`, `CounterfactualType`, `CounterfactualDelta`, `DeltaDirection`
- `mobile/lib/domain/simulation/scenario_projection.dart` — `ScenarioProjection`, `ProjectionPoint`
- `mobile/lib/domain/simulation/shock_scenario.dart` — `ShockType` enum
- `mobile/lib/domain/engines/counterfactual_engine.dart` — interface (extends existing `SimulationEngine`)
- `mobile/lib/infrastructure/engines/simulation/deterministic_counterfactual_engine.dart` — v1 deterministic implementation (all 5 calculators)
- `mobile/lib/infrastructure/engines/simulation/commitment_counterfactual_adapter.dart` — wraps existing `GoalImpactAnalyzer`
- `mobile/lib/infrastructure/engines/simulation/narration_engine.dart` — loss-framing templates
- `mobile/lib/application/simulation/generate_counterfactuals_use_case.dart`
- DI registration

**Acceptance criteria:**

- SIP FV golden-value tests pass (7 test cases from `05-counterfactual-engine.md` Section 11.1)
- `GoalImpactAnalyzer` compatibility: months output matches legacy output (regression test)
- `CounterfactualScenario.confidence <= FinancialFacts.overallConfidence` (invariant test)
- `CounterfactualPair.narration` never contains unfilled template variables (integration test)
- Pipeline completes in < 50ms for all 12 scenario types (performance test)
- `flutter analyze`: 0 errors

**Estimated new files:** 8 domain files, 6 infrastructure files, 2 application files, 8 test files

---

### Sprint 11G — Challenge Layer

**Prerequisite:** Sprint 11F complete.

**Deliverables:**

- `mobile/lib/domain/reasoning/challenge/challenge_result.dart` — `ChallengeType`, `ChallengeOutcome`, `ChallengeResult`, `ChallengeLayerResult`
- `mobile/lib/domain/engines/challenge_layer_engine.dart` — interface
- `mobile/lib/infrastructure/engines/rule_based_challenge_layer_engine.dart` — 6 challenges from `06-challenge-layer.md` Section 6
- Feature flag: `EngineFlag.challengeLayerEnabled` (default: false)
- Wire into `FinancialReasoningEngine.reason()` after utility scoring, before Decision assembly

**Acceptance criteria:**

- Exactly 6 `ChallengeResult` objects always in `ChallengeLayerResult.results` (invariant test)
- `LiquidityChallenge` fires and proposes `buildEmergencyFund` when `emergencyFundMonths < 1.0` and candidate != `buildEmergencyFund` (fiduciary test)
- `TaxChallenge` fires in January–March when `taxEfficiency < 0.85` and candidate not tax-related (Q4 urgency test)
- Priority resolution: when Liquidity and Debt both propose replacements, Liquidity wins (priority test)
- `totalConfidenceDelta <= +0.05` (invariant test — tax challenge exception allowed)
- All 6 results visible in `ExplanationData.alternatives[]` (explainability test)
- `flutter analyze`: 0 errors

**Estimated new files:** 3 domain files, 1 infrastructure file, 3 test files

---

### Sprint 11H — RecommendationPortfolio + ReasoningMemory + ConfidenceGraph + DecisionKPIs

**Prerequisite:** Sprints 11A–11G complete.

This is the integration sprint. All seven pipeline components are wired into a single `RecommendationPipeline` orchestrator. Two pre-11A additions — `ReasoningMemory` and `DecisionKPIs` — are delivered here because they depend on every prior step's output.

**Deliverables:**

_Portfolio and Confidence (pipeline output):_

- `mobile/lib/domain/reasoning/output/recommendation_portfolio.dart` — `RecommendationPortfolio`, `RankedRecommendation`, `ConfidenceGraph`
- `mobile/lib/domain/engines/confidence_aggregator.dart` — interface and implementation
- `mobile/lib/infrastructure/engines/recommendation_pipeline.dart` — orchestrates all 10 steps in sequence

_Reasoning Memory (chain-of-reasoning storage — see `08-reasoning-memory.md`):_

- `mobile/lib/domain/reasoning/memory/reasoning_memory.dart` — `ReasoningMemory` + all supporting record types (`ActivatedBeliefRecord`, `CandidateRecord`, `PrunedCandidateRecord`, `ConstitutionCheckRecord`, `UtilityBreakdownRecord`, `CounterfactualRecord`, `ChallengeRecord`)
- `mobile/lib/domain/reasoning/memory/reasoning_memory_repository.dart` — abstract repository interface
- `mobile/lib/infrastructure/repositories/in_memory_reasoning_memory_repository.dart` — in-memory LRU (max 50 records per session)
- `mobile/lib/infrastructure/engines/reasoning_memory_assembler.dart` — assembles from per-step outputs; writes async, fire-and-forget

_Decision KPIs (engine observability — see `09-decision-kpis.md`):_

- `mobile/lib/domain/reasoning/kpi/decision_kpis.dart` — `DecisionKPIs`, `DecisionKPISnapshot`, `KPIWindow`
- `mobile/lib/domain/engines/decision_kpi_engine.dart` — abstract interface
- `mobile/lib/infrastructure/engines/rule_based_decision_kpi_engine.dart` — computes from `ReasoningMemory` + `LearningSnapshot`
- `mobile/lib/application/reasoning/get_decision_kpis_use_case.dart`

_Widget integration:_

- `GetDashboardFeedUseCase` updated to invoke full pipeline
- `TodaysBestDecisionCard` widget updated to display `RecommendationPortfolio.primary` (rank 1 with counterfactual)
- Alternatives panel: displays `portfolio.alternatives` (ranks 2–4 condensed)
- Explainability panel: displays `ChallengeLayerResult.challengeReasons` as "We also considered..."
- `CandidatePortfolio.considered` available as "considered but not recommended" section

**Acceptance criteria:**

_Pipeline output:_

- Full pipeline benchmark: `< 200ms` end-to-end on mid-range device with all 10 steps active (memory write is async and excluded from this benchmark)
- `RecommendationPortfolio.primary != null` always (pipeline always produces output)
- v2 top recommendation matches v1 type in >= 92% of 100 canonical test profiles (regression suite)
- All 10 synthetic test user profiles produce valid, non-null portfolios
- `ConfidenceGraph.compoundConfidence` matches legacy `DecisionConfidenceReport.compoundConfidence` bit-for-bit (backward compatibility test)

_ReasoningMemory:_

- `ReasoningMemory.challengeResults.length == 6` always (RM-1 invariant test)
- `compoundConfidence == dataConf × decisionConf × behaviorConf × historicalAcc` (RM-2 invariant test)
- Memory assembly adds `< 2ms` to pipeline execution (performance test — assembly only, excludes async write)
- Storage failure does not propagate to `GetDashboardFeedUseCase` return path (error isolation test)

_DecisionKPIs:_

- `calibrationError` returns 0.0 for empty record set (edge case test)
- `engineHealthGrade == 'F'` when `averageHealthScoreDelta < -1.0` regardless of other metrics (Grade F dominance test)
- KPI computation completes in `< 100ms` for 500 memory records (performance test)

_All:_

- `flutter analyze`: 0 errors

**Estimated new files:** 10 domain files, 5 infrastructure files, 2 application files, 3 widget files, 15 test files (including regression suite)

---

## 12. Testing Strategy

### 12.1 Unit Testing — Per-Component Pure Function Tests

Every engine is a pure function and is testable without infrastructure. The test pyramid starts here.

| Component                | Test File                                                          | Key Test Cases                                                                                            |
| ------------------------ | ------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------- |
| PolicySelector           | `test/domain/reasoning/policy/policy_selector_test.dart`           | 14 named policies × selection invariants; all weight tables sum to 1.0; all modifier deltas sum to 0      |
| BeliefInferenceEngine    | `test/infrastructure/engines/belief_inference_engine_test.dart`    | Each of 26 rules (confidence formula, evidence assembly, contradiction handling); decay model; TTL expiry |
| CandidateGenerator       | `test/infrastructure/engines/candidate_generator_test.dart`        | All 27 applicability conditions; all 7 pruning rules; pyramid invariant; minimum viable set fallback      |
| ConstitutionChecker      | `test/infrastructure/engines/constitution_engine_test.dart`        | Each of 8 system rules; empty-set fallback; `reviewPastDecision` always permissible                       |
| UtilityEngine            | `test/infrastructure/engines/utility_engine_test.dart`             | Worked example from `04-utility-engine.md` Section 12; archetype differentiation; boundary conditions     |
| CounterfactualEngine     | `test/infrastructure/engines/counterfactual_engine_test.dart`      | 7 golden-value SIP formula tests; shock scenarios; narration template completeness                        |
| ChallengeLayer           | `test/infrastructure/engines/challenge_layer_engine_test.dart`     | Each of 6 challenges; priority resolution; invariant compliance                                           |
| ConfidenceAggregator     | `test/domain/reasoning/output/confidence_aggregator_test.dart`     | v1 `compoundConfidence` preserved; challenge delta applied correctly; constitution compliance             |
| ReasoningMemoryAssembler | `test/infrastructure/engines/reasoning_memory_assembler_test.dart` | RM-1 through RM-6 invariants; storage failure isolation; assembly adds < 2ms                              |
| DecisionKPIEngine        | `test/infrastructure/engines/decision_kpi_engine_test.dart`        | Grade F dominance; calibration error computation; health score delta averaging                            |

### 12.2 Integration Testing — Pipeline End-to-End with Synthetic Profiles

```
test/integration/reasoning_pipeline_test.dart

For each of the 10 canonical test users (Section 12.5):
  1. Build FinancialReasoningContext with full set of inputs
  2. Run complete 10-step pipeline
  3. Assert: RecommendationPortfolio.primary != null
  4. Assert: primary.candidate.actionType matches expected recommendation type
  5. Assert: primary.counterfactualSet != null and confidence >= 0.30
  6. Assert: ConfidenceGraph.constitutionCompliant == true
  7. Assert: all 6 ChallengeResult objects present
  8. Assert: pipeline completes in < 200ms
```

### 12.3 Regression Testing — v1 Equivalence Check

**Requirement:** v2 must produce the same top recommendation type as v1 in >= 92% of canonical test profiles.

```
test/regression/v1_v2_equivalence_test.dart

For 100 synthetic FinancialFacts profiles (ranging from student/survive to retiree/optimize):
  1. Run v1 RuleBasedFinancialReasoningEngine.reason() → v1DecisionType
  2. Run v2 pipeline → v2DecisionType (portfolio.primary.candidate.actionType)
  3. Record match/mismatch
  4. Assert: matchRate >= 0.92

For profiles where v1 and v2 disagree:
  5. Assert: v2 recommendation is reviewed and documented as deliberate improvement
     (not a regression) before Phase E migration proceeds
```

### 12.4 Property-Based Testing — Invariant Verification

These tests verify that invariants hold across all valid inputs, not just golden fixtures.

```
// I-1: Pipeline always produces output
for_all valid FinancialReasoningContext:
  portfolio = pipeline.run(ctx)
  assert(portfolio.primary != null)

// I-4: Confidence never exceeds data cap
for_all valid (FinancialFacts, DataConfidenceReport) pairs:
  beliefs = beliefEngine.infer(facts, ...)
  assert(beliefs.overallConfidence <= dataConfidence.recommendationConfidenceCap)

// I-7: Weights always sum to 1.0
for_all UserArchetype × FinancialState combinations:
  policy = policySelector.select(...)
  assert(policy.weights.sum.closeTo(1.0, epsilon: 0.001))

// I-9: CandidateSet always has >= 2 viable candidates
for_all valid FinancialReasoningContext:
  candidates = generator.generate(ctx)
  assert(candidates.viable.length >= 2)

// III: Constitution violations never reach output
for_all (candidates, constitution) pairs with at least 1 hard violation:
  results = constitutionChecker.check(candidates, ctx, constitution)
  permissible = results.where((r) => r.isPermissible).map((r) => r.candidate).toList()
  assert(hardViolatedCandidates.none((c) => permissible.contains(c)))
```

### 12.5 Canonical Test Users (10 Profiles)

| Profile              | Age | Income/mo          | EF Months | Debt Ratio | Savings Rate | Archetype          | SMRT State |
| -------------------- | --- | ------------------ | --------- | ---------- | ------------ | ------------------ | ---------- |
| **Student**          | 22  | ₹15,000            | 0.2       | 0.0        | 0.05         | student            | survive    |
| **SalariedSurvive**  | 28  | ₹55,000            | 0.8       | 0.15       | 0.08         | salariedWithFamily | survive    |
| **SalariedBuild**    | 34  | ₹85,000            | 6.5       | 0.22       | 0.20         | salariedWithFamily | build      |
| **SalariedOptimize** | 42  | ₹1,50,000          | 8.0       | 0.10       | 0.32         | salariedWithFamily | optimize   |
| **Freelancer**       | 31  | ₹70,000 (variable) | 4.5       | 0.05       | 0.14         | freelancer         | stabilize  |
| **BusinessOwner**    | 38  | ₹2,00,000          | 7.0       | 0.28       | 0.18         | businessOwner      | build      |
| **PreRetirement**    | 57  | ₹1,20,000          | 12.0      | 0.0        | 0.35         | preRetiree         | optimize   |
| **Retired**          | 65  | ₹40,000 (pension)  | 28.0      | 0.0        | 0.0          | retiree            | optimize   |
| **HighDebt**         | 30  | ₹60,000            | 1.5       | 0.52       | 0.06         | salariedWithFamily | stabilize  |
| **NewParent**        | 33  | ₹95,000            | 3.5       | 0.35       | 0.12         | salariedWithFamily | build      |

**Expected primary recommendation type for each profile:**

| Profile          | Expected v2 Primary                            |
| ---------------- | ---------------------------------------------- |
| Student          | `buildEmergencyFund`                           |
| SalariedSurvive  | `buildEmergencyFund`                           |
| SalariedBuild    | `startSip` or `maximize80C` (policy-dependent) |
| SalariedOptimize | `stepUpSip` or `maximize80CCD`                 |
| Freelancer       | `buildEmergencyFund` (9-month target not met)  |
| BusinessOwner    | `maximize80C` or `startSip`                    |
| PreRetirement    | `increaseGoalContribution` (retirement corpus) |
| Retired          | `reviewInsurance` or `reviewPastDecision`      |
| HighDebt         | `accelerateDebtRepayment`                      |
| NewParent        | `getHealthInsurance` or `buildEmergencyFund`   |

### 12.6 Golden File Tests (Policy Weights)

For each of the 14 named policies, a committed golden file captures:

- The `AxisWeightProfile` values
- Expected `decisionConfidenceFactor` range (±0.02) for the canonical scenario
- Top contributing axis

CI fails if any policy output deviates from its golden file without an explicit `UPDATE_GOLDEN=true` flag in the test command.

```
test/golden/policies/
  student_v1_canonical.json
  salaried_survive_v1_canonical.json
  salaried_build_v1_canonical.json
  ...14 files total
```

---

## 13. Extension Points

v2 is designed so that Phase 11 (Digital Twin) and Phase 12 (Daily Intelligence) plug in without redesigning existing interfaces.

### 13.1 CounterfactualEngine → SimulationEngine Upgrade Path

The `CounterfactualEngine` interface in v2 uses deterministic FV math (O(1), synchronous). Phase 11's Digital Twin needs Monte Carlo simulation (O(N), potentially async).

**Extension mechanism:** The `SimulationEngine` interface already scaffolded in `mobile/lib/domain/engines/simulation_engine.dart` is extended:

```dart
abstract class SimulationEngine {
  // v2 (deterministic) — stable interface, no change:
  CounterfactualSet generateCounterfactuals({...});

  // Phase 11 (Monte Carlo) — new method on same interface:
  Future<MonteCarloResult> runMonteCarlo({
    required FinancialFacts facts,
    required int simulations,
    required int horizonMonths,
  });
}
```

The `CounterfactualSet` domain type is stable across both implementations. All widgets and use cases that consume `CounterfactualSet` work unchanged when the underlying engine switches from deterministic to Monte Carlo.

**What enables this:** `CounterfactualEngine` is registered in DI. Phase 11 registers `MonteCarloCounterfactualEngine as CounterfactualEngine`. Zero change to call sites.

### 13.2 PolicySelector → ML Policy Upgrade Path

v2 `PolicySelector` uses rule-based archetype detection and SMRT state mapping. Phase 12's behavioral intelligence needs a learned policy selector trained on outcome data.

**Extension mechanism:** `PolicySelector` is a domain interface:

```dart
abstract class PolicySelector {
  DecisionPolicy select(FinancialFacts facts, BehaviorInterpretation? behavior,
                        UserArchetype archetype, PolicyStateRecord? existingRecord);
}
```

Phase 12 registers `MLPolicySelector as PolicySelector`. The rule-based implementation remains as a fallback for new users before ML calibration.

**What enables this:** The named policy weight tables in Sprint 11A become the Bayesian priors for the ML version. The ML update runs on top of rule-based weights, nudging them based on individual outcome data. The policy engine is not replaced — it is the foundation the ML model runs on.

### 13.3 BeliefInferenceEngine → Bayesian Network Upgrade Path

v2 uses rule-based inference (each rule independently fires). Phase 12's behavioral intelligence can use a Bayesian Belief Network (BBN) where belief confidences propagate through conditional dependencies.

**Extension mechanism:** `BeliefInferenceEngine` is a domain interface. `BayesianBeliefInferenceEngine as BeliefInferenceEngine` is registered in Phase 12. The `BeliefSet` output type is unchanged — downstream engines consume beliefs the same way regardless of inference method.

**What enables this:** The rule-based implementation defines the factual dependencies (required vs. optional facts) per rule. These are the conditional independence assumptions the BBN encodes. When the BBN ships, it uses the same `BeliefInferenceRule.requiredFacts` / `optionalFacts` declarations as its graph structure.

### 13.4 UtilityModel → Learned Utility Function Upgrade Path

v2 `UtilityModel` parameters are initialized from archetype priors and updated via exponential moving averages from observed outcomes. Phase 12 can replace the moving-average update with a full Bayesian posterior update using the outcome data accumulated in `LearningSnapshot`.

**Extension mechanism:** `UtilityModel.calibrationSource` tracks provenance (`QUESTIONNAIRE | INFERRED | LEARNED`). The `learningRate` field decreases as `LearningSnapshot.maturity` increases — the system is already designed to transition from fast-learning (early calibration) to fine-tuning (mature calibration). Phase 12 adds a fourth source: `BAYESIAN_POSTERIOR`.

**What enables this:** Every `UtilityScore` stores `sensitivityToLossAversion` and `sensitivityToPresentBias`. These sensitivities form the gradient of the utility function with respect to parameters — the foundation for gradient-based optimization of `UtilityModel` parameters.

---

## 14. What v2 Enables That v1 Cannot

### Capability 1: Concrete Counterfactual Stakes

**v1:** "Start a SIP for your retirement goal."

**v2:** "Starting ₹2,000 today → ₹1.15Cr in 20 years. Waiting 6 months → ₹1.03Cr. That 6-month delay costs you ₹12L in compounding — permanently."

_What makes this possible:_ `CounterfactualEngine` (Component 5), `NarrationEngine` with loss-framing rules, `CounterfactualSet.delayCounterfactuals[]` attached to primary recommendation.

---

### Capability 2: Constitution Enforcement with Audit

**v1:** No mechanism exists to enforce user-declared financial rules. Every candidate enters scoring.

**v2:** "This recommendation conflicts with your constitution rule: 'Never reduce emergency fund below 12 months.' The engine considered 5 alternatives. After your constitution check, 4 remained eligible." The audit trail in `DecisionAudit.constitutionViolations[]` answers "why wasn't X recommended?" transparently.

_What makes this possible:_ `ConstitutionChecker` (Component 7, Step 4), `FinancialConstitution` in `FinancialReasoningContext`, system rules `SYS-001` through `SYS-008` always active.

---

### Capability 3: Full Alternative Transparency

**v1:** "Optimize your taxes." (No context on what else was considered or why.)

**v2:** "We considered 7 options. We chose Start SIP over Maximize 80C because: (a) your 80C is 72% utilized and the remaining ₹43,200 saves ₹13,000 in tax, but (b) your retirement goal is 27% underfunded and a ₹2,000 SIP closes ₹8L of the funding gap. The tax saving is real but smaller in magnitude than the goal funding urgency."

_What makes this possible:_ `CandidateSet.pruned` (with `rejectionReason`), `UtilityScore.utilityNarrative` for each alternative, `ChallengeLayerResult.challengeReasons` in `ExplanationData.alternatives[]`.

---

### Capability 4: Behavioral Execution Probability

**v1:** No behavioral execution modeling. Every recommendation is treated as equally executable.

**v2:** "Your behavioral pattern suggests 73% likelihood of following through on this recommendation (based on your 4 previously accepted recommendations and discipline score of 68/100). We are recommending the 2-step setup path rather than the 5-step AMC account opening because your behavioral resistance score for new-platform SIPs is 0.79 — too high."

_What makes this possible:_ `UtilityEngine.resistanceScore` (6-factor behavioral resistance model), `UtilityScore.behavioralResistancePenalty`, `BehaviorDifficulty` on `DecisionCandidate`, `LearningSnapshot.activeLessons` rejection pattern detection.

---

### Capability 5: The Challenge Verdict

**v1:** Top-scored candidate exits directly to the user with no adversarial review.

**v2:** "The Challenge Layer tested this recommendation against 6 alternative strategies. It survived all 6 challenges. Specifically: the Debt Challenge confirmed that your 22% EMI ratio does not make debt paydown superior to the SIP. The Liquidity Challenge confirmed your 6.5-month emergency fund is above the target. The Behavior Challenge found moderate resistance and reduced confidence by 0.05."

_What makes this possible:_ `ChallengeLayer` (Component 6, Step 7), `ChallengeLayerResult.results` (all 6 always recorded), `challengeReasons` in `ExplanationData.alternatives[]`.

---

### Capability 6: Personalized Advice by Life Stage

**v1:** A 22-year-old student and a 48-year-old pre-retiree with the same income receive recommendations computed with the same axis weights: `cashFlow=0.30, liquidity=0.25, goalImpact=0.20, behavior=0.10, taxes=0.05, opportunityCost=0.10`.

**v2:** The student receives `behavior=0.20, goalImpact=0.30, taxes=0.02, opportunityCost=0.03` (habit formation matters most; tax optimization is irrelevant at zero taxable income). The pre-retiree receives `liquidity=0.28, goalImpact=0.22, taxes=0.12, opportunityCost=0.08` (retirement buffer building and NPS efficiency are the dominant axes). Same facts, structurally different recommendations.

_What makes this possible:_ `PolicySelector` (Component 1), `AxisWeightProfile` selected per `UserArchetype × FinancialState`, `PolicyThresholds` replacing hardcoded thresholds in axis analyzers.

---

_This document is the authoritative master architecture for PennyWise Financial Reasoning Engine v2. It synthesizes component design documents 01 through 09. Implementation proceeds against this document and its referenced component specs without redesign. Any architectural deviation during implementation must be recorded as an amendment to this document with rationale._

_Component design documents (`01-decision-policy-engine.md` through `09-decision-kpis.md`) remain authoritative for per-component implementation detail. This master document governs integration, sequencing, interfaces, and invariants._

_Sprint order rationale: Sprints 11A–11H follow pipeline step order (Steps 1→10). Financial Constitution (Step 4) is implemented in Sprint 11D — before Utility Engine (Step 5, Sprint 11E) — because the constitution hard-filters candidates before utility scoring begins. This is not a stylistic choice: it is the semantic definition of a hard constraint._

_Authored: 2026-08-05_
