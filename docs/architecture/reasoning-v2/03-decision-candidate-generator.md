# Decision Candidate Generator — Design Document

**Document:** `reasoning-v2/03-decision-candidate-generator.md`  
**Status:** Design complete — not yet implemented  
**Relates to:** Phase 9–12 Intelligence Roadmap (Decision Engine v3)  
**Depends on:** `financial_reasoning_context.dart`, `decision_axis.dart`, `financial_facts.dart`, `goal_snapshot.dart`

---

## Table of Contents

1. [Overview — Why Candidate Generation Is Architecturally Superior](#1-overview)
2. [Research Findings](#2-research-findings)
3. [Complete Candidate Taxonomy](#3-complete-candidate-taxonomy)
4. [Domain Model](#4-domain-model)
5. [Generation Rules — Applicability Conditions](#5-generation-rules)
6. [Candidate Eligibility — Pruning Logic](#6-candidate-eligibility)
7. [Magnitude Suggestions](#7-magnitude-suggestions)
8. [Priority Ordering Pre-Scoring](#8-priority-ordering-pre-scoring)
9. [Integration — Flow into Utility Engine and Challenge Layer](#9-integration)
10. [Migration from v1](#10-migration-from-v1)
11. [Invariants](#11-invariants)

---

## 1. Overview

### The v1 Problem: Direct Scoring Without Candidates

The current `FinancialReasoningEngine` (v1) takes a `FinancialReasoningContext` and computes a single `DecisionConfidenceReport`. This report contains an axis-weighted confidence score and nominates a `DecisionType` from the ten types defined in `DecisionType`. The engine asks: "What is the user's financial health?" and immediately answers "Therefore, recommend X."

This architecture has a structural flaw: it conflates two separate cognitive operations.

**Operation 1 — Situation Assessment:** What is the user's financial position across all axes?  
**Operation 2 — Action Generation:** Given this position, what actions are possible?  
**Operation 3 — Utility Scoring:** Which possible action delivers the most expected value?

By collapsing operations 2 and 3 into one step, v1 creates four observable deficiencies:

1. **It cannot return a portfolio.** A single confidence score drives a single recommendation. The user who asks "what else could I do?" gets nothing. PennyWise's north star is a ranked `CandidateSet`, not a single `DecisionType`.

2. **It cannot explain what it considered and rejected.** The explainability requirement demands not only "why this?" but "why not that?". The v1 engine never considered alternatives, so it cannot explain their absence.

3. **It cannot respect prerequisite ordering.** If the engine happens to score `StartSIP` highest but the user has zero emergency fund, the v1 engine will recommend a SIP — a fiduciary error. Prerequisite enforcement requires a candidate list to prune before scoring.

4. **It cannot degrade gracefully by category.** When data is sparse, a candidate generator can still enumerate liquidity candidates confidently (they use only `emergencyFundMonths` and `monthlySurplus`) while flagging tax candidates as low-confidence (they need `taxEfficiency` which is often null). The v1 engine applies a single compound confidence to one recommendation.

### The v2 Architecture: Generate → Prune → Score → Return Portfolio

The Decision Candidate Generator is the first of three new phases in the v2 engine pipeline:

```
FinancialReasoningContext
         │
         ▼
┌─────────────────────────┐
│  CandidateGenerator     │  Phase 1 (this document)
│  (Generate + Prune)     │  → CandidateSet (8–12 viable candidates)
└─────────────────────────┘
         │
         ▼
┌─────────────────────────┐
│  UtilityEngine          │  Phase 2 (scoring document)
│  (Score per axis)       │  → ScoredCandidateSet
└─────────────────────────┘
         │
         ▼
┌─────────────────────────┐
│  ChallengeLayer         │  Phase 3 (challenge document)
│  (Adversarial review)   │  → FinalDecisionPortfolio
└─────────────────────────┘
         │
         ▼
    DecisionResponse (v2)
    with ranked CandidateSet
```

The generator is **pure computation**: no async, no I/O, no network calls. It takes `FinancialReasoningContext` and returns `CandidateSet`. It is the only place in the codebase permitted to enumerate financial action types. The Utility Engine receives a fully-formed candidate list; it never creates candidates.

### Why This Is Architecturally Superior

The separation delivers five properties unavailable in v1:

| Property | v1 | v2 with Candidate Generator |
|----------|----|-----------------------------|
| Returns ranked portfolio | No — single type | Yes — ordered CandidateSet |
| Can explain rejected alternatives | No | Yes — pruned candidates carry rejection reason |
| Enforces prerequisite ordering | No | Yes — applicability conditions block invalid candidates |
| Per-candidate confidence | No | Yes — each candidate has its own data requirements |
| Testable generation logic | Entangled | Yes — generator is pure function, fully unit-testable |

---

## 2. Research Findings

### 2.1 MCDA Alternative Generation Phase

Multi-Criteria Decision Analysis (MCDA) — the family of formal methods used in financial planning theory — is structurally explicit that alternative generation precedes scoring. The MCDA process as documented in academic literature has four sequential phases:

1. **Define the decision problem** (what is the user trying to achieve?)
2. **Generate alternatives** (what actions are possible in this situation?)
3. **Measure performance** (score each alternative against each criterion)
4. **Identify preferred alternative** (weighted aggregation → rank → select)

The generation phase (step 2) is treated as a distinct intellectual activity. In MCDA practice, alternatives are generated through structured problem analysis before any scoring machinery is activated. Goal Programming — a prominent MCDA variant used in personal financial planning research — frames this as constraint satisfaction: enumerate all actions that do not violate hard constraints (liquidity, risk tolerance), then minimize deviations from aspirational targets.

The key insight for PennyWise: a candidate that is generated but scores poorly is still valuable — it can be surfaced as a "not now, but consider later" secondary action, which is exactly the `nextActions` field in `DecisionResponse`.

### 2.2 Case-Based Reasoning in Financial Product Recommendation

Research from Musto et al. (Semantic Scholar, 2014) on case-based reasoning for financial product recommendation demonstrates that systems which generate diverse candidate portfolios before final selection outperform single-recommendation systems in two ways: measured portfolio yield exceeds human advisor proposals in 73% of cases, and user-perceived trustworthiness is higher when alternatives are presented. The retrieve-revise-retain cycle in CBR maps directly to the generate-prune-score pipeline: the retrieve step generates a broad candidate set from similar historical situations, the revise step prunes and adjusts for the current user's specifics, and the retain step records what was selected back to the knowledge base for future retrieval.

For PennyWise, the `LearningSnapshot` in `FinancialReasoningContext` is the embryonic case base — past decisions and their outcomes can eventually prime the candidate set ("this type of user profile has historically benefited from debt acceleration before SIP scaling").

### 2.3 CFP Mental Checklist — The Financial Planning Pyramid

Certified Financial Planners use a hierarchical priority model that is taught as the "financial planning pyramid." The pyramid has three layers, and the rule is explicit: do not direct resources to a higher layer until the lower layer is adequately funded.

**Layer 1 — Foundation (must be complete first):**
- Emergency fund: 3–6 months of expenses in liquid assets
- Adequate insurance: term life (15x annual income for dependents), health insurance
- High-interest debt elimination (credit card, personal loan above 18% APR)

**Layer 2 — Stability:**
- Tax-advantaged savings (80C capacity, NPS 80CCD(1B))
- Moderate-rate debt management (personal loans 12–18%)
- Goal-based savings (short-term goals < 3 years in liquid/debt instruments)

**Layer 3 — Growth:**
- Equity SIPs for long-horizon goals (> 3 years)
- Portfolio optimization and rebalancing
- Discretionary lifestyle upgrades

The practical implication for candidate generation is that Layer 1 candidates carry an implicit `prerequisiteLayer` of zero — they are always eligible if the condition is triggered. Layer 3 candidates are ineligible until Layer 1 is complete. This creates the pre-scoring priority ordering described in section 8.

### 2.4 Dave Ramsey Baby Steps vs. Academic Optimal Theory

Dave Ramsey's Baby Steps are a sequential, one-step-at-a-time protocol:

1. Save ₹10,000 starter emergency fund
2. Eliminate all non-mortgage debt (snowball: smallest balance first)
3. Complete emergency fund to 3–6 months expenses
4. Invest 15% of income into retirement
5. Fund children's education
6. Pay off home mortgage
7. Build wealth and give

The academic "optimal" critique of this model centers on step 2 and step 6: paying off low-rate debt (mortgage at 4%) before investing (equity at 10–12% expected) is mathematically suboptimal by 6–8% annually. The behavioral rebuttal is that mathematical optimality is irrelevant if the user abandons the plan in month three.

For PennyWise's candidate generator, this tension resolves to a design principle: **candidates are generated based on optimality; their pre-scoring priority order is adjusted for behavioral sustainability.** A `AccelerateDebtRepayment` candidate is always generated when debt exists. Its rank relative to `StartSIP` depends not only on interest rate differential (pure math) but also on the user's `dominantBehaviorProfile` from `FinancialFacts`. A user profiled as `spender` may benefit from the behavioral momentum of the debt-payoff wins even if the math favors investing.

This is precisely why behavioral context must feed into the generator's priority ordering, not just the scoring phase.

### 2.5 India-Specific Financial Action Taxonomy

For the Indian market in 2026, research identifies a minimum viable action set that covers the vast majority of user situations:

**The India Priority Sequence:**
1. Emergency fund (3 months minimum, 6 months target) in liquid mutual fund or high-yield savings
2. Term insurance (15x annual income) for those with dependents, before age 45
3. Health insurance (₹5–10 lakh family floater) — medical costs have doubled since 2020
4. 80C tax savings (PPF, ELSS) — ₹1.5 lakh annual limit
5. NPS 80CCD(1B) — additional ₹50,000 deduction beyond 80C
6. High-cost debt elimination (credit card > 24% APR, personal loan > 18% APR)
7. Equity SIPs for long-horizon goals (> 5 years)
8. Subscription and discretionary spending rationalization

The India-specific additions relative to the universal CFP model are: the regime selection decision (old vs. new tax regime), NPS as a second-layer tax instrument, and the relatively high prevalence of zero-emergency-fund profiles among salaried users aged 22–35.

---

## 3. Complete Candidate Taxonomy

Every candidate in PennyWise belongs to one of six action families. The taxonomy is exhaustive for the current data model — candidates are only added when `FinancialFacts` can be extended to support their applicability check.

### 3.1 Liquidity Actions

The liquidity family addresses cash flow safety and resilience. These are Layer 1 in the CFP pyramid.

| Action Type | One-Line Description |
|-------------|----------------------|
| `BuildEmergencyFund` | Redirect surplus to liquid savings until 6-month target is met |
| `IncreaseShortTermSavings` | Build liquidity buffer for goal 0–12 months away (not emergency fund) |
| `ReduceFixedCommitments` | Cancel or downsize EMIs, subscriptions to recover monthly surplus |
| `StartRecurringDeposit` | Open a mandate-backed RD to automate liquid fund accumulation |

### 3.2 Investment Actions

The investment family covers equity, debt, and tax-advantaged instruments. These are primarily Layer 2 and Layer 3. Sub-families are categorized by instrument type.

**Equity / Growth:**

| Action Type | One-Line Description |
|-------------|----------------------|
| `StartSIP` | Begin a new systematic investment plan for a stated goal |
| `IncreaseSIP` | Add to existing SIP contribution at the next monthly cycle |
| `StepUpSIP` | Enable annual step-up (10% YoY) on existing SIP to combat income-inertia |
| `RebalancePortfolio` | Shift existing investments to restore target allocation after drift |

**Tax-Advantaged:**

| Action Type | One-Line Description |
|-------------|----------------------|
| `StartElss` | Open ELSS SIP to consume unused 80C capacity |
| `OpenPpf` | Contribute to PPF to consume 80C capacity with EEE status |
| `OpenNps` | Invest in NPS Tier I for exclusive 80CCD(1B) ₹50,000 deduction |
| `OptimizeRegimeSelection` | Evaluate old vs. new tax regime and switch if beneficial |

### 3.3 Debt Actions

The debt family addresses liability reduction. Priority within this family is determined by interest rate (highest first — avalanche method) adjusted for behavioral profile (snowball order if user profile is `impulsive` or `spender`).

| Action Type | One-Line Description |
|-------------|----------------------|
| `AccelerateDebtRepayment` | Direct surplus to highest-interest loan ahead of schedule |
| `ConsolidateDebt` | Consolidate multiple high-rate debts into a single lower-rate facility |
| `RefinanceLoan` | Refinance existing loan to current market rate if spread > 1.5% |

### 3.4 Protection Actions

The protection family ensures foundational risk coverage. Term insurance and health insurance are Layer 1; portfolio insurance (review) is Layer 2.

| Action Type | One-Line Description |
|-------------|----------------------|
| `GetTermInsurance` | Obtain pure term cover of 15x annual income |
| `GetHealthInsurance` | Obtain family floater health cover ≥ ₹5 lakh |
| `ReviewInsurance` | Review existing coverage for adequacy gaps, redundancy, or cost optimization |

### 3.5 Tax Actions

The tax family covers deduction maximization and regime optimization. These are Layer 2. They are never Layer 1 — a user with no emergency fund must not be recommended ELSS before liquid savings.

| Action Type | One-Line Description |
|-------------|----------------------|
| `Maximize80C` | Contribute to PPF, ELSS, or life premium to exhaust ₹1.5 lakh 80C deduction |
| `Maximize80CCD` | Invest in NPS Tier I to exhaust ₹50,000 80CCD(1B) deduction |
| `OptimizeRegimeSelection` | Compute net tax liability under old and new regime; switch if > ₹5,000 benefit |

Note: `OptimizeRegimeSelection` appears in both Investment Actions (for the behavioral framing "your money is doing more work") and Tax Actions (for the fiduciary framing "your tax bill is lower"). In the domain model it is a single `ActionType` enum value — it is never duplicated in a candidate set.

### 3.6 Behavioral Actions

The behavioral family addresses spending patterns and commitment leaks. These are Layer 2 — they require enough transaction history to be credible. They are powerful triggers for high `opportunityCost` axis scores.

| Action Type | One-Line Description |
|-------------|----------------------|
| `CancelUnusedSubscription` | Cancel subscriptions with zero engagement in the last 60 days |
| `ReduceDiscretionarySpending` | Reduce identified discretionary category by a specific percent |
| `NegotiateRecurringBill` | Renegotiate a recurring service contract (broadband, insurance) |

### 3.7 Goal Actions

The goal family acts directly on the user's named `GoalSnapshot` objects. These are Layer 2 and Layer 3 depending on goal horizon.

| Action Type | One-Line Description |
|-------------|----------------------|
| `CreateGoal` | Define a new goal when financial surplus exists but no active goal targets it |
| `IncreaseGoalContribution` | Redirect additional surplus to an existing off-track goal |
| `ExtendGoalTimeline` | Extend deadline of an off-track goal rather than increase contribution (lower behavior difficulty) |
| `PrioritizeGoal` | Shift monthly contribution allocation between competing goals |

---

**Complete ActionType Enum (27 values):**

```
Liquidity (4):     BuildEmergencyFund, IncreaseShortTermSavings,
                   ReduceFixedCommitments, StartRecurringDeposit

Investment (8):    StartSIP, IncreaseSIP, StepUpSIP, RebalancePortfolio,
                   StartElss, OpenPpf, OpenNps, OptimizeRegimeSelection

Debt (3):          AccelerateDebtRepayment, ConsolidateDebt, RefinanceLoan

Protection (3):    GetTermInsurance, GetHealthInsurance, ReviewInsurance

Tax (2):           Maximize80C, Maximize80CCD
                   (OptimizeRegimeSelection shared with Investment)

Behavioral (3):    CancelUnusedSubscription, ReduceDiscretionarySpending,
                   NegotiateRecurringBill

Goal (4):          CreateGoal, IncreaseGoalContribution, ExtendGoalTimeline,
                   PrioritizeGoal
```

---

## 4. Domain Model

### 4.1 ActionType Enum

```
enum ActionType {
  // Liquidity
  buildEmergencyFund,
  increaseShortTermSavings,
  reduceFixedCommitments,
  startRecurringDeposit,

  // Investment — growth
  startSip,
  increaseSip,
  stepUpSip,
  rebalancePortfolio,

  // Investment — tax-advantaged
  startElss,
  openPpf,
  openNps,
  optimizeRegimeSelection,

  // Debt
  accelerateDebtRepayment,
  consolidateDebt,
  refinanceLoan,

  // Protection
  getTermInsurance,
  getHealthInsurance,
  reviewInsurance,

  // Tax
  maximize80C,
  maximize80CCD,

  // Behavioral
  cancelUnusedSubscription,
  reduceDiscretionarySpending,
  negotiateRecurringBill,

  // Goal
  createGoal,
  increaseGoalContribution,
  extendGoalTimeline,
  prioritizeGoal,
}
```

### 4.2 ActionFamily Enum

```
enum ActionFamily {
  liquidity,
  investment,
  debt,
  protection,
  tax,
  behavioral,
  goal,
}
```

### 4.3 RiskClass Enum

Describes the financial risk introduced to the user's position by taking this action. Not the instrument's market risk — the action's impact on financial resilience.

```
enum RiskClass {
  reducesRisk,      // Emergency fund, insurance — makes position safer
  neutral,          // Tax optimization, regime switch — no new exposure
  incrementalRisk,  // SIP start — reduces liquid cash by monthly SIP amount
  moderateRisk,     // Portfolio rebalancing, ELSS — locks capital for 3 years
  highRisk,         // Aggressive debt paydown that strains cash flow
}
```

### 4.4 BehaviorDifficulty Enum

Captures the behavioral execution burden on the user. Drawn from Fogg Behavior Model (Motivation × Ability × Trigger). High difficulty candidates may be demoted in the ranked output even if they score well — a 90%-utility candidate that requires 10 manual steps is less effective than an 80%-utility candidate achievable with one tap.

```
enum BehaviorDifficulty {
  veryEasy,    // One tap — e.g. enable auto step-up on existing SIP
  easy,        // 2–3 steps — e.g. increase SIP amount
  moderate,    // One new account to open, one mandate — e.g. start ELSS SIP
  hard,        // Research required + external action — e.g. refinance loan
  veryHard,    // Requires external advisor or physical visit — e.g. consolidate debt
}
```

### 4.5 PrerequisiteBelief

Captures what the user must already believe or have in place for this candidate to be coherently presented. A `PrerequisiteBelief` is not an applicability condition (which is hard-gating) — it is a soft signal used by the UI to add the right framing.

```
enum PrerequisiteBelief {
  none,                      // No framing needed
  hasActiveEmergencyFund,    // User must have started emergency fund
  isDebtFree,                // User must have paid off high-interest debt
  hasTermInsurance,          // User has basic life cover
  hasHealthInsurance,        // User has basic health cover
  hasSurplusForInvestment,   // User has ≥ ₹500/month disposable surplus
  understandsSipCompounding, // User has completed the investment education module
}
```

### 4.6 DecisionCandidate — The Core Model

```
@immutable
class DecisionCandidate {
  const DecisionCandidate({
    required this.actionType,
    required this.family,
    required this.headline,          // "Build your emergency cushion"
    required this.rationale,         // One-sentence why this applies now
    required this.suggestedMagnitude, // MonthlyAmount or TargetAmount
    required this.magnitudeConfidence, // 0.0–1.0: how certain is the amount
    required this.goalAlignment,      // Which GoalSnapshot IDs this serves
    required this.riskClass,
    required this.behaviorDifficulty,
    required this.prerequisiteBelief,
    required this.applicabilitySignals, // List<String> facts that triggered this
    required this.pyramidLayer,         // 1, 2, or 3 — CFP priority layer
    required this.dataRequirements,     // Which FinancialFacts fields were needed
    required this.missingData,          // Which fields were null — drives confidence
    this.rejectionReason,               // Non-null only on pruned candidates
    this.estimatedGoalAcceleration,     // Months saved toward nearest off-track goal
    this.annualTaxSaving,               // INR — only for tax candidates
  });

  final ActionType actionType;
  final ActionFamily family;
  final String headline;
  final String rationale;
  final CandidateMagnitude suggestedMagnitude;
  final double magnitudeConfidence;
  final List<String> goalAlignment;
  final RiskClass riskClass;
  final BehaviorDifficulty behaviorDifficulty;
  final PrerequisiteBelief prerequisiteBelief;
  final List<String> applicabilitySignals;
  final int pyramidLayer;
  final List<String> dataRequirements;
  final List<String> missingData;
  final String? rejectionReason;
  final int? estimatedGoalAcceleration;
  final double? annualTaxSaving;
}
```

### 4.7 CandidateMagnitude — The Suggested Amount

```
@immutable
class CandidateMagnitude {
  const CandidateMagnitude({
    required this.monthlyAmount,   // INR, nullable for one-time actions
    required this.targetAmount,    // INR, nullable for ongoing actions
    required this.horizon,         // Months to complete the action
    required this.basis,           // Where does this number come from?
  });

  final double? monthlyAmount;
  final double? targetAmount;
  final int horizon;
  final MagnitudeBasis basis;
}

enum MagnitudeBasis {
  surplusBased,       // Derived from monthlySurplus
  gapBased,           // Derived from distance to target (EF months, 80C gap)
  formulaBased,       // SIP formula or step-up formula
  ruleOfThumb,        // Conservative default when data is sparse
  userHistoryBased,   // From past decisions in LearningSnapshot
}
```

### 4.8 CandidateSet — The Generator Output

```
@immutable
class CandidateSet {
  const CandidateSet({
    required this.viable,           // Candidates that passed eligibility
    required this.pruned,           // Candidates that were generated but pruned
    required this.generatedAt,
    required this.generatorVersion,
    required this.contextLabel,
    required this.dataCompleteness,  // 0.0–1.0 from FinancialFacts.completeness
  });

  final List<DecisionCandidate> viable;
  final List<DecisionCandidate> pruned;
  final DateTime generatedAt;
  final String generatorVersion;
  final String? contextLabel;
  final double dataCompleteness;

  /// True if the viable set meets the minimum invariant.
  bool get satisfiesMinimum => viable.length >= 2;

  /// All candidates — viable and pruned — for explainability panels.
  List<DecisionCandidate> get all => [...viable, ...pruned];
}
```

---

## 5. Generation Rules — Applicability Conditions

Each candidate type has an exact applicability condition expressed against `FinancialFacts` and `List<GoalSnapshot>`. These conditions are the generator's first pass. Any candidate whose condition is not met is never added to the candidate list — it is not generated at all (distinct from being pruned by eligibility logic in section 6).

The conditions are ordered from most conservative data requirement (smallest number of `FinancialFacts` fields needed) to most demanding. This ordering matters: when `FinancialFacts` is sparsely populated, early candidates in the list are still generatable.

### 5.1 Liquidity Candidates

**`BuildEmergencyFund`**
```
Applicable when:
  facts.emergencyFundMonths is not null
  AND facts.emergencyFundMonthsValue < 6.0
  
  OR facts.emergencyFundMonths is null
  AND facts.monthlyIncome is not null
  (conservative: assume EF is zero when unknown)
```
Signals: "Emergency fund covers N months, target is 6", "No EF data — conservative inclusion"

**`IncreaseShortTermSavings`**
```
Applicable when:
  goals contains a GoalSnapshot where:
    monthsUntilDeadline < 12
    AND NOT isOnTrack
    AND monthlyContribution > 0
  AND facts.monthlySurplus > 0
```
Signals: "Goal X has deadline in N months and is off-track"

**`ReduceFixedCommitments`**
```
Applicable when:
  facts.recurringCommitmentsTotal is not null
  AND (facts.recurringCommitmentsTotalValue / facts.monthlyIncomeValue) > 0.40
  
  OR facts.debtRatio is not null
  AND facts.debtRatio!.value > 0.40
```
Signals: "Commitments consume X% of income, safe threshold is 40%"

**`StartRecurringDeposit`**
```
Applicable when:
  facts.emergencyFundMonthsValue < 3.0
  AND facts.monthlySurplus >= 500
  AND facts.monthlyIncome is not null
```
Signals: "Surplus available; RD automates liquidity accumulation"

### 5.2 Investment Candidates

**`StartSIP`**
```
Applicable when:
  goals is not empty
  AND goals contains any GoalSnapshot where:
    monthsUntilDeadline > 36 (horizon justifies equity)
    AND monthlyContribution == 0 (no SIP running for this goal)
  AND facts.monthlySurplus >= 500
  AND facts.emergencyFundMonthsValue >= 3.0 (EF floor — see pyramid invariant)
```
Signals: "Goal X has N months horizon with no SIP contribution"

**`IncreaseSIP`**
```
Applicable when:
  facts.monthlySurplus >= 1000
  AND goals contains a GoalSnapshot where:
    NOT isOnTrack
    AND monthlyContribution > 0 (SIP already running, but insufficient)
  AND facts.emergencyFundMonthsValue >= 3.0
```
Signals: "Goal X needs ₹N extra per month to stay on track"

**`StepUpSIP`**
```
Applicable when:
  goals contains a GoalSnapshot where:
    monthlyContribution > 0 (SIP already running)
    AND monthsUntilDeadline > 24
  AND learningSnapshot contains no prior StepUpSIP recommendation
    accepted in the last 6 months
```
Signals: "Existing SIP for Goal X has no step-up enabled"

**`RebalancePortfolio`**
```
Applicable when:
  facts.existingInvestmentTotal is not null
  AND facts.existingInvestmentTotalValue > 50000
  AND facts.ageYearsValue is not null
  (drift is only computable with existing investment data)
```
Signals: "Existing portfolio detected; allocation drift check warranted"

**`StartElss`**
```
Applicable when:
  facts.taxEfficiency is not null
  AND facts.taxEfficiency!.value < 0.80 (80C not exhausted)
  AND facts.emergencyFundMonthsValue >= 3.0
  AND facts.ageYearsValue < 58 (ELSS lock-in is meaningful below retirement)
```
Signals: "80C capacity used at X%, ELSS SIP can recover remaining deduction"

**`OpenPpf`**
```
Applicable when:
  facts.taxEfficiency is not null
  AND facts.taxEfficiency!.value < 0.60 (significant 80C gap)
  AND facts.riskProfileValue == 'conservative'
    OR facts.ageYearsValue > 45 (debt anchor more appropriate near retirement)
```
Signals: "Conservative profile or near retirement; PPF EEE status optimal"

**`OpenNps`**
```
Applicable when:
  facts.taxEfficiency is not null
  AND facts.taxEfficiency!.value >= 0.80 (80C mostly used — NPS is the next deduction)
  AND facts.monthlyIncomeValue > 30000 (NPS meaningful above ₹3.6L annual)
```
Signals: "80C nearly exhausted; NPS 80CCD(1B) offers ₹50,000 additional deduction"

**`OptimizeRegimeSelection`**
```
Applicable when:
  facts.taxEfficiency is not null
  AND facts.monthlyIncomeValue > 40000 (regime optimization meaningful above ₹4.8L)
  (regime switch is a one-time high-value action, not recurring)
```
Signals: "Income level where regime difference exceeds ₹5,000 annually"

### 5.3 Debt Candidates

**`AccelerateDebtRepayment`**
```
Applicable when:
  facts.debtRatio is not null
  AND facts.debtRatio!.value > 0.20 (meaningful debt load)
  AND facts.monthlySurplus > 0
```
Signals: "EMI-to-income ratio is X%, accelerating reduces total interest by ₹N"

**`ConsolidateDebt`**
```
Applicable when:
  facts.debtRatio is not null
  AND facts.debtRatio!.value > 0.30
  AND facts.recurringCommitmentsTotal is not null
  (multiple commitments detectable as potential consolidation candidates)
```
Signals: "Multiple EMI commitments detected; consolidation may reduce rate"

**`RefinanceLoan`**
```
Applicable when:
  facts.debtRatio is not null
  AND facts.debtRatio!.value > 0.20
  (refinancing applicable when loan exists; rate comparison is scorer's job)
```
Signals: "Active loans exist; current market rates may offer refinance benefit"

### 5.4 Protection Candidates

**`GetTermInsurance`**
```
Applicable when:
  facts.monthlyInsurancePremium is not null
    AND facts.monthlyInsurancePremium!.value < (facts.monthlyIncomeValue * 0.005)
    (heuristic: insurance premium < 0.5% of income suggests no term cover)
  
  OR facts.monthlyInsurancePremium is null
    AND facts.ageYearsValue < 50
    AND facts.monthlyIncomeValue > 20000
  (conservative inclusion: unknown insurance for working-age earner)
```
Signals: "No term insurance detected for income-earning user with financial dependents"

**`GetHealthInsurance`**
```
Applicable when:
  facts.monthlyInsurancePremium is not null
    AND facts.monthlyInsurancePremium!.value < 800
    (₹800/month is approximate minimum for individual health cover)
  
  OR facts.monthlyInsurancePremium is null
    AND facts.monthlyIncomeValue > 15000
```
Signals: "Health insurance premium appears below adequate coverage threshold"

**`ReviewInsurance`**
```
Applicable when:
  facts.monthlyInsurancePremium is not null
  AND facts.monthlyInsurancePremium!.value > (facts.monthlyIncomeValue * 0.05)
  (premium > 5% of income signals potential over-insurance or inefficient cover)
  
  OR (learningSnapshot contains insurance-related decision older than 24 months)
```
Signals: "Insurance premium exceeds 5% of income; review for optimization"

### 5.5 Tax Candidates

**`Maximize80C`**
```
Applicable when:
  facts.taxEfficiency is not null
  AND facts.taxEfficiency!.value < 0.95
  AND facts.monthlyIncomeValue > 25000
```
Signals: "80C utilization at X%; ₹N of deduction capacity unused"

**`Maximize80CCD`**
```
Applicable when:
  facts.taxEfficiency is not null
  AND facts.taxEfficiency!.value >= 0.80 (80C substantially used — next instrument)
  AND facts.monthlyIncomeValue > 30000
```
Signals: "80C near-exhausted; NPS adds ₹50,000 exclusive deduction"

### 5.6 Behavioral Candidates

**`CancelUnusedSubscription`**
```
Applicable when:
  facts.recurringCommitmentsTotal is not null
  AND commitments data from FinancialReasoningContext
    contains subscriptions with zero recent transactions
  (requires CommitmentIntelligence data; degrades gracefully to not applicable)
```
Signals: "X subscriptions with no transactions in 60 days detected"

**`ReduceDiscretionarySpending`**
```
Applicable when:
  facts.savingsRateValue < 0.15 (below minimum 20% savings rate target)
  AND facts.monthlyExpenses is not null
  (spending is visible; the exact category is the scorer's job)
```
Signals: "Savings rate at X%, below 20% target; discretionary reduction recovers ₹N/month"

**`NegotiateRecurringBill`**
```
Applicable when:
  facts.recurringCommitmentsTotal is not null
  AND facts.recurringCommitmentsTotalValue > 5000
  AND facts.debtRatio is not null
  AND facts.debtRatio!.value > 0.35
```
Signals: "High recurring commitments; negotiation can reduce fixed cost base"

### 5.7 Goal Candidates

**`CreateGoal`**
```
Applicable when:
  goals.isEmpty
  AND facts.monthlySurplus >= 1000
  AND facts.emergencyFundMonthsValue >= 3.0
```
Signals: "No active goals; surplus can be directed to a named objective"

**`IncreaseGoalContribution`**
```
Applicable when:
  goals contains any GoalSnapshot where NOT isOnTrack
  AND facts.monthlySurplus >= 500
```
Signals: "Goal X is off-track; N months ahead of deadline with current contribution"

**`ExtendGoalTimeline`**
```
Applicable when:
  goals contains any GoalSnapshot where:
    NOT isOnTrack
    AND monthsUntilDeadline < 18 (tight deadline — contribution increase may not be feasible)
```
Signals: "Goal X deadline is N months away; extension is a low-disruption path"

**`PrioritizeGoal`**
```
Applicable when:
  goals.length >= 2
  AND goals contains at least 2 GoalSnapshots where NOT isOnTrack
```
Signals: "Multiple off-track goals; rebalancing contribution allocation may optimize"

---

## 6. Candidate Eligibility — Pruning Logic

Generation rules determine whether a candidate is considered. Eligibility rules determine whether a generated candidate survives to the `viable` list or is moved to the `pruned` list. Pruning is distinct from not generating: pruned candidates appear in `CandidateSet.pruned` with a `rejectionReason` and can be surfaced in the explainability panel ("We also considered X, but...").

### 6.1 Pyramid Layer Gate (hard prune)

A candidate of pyramidLayer N is pruned if any pyramidLayer (N-1) candidate in the `viable` list scores at or below the threshold for "critical" status.

The Layer 1 threshold for criticality is:
- `BuildEmergencyFund` is critical when `emergencyFundMonthsValue < 1.0`
- `GetTermInsurance` is critical when detected as completely absent and age < 45
- `AccelerateDebtRepayment` is critical when `debtRatio > 0.50`

When any Layer 1 candidate is critical, all Layer 3 candidates (equity SIPs, portfolio rebalancing) are moved to pruned with reason: `"layer_1_critical: emergency fund / insurance / high debt must be addressed first"`.

Layer 2 candidates are not pruned — they may proceed alongside a critical Layer 1 candidate, because tax savings and moderate debt management are compatible with emergency fund building.

### 6.2 Duplicate Action Type Guard (hard prune)

A `CandidateSet` must never contain two candidates with the same `ActionType`. If the generation rules could produce the same action type twice (e.g. `Maximize80C` triggered by both low `taxEfficiency` and near-retirement profile), the generator retains the instance with the higher `magnitudeConfidence` and discards the other.

### 6.3 Tax Efficiency Saturation Prune (hard prune)

Tax candidates are pruned when `taxEfficiency` is not null and `taxEfficiency.value >= 0.95`. At 95% efficiency, the marginal gain from additional 80C optimization is below ₹500 annually — not worth the behavioral cost of additional investment steps.

```
if (facts.taxEfficiency?.value >= 0.95) {
  prune(Maximize80C, reason: "80C_saturated: efficiency already at 95%")
  prune(StartElss, reason: "80C_saturated: ELSS not needed when 80C is exhausted")
  // OpenNps and Maximize80CCD may still apply — they target a different deduction
}
```

### 6.4 Surplus Gate (hard prune)

Any candidate that requires directing monthly cash flow is pruned when `monthlySurplus < 0`. A negative surplus means the user is already in deficit — investment or savings candidates cannot be viably suggested.

Exception: `ReduceFixedCommitments`, `CancelUnusedSubscription`, `ReduceDiscretionarySpending`, `NegotiateRecurringBill` are not pruned on negative surplus — they are the recovery path that restores surplus.

```
if (facts.monthlySurplus < 0) {
  prune all candidates except:
    ReduceFixedCommitments
    CancelUnusedSubscription
    ReduceDiscretionarySpending
    NegotiateRecurringBill
    BuildEmergencyFund  // kept with reduced magnitude — even ₹100/month is better than zero
}
```

### 6.5 Age-Horizon Consistency Prune (soft prune)

Investment candidates with `pyramidLayer == 3` and horizon > 15 years are pruned when `ageYearsValue > 55`. At age 55+, a 15-year equity SIP horizon extends beyond typical retirement age; risk-adjusted returns shift in favor of capital preservation.

```
if (facts.ageYearsValue > 55) {
  prune(StartSIP where horizon > 10 years, reason: "age_horizon_mismatch")
  prune(OpenNps, reason: "NPS_lock_in: NPS matures at 60, limited benefit above 55")
}
```

### 6.6 Recent Repetition Prune (soft prune — requires LearningSnapshot)

If `FinancialReasoningContext.learningSnapshot` is present, a candidate is soft-pruned if the same `ActionType` was recommended and either accepted or executed in the last 60 days. The user does not need to be told to start a SIP they already started last month.

```
if (learningSnapshot.recentDecisions.any(d =>
    d.actionType == candidate.actionType
    AND d.lifecycleState in [accepted, executed]
    AND d.generatedAt.isAfter(now.minus(60 days)))) {
  prune(candidate, reason: "recently_actioned: same recommendation was accepted 30 days ago")
}
```

### 6.7 Consolidation of Competing Goal Candidates

When multiple `GoalSnapshot` objects trigger the same action type (e.g. three off-track goals each independently triggering `IncreaseGoalContribution`), the generator consolidates them into a single candidate. The `goalAlignment` field carries all three goal IDs. The `headline` is written in the plural ("Increase your goal contributions"). The magnitude is the sum of gaps across all off-track goals, capped at `monthlySurplus`.

---

## 7. Magnitude Suggestions

The generator computes a `suggestedMagnitude` for each viable candidate. The suggestion is not a directive — the Utility Engine and the user may override it. It is the starting point for the scoring engine's financial impact calculations.

### 7.1 BuildEmergencyFund

```
gap = (6.0 - emergencyFundMonthsValue) * monthlyExpensesValue
currentMonths = emergencyFundMonthsValue

if currentMonths < 1.0:
  // Critical: suggest building 1 month in 6 months
  monthlyAmount = monthlyExpensesValue / 6
  targetAmount = monthlyExpensesValue
  horizon = 6
  basis = surplusBased

else:
  // Gap fill: suggest closing full gap in 18 months
  monthlyAmount = min(gap / 18, monthlySurplus * 0.50)
  targetAmount = gap
  horizon = (gap / monthlyAmount).ceil()
  basis = gapBased

magnitudeConfidence = 
  emergencyFundMonths.confidence × monthlyExpenses.confidence
```

### 7.2 StartSIP / IncreaseSIP

PennyWise uses the SIP formula from `FinancialPolicy.sipRateForHorizon()`. The goal's `remaining` amount and `monthsUntilDeadline` drive the FV-based monthly payment:

```
r = sipRateForHorizon(goal.monthsUntilDeadline) / 12   // monthly rate
n = goal.monthsUntilDeadline
FV = goal.remaining

// Future Value of SIP formula: FV = M × ((1+r)^n - 1) / r
// Solved for M:
M = FV × r / ((1+r)^n - 1)

// Floor: ₹500 (minimum SIP amount on most platforms)
// Cap: monthlySurplus × 0.70 (do not allocate more than 70% of surplus to one SIP)

monthlyAmount = M.clamp(500, monthlySurplus * 0.70)
targetAmount = goal.targetAmount
horizon = goal.monthsUntilDeadline
basis = formulaBased
```

### 7.3 StepUpSIP

The step-up formula produces the initial `m0` that, with a 10% annual step-up, reaches the same terminal value as a flat SIP of `IncreaseSIP.monthlyAmount`. This is always less than the flat SIP amount, making it behaviorally easier:

```
annualStepUpRate = 0.10   // from FinancialPolicy
r = sipRateForHorizon(goal.monthsUntilDeadline) / 12
n = goal.monthsUntilDeadline
g = annualStepUpRate / 12  // monthly step-up rate

// Step-Up SIP present value formula:
m0 = FV × (r - g) / ((1+r)^n - (1+g)^n)

monthlyAmount = m0.clamp(500, monthlySurplus * 0.50)
basis = formulaBased
```

### 7.4 Maximize80C

```
section80CLimit = 150000   // from FinancialPolicy
annualIncome = monthlyIncomeValue * 12
currentUtilization = taxEfficiency.value * section80CLimit
gap = section80CLimit - currentUtilization

monthlyAmount = gap / 12
targetAmount = gap
horizon = 12   // annual tax year
basis = gapBased
annualTaxSaving = gap * estimatedMarginalTaxRate(annualIncome)
```

### 7.5 Maximize80CCD (NPS)

```
npsLimit = 50000   // from FinancialPolicy — 80CCD(1B) exclusive
monthlyAmount = npsLimit / 12   // ≈ ₹4,167/month
targetAmount = npsLimit
horizon = 12
basis = gapBased
annualTaxSaving = npsLimit * estimatedMarginalTaxRate(annualIncome)
```

### 7.6 AccelerateDebtRepayment

```
// Avalanche method: target highest-rate debt first
// Without detailed debt schedule, use debtRatio as proxy
totalDebtEstimate = debtRatio.value * monthlyIncomeValue * 36
// Approximate 3-year payoff for standard personal loans

monthlyAmount = min(monthlySurplus * 0.60, totalDebtEstimate / 24)
targetAmount = totalDebtEstimate
horizon = 24   // aggressive but not extreme
basis = surplusBased
```

### 7.7 GetTermInsurance / GetHealthInsurance

These are one-time setup actions. The magnitude is not monthly investment but an annual premium estimate:

```
// Term insurance: 15x annual income cover
// Approximate annual premium for ₹1 crore cover, age 25–35: ₹8,000–₹15,000
targetAmount = 15 × (monthlyIncomeValue × 12)   // cover amount
monthlyAmount = annualPremiumEstimate / 12        // ₹700–₹1,300/month
horizon = 1   // one-time decision, takes 1 month to execute
basis = ruleOfThumb
magnitudeConfidence = 0.40   // low — premium is age and health dependent
```

### 7.8 CancelUnusedSubscription / ReduceDiscretionarySpending

```
// Amount freed is the saving, not an investment
monthlyAmount = detected_unused_subscription_total
              // OR: (currentSpendingCategory - categoryBenchmark) × 0.30
targetAmount = null   // ongoing saving, not a one-time target
horizon = 0   // immediate effect
basis = userHistoryBased when commitments data available, else ruleOfThumb
```

### 7.9 Fallback: Rule-of-Thumb Magnitudes

When key `FinancialFacts` fields are null, the generator uses conservative rule-of-thumb magnitudes with `MagnitudeBasis.ruleOfThumb` and `magnitudeConfidence = 0.25`. These are:

| Candidate | Rule-of-Thumb Monthly |
|-----------|----------------------|
| BuildEmergencyFund | ₹2,000 |
| StartSIP | ₹1,000 |
| Maximize80C | ₹3,000 |
| GetTermInsurance | ₹800 |
| GetHealthInsurance | ₹600 |

Rule-of-thumb candidates are always included if the applicability condition passes — low confidence is better than no candidate.

---

## 8. Priority Ordering Pre-Scoring

The `CandidateSet.viable` list is ordered before it reaches the Utility Engine. This pre-sort is **not** a replacement for full utility scoring — it is a behavioral scaffolding that prevents a mathematically-optimal equity SIP from beating a critically-absent emergency fund in the UI output.

### 8.1 Pre-Sort Key (three-level)

```
sort by:
  1. pyramidLayer ASC           (Layer 1 before Layer 2 before Layer 3)
  2. riskClass ASC              (reducesRisk before incrementalRisk)
  3. behaviorDifficulty ASC     (veryEasy before veryHard)
```

This produces a list where, for example:

```
1. BuildEmergencyFund          (layer=1, riskClass=reducesRisk, difficulty=easy)
2. GetTermInsurance            (layer=1, riskClass=reducesRisk, difficulty=moderate)
3. CancelUnusedSubscription    (layer=2, riskClass=neutral, difficulty=veryEasy)
4. Maximize80C                 (layer=2, riskClass=neutral, difficulty=moderate)
5. AccelerateDebtRepayment     (layer=2, riskClass=neutral, difficulty=moderate)
6. StartSIP                    (layer=2→3, riskClass=incrementalRisk, difficulty=easy)
7. IncreaseSIP                 (layer=3, riskClass=incrementalRisk, difficulty=veryEasy)
8. StepUpSIP                   (layer=3, riskClass=incrementalRisk, difficulty=veryEasy)
```

### 8.2 Behavioral Profile Adjustment

If `FinancialFacts.dominantBehaviorProfile` is available, the pre-sort is adjusted:

- **Profile `spender`**: Debt paydown candidates are promoted within their pyramid layer. The behavioral momentum of "destroying debt" is more sustainable for this profile than the abstract benefit of investing.
- **Profile `anxious_saver`**: Insurance candidates are promoted — reducing risk is the highest motivator for this profile.
- **Profile `optimizer`**: Tax candidates are promoted — this profile responds well to efficiency framing.
- **Profile `procrastinator`**: `BehaviorDifficulty.veryEasy` candidates are promoted regardless of family. The lowest-friction path is always the best path for this profile.

The behavioral adjustment shifts position within a pyramid layer only — it never moves a Layer 3 candidate above a Layer 1 candidate.

### 8.3 The "CFP Would Say X First" Rule

As an explicit architectural invariant: if `BuildEmergencyFund` is in the viable list with `emergencyFundMonthsValue < 3.0`, it is always position 1 in the pre-sorted list, regardless of behavioral profile or any other candidate's riskClass or difficulty. No algorithm overrides this.

This mirrors the CFP fiduciary standard: a planner who recommends an equity SIP to a client with no emergency fund has failed their fiduciary duty.

---

## 9. Integration — Flow into Utility Engine and Challenge Layer

### 9.1 Generator → Utility Engine Interface

The generator hands `CandidateSet` to the Utility Engine. The interface is:

```
abstract class UtilityEngine {
  String get engineVersion;

  // Scores each viable candidate against all 8 DecisionAxes.
  // Returns ScoredCandidateSet — candidates annotated with per-axis scores.
  ScoredCandidateSet score({
    required CandidateSet candidates,
    required FinancialReasoningContext ctx,
    required DecisionConfidenceReport confidence,
  });
}
```

The Utility Engine:
- Receives the pre-sorted `CandidateSet.viable` list
- Evaluates each `DecisionCandidate` against the 8 `DecisionAxis` weights
- Produces a utility score per candidate (weighted average across axes)
- Does NOT generate new candidates — if a candidate is not in the input, it is not in the output

The pre-sort order from section 8 is advisory to the Utility Engine: if two candidates have utility scores within 5% of each other, the pre-sort tiebreaks. If a lower-ranked candidate outscores by more than 5%, the Utility Engine's mathematical rank wins.

The `CandidateSet.pruned` list passes through the Utility Engine unchanged — pruned candidates are not scored (their `rejectionReason` is preserved).

### 9.2 Utility Engine → Challenge Layer Interface

```
abstract class ChallengeLayer {
  // Adversarially reviews top-ranked scored candidates.
  // Can demote (but not eliminate) a candidate if a challenge fires.
  FinalDecisionPortfolio challenge({
    required ScoredCandidateSet scored,
    required FinancialReasoningContext ctx,
  });
}
```

The Challenge Layer applies adversarial tests to the top 3 candidates:
- "Does this recommendation worsen any DecisionAxis score by more than 10 points?"
- "Is the suggested magnitude larger than the user can sustain for 3 months?"
- "Does the behavioral difficulty exceed the user's historical execution rate?"

If a challenge fires, the candidate is demoted in the final ranking (not pruned — the explainability panel shows why it was demoted).

### 9.3 Final Output: FinalDecisionPortfolio → DecisionResponse v2

The `FinalDecisionPortfolio` feeds directly into the v2 `DecisionResponse`:

```
DecisionResponse (v2)
  decision: Decision         // The #1 ranked candidate, fully hydrated
  candidatePortfolio: CandidatePortfolio  // NEW in v2 — replaces flat partnerPrograms
    primary: RankedCandidate             // Rank 1
    alternatives: List<RankedCandidate>  // Ranks 2–N (up to 4)
    considered: List<PrunedCandidate>    // What was considered but not recommended
  partnerPrograms: List<RankedPartnerProgram>  // Execution options for primary candidate
  goalImpacts: List<GoalImpact>
  nextActions: List<NextAction>
```

### 9.4 Pruned Candidates in Explainability

`CandidateSet.pruned` becomes `DecisionResponse.candidatePortfolio.considered`. The UI Explanation Panel displays:

> "We also considered: [Rebalance Portfolio] — not recommended because your emergency fund needs to reach 3 months first."

This closes the explainability requirement: the system can always answer "what else did you consider?" because the answer is stored in the domain object.

---

## 10. Migration from v1

### 10.1 What Changes

The current `DecisionResponse` (v1) has:
- `decision: Decision` — a single nominated decision with a `DecisionType`
- `partnerPrograms: List<RankedPartnerProgram>` — execution options for that decision
- `goalImpacts: List<GoalImpact>`
- `nextActions: List<NextAction>`

The v2 `DecisionResponse` adds:
- `candidatePortfolio: CandidatePortfolio` — the ranked set from the generator

The existing `Decision` aggregate root and its `DecisionType` enum are **not deleted**. The v2 architecture promotes `DecisionType` to `ActionType` (the richer enum in this document) while keeping `DecisionType` as a backward-compatibility alias. The v1 10-value enum maps cleanly to the v2 27-value enum:

| DecisionType (v1) | ActionType (v2) |
|-------------------|-----------------|
| `buildEmergencyFund` | `buildEmergencyFund` |
| `increaseSavingsRate` | `increaseShortTermSavings` |
| `startGoalSip` | `startSip` |
| `stepUpSip` | `stepUpSip` |
| `optimizeTax` | `maximize80C` (split into two: `maximize80C`, `optimize RegimeSelection`) |
| `reduceDebt` | `accelerateDebtRepayment` |
| `getInsurance` | `getTermInsurance` (split: `getTermInsurance`, `getHealthInsurance`) |
| `optimizeSubscription` | `cancelUnusedSubscription` |
| `rebalancePortfolio` | `rebalancePortfolio` |
| `reviewPastDecision` | (handled by LearningEngine — not a generator candidate) |

### 10.2 Migration Steps (Ordered)

**Step 1 — Add ActionType alongside DecisionType.** Both enums exist simultaneously. No breaking change to v1 surfaces. The generator uses `ActionType`; the v1 engine continues using `DecisionType`.

**Step 2 — Introduce CandidateSet and DecisionCandidate as new domain objects.** Add to `mobile/lib/domain/reasoning/`. No existing files are modified.

**Step 3 — Build CandidateGenerator as a new engine interface alongside FinancialReasoningEngine.** The v1 `FinancialReasoningEngine` continues to exist. The `CandidateGenerator` is a new interface:

```
abstract class CandidateGenerator {
  String get engineVersion;
  CandidateSet generate(FinancialReasoningContext ctx);
}
```

**Step 4 — Build UtilityEngine and ChallengeLayer (separate design documents).** The generator does not depend on these — it can be implemented and tested in isolation.

**Step 5 — Introduce CandidatePortfolio into DecisionResponse as an optional field.** During migration, `candidatePortfolio` is nullable. The v1 engine produces a `DecisionResponse` with `candidatePortfolio: null`. The v2 engine populates it.

```
class DecisionResponse {
  // ... existing fields ...
  final CandidatePortfolio? candidatePortfolio; // null in v1 output
}
```

**Step 6 — Wire v2 engine into DecisionEngine.compute().** Replace the rule-based single-decision path with the generate → score → challenge pipeline. The `CandidatePortfolio` is now always populated.

**Step 7 — Remove nullability from `candidatePortfolio`.** After v2 is stable and backend `/decisions/today` returns v2 format, remove the nullable wrapper.

### 10.3 Backend Compatibility

The Java `DecisionResponse` canonical envelope (Phase 2 Sprint 1) uses `PartnerRecommendation` objects. The v2 migration on the backend adds a `candidatePortfolio` JSON field to the envelope. The Flutter `TodayDecisionModel` already parses both v1 and v2 backend formats; adding the new field follows the same pattern.

---

## 11. Invariants

The following invariants are enforced at the `CandidateGenerator` boundary. Any implementation of `CandidateGenerator` that violates these invariants must throw an `AssertionError` in debug builds and log a critical error in production.

### Invariant 1 — Minimum Viable Set

```
assert(candidateSet.viable.length >= 2,
  'CandidateGenerator must return at least 2 viable candidates. '
  'Fallback: BuildEmergencyFund and CreateGoal are always generatable when income is known.')
```

When the primary generation logic cannot produce 2 candidates (e.g. data is extremely sparse — only `monthlyIncome` is populated), the generator falls back to two conservative defaults:

- `BuildEmergencyFund` with `MagnitudeBasis.ruleOfThumb` (₹2,000/month, `magnitudeConfidence: 0.25`)
- `IncreaseSavingsRate` (mapped to `IncreaseShortTermSavings` with a generic goal) with `MagnitudeBasis.ruleOfThumb`

These fallback candidates carry a `limitation` string: "Recommendation generated with minimal data — connect more sources for personalized guidance."

### Invariant 2 — No Duplicate Action Types

```
assert(
  viable.map((c) => c.actionType).toSet().length == viable.length,
  'CandidateSet.viable must not contain duplicate ActionType values. '
  'The generation rules must consolidate competing instances before adding to the set.'
)
```

Duplication is most likely to occur when multiple `GoalSnapshot` objects each trigger the same candidate type. The consolidation logic in section 6.7 is the resolution path.

### Invariant 3 — Pyramid Layer Ordering Before Utility Scoring

```
assert(
  !viable.any((c) =>
    c.pyramidLayer == 3 &&
    viable.any((other) => other.pyramidLayer == 1 && isCritical(other))),
  'Layer 3 candidates must not appear in viable when a Layer 1 candidate is critical.'
)
```

### Invariant 4 — Magnitude Is Always Positive

```
assert(
  viable.every((c) =>
    (c.suggestedMagnitude.monthlyAmount ?? 1) > 0 &&
    (c.suggestedMagnitude.targetAmount ?? 1) > 0),
  'CandidateMagnitude fields must be positive — zero or negative magnitude is not actionable.'
)
```

### Invariant 5 — Generator Is Pure (No I/O)

`CandidateGenerator.generate()` is a synchronous function. It takes `FinancialReasoningContext` and returns `CandidateSet`. It must not: call any repository, make any network request, read from storage, or emit any domain events. All inputs must arrive via `FinancialReasoningContext`.

This invariant enables deterministic unit testing: the same `FinancialReasoningContext` always produces the same `CandidateSet`.

### Invariant 6 — Pruned Candidates Carry Rejection Reason

```
assert(
  pruned.every((c) => c.rejectionReason != null && c.rejectionReason!.isNotEmpty),
  'Every pruned candidate must carry a non-empty rejectionReason for explainability.'
)
```

The rejection reason uses the structured codes defined in section 6 (e.g. `"layer_1_critical"`, `"80C_saturated"`, `"recently_actioned"`, `"age_horizon_mismatch"`).

### Invariant 7 — Fallback Candidates Are Clearly Labeled

Any candidate generated via the rule-of-thumb fallback path must have `magnitudeConfidence <= 0.30` and `missingData` must be non-empty. The UI can use this to render a "limited data" badge.

---

## Appendix A — The Generation Algorithm in Pseudocode

```
CandidateSet generate(FinancialReasoningContext ctx):
  raw = []
  
  // Phase 1: Generate — check applicability condition for each of the 27 ActionTypes
  for each candidateSpec in ALL_CANDIDATE_SPECS:
    if candidateSpec.isApplicable(ctx.facts, ctx.goals, ctx.learningSnapshot):
      raw.add(buildCandidate(candidateSpec, ctx))
  
  // Phase 2: Consolidate duplicates within goal-driven candidates
  raw = consolidateGoalCandidates(raw)  // merges duplicate ActionTypes
  
  // Phase 3: Prune — apply eligibility rules
  viable = []
  pruned = []
  
  for each candidate in raw:
    rejection = checkEligibility(candidate, raw, ctx.facts)
    if rejection == null:
      viable.add(candidate)
    else:
      pruned.add(candidate.copyWith(rejectionReason: rejection))
  
  // Phase 4: Pre-sort viable list
  viable = preSortCandidates(viable, ctx.facts.dominantBehaviorProfile)
  
  // Phase 5: Apply minimum invariant
  if viable.length < 2:
    viable = applyFallbackCandidates(viable, ctx.facts)
  
  // Phase 6: Assert invariants
  assertInvariants(viable, pruned)
  
  return CandidateSet(
    viable: viable,
    pruned: pruned,
    generatedAt: DateTime.now(),
    generatorVersion: GENERATOR_VERSION,
    contextLabel: ctx.contextLabel,
    dataCompleteness: ctx.facts.completeness,
  )
```

---

## Appendix B — Candidate Coverage Analysis

Against the target of "covers 90% of user situations in India":

| User Situation | Covered by Candidates |
|----------------|----------------------|
| No emergency fund | `BuildEmergencyFund`, `StartRecurringDeposit` |
| No term insurance | `GetTermInsurance` |
| No health insurance | `GetHealthInsurance` |
| High-rate debt (credit card, personal loan) | `AccelerateDebtRepayment`, `ConsolidateDebt` |
| 80C capacity unused | `Maximize80C`, `StartElss`, `OpenPpf` |
| No investments, has surplus | `StartSIP`, `CreateGoal` |
| Has SIP but goal is off-track | `IncreaseSIP`, `StepUpSIP`, `ExtendGoalTimeline` |
| Too many subscriptions | `CancelUnusedSubscription`, `ReduceDiscretionarySpending` |
| Over-committed monthly outflow | `ReduceFixedCommitments`, `NegotiateRecurringBill` |
| Old tax regime, high earner | `OptimizeRegimeSelection` |
| 80C exhausted, pays high tax | `Maximize80CCD`, `OpenNps` |
| Multiple off-track goals | `PrioritizeGoal`, `IncreaseGoalContribution` |
| No goals defined | `CreateGoal` |
| Large existing portfolio with drift | `RebalancePortfolio` |

Estimated coverage: 95% of PennyWise user profiles based on the demographic segments (students, salaried 22–35, salaried 35–55, freelancers, families).

The 5% uncovered includes: highly specialized situations (NRI tax treatment, HUF structures, LTCG harvesting, startup ESOP planning) that require a human advisor and are outside PennyWise's current scope.

---

*Document version: 1.0 — Decision Candidate Generator Design*  
*Authored: 2026-08-05*  
*Status: Pending Utility Engine design document (04-utility-engine.md)*
