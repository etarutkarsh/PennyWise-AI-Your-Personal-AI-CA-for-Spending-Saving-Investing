# PennyWise AI — Financial Belief Engine
## Architecture Design Document: reasoning-v2/02

**Status:** Design (pre-implementation)
**Version:** 1.0
**Date:** 2026-08-05
**Supersedes:** None (introduces new layer)
**Authors:** CTO Architecture Review

---

## Table of Contents

1. Overview — Why Facts→Decision Is Insufficient
2. Research Findings
3. Complete Belief Taxonomy
4. Domain Model
5. Inference Rules
6. Belief Confidence Model
7. Expiry and Refresh
8. Integration Point — Slot into FinancialReasoningContext
9. Relationship to BehaviorInterpretation
10. Migration from v1
11. Invariants

---

## 1. Overview — Why Facts→Decision Is Insufficient

### The Current Pipeline

PennyWise v1 follows a direct Facts→Decision path:

```
FinancialFacts (14 raw facts)
    ↓
HealthScoreEngine / DecisionEngine
    ↓
DecisionResponse (recommendation + explanation)
```

Each engine receives raw numeric facts (`emergencyFundMonths: 2.1`, `debtRatio: 0.38`, `investmentRatio: 0.05`) and must interpret them independently. Every engine re-derives the same higher-order conclusions:

- "Is this person liquidity-constrained?" — computed redundantly in HealthScoreEngine, DecisionEngine, AffordabilityEngine.
- "Is this person underinvested for their age?" — each engine has its own threshold logic with no shared standard.
- "Should we treat this user as financially fragile?" — invisible in the pipeline; each engine guesses separately.

### The Three Failure Modes

**1. Repeated threshold logic with no canonical home.** The rule `emergencyFundMonths < 3` appears in at least three engines. When the threshold changes (RBI guidance, product decision), it must be updated everywhere or drift silently. `FinancialPolicy` captures constants, but not the inference that combines them.

**2. Context collapse.** A user with `savingsRate: 0.22` looks healthy to the Decision Engine. But if `debtRatio: 0.44` and `emergencyFundMonths: 0.8`, the combination means "high income, but almost no buffer and over-leveraged." The engines see three separate facts; no engine sees "this is a fragile-looking accumulator." The interpretation lives in the space between facts — it requires synthesis.

**3. Explainability without meaning.** When the Explainability Engine surfaces "Emergency Fund: 2.1 months" in an explanation, the user does not know what to feel. The belief "You are liquidity constrained" is what the user needs to understand. Beliefs are the semantic layer between raw numbers and actionable understanding.

### What the Belief Layer Adds

The Belief Layer inserts a **named, confidence-tagged, evidence-backed interpretation** between raw facts and the decision engines:

```
FinancialFacts (14 raw numerical facts)
    ↓  BeliefInferenceEngine
BeliefSet (25+ named financial beliefs, each with confidence + evidence)
    ↓
FinancialReasoningContext (facts + beliefs + behavior + learning)
    ↓
HealthScoreEngine / DecisionEngine / AffordabilityEngine
    ↓
DecisionResponse
```

A belief encodes the system's current best inference about the user's financial situation:

- `liquidityConstrained` — high confidence (0.89) — "User has < 1 month liquid buffer and negative surplus"
- `underinvested` — medium confidence (0.62) — "User is 32 years old with investmentRatio 0.03, well below 0.10 target"
- `goalAtRisk(goalId)` — high confidence (0.81) — "SIP amount covers only 41% of required monthly contribution"

Engines no longer decide independently whether to treat a user as liquidity-constrained. They consume the pre-computed, consistently-applied belief.

### Why Beliefs Are Not Just Thresholds

A threshold says: `if emergencyFundMonths < 3 then flag`. A belief says: `given the weight of evidence across multiple facts, with this confidence, I infer this state about the user`. The distinction matters for three reasons:

1. **Graduated certainty.** A user with `emergencyFundMonths: 2.9` is barely below a 3-month threshold. The belief `safetyNetAdequate` fires at 0.35 confidence — not binary, not discarded. The engine reasons proportionally.

2. **Contradicting evidence.** A user might have `emergencyFundMonths: 0.7` (supporting `liquidityConstrained`) but also `savingsRate: 0.42` (contradicting it — they are rapidly building up). The belief system records both and produces a nuanced confidence value rather than a false alarm.

3. **Explainability.** Every belief carries its exact supporting and contradicting facts. The Explainability Engine can surface "We believe you are liquidity constrained because your emergency fund covers 0.7 months (target: 3), though your savings rate of 42% suggests this may resolve within 2 months." This is impossible without the belief layer.

---

## 2. Research Findings

### 2.1 Industry Pattern: AI Financial Advisors and Belief Representation

**Betterment and Wealthfront** do not publish their internal belief models, but their architecture patents and engineering blog posts reveal a consistent pattern: they maintain a **client state model** that is distinct from raw account data. This state model is a curated set of inferences (sufficient emergency fund, appropriate risk level, on-track for goal, tax-loss opportunity present) that are refreshed on a schedule and event-triggered basis. The recommendation engine consumes this state model, not the raw transaction feed. The state model is versioned: changing the inference rules produces a new version that can be backtested against historical data.

**MoneyLion's Instacash and financial health score** follow a similar pattern — raw facts (transactions, balances, income) are processed into "financial health pillars" (spending, savings, debt, insurance) before any recommendation is generated. The pillar assessment is what the recommendation engine reads.

**The common pattern across the industry:**

```
Raw Data (transactions, balances) 
    → Derived Facts (income, expense, ratios)
    → Client State / Beliefs (interpreted situation)
    → Recommendations (actions)
```

Each layer compresses information upward. The Belief Layer is the compression from quantitative facts to qualitative states. This is the layer PennyWise v1 is currently missing.

### 2.2 BDI Architecture Applied to Financial Advisory

The **Belief-Desire-Intention (BDI)** model, developed by Michael Bratman (1987) and implemented in AI systems by Rao and Georgeff (1991), provides a formal framework for goal-directed rational agents. BDI has been applied to financial advisory AI in academic research (e.g., Noia et al., 2011, "A BDI approach for financial investment advisor systems").

The three components map directly to PennyWise's architecture:

| BDI Component | Financial Meaning | PennyWise Equivalent |
|---|---|---|
| **Beliefs** | What the system knows (or infers) about the user's financial situation | `BeliefSet` — the inferred financial state (liquidity constrained, underinvested, goal at risk) |
| **Desires** | What the user wants to achieve (goals, aspirations) | `GoalSnapshot[]` — active financial goals with target, deadline, saved amount |
| **Intentions** | Committed plans the user has agreed to act on | `DecisionExecution` — accepted decisions in the learning loop |

In a BDI framework, the **practical reasoning cycle** is:
1. Update beliefs from new percepts (new transactions, new facts).
2. Deliberate over desires and current beliefs to generate options.
3. Select the option most compatible with current intentions.
4. Commit to an intention (a plan) and execute it.

For PennyWise, this maps to:
1. New transactions arrive → `FinancialFactBuilder` recomputes facts → `BeliefInferenceEngine` refreshes beliefs.
2. `DecisionEngine` deliberates: given beliefs, what is the highest-impact action?
3. The engine filters candidates against the user's existing commitments (`LearningSnapshot.activeLessons`) — it does not recommend a new SIP if the user has already committed to one.
4. `DecisionResponse` is produced; user accepts it → `DecisionExecution` is created.

**Key BDI insight for the belief layer:** Beliefs must be **separable from desires and intentions**. A user who is `liquidityConstrained` and has a goal `buildEmergencyFund` still has the goal — but the belief modifies what recommendation is appropriate. The belief system must not encode goals; it encodes the system's understanding of reality.

### 2.3 Bayesian Belief Networks in Financial Planning

A **Bayesian Belief Network (BBN)** is a directed acyclic graph where nodes represent random variables and edges represent conditional dependencies. In financial planning, BBNs have been used for:

- **Risk tolerance inference** (Crespo et al., 2016): infer risk tolerance from observable behaviors rather than questionnaire responses alone, because stated preferences diverge from revealed preferences.
- **Goal success probability** (Blanchett & Kaplan, Morningstar): Monte Carlo simulations model the probability distribution of outcomes given current savings behavior, market assumptions, and spending path.
- **Credit risk scoring**: classic application — probability of default given observable features.

**Key Bayesian principles that apply to PennyWise beliefs:**

**1. Prior + Evidence = Posterior.** A new user starts with a prior belief about their financial state based on their declared profile (age, income, risk preference). As facts accumulate, the posterior is updated. `BehaviorInterpretation.uncalibrated()` already implements this — it sets a neutral 50/100 prior. The Belief Engine should do the same: `liquidityConstrained` starts at 0.50 confidence for a new user with only declared income; it updates as real transaction data arrives.

**2. Conditional independence.** Not all beliefs depend on all facts. `liquidityConstrained` depends on `emergencyFundMonths` and `monthlySurplus`. It does not depend on `taxEfficiency`. The inference rule should declare its fact dependencies explicitly, allowing the engine to skip recalculation when only irrelevant facts change.

**3. Confidence propagates through the graph.** If `emergencyFundMonths` has confidence 0.40 (estimated from limited transaction history), then `liquidityConstrained`, which depends on it, cannot have confidence higher than 0.40. The confidence of a derived belief is bounded by the minimum confidence of its input facts. This is the Bayesian constraint that `DataConfidenceReport.recommendationConfidenceCap` already partially implements.

**4. Uncertainty ≠ 1 − Confidence.** Following the design of `DimensionInterpretation`, confidence and uncertainty are orthogonal. A belief can be: high confidence AND low uncertainty (strong, consistent evidence); high confidence AND high uncertainty (one strong signal, nothing else); low confidence AND high uncertainty (sparse and conflicting).

### 2.4 CFP Taxonomy of Client Beliefs

A **Certified Financial Planner** does not work directly from a client's account statements. After the fact-finding meeting, the CFP forms a structured interpretation of the client's situation — a mental model with specific named beliefs. Published CFP training materials (CFP Board, 2023 exam curriculum; Dalton's Personal Financial Planning) identify the following domains of CFP belief formation:

**Liquidity Assessment:**
- Does the client have adequate liquid reserves (3–6 months expenses)?
- Is the client's cash flow positive or negative?
- Is the client at risk of forced liquidation of investments for an emergency?

**Debt Assessment:**
- Is the debt burden manageable (EMI < 40% income)?
- Is the debt "good" (home, education) or "bad" (revolving credit, consumer)?
- Is the client trending toward debt freedom or debt accumulation?

**Investment Assessment:**
- Is the client invested at all relative to their income and age?
- Is the asset allocation appropriate for the declared risk profile?
- Is the portfolio concentrated (single asset class, single instrument)?
- Is the client leaving tax-advantaged space unused (80C capacity)?

**Insurance Assessment:**
- Is the client adequately covered for life risk (10×annual income rule)?
- Is health insurance in place?
- Is there a gap between declared coverage and estimated liability?

**Goal Assessment (per goal):**
- Is each goal funded at the required rate?
- Is the timeline realistic given current savings pace?
- Has a recent adverse event put a goal at risk?

**Behavioral Assessment:**
- Does the client follow through on financial commitments?
- Are there recurrent impulsive spending patterns?
- Does loss aversion prevent appropriate equity exposure?

**Life Stage Assessment:**
- Is the client's overall financial position consistent with their life stage?
- Are they "ahead" (financial independence indicators) or "behind" (fragile)?
- What is the client's financial resilience to a job loss or medical event?

This CFP taxonomy maps directly to the seven belief categories in Section 3 of this document. Every named belief in PennyWise's system should correspond to a judgment a qualified CFP would explicitly make about a client.

### 2.5 Belief Expiry and Refresh: Industry Practice

**TTL-based expiry** is the most common approach in production financial systems. Betterment refreshes its client state model daily (overnight batch) and on every significant event (large transaction, goal modification). The rationale: financial beliefs derived from daily data are stale after 24 hours because spending patterns and account balances change continuously.

**Event-driven invalidation** is the complementary approach. Rather than waiting for the TTL to expire, certain events immediately invalidate specific beliefs. A large debit transaction (>20% of monthly income in a single day) immediately invalidates `safetyNetAdequate` and `liquidityConstrained` beliefs and triggers re-inference.

**Confidence decay over time** is a subtler mechanism used by some systems: a belief that was computed from data 10 days ago has a lower effective confidence than one computed today, because the underlying facts may have changed. The confidence decays toward a floor (typically 0.30) as the belief ages, regardless of TTL. The user is not shown a "stale" warning; the lower confidence simply makes the belief less influential in downstream reasoning.

**The practical tradeoff:** Full Bayesian refresh on every transaction is computationally expensive and produces noisy belief updates (a ₹200 food purchase should not change `liquidityConstrained`). PennyWise's approach should use:
- **TTL:** 24 hours for all beliefs during active usage.
- **Event triggers:** Large transactions, new goals, goal completion, income change, new data source connected.
- **Confidence decay:** Beliefs older than 48 hours lose 0.10 confidence per 24-hour period, flooring at 0.20.
- **Lazy re-inference:** Beliefs are only re-inferred when consumed if they are stale or expired, not proactively.

---

## 3. Complete Belief Taxonomy

### Taxonomy Overview

PennyWise holds **26 named beliefs** grouped into 7 categories. Every belief is **mutually exclusive within its category** — for each category, at most one belief fires above threshold (confidence ≥ 0.50). This prevents contradictory beliefs being presented to the Decision Engine simultaneously.

The categories mirror the CFP's seven mental model domains (Section 2.4).

---

### Category 1: Liquidity Beliefs

**Domain:** How safe is the user's liquid cash position?

| Belief ID | Label | Plain English Meaning |
|---|---|---|
| `liquidityConstrained` | Liquidity Constrained | Emergency fund critically low; any unexpected expense will cause financial distress |
| `liquidityVulnerable` | Liquidity Vulnerable | Emergency fund below 3 months; not critical yet but insufficient buffer |
| `safetyNetAdequate` | Safety Net Adequate | Emergency fund between 3–6 months; meets minimum standard |
| `safetyNetStrong` | Safety Net Strong | Emergency fund above 6 months; exceeds target |
| `overLiquid` | Over-Liquid | Excess cash held in low-yield accounts when it could be deployed for growth |

**Mutual exclusivity rule:** The belief with the highest confidence in this category wins. Secondary beliefs with confidence < 0.30 are discarded. When confidence is close (within 0.15), both are retained with their raw confidence values and the Decision Engine must reason under uncertainty.

---

### Category 2: Debt Beliefs

**Domain:** How is the user's debt position affecting their financial health?

| Belief ID | Label | Plain English Meaning |
|---|---|---|
| `debtBurdened` | Debt Burdened | EMI-to-income ratio exceeds safe threshold; debt is constraining financial choices |
| `debtElevated` | Debt Elevated | EMI ratio is high but below critical; user should not add new debt commitments |
| `healthyDebtService` | Healthy Debt Service | EMI ratio within acceptable range; debt is manageable |
| `debtFree` | Effectively Debt Free | No or negligible recurring debt commitments |
| `debtTrending` | Debt Trending Up | Debt ratio has increased over past 3 months — trajectory is the concern, not current level |

---

### Category 3: Investment Beliefs

**Domain:** Is the user building long-term wealth?

| Belief ID | Label | Plain English Meaning |
|---|---|---|
| `uninvested` | Not Yet Investing | No active investments detected; full wealth-building upside available |
| `underinvested` | Under-Invested | Investment ratio below age-adjusted target; not building wealth at required rate |
| `appropriatelyInvested` | Appropriately Invested | Investment ratio within expected range for age and income |
| `overConcentrated` | Over-Concentrated | Investment portfolio concentrated in a single instrument or asset class |
| `taxSpaceUnused` | Tax Space Unused | Significant 80C capacity available but not utilized; tax-free returns foregone |

---

### Category 4: Insurance Beliefs

**Domain:** Is the user protected against catastrophic financial shocks?

| Belief ID | Label | Plain English Meaning |
|---|---|---|
| `insuranceUnknown` | Coverage Unknown | No insurance data available; cannot assess protection gap |
| `protectionGapPresent` | Protection Gap Present | Insurance premium is zero or negligible; likely uninsured against health/life risk |
| `underinsured` | Under-Insured | Insurance premium exists but appears insufficient for age/income profile |
| `adequatelyCovered` | Adequately Covered | Insurance premium consistent with expected coverage for profile |
| `overinsured` | Over-Insured | Insurance premium disproportionately high relative to income; opportunity cost of premiums |

---

### Category 5: Goal Beliefs

**Domain:** Are the user's financial goals on track? (One belief per active goal)

Goal beliefs are per-goal. The `BeliefSet` holds a `Map<GoalId, GoalBeliefType>`.

| Belief ID | Label | Plain English Meaning |
|---|---|---|
| `goalAtRisk` | Goal At Risk | Current savings pace will not achieve goal by deadline |
| `goalVulnerable` | Goal Vulnerable | Current pace is close to but below required contribution; small disruption = failure |
| `goalOnTrack` | Goal On Track | Current monthly contribution is meeting or exceeding required rate |
| `goalAheadOfSchedule` | Goal Ahead of Schedule | User is contributing significantly above required rate; milestone may arrive early |
| `goalFundingUnknown` | Goal Funding Unknown | Goal exists but no contribution data available; cannot assess |

---

### Category 6: Behavioral Beliefs

**Domain:** What behavioral patterns are shaping financial outcomes? Note: this category is a bridge to `BehaviorInterpretation`, not a replacement. See Section 9.

| Belief ID | Label | Plain English Meaning |
|---|---|---|
| `behaviorallyUncalibrated` | Not Enough Data | Insufficient transaction history to infer behavioral patterns |
| `impulsiveSpender` | Impulsive Spender | Elevated impulse spending pattern detected from transaction timing/categories |
| `disciplinedSaver` | Disciplined Saver | Consistent saving pattern with low variance — high execution reliability |
| `investmentShy` | Investment Shy | Investment Discipline dimension is low despite financial capacity; behavioral barrier present |
| `consistentExecutor` | Consistent Executor | User follows through on financial commitments; recommendations have high execution probability |

---

### Category 7: Life Stage Beliefs

**Domain:** What is the user's overall financial maturity relative to their life stage?

| Belief ID | Label | Plain English Meaning |
|---|---|---|
| `financiallyFragile` | Financially Fragile | Multiple adverse beliefs present; system is in overall poor financial health |
| `financiallyVulnerable` | Financially Vulnerable | Some adverse beliefs; not fragile but not stable either |
| `financiallyStable` | Financially Stable | No critical adverse beliefs; adequate safety net, manageable debt |
| `financiallyGrowing` | Financially Growing | Stable plus active investment and goal progress; building wealth deliberately |
| `financiallyIndependent` | Financially Independent | Strong safety net, low debt, strong investments, goals on track — approaching financial independence |

Life stage beliefs are **composite beliefs** — they are derived from the outputs of the other six categories, not directly from `FinancialFacts`. They are the highest-order belief in the system.

---

## 4. Domain Model

### 4.1 Core Types

#### `FinancialBeliefType`

An enum covering all 26 named belief IDs across the 7 categories. Organized by category prefix:

```
// Liquidity
liquidityConstrained
liquidityVulnerable
safetyNetAdequate
safetyNetStrong
overLiquid

// Debt
debtBurdened
debtElevated
healthyDebtService
debtFree
debtTrending

// Investment
uninvested
underinvested
appropriatelyInvested
overConcentrated
taxSpaceUnused

// Insurance
insuranceUnknown
protectionGapPresent
underinsured
adequatelyCovered
overinsured

// Behavioral
behaviorallyUncalibrated
impulsiveSpender
disciplinedSaver
investmentShy
consistentExecutor

// Goal (per-goal beliefs, not named as an enum variant)
// Represented as GoalBelief.type: GoalBeliefType enum (separate)

// Life Stage
financiallyFragile
financiallyVulnerable
financiallyStable
financiallyGrowing
financiallyIndependent
```

#### `BeliefCategory`

```
enum BeliefCategory {
  liquidity,
  debt,
  investment,
  insurance,
  goal,
  behavioral,
  lifeStage,
}
```

#### `BeliefMagnitude`

Describes how strongly the belief manifests — not just that it is present, but how severe or how positive.

```
enum BeliefMagnitude {
  severe,     // critical level — immediate action required
  moderate,   // significant level — action important
  mild,       // below-threshold level — awareness only
  neutral,    // borderline — not actionable on its own
  positive,   // favorable — mild positive state
  strong,     // significantly favorable state
}
```

---

#### `FinancialBelief` — The Core Domain Object

```
FinancialBelief {
  // Identity
  type:                 FinancialBeliefType
  category:             BeliefCategory

  // State
  confidence:           double              // 0.0–1.0, bounded by fact confidence
  uncertainty:          double              // 0.0–1.0, orthogonal to confidence
  magnitude:            BeliefMagnitude

  // Evidence
  supportingFacts:      List<FinancialFactKey>   // facts that triggered this belief
  contradictingFacts:   List<FinancialFactKey>   // facts that reduce confidence
  supportingEvidence:   List<BeliefEvidenceItem> // human-readable evidence strings
  contradictingEvidence: List<BeliefEvidenceItem>

  // Temporal
  derivedAt:            DateTime
  expiresAt:            DateTime
  confidenceDecayStart: DateTime            // when confidence starts decaying

  // Recalculation
  recalculationTriggers: List<BeliefTrigger>  // events that invalidate this belief

  // Rule provenance
  inferenceRuleId:      String              // which rule fired (for debugging/versioning)
  engineVersion:        String

  // Computed
  bool get isExpired
  bool get isStale                          // past confidenceDecayStart
  double get effectiveConfidence            // confidence after decay applied
  bool get isActionable                     // confidence >= 0.50 and not expired
  bool get hasConflict                      // both supporting and contradicting facts present
}
```

**`BeliefEvidenceItem`** is a human-readable evidence string with its source fact key and the observed value:

```
BeliefEvidenceItem {
  factKey:    FinancialFactKey
  observed:   String    // "2.1 months" or "38% of income"
  threshold:  String    // "target: 3 months"
  narrative:  String    // "Emergency fund covers 2.1 months — target is 3"
  direction:  BeliefEvidenceDirection  // supporting | contradicting
}
```

---

#### `GoalBelief` — Per-Goal Belief Object

```
GoalBelief {
  goalId:               GoalId
  goalName:             String            // from GoalSnapshot
  type:                 GoalBeliefType    // goalAtRisk | goalVulnerable | goalOnTrack | goalAheadOfSchedule | goalFundingUnknown
  confidence:           double
  monthsToDeadline:     int
  requiredMonthlyContribution: double     // INR
  actualMonthlyContribution:   double     // INR (0 if unknown)
  fundingRatio:         double            // actual / required (0.0–∞)
  derivedAt:            DateTime
  expiresAt:            DateTime
}
```

---

#### `BeliefSet` — The Full User Belief State

```
BeliefSet {
  userId:           UserId

  // Per-category primary beliefs (highest confidence in each category)
  liquidity:        FinancialBelief?
  debt:             FinancialBelief?
  investment:       FinancialBelief?
  insurance:        FinancialBelief?
  behavioral:       FinancialBelief?
  lifeStage:        FinancialBelief?   // derived last, from other categories

  // Per-goal beliefs
  goalBeliefs:      Map<GoalId, GoalBelief>

  // All beliefs including secondary (< 0.50 confidence)
  allBeliefs:       List<FinancialBelief>

  // Set-level metadata
  computedAt:       DateTime
  overallConfidence: double            // average confidence across non-null primary beliefs
  factCompleteness: double             // from FinancialFacts.completeness at computation time

  // Convenience accessors
  bool get isFragile    // lifeStage.type == financiallyFragile
  bool get hasAnyAtRisk // any goalBelief.type == goalAtRisk
  bool get isCalibrated // behavioral.type != behaviorallyUncalibrated

  List<FinancialBelief> get adverseBeliefs     // severity == severe | moderate
  List<FinancialBelief> get actionableBeliefs  // isActionable == true
  List<GoalBelief> get goalsAtRisk             // type == goalAtRisk

  // Returns a neutral BeliefSet for new users with no data
  static BeliefSet empty(UserId)
}
```

---

#### `BeliefInferenceRule` — A Single Named Inference Rule

```
BeliefInferenceRule {
  ruleId:           String             // e.g. "LQ-001", "DT-003"
  targetBelief:     FinancialBeliefType
  category:         BeliefCategory
  requiredFacts:    List<FinancialFactKey>   // facts that must be non-null to fire
  optionalFacts:    List<FinancialFactKey>   // facts that modulate confidence if present

  // The actual inference function signature:
  // BeliefInferenceResult evaluate(FinancialFacts facts, BehaviorInterpretation? behavior)

  // Rule metadata
  ruleVersion:      String
  description:      String
  thresholdBasis:   String  // e.g. "FinancialPolicy.MIN_EMERGENCY_FUND_MONTHS"
}
```

`BeliefInferenceResult` is an intermediate type returned by a rule evaluation before it is assembled into a `FinancialBelief`:

```
BeliefInferenceResult {
  fired:                bool
  confidence:           double
  uncertainty:          double
  magnitude:            BeliefMagnitude
  supportingEvidence:   List<BeliefEvidenceItem>
  contradictingEvidence: List<BeliefEvidenceItem>
  supportingFacts:      List<FinancialFactKey>
  contradictingFacts:   List<FinancialFactKey>
}
```

---

#### `BeliefTrigger` — What Causes Belief Invalidation

```
enum BeliefTriggerType {
  newTransaction,             // any transaction posted
  largeTransaction,           // transaction > 20% monthly income in a single event
  newGoalAdded,               // user adds a goal
  goalContributionChanged,    // goal monthly contribution modified
  incomeChanged,              // income fact changes by > 10%
  newDataSourceConnected,     // SMS or AA connected for the first time
  manualRefreshRequested,     // user pulls-to-refresh on dashboard
  ttlExpired,                 // TTL-based expiry (24h default)
}

BeliefTrigger {
  type:       BeliefTriggerType
  factsAffected: List<FinancialFactKey>   // which facts change when this trigger fires
}
```

---

## 5. Inference Rules

All thresholds reference constants defined in `FinancialPolicy`. Where a constant is not yet in `FinancialPolicy`, the rule section defines the proposed constant alongside the rule.

The rule ID scheme: `[CATEGORY_PREFIX]-[THREE_DIGIT_NUMBER]`. Category prefixes: `LQ` (liquidity), `DT` (debt), `IV` (investment), `IS` (insurance), `GL` (goal), `BH` (behavioral), `LS` (life stage).

---

### Liquidity Rules

#### LQ-001: `liquidityConstrained`

**Target:** `FinancialBeliefType.liquidityConstrained`
**Required facts:** `emergencyFundMonths`, `monthlyIncome`
**Optional facts:** `savingsRate`, `monthlySurplus`

**Primary condition (must hold for rule to fire):**
```
emergencyFundMonths.value < FinancialPolicy.MIN_EMERGENCY_FUND_MONTHS   // < 1.0
```

**Confidence formula:**
```
base = 0.90
// Reduce confidence if EF fact is low-confidence
base = base × emergencyFundMonths.confidence

// Increase severity if monthlySurplus is also negative or near-zero
if (monthlySurplus <= 0):        confidence += 0.08, magnitude = severe
if (monthlySurplus < 0.05×income): confidence += 0.04, magnitude = severe
if (savingsRate < 0.05):           confidence += 0.03

// Contradict if savingsRate is high (rapidly building)
if (savingsRate > 0.30):           confidence -= 0.12, addContradictingFact(savingsRate)
if (savingsRate > 0.40):           confidence -= 0.18

final confidence = clamp(0.0, 1.0)
```

**Magnitude mapping:**
- `emergencyFundMonths < 0.5` → `severe`
- `emergencyFundMonths 0.5–1.0` → `moderate`
- Default (< 1.0) → `moderate`

**Supporting evidence text:** "Emergency fund covers {value} months — minimum safe level is 1 month."
**Contradicting evidence text (if savingsRate high):** "Savings rate of {value}% suggests the buffer may be building quickly."

---

#### LQ-002: `liquidityVulnerable`

**Required facts:** `emergencyFundMonths`
**Primary condition:**
```
emergencyFundMonths.value >= 1.0 AND emergencyFundMonths.value < 3.0
```

**Confidence formula:**
```
base = 0.75
base = base × emergencyFundMonths.confidence
// The closer to 3.0, the lower the confidence (approaching adequacy)
proximityToTarget = emergencyFundMonths.value / 3.0
base = base × (1.0 - 0.20 × proximityToTarget)
final confidence = clamp(0.0, 1.0)
```

**Magnitude:** `mild` (1.0–2.0 months) or `mild` (2.0–3.0 months).

---

#### LQ-003: `safetyNetAdequate`

**Required facts:** `emergencyFundMonths`
**Primary condition:**
```
emergencyFundMonths.value >= 3.0 AND emergencyFundMonths.value < 6.0
```
**Base confidence:** 0.85 × emergencyFundMonths.confidence
**Magnitude:** `positive`

---

#### LQ-004: `safetyNetStrong`

**Required facts:** `emergencyFundMonths`
**Primary condition:**
```
emergencyFundMonths.value >= FinancialPolicy.TARGET_EMERGENCY_FUND_MONTHS   // >= 6.0
```
**Base confidence:** 0.90 × emergencyFundMonths.confidence
**Magnitude:** `strong`

---

#### LQ-005: `overLiquid`

**Required facts:** `emergencyFundMonths`, `investmentRatio`
**Primary condition:**
```
emergencyFundMonths.value > 12.0 AND investmentRatio.value < 0.05
```
**Rationale:** More than 12 months of cash held while barely investing — opportunity cost of excess liquidity.
**Base confidence:** 0.70 × min(emergencyFundMonths.confidence, investmentRatio.confidence)
**Magnitude:** `moderate` (the concern is missed growth, not immediate danger)

---

### Debt Rules

#### DT-001: `debtBurdened`

**Required facts:** `debtRatio`
**Primary condition:**
```
debtRatio.value > FinancialPolicy.SAFE_EMI_INCOME_RATIO   // > 0.40
```
**Confidence formula:**
```
base = 0.88 × debtRatio.confidence
if (debtRatio.value > 0.50): magnitude = severe, base += 0.05
if (debtRatio.value > 0.60): magnitude = severe, base += 0.05
```
**Magnitude:** `moderate` (0.40–0.50), `severe` (> 0.50)

---

#### DT-002: `debtElevated`

**Required facts:** `debtRatio`
**Primary condition:**
```
debtRatio.value >= 0.30 AND debtRatio.value <= 0.40
```
**Base confidence:** 0.75 × debtRatio.confidence
**Magnitude:** `mild`

---

#### DT-003: `healthyDebtService`

**Primary condition:** `debtRatio.value > 0.10 AND debtRatio.value < 0.30`
**Base confidence:** 0.85 × debtRatio.confidence
**Magnitude:** `positive`

---

#### DT-004: `debtFree`

**Primary condition:** `debtRatio.value <= 0.10` OR `recurringCommitmentsTotal.value <= 0`
**Note:** Confidence penalty if `recurringCommitmentsTotal` is null (cannot confirm no debt):
```
if (recurringCommitmentsTotal == null): base confidence = 0.50 (low certainty)
else: base confidence = 0.88 × debtRatio.confidence
```
**Magnitude:** `strong`

---

#### DT-005: `debtTrending`

**Required facts:** `debtRatio` at current time AND historical `debtRatio` (from `FinancialFactSnapshot`)
**Primary condition:**
```
currentDebtRatio > priorDebtRatio × 1.10   // 10% increase over prior period
```
**Note:** This rule requires temporal reasoning — it depends on fact snapshots, not just current facts. The `BeliefInferenceEngine` must pass the previous snapshot alongside the current `FinancialFacts`. This rule fires even if `debtRatio` is in the healthy range, because trajectory is the concern.
**Base confidence:** 0.70 × min(current.confidence, prior.confidence)
**Magnitude:** `mild` (10–25% increase), `moderate` (> 25% increase)

---

### Investment Rules

#### IV-001: `uninvested`

**Required facts:** `existingInvestmentTotal`, `investmentRatio`
**Primary condition:**
```
existingInvestmentTotal.value <= 0 OR investmentRatio.value <= 0.001
```
**Confidence:**
```
base = 0.90 × min(existingInvestmentTotal.confidence, investmentRatio.confidence)
// Penalize if investmentsUntracked data gap is present in DataConfidenceReport
if (dataGap.investmentsUntracked): base = base × 0.60  // could be invested, just not tracked
```
**Magnitude:** `moderate`

---

#### IV-002: `underinvested`

**Required facts:** `investmentRatio`, `ageYears`
**Primary condition:**
```
// Age-adjusted investment ratio target
ageAdjustedTarget = FinancialPolicy.investmentTargetForAge(ageYears)
// Simple heuristic: target = max(0.10, (age - 20) / 200)
// Age 25 → 0.10, Age 30 → 0.10, Age 40 → 0.10 + (40-30)/200 = 0.15
investmentRatio.value < ageAdjustedTarget × 0.70  // firing at 70% of target
```
**Confidence:**
```
base = 0.80 × min(investmentRatio.confidence, ageYears.confidence)
shortfallRatio = investmentRatio.value / ageAdjustedTarget
// The bigger the shortfall, the higher the confidence
base = base × (1.0 + (1.0 - shortfallRatio) × 0.15)
// Contradict: if emergency fund is < 3 months, underinvested is expected — reduce concern
if (liquidityBelief.type == liquidityConstrained): base -= 0.20, addContradiction
final confidence = clamp(0.0, 1.0)
```
**Magnitude:** `moderate` (shortfall 30–60%), `severe` (shortfall > 60%)

---

#### IV-003: `appropriatelyInvested`

**Primary condition:**
```
investmentRatio.value >= ageAdjustedTarget × 0.70 AND
investmentRatio.value <= ageAdjustedTarget × 2.0
```
**Base confidence:** 0.82 × investmentRatio.confidence
**Magnitude:** `positive`

---

#### IV-004: `overConcentrated`

**Required facts:** `existingInvestmentTotal`
**Note:** This rule requires knowledge of portfolio composition — not currently in `FinancialFacts`. This rule is defined but **cannot fire until a portfolio breakdown fact is added** (Sprint 9+ scope). The rule definition is included here to reserve the belief slot and document the intended logic.
**Primary condition (future):**
```
topAssetClassFraction > 0.80   // > 80% in one asset class
```
**Proposed new fact:** `FinancialFactKey.topAssetClassFraction`
**Magnitude:** `moderate`

---

#### IV-005: `taxSpaceUnused`

**Required facts:** `taxEfficiency`, `monthlyIncome`
**Primary condition:**
```
taxEfficiency.value < 0.50 AND
annualIncome > FinancialPolicy.SECTION_80C_LIMIT × 0.50  // earning enough to benefit from 80C
```
**Base confidence:** 0.75 × taxEfficiency.confidence
**Magnitude:** `mild` (taxEfficiency 0.30–0.50), `moderate` (taxEfficiency < 0.30)

---

### Insurance Rules

#### IS-001: `insuranceUnknown`

**Condition:**
```
monthlyInsurancePremium == null OR
dataConfidence.hasGap(DataGapType.insuranceUntracked)
```
**Base confidence:** 0.95 (high confidence that we do not know — this is a data gap belief, not a risk belief)
**Magnitude:** `neutral`
**Note:** This belief is the default when no insurance data exists. It prevents other insurance beliefs from being inferred with false precision.

---

#### IS-002: `protectionGapPresent`

**Required facts:** `monthlyInsurancePremium`, `monthlyIncome`
**Primary condition:**
```
monthlyInsurancePremium.value < 500   // INR — below any meaningful coverage threshold
```
**Confidence:** 0.82 × monthlyInsurancePremium.confidence
**Magnitude:** `severe` (explicit absence of coverage is the most urgent insurance state)

---

#### IS-003: `underinsured`

**Required facts:** `monthlyInsurancePremium`, `monthlyIncome`, `ageYears`
**Primary condition:**
```
// Expected premium band: age × 150 to age × 400 INR/month (rough heuristic)
expectedMinPremium = ageYears × 150
monthlyInsurancePremium.value >= 500 AND
monthlyInsurancePremium.value < expectedMinPremium
```
**Confidence:** 0.65 × monthlyInsurancePremium.confidence
**Note:** Lower confidence than `protectionGapPresent` because the threshold is heuristic, not policy-defined.
**Magnitude:** `moderate`

---

#### IS-004: `adequatelyCovered`

**Primary condition:**
```
monthlyInsurancePremium.value >= expectedMinPremium AND
monthlyInsurancePremium.value <= expectedMinPremium × 3.0
```
**Base confidence:** 0.72 × monthlyInsurancePremium.confidence
**Magnitude:** `positive`

---

#### IS-005: `overinsured`

**Primary condition:**
```
monthlyInsurancePremium.value > expectedMinPremium × 4.0 AND
// Premium exceeds 5% of monthly income — likely over-allocated
monthlyInsurancePremium.value > monthlyIncome × 0.05
```
**Base confidence:** 0.60 × monthlyInsurancePremium.confidence
**Magnitude:** `mild` (premiums are not dangerous, just inefficient)

---

### Goal Rules

#### GL-001: `goalAtRisk`

**Required data:** `GoalSnapshot` (target, savedAmount, deadline, monthlyContribution), `monthlySurplus`
**Primary condition:**
```
monthsToDeadline = deadline.monthsFrom(now)
outstandingAmount = target - savedAmount
requiredMonthlyContribution = outstandingAmount / monthsToDeadline
// Using investment growth factor from FinancialPolicy.sipRateForHorizon:
// actual required = SIP formula not just linear division
fundingRatio = actualMonthlyContribution / requiredMonthlyContribution
fundingRatio < 0.60   // covering less than 60% of required contribution
```
**Confidence:**
```
base = 0.85 × goalDataConfidence
// Higher confidence when deadline is close (less time to correct)
if (monthsToDeadline < 6): base += 0.08
// Lower confidence if surplus suggests ability to increase contribution
if (monthlySurplus > requiredMonthlyContribution × 0.50): base -= 0.10
```
**Magnitude:** `severe` (fundingRatio < 0.30), `moderate` (0.30–0.60)

---

#### GL-002: `goalVulnerable`

**Primary condition:** `fundingRatio >= 0.60 AND fundingRatio < 0.90`
**Base confidence:** 0.75
**Magnitude:** `mild`

---

#### GL-003: `goalOnTrack`

**Primary condition:** `fundingRatio >= 0.90 AND fundingRatio <= 1.20`
**Base confidence:** 0.85
**Magnitude:** `positive`

---

#### GL-004: `goalAheadOfSchedule`

**Primary condition:** `fundingRatio > 1.20`
**Base confidence:** 0.85
**Magnitude:** `strong`

---

### Behavioral Rules

Behavioral beliefs in this category are **derived from `BehaviorInterpretation`**, not from `FinancialFacts` directly. The rules translate `BehaviorDimensionType` scores into named beliefs. See Section 9 for the full relationship.

#### BH-001: `behaviorallyUncalibrated`

**Condition:** `BehaviorInterpretation.isCalibrated == false` OR `behavior == null`
**Base confidence:** 0.95
**Magnitude:** `neutral`

---

#### BH-002: `impulsiveSpender`

**Required:** `BehaviorInterpretation.dimensions[impulsiveness].score`
**Primary condition:**
```
impulsiveness.score >= 65 AND impulsiveness.confidence >= 0.50
```
**Confidence:** `impulsiveness.confidence`
**Magnitude:** `moderate` (score 65–80), `severe` (score > 80)

---

#### BH-003: `disciplinedSaver`

**Primary condition:**
```
savingDiscipline.score >= 70 AND consistency.score >= 60
AND savingDiscipline.confidence >= 0.55
```
**Confidence:** min(savingDiscipline.confidence, consistency.confidence)
**Magnitude:** `positive`

---

#### BH-004: `investmentShy`

**Required:** `investmentRatio` fact AND `BehaviorInterpretation.dimensions[investmentDiscipline]`
**Primary condition:**
```
// Financial capacity exists but investment behavior is low
savingsRate.value > 0.15 AND          // has money to invest
investmentRatio.value < 0.05 AND      // not investing
investmentDiscipline.score < 45       // behavioral dimension confirms pattern
```
**Confidence:** min(investmentDiscipline.confidence, investmentRatio.confidence)
**Magnitude:** `moderate`

---

#### BH-005: `consistentExecutor`

**Primary condition:**
```
consistency.score >= 70 AND
LearningSnapshot.completedCycles >= 3 AND
LearningSnapshot.maturity >= 0.40
```
**Confidence:** min(consistency.confidence, LearningSnapshot.maturity)
**Magnitude:** `strong`

---

### Life Stage Rules (Composite)

Life stage beliefs are derived from the outputs of the other 6 categories, not from `FinancialFacts` directly.

#### LS-001: `financiallyFragile`

**Condition (any two of):**
```
liquidity.type IN [liquidityConstrained] WITH confidence > 0.60
debt.type IN [debtBurdened] WITH confidence > 0.60
investment.type IN [uninvested] WITH confidence > 0.70
goal.anyAtRisk WITH confidence > 0.65
```
**Confidence:** average confidence of the triggering beliefs
**Magnitude:** `severe`

---

#### LS-002: `financiallyVulnerable`

**Condition:**
```
liquidity.type IN [liquidityVulnerable] OR
debt.type IN [debtElevated] OR
(goal.anyAtRisk WITH confidence 0.40–0.64)
AND NOT financiallyFragile.fired
```
**Magnitude:** `moderate`

---

#### LS-003: `financiallyStable`

**Condition:**
```
liquidity.type IN [safetyNetAdequate, safetyNetStrong] AND
debt.type IN [healthyDebtService, debtFree] AND
NOT goal.anyAtRisk
```
**Magnitude:** `positive`

---

#### LS-004: `financiallyGrowing`

**Condition:**
```
financiallyStable AND
investment.type IN [appropriatelyInvested] AND
(goal.anyOnTrack OR goal.anyAheadOfSchedule)
```
**Magnitude:** `strong`

---

#### LS-005: `financiallyIndependent`

**Condition:**
```
financiallyGrowing AND
emergencyFundMonths > 12 AND
investmentRatio > 0.25 AND
debtRatio < 0.10 AND
goal.allOnTrack
```
**Note:** This is an aspirational belief — expected to fire for very few users in the current system population. It exists to give the Decision Engine a terminal positive state.
**Magnitude:** `strong`

---

## 6. Belief Confidence Model

### 6.1 Confidence Hierarchy

Belief confidence is never higher than the confidence of the facts it depends on. This is the key invariant that prevents false precision:

```
BeliefConfidence = RuleBaseConfidence × ProductOf(FactConfidences) × DecayFactor
```

More precisely, for a rule with `n` required facts:

```
factConfidenceCap = min(fact_1.confidence, fact_2.confidence, ..., fact_n.confidence)
rawBeliefConfidence = ruleFireConfidence (computed by the rule logic, includes contradictions)
cappedConfidence = min(rawBeliefConfidence, factConfidenceCap)
effectiveConfidence = cappedConfidence × decayFactor(ageInHours)
```

The `factConfidenceCap` ensures that if any required fact has low confidence (e.g., `emergencyFundMonths.confidence = 0.35` because it was estimated from limited transactions), the belief's confidence is capped at 0.35 regardless of how cleanly the rule fired.

This connects to the existing `DataConfidenceReport.recommendationConfidenceCap` — the belief's effective confidence is further bounded by the overall recommendation confidence cap.

### 6.2 Confidence Modifiers

Three types of confidence modifiers apply to all rules:

**Amplifiers** (increase confidence within the cap):
- Contradicting facts are absent → no penalty
- Multiple facts all point in the same direction → +0.05 to +0.10
- Fact is verified (AA-sourced) → +0.05
- Fact is fresh (< 24 hours old) → no penalty (baseline)

**Reducers** (decrease confidence):
- Contradicting facts present → calculated reduction per rule (see Section 5)
- Fact is stale (> 7 days) → -0.10
- Fact confidence < 0.50 → applied via cap
- DataGap present for a relevant data type → -0.15 to -0.30

**Floor:** No belief's effective confidence drops below `0.10`. A belief at confidence `0.10` is technically present in the `BeliefSet` but is marked `isActionable = false` and will not be used by downstream engines.

### 6.3 Uncertainty Model

Following the pattern of `DimensionInterpretation`, beliefs carry separate confidence and uncertainty:

- **Confidence** answers: "How sure are we that this belief is the correct characterization?"
- **Uncertainty** answers: "How much is our conclusion limited by missing or conflicting data?"

A belief with `confidence: 0.80, uncertainty: 0.15` is strongly supported and well-evidenced.
A belief with `confidence: 0.65, uncertainty: 0.55` is the most likely explanation given what we know, but we are missing key data that could change the conclusion.

**Uncertainty is set by:**
- Number of required facts that are null (each null required fact adds 0.15 uncertainty)
- Presence of contradicting evidence (adds 0.10 per contradicting fact)
- Low fact confidence on any required fact (adds 0.10 if any required fact < 0.50)

### 6.4 Composite Belief Confidence (Life Stage)

Life stage beliefs are derived from primary beliefs, not from raw facts. Their confidence is computed differently:

```
lifeStageConfidence = weightedAverage(
  triggeringBeliefs,
  weight = belief.confidence × (1 - belief.uncertainty)
)
```

The life stage belief cannot be more confident than the average confidence of the beliefs it is composed from.

---

## 7. Expiry and Refresh

### 7.1 TTL Model

Every belief has a `derivedAt` and `expiresAt`. The default TTL for all beliefs is **24 hours** for users with active data sources (SMS or AA connected), and **72 hours** for users in manual-only mode (beliefs are less likely to change rapidly without real transaction data).

```
defaultTtl(DataConfidenceReport) = dataConfidence.hasSmsConnected || dataConfidence.hasAaConnected
  ? Duration(hours: 24)
  : Duration(hours: 72)

expiresAt = derivedAt + defaultTtl
```

Life stage beliefs (composite) use the minimum TTL of the primary beliefs they depend on.

### 7.2 Confidence Decay

Beliefs that have not expired but are past their `confidenceDecayStart` lose 0.10 confidence per 24-hour period:

```
confidenceDecayStart = derivedAt + Duration(hours: 36)
hoursOverDecayStart = max(0, (now - confidenceDecayStart).inHours)
periodsElapsed = hoursOverDecayStart / 24
decayFactor = max(0.20 / rawConfidence, 1.0 - (0.10 × periodsElapsed / rawConfidence))
effectiveConfidence = rawConfidence × decayFactor
```

The floor `0.20 / rawConfidence` ensures the effective confidence does not drop below 0.20 due to decay alone, even if the belief is very stale but not yet expired.

### 7.3 Event-Driven Invalidation

The following events immediately expire specific beliefs, overriding TTL:

| Trigger Event | Beliefs Invalidated |
|---|---|
| Any transaction posted | `liquidityConstrained`, `liquidityVulnerable`, `safetyNetAdequate`, `safetyNetStrong`, `overLiquid` (recalculate liquidity) |
| Large transaction (> 20% monthly income) | All liquidity beliefs + all goal beliefs |
| Income change (> 10%) | All beliefs except insurance beliefs |
| New goal added | All goal beliefs + life stage beliefs |
| Goal contribution changed | All goal beliefs for that goal + life stage beliefs |
| SMS connected for first time | All beliefs (full recalculation with higher-confidence facts) |
| AA connected for first time | All beliefs (full recalculation with verified facts) |
| Manual refresh (user-triggered) | All beliefs |
| `debtRatio` change > 5% | All debt beliefs + life stage beliefs |
| New investment transaction | All investment beliefs + life stage beliefs |

Invalidation does not delete beliefs — it sets `expiresAt = now()`, causing the next call to `BeliefSet.isExpired` to return true and triggering lazy re-inference.

### 7.4 Lazy vs Eager Re-Inference

**Lazy re-inference (default):** Beliefs are re-inferred only when the `BeliefSet` is consumed (e.g., when `GetDashboardFeedUseCase` builds `FinancialReasoningContext`). If a transaction posts at 2:00 PM but the user does not open the app, no re-inference happens until next app launch.

**Eager re-inference (future):** When SMS intelligence is running in the background, a background service can eagerly re-infer beliefs when a `largeTransaction` trigger fires, pre-computing the new `BeliefSet` and caching it. This is a Phase 10+ concern.

For v1 implementation: lazy re-inference only.

### 7.5 Re-inference Rate Limiting

To prevent belief thrashing (rapidly changing beliefs on every small transaction), apply a **minimum re-inference interval** of 4 hours per belief category. If a belief in the liquidity category was inferred within the last 4 hours, skip re-inference even if a trigger fired, unless the trigger is `largeTransaction` or `manualRefreshRequested`.

---

## 8. Integration Point — BeliefSet in FinancialReasoningContext

### 8.1 The Updated FinancialReasoningContext

`BeliefSet` slots into `FinancialReasoningContext` as an optional field, preserving v1 compatibility:

```dart
class FinancialReasoningContext {
  const FinancialReasoningContext({
    required this.facts,
    required this.dataConfidence,
    this.behavior,
    this.learningSnapshot,
    this.goals = const [],
    this.beliefs,          // NEW — null in v1, populated in v2
    this.contextLabel,
  });

  final FinancialFacts facts;
  final DataConfidenceReport dataConfidence;
  final BehaviorInterpretation? behavior;
  final LearningSnapshot? learningSnapshot;
  final List<GoalSnapshot> goals;
  final BeliefSet? beliefs;   // NEW
  final String? contextLabel;

  // Convenience — engines use this to safely access beliefs
  BeliefSet get beliefSetOrEmpty => beliefs ?? BeliefSet.empty(/* userId inferred */);
}
```

### 8.2 How Engines Consume BeliefSet

Engines access beliefs via the `BeliefSet` interface, not by re-running threshold logic:

**Before (v1 pattern):**
```dart
// Inside DecisionEngine — threshold logic duplicated
if (facts.emergencyFundMonthsValue < 1.0) {
  return _buildBuildEmergencyFundDecision(facts);
}
```

**After (v2 pattern):**
```dart
// Inside DecisionEngine — consume the belief
final beliefs = context.beliefSetOrEmpty;
if (beliefs.liquidity?.type == FinancialBeliefType.liquidityConstrained &&
    beliefs.liquidity!.isActionable) {
  return _buildBuildEmergencyFundDecision(context, beliefs.liquidity!);
}
```

The engine no longer performs inference — it acts on pre-inferred beliefs. The threshold logic lives exclusively in `BeliefInferenceRule` implementations.

### 8.3 Belief-to-Explanation Passthrough

`FinancialBelief.supportingEvidence` and `contradictingEvidence` are pre-formatted `BeliefEvidenceItem` objects that the Explainability Engine can directly include in `ExplanationData.because[]` and `ExplanationData.evidence[]`:

```dart
// In ExplainabilityEngine, assembling explanation for a DecisionResponse
final liquidityBelief = context.beliefs?.liquidity;
if (liquidityBelief != null) {
  explanation.because.addAll(
    liquidityBelief.supportingEvidence.map((e) => e.narrative)
  );
  explanation.limitations.addAll(
    liquidityBelief.contradictingEvidence.map((e) => e.narrative)
  );
}
```

This eliminates the current problem where each engine re-writes similar explanations from scratch.

### 8.4 BeliefSet Construction Flow

The `BeliefInferenceEngine` (new engine interface) is responsible for producing `BeliefSet` from `FinancialFacts` + `BehaviorInterpretation` + `List<GoalSnapshot>`:

```
FinancialFacts
BehaviorInterpretation?     →  BeliefInferenceEngine  →  BeliefSet
List<GoalSnapshot>
DataConfidenceReport
FinancialFactSnapshot?      (for DT-005 trending rule)
```

The `BeliefInferenceEngine` is an interface in the domain layer. `RuleBasedBeliefInferenceEngine` is the concrete implementation in the infrastructure layer, following the same pattern as `RuleBasedHealthScoreEngine` from Sprint 6.

---

## 9. Relationship to BehaviorInterpretation

### 9.1 What BehaviorInterpretation Already Does

`BehaviorInterpretation` already contains beliefs, in a different vocabulary:

- **10 `DimensionInterpretation` objects** — each with score, confidence, uncertainty, supporting/opposing evidence, trend. These are behavioral beliefs about how the user behaves.
- **`FinancialPersonality`** — an archetype belief (guardian, accumulator, builder, optimizer).
- **`BehaviorIntent[]`** — higher-order inferences like `buildEmergencyBuffer`, `increaseInvestments`. These are behavioral beliefs about what the user should do.
- **`BehaviorContradiction[]`** — detected contradictions between behavioral beliefs.

This is already a full belief system, but scoped to **behavioral** facts (transaction timing, SIP consistency, impulse windows, etc.). It is produced by the `BehaviorInterpretationEngine`.

### 9.2 The Boundary Rule

The distinction is strictly drawn by the source of evidence:

| System | Evidence Source | Example |
|---|---|---|
| `BehaviorInterpretation` | Behavioral signals (transaction patterns, SIP timing, impulse windows, consistency over time) | "User has high impulsiveness because 73% of transactions occur within 48 hours of paycheck" |
| `BeliefSet` (financial beliefs) | Financial facts (ratios, amounts, calculated metrics) | "User is liquidity constrained because emergency fund = 2.1 months < 3-month target" |

The same phenomenon can be described by both systems with no duplication, because they describe different aspects:

> **BehaviorInterpretation:** `investmentDiscipline.score: 22/100` — "User has low investment discipline, evidenced by 3 skipped SIPs and no new investment in 4 months."
>
> **BeliefSet:** `underinvested` — "User's investment ratio (3%) is below age-adjusted target (10%) for a 32-year-old."

Both are true. The behavioral belief describes the pattern causing the problem. The financial belief describes the resulting financial state. The Decision Engine needs both: it uses the financial belief to know what to recommend, and the behavioral belief to know how to frame it (a user with `investmentShy` needs a different message than a user who is `underinvested` due to `liquidityConstrained`).

### 9.3 Behavioral Beliefs in BeliefSet — The Bridge Category

Category 6 (Behavioral Beliefs in `BeliefSet`) is the one category that bridges the two systems. These beliefs are **derived from `BehaviorInterpretation`**, not from `FinancialFacts`. They serve a specific purpose: they translate the rich 10-dimension behavioral model into a small number of named financial consequences that the rest of the `BeliefSet` reasoning can act on.

The rule: if a belief can be expressed purely in terms of `BehaviorInterpretation` outputs (dimension scores, personality, intent), it belongs in the behavioral category of `BeliefSet`. If it requires `FinancialFacts` (amounts, ratios, thresholds), it belongs in the financial belief categories (liquidity, debt, investment, etc.).

**No duplication:** `BehaviorInterpretation.dimensions[impulsiveness]` carries the full evidence chain with transaction-level detail. `BeliefSet.behavioral.impulsiveSpender` is a summary node that says "yes, impulsive spending is present at the financial-decision level" without duplicating the evidence. The Decision Engine accesses the full behavioral evidence through `BehaviorInterpretation`; it accesses the financial consequence through `BeliefSet`.

### 9.4 Mutual Influence (Future)

In Phase 12+, beliefs and behavioral interpretation will mutually influence each other:

- `liquidityConstrained` belief (financial) should amplify the `protectCash` behavioral intent in `BehaviorInterpretation`.
- `disciplinedSaver` belief (behavioral) should increase confidence in `safetyNetAdequate` belief (financial) — a disciplined saver is more likely to maintain their buffer.

This mutual influence is out of scope for the initial Belief Engine implementation. The v1 belief system treats `BehaviorInterpretation` as a read-only input, not as a bidirectional peer.

---

## 10. Migration from v1

### 10.1 Migration Strategy: Additive, Non-Breaking

The v1 system must continue to work throughout the migration. The principle: beliefs are introduced additively — the old code paths remain functional and are deprecated, not deleted.

**Phase A: Introduce the domain model (no behavior change)**
1. Add `FinancialBeliefType`, `FinancialBelief`, `GoalBelief`, `BeliefSet`, `BeliefInferenceRule` to `mobile/lib/domain/reasoning/`.
2. Add `BeliefSet? beliefs` to `FinancialReasoningContext` as a nullable field.
3. Add `BeliefSet.empty()` static factory.
4. `flutter analyze` must pass with zero errors.
5. No engine behavior changes — beliefs are null everywhere.

**Phase B: Implement BeliefInferenceEngine (shadow mode)**
1. Create `BeliefInferenceEngine` interface in domain layer.
2. Create `RuleBasedBeliefInferenceEngine` in infrastructure layer, implementing rules from Section 5.
3. Wire into DI alongside existing engines.
4. Run the engine on every `GetDashboardFeedUseCase` call, populating `FinancialReasoningContext.beliefs`.
5. Log computed beliefs for debugging, but no engine consumes them yet.
6. Verify: all existing tests pass. Belief output is observable in debug logs.

**Phase C: Migrate HealthScoreEngine to consume beliefs**
1. `RuleBasedHealthScoreEngine` switches liquidity, debt, and investment axes to read from `BeliefSet` instead of re-deriving from `FinancialFacts`.
2. Keep the old code paths behind a `useBeliefLayer` flag in `FinancialPolicy` or feature flags.
3. Run both paths in parallel for 2 weeks; verify health score outputs are equivalent (within ±2 points).
4. Disable the old paths when equivalence is confirmed.

**Phase D: Migrate DecisionEngine**
1. Same pattern as Phase C for the Decision Engine.
2. This is the most impactful migration — the engine's recommendation logic changes from threshold-based to belief-based.
3. A/B test: route 10% of decisions through belief-based path, compare recommendation quality (proxy: acceptance rate, lifecycle completion rate).

**Phase E: Remove deprecated threshold logic**
1. Once Phase C and D are stable, delete the old threshold logic from engines.
2. Update `FinancialPolicy` to remove thresholds that are now exclusively in `BeliefInferenceRule` definitions.
3. Final state: facts → beliefs → decisions. No direct facts-to-decisions path remains.

### 10.2 Feature Flag

During migration, the belief layer is controlled by a single feature flag:

```dart
// In FinancialPolicy or FeatureFlags:
static const bool enableBeliefLayer = false;  // Phase A–B: false
                                               // Phase C+: true with rollout
```

When `enableBeliefLayer = false`, all engines fall back to v1 threshold logic. When true, engines consume beliefs. The flag is removed in Phase E.

### 10.3 Equivalence Test Requirement

Before Phase E (removal of old logic), the following equivalence tests must pass:

1. For 100 synthetic user profiles spanning the full range of `FinancialFacts` values, the belief-derived health score must agree with the facts-derived health score within ±2 points on the 0–100 scale.
2. For the same profiles, the top recommendation type (SIP, emergency fund, debt reduction) must match between v1 and v2 in at least 92% of cases.
3. For profiles where v1 and v2 disagree, the belief-based recommendation must be reviewed manually and confirmed to be the more appropriate recommendation (i.e., the disagreement is an improvement, not a regression).

---

## 11. Invariants

The following invariants must hold for every `FinancialBelief` in the system. Any belief that violates an invariant must be rejected by the `BeliefInferenceEngine` before being added to the `BeliefSet`.

### Belief-Level Invariants

1. **Confidence bounds.** `confidence ∈ [0.0, 1.0]`. No belief may have confidence outside this range. The engine must `clamp(0.0, 1.0)` after applying all modifiers.

2. **Uncertainty bounds.** `uncertainty ∈ [0.0, 1.0]`. Uncertainty is independent of confidence and may independently hit either bound.

3. **At least one supporting fact.** Every belief must have `supportingFacts.length >= 1`. A belief with no supporting facts is an inference error and must not be added to `BeliefSet`. The `BeliefInferenceEngine` must validate this before assembling the result.

4. **Supporting evidence matches supporting facts.** `supportingEvidence.length >= 1` and each item in `supportingEvidence` must reference a key in `supportingFacts`. If a rule fires with evidence but no supporting facts listed, it is a rule authoring bug.

5. **Expiry after derivation.** `expiresAt > derivedAt`. A belief with `expiresAt <= derivedAt` is an invalid belief and must be rejected.

6. **Inference rule must be cited.** `inferenceRuleId` must be non-null and must correspond to a registered rule. This enables debugging ("which rule produced this belief?") and versioned backtesting.

7. **Confidence floor.** `effectiveConfidence >= 0.10` while the belief is not expired. Below 0.10 the belief has no predictive value; the engine should mark it as non-actionable and exclude it from downstream reasoning.

### BeliefSet-Level Invariants

8. **No two beliefs of the same type.** Within a `BeliefSet`, `allBeliefs` must not contain two `FinancialBelief` instances with the same `type`. If two rules for the same belief type fire (possible during transition), the one with higher `effectiveConfidence` wins.

9. **Life stage belief must be derived last.** The `lifeStage` belief in `BeliefSet` must be derived after all other category beliefs are computed. It cannot reference primary beliefs that have not yet been inferred.

10. **BeliefSet confidence bound.** `BeliefSet.overallConfidence` must equal the mean of the effective confidences of its non-null primary beliefs, and must be ≤ `DataConfidenceReport.recommendationConfidenceCap`. The `BeliefInferenceEngine` must apply this cap before returning the `BeliefSet`.

11. **Empty is safe.** `BeliefSet.empty()` must be a valid, fully-constructed object that any engine can safely consume without null-pointer errors. All accessor methods on `BeliefSet.empty()` return safe defaults (empty lists, null primaries, `isFragile = false`, `hasAnyAtRisk = false`).

12. **Goal beliefs require active goals.** If `List<GoalSnapshot>` is empty, `BeliefSet.goalBeliefs` must be an empty map. The engine must not infer goal beliefs in the absence of goal data.

---

## Appendix A: Belief ID Reference

| ID | Category | Belief Type |
|---|---|---|
| LQ-001 | Liquidity | `liquidityConstrained` |
| LQ-002 | Liquidity | `liquidityVulnerable` |
| LQ-003 | Liquidity | `safetyNetAdequate` |
| LQ-004 | Liquidity | `safetyNetStrong` |
| LQ-005 | Liquidity | `overLiquid` |
| DT-001 | Debt | `debtBurdened` |
| DT-002 | Debt | `debtElevated` |
| DT-003 | Debt | `healthyDebtService` |
| DT-004 | Debt | `debtFree` |
| DT-005 | Debt | `debtTrending` |
| IV-001 | Investment | `uninvested` |
| IV-002 | Investment | `underinvested` |
| IV-003 | Investment | `appropriatelyInvested` |
| IV-004 | Investment | `overConcentrated` |
| IV-005 | Investment | `taxSpaceUnused` |
| IS-001 | Insurance | `insuranceUnknown` |
| IS-002 | Insurance | `protectionGapPresent` |
| IS-003 | Insurance | `underinsured` |
| IS-004 | Insurance | `adequatelyCovered` |
| IS-005 | Insurance | `overinsured` |
| GL-001 | Goal | `goalAtRisk` |
| GL-002 | Goal | `goalVulnerable` |
| GL-003 | Goal | `goalOnTrack` |
| GL-004 | Goal | `goalAheadOfSchedule` |
| BH-001 | Behavioral | `behaviorallyUncalibrated` |
| BH-002 | Behavioral | `impulsiveSpender` |
| BH-003 | Behavioral | `disciplinedSaver` |
| BH-004 | Behavioral | `investmentShy` |
| BH-005 | Behavioral | `consistentExecutor` |
| LS-001 | Life Stage | `financiallyFragile` |
| LS-002 | Life Stage | `financiallyVulnerable` |
| LS-003 | Life Stage | `financiallyStable` |
| LS-004 | Life Stage | `financiallyGrowing` |
| LS-005 | Life Stage | `financiallyIndependent` |

---

## Appendix B: Facts Required Per Belief Category

| Belief Category | Required FinancialFactKeys |
|---|---|
| Liquidity | `emergencyFundMonths`, `monthlyIncome`, (`savingsRate`, `monthlySurplus` optional) |
| Debt | `debtRatio`, (`recurringCommitmentsTotal` optional for DT-004) |
| Investment | `investmentRatio`, `existingInvestmentTotal`, (`ageYears` for IV-002, `taxEfficiency` for IV-005) |
| Insurance | `monthlyInsurancePremium`, (`monthlyIncome` for IS-003–IS-005) |
| Goal | `GoalSnapshot` data (not in `FinancialFacts`) + `monthlySurplus` |
| Behavioral | `BehaviorInterpretation` (not in `FinancialFacts`) |
| Life Stage | Derived from other category beliefs — no direct fact dependency |

---

## Appendix C: Data Gaps and Belief Degradation

| DataGapType | Beliefs Most Affected | Confidence Penalty |
|---|---|---|
| `noSmsConnected` | Liquidity, Debt | −0.15 (facts less fresh, less reliable) |
| `noAaConnected` | All financial categories | −0.10 (cannot verify any fact) |
| `insufficientTransactionHistory` | All financial categories | −0.20 (averages unreliable) |
| `merchantsUnresolved` | Behavioral | −0.10 (spending categories inaccurate) |
| `investmentsUntracked` | Investment | −0.30 (`uninvested` fires at reduced confidence; could be invested elsewhere) |
| `insuranceUntracked` | Insurance | Forces `insuranceUnknown` belief, blocks all other insurance beliefs |
| `incomeNotDetected` | All income-dependent beliefs | All income-dependent beliefs fire at ≤ 0.30 confidence |
