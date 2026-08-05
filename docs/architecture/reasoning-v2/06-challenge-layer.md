# Challenge Layer — v2 Reasoning Architecture

**Document:** `docs/architecture/reasoning-v2/06-challenge-layer.md`
**Status:** Design Specification
**Phase:** Pre-Implementation
**Depends on:** `DecisionAxis`, `DecisionConfidenceReport`, `FinancialReasoningContext`, `FinancialPolicy`

---

## 1. Overview — Why Self-Critique Is a Hallmark of Advanced Reasoning

The most dangerous failure mode of a financial recommendation engine is not an incorrect calculation. It is correct arithmetic applied to the wrong question.

An engine that selects a SIP recommendation with high confidence because the user has surplus income may be entirely correct about cash flow and entirely wrong about the user's liquidity position, behavioral track record, or the presence of high-interest debt that makes investing before debt reduction a fiduciary error.

The Challenge Layer exists to prevent exactly this failure. It is an internal adversarial function that attacks the top-ranked recommendation candidate before it exits the engine. It does not produce a different output. It either confirms the candidate or replaces it with a demonstrably stronger one. The user sees only the winner of this internal debate.

### The Mental Model

Think of the Decision Engine as a senior CA who has just formed a recommendation. Before presenting it to the client, they apply the same mental discipline that separates expert financial planners from order-takers: they deliberately argue against their own conclusion. They ask whether debt reduction matters more, whether the user has the behavioral history to follow through, whether the tax treatment changes the calculus, whether liquidity should be preserved first.

This is not a second engine layered on top of the first. It is a discipline applied within the same pipeline — a structured self-critique that happens after utility scoring but before the recommendation is assembled into a `Decision` object.

### Why This Matters at the Architecture Level

Without a Challenge Layer, the Decision Engine is susceptible to:

- **Axis dominance errors** — a single high-scoring axis (e.g. cash flow surplus) drowning out a critical low-scoring axis (e.g. zero emergency fund coverage)
- **Recommendation type lock-in** — once a candidate type is selected via utility scoring, no mechanism revisits whether a different decision type would serve the user better
- **Behavioral blindness** — recommending an instrument that the user has historically failed to sustain (e.g. SIP cancellations after 2 months)
- **Tax regret** — recommending a wealth-building action that misses Section 80C capacity in Q4, costing real money
- **Timing errors** — recommending a long-horizon investment when a short-term obligation is approaching

The Challenge Layer is the mechanism that catches these failures before they reach the user.

---

## 2. Research Findings

### 2.1 Adversarial Testing in AI Systems (Red Teaming)

Red teaming in AI involves systematically probing a system's outputs with adversarial intent to surface failure modes before deployment. NIST's AI Risk Management Framework defines it as "adversarial testing of AI systems under stress conditions to seek out AI system failure modes or vulnerabilities."

In recommendation systems specifically, red teaming has evolved from external attacks to internal adversarial functions — an agent designed to argue against the primary agent's output. Research on agentic AI for commercial insurance underwriting (2025) describes a pattern where "the primary agent then revises its decision, addressing the critic's points. One full critique-revision cycle is allowed to balance thoroughness with efficiency. This self-critique acts as an internal check, where the agent must convince an adversarial version of itself before reaching human review."

This is the pattern the Challenge Layer implements: a structured, bounded critique cycle that runs inside the engine, not in the UI or in post-recommendation feedback.

### 2.2 Devil's Advocate Practice in Financial Planning

The CFP Board's professional standards explicitly require that financial planners challenge their own recommendations before presenting them to clients. The FPA Journal describes the CFP's analytical obligation: "As an advisor, you should look for data on both sides of an issue, play devil's advocate with your recommendations, and model it to reflect an open-minded approach."

Critically, this discipline exists to overcome confirmation bias — "a tendency to seek evidence that supports their beliefs while ignoring or failing to notice evidence that challenges those beliefs." The professional standard is that an advisor must not "develop an initial recommendation and then search only for evidence to confirm it."

This is precisely what the Challenge Layer implements algorithmically: after the engine selects a candidate, it is required to search for evidence against it, not evidence for it.

### 2.3 Pre-Mortem Analysis (Gary Klein)

Gary Klein's pre-mortem technique — described by Daniel Kahneman as "my favourite method for making better decisions" — works by imagining a future failure has already occurred and asking why. Research demonstrates that "prospective hindsight increases the ability to correctly identify reasons for future outcomes by 30%." It "consistently surfaces failure modes that standard risk analysis misses, prevents the most common and most costly decision errors."

The Challenge Layer applies the pre-mortem frame to each challenge: rather than asking "might this recommendation fail?", each challenger asks "this recommendation failed — what was the reason?" The shift from conditional to retrospective framing forces the engine to find concrete failure pathways rather than general uncertainty.

### 2.4 Constitutional AI — Self-Critique and Revision

Anthropic's Constitutional AI (CAI) framework demonstrates how self-critique can be embedded in an AI pipeline. The supervised phase works as: "the system samples from an initial model, then generates self-critiques and revisions, and then finetunes the original model on revised responses." The model evaluates its output against a set of principles and revises based on violations.

The Challenge Layer adopts the self-critique structure from CAI but differs in a critical design choice: the challenges are not general constitutional principles but specific financial domain tests grounded in `FinancialPolicy` constants. Each challenge is falsifiable — it produces a yes/no verdict with a confidence delta, not a general critique.

### 2.5 Chess Engine Counterplay Evaluation

Chess engines evaluate candidate moves not just by their static evaluation score but by the best opponent response. A move that looks strong in isolation may fail because it allows a decisive counterattack. The engine generates the adversarial line, not just the favorable one.

This maps directly to the Challenge Layer's function: after selecting a recommendation candidate, the layer generates the strongest counter-argument for each challenge axis. The candidate must survive each counter-argument to be confirmed.

---

## 3. Challenge Taxonomy

The Challenge Layer runs six distinct challenges against the recommended candidate. Each challenge is named after the primary `DecisionAxis` it scrutinizes. Each challenge is independent — they run in parallel and produce independent `ChallengeResult` objects. The overall challenge outcome is the worst-case result across all challenges.

### Challenge 1 — LiquidityChallenge

**Question:** "Does this recommendation implicitly assume liquidity that the user does not have?"

Investments, SIPs, and recurring commitments reduce liquid reserves. If the user's emergency fund coverage is already below the `FinancialPolicy.emergencyFundTargetMonths` threshold, recommending any action that reduces monthly surplus is potentially dangerous — even if the action is financially sound in isolation.

The LiquidityChallenge asks whether recommending `buildEmergencyFund` would be a stronger action than the current candidate, using the weighted axis differential between the candidate's utility and a `buildEmergencyFund` utility computed from the same `FinancialReasoningContext`.

### Challenge 2 — DebtChallenge

**Question:** "Does this recommendation compete with high-cost debt that should be prioritized?"

Recommending a SIP or tax-optimization action while the user carries debt at an effective rate exceeding 12% per annum is a mathematical error. The expected return on the investment is unlikely to exceed the guaranteed return of eliminating the debt.

The DebtChallenge computes the effective debt burden from `FinancialFacts.debtRatio` and compares it against the expected return of the candidate recommendation. If eliminating the debt produces a higher risk-adjusted net present value than the candidate, the challenge recommends replacement with `reduceDebt`.

### Challenge 3 — BehaviorChallenge

**Question:** "Does the user's behavioral track record indicate they are unlikely to follow through with this recommendation?"

A recommendation that is financially correct but behaviorally unachievable is not a good recommendation — it is a prediction of failure with a fiduciary veneer. If the `BehaviorInterpretation` in `FinancialReasoningContext.behavior` shows a pattern of SIP cancellations, the `startGoalSip` recommendation should be challenged.

The BehaviorChallenge inspects the behavioral confidence factor from `DecisionConfidenceReport.behaviorConfidenceFactor` and the behavioral signals from `FinancialFacts.dominantBehaviorProfile`. When behavioral resistance patterns are detected for the candidate's required action type, the challenge penalizes the candidate's confidence and proposes an alternative with lower behavioral friction.

### Challenge 4 — TaxChallenge

**Question:** "Does this recommendation miss a tax-saving opportunity that produces higher after-tax utility?"

Tax efficiency is a force multiplier on wealth creation. In Q4 (January–March), the tax-saving opportunity has a hard deadline. Section 80C capacity unused by March 31 is a permanent loss. The TaxChallenge computes remaining 80C capacity from `FinancialFacts.taxEfficiency` and the current month.

If the candidate is not a tax-saving action and the user has unused 80C capacity in Q4 with less than 60 days until the filing deadline, the TaxChallenge proposes `optimizeTax` as a replacement candidate and calculates the after-tax utility differential.

### Challenge 5 — TimingChallenge

**Question:** "Does this recommendation have a timing dependency that makes it wrong right now, regardless of its structural soundness?"

Some recommendations are correct in the medium term but wrong at this specific moment. Starting a 10-year equity SIP is structurally sound, but if the user has a major expense (EMI, tax payment, insurance premium) due within 30 days that consumes their surplus, the recommendation will fail on execution — the SIP will bounce or be cancelled within the first month.

The TimingChallenge inspects `FinancialFacts.recurringCommitmentsTotal`, the user's commitment calendar, and near-term obligation density. It applies a timing suitability score: if near-term obligations consume more than 80% of monthly surplus, long-horizon commitments are flagged as poorly timed.

### Challenge 6 — RiskChallenge

**Question:** "Does this recommendation carry risk that is inconsistent with the user's current financial state classification?"

`FinancialState` classifies the user into four states: `Survive`, `Stabilize`, `Build`, `Optimize`. Recommendations appropriate for `Build` may be inappropriate for `Stabilize`. Equity recommendations are appropriate for long-horizon users with stable income; they are inappropriate for users in `Survive` state regardless of the recommendation's utility score.

The RiskChallenge compares the risk profile of the candidate recommendation's `FinancialInstrument` against the user's `FinancialState` and `FinancialFacts.riskProfile`. When instrument risk exceeds the state-appropriate ceiling, the challenge proposes a risk-equivalent instrument at an appropriate risk tier.

---

## 4. Domain Model

### 4.1 ChallengeType

```
enum ChallengeType {
  liquidity,
  debt,
  behavior,
  tax,
  timing,
  risk,
}
```

### 4.2 ChallengeOutcome

```
enum ChallengeOutcome {
  /// The challenger found no stronger alternative. The original candidate stands.
  confirmed,

  /// The challenger found a materially stronger alternative. The candidate is
  /// replaced. The engine selects the challenger's proposed candidate instead.
  replaced,

  /// The challenger found that the candidate is sound but requires a modification
  /// — a different amount, instrument tier, or timing. The candidate is modified
  /// in place rather than replaced.
  modified,
}
```

### 4.3 ChallengeResult

```
ChallengeResult {
  // Which challenge ran.
  final ChallengeType challenger;

  // The outcome: confirmed, replaced, or modified.
  final ChallengeOutcome outcome;

  // The challenger's proposed DecisionType if outcome == replaced.
  // Null when outcome == confirmed.
  final DecisionType? proposedReplacement;

  // Human-readable reason for the challenge outcome. Always populated.
  // Surfaces in the Explanation.alternatives[] and ExplanationData.limitations[].
  final String reason;

  // The delta applied to the candidate's compound confidence score.
  // Negative when the challenge weakens the recommendation.
  // Range: -1.0 to 0.0. Zero when outcome == confirmed.
  final double confidenceDelta;

  // The axis score that drove this challenge result.
  // Populated from DecisionAxisResult for the challenge's primary axis.
  final double triggeringAxisScore;

  // Evidence from FinancialFacts that drove this challenge.
  // Surfaces in ExplanationData.evidence[].
  final List<String> evidence;
}
```

### 4.4 ChallengeLayerResult

The aggregate output of running all six challenges:

```
ChallengeLayerResult {
  // The original candidate DecisionType before challenges.
  final DecisionType originalCandidate;

  // The final candidate after all challenges have run.
  // May equal originalCandidate (if all confirmed) or differ (if any challenge
  // produced a replacement).
  final DecisionType finalCandidate;

  // All six ChallengeResult objects. Always exactly 6 — one per ChallengeType.
  final List<ChallengeResult> results;

  // True if any challenge produced outcome == replaced or modified.
  bool get wasChanged => results.any(
    (r) => r.outcome == ChallengeOutcome.replaced || r.outcome == ChallengeOutcome.modified
  );

  // The net confidence delta: sum of all individual challenge confidenceDeltas.
  // Applied to the DecisionConfidenceReport.compoundConfidence of the final candidate.
  double get totalConfidenceDelta => results.fold(0.0, (sum, r) => sum + r.confidenceDelta);

  // All challenges that produced a non-confirmed outcome.
  List<ChallengeResult> get activeResults =>
    results.where((r) => r.outcome != ChallengeOutcome.confirmed).toList();

  // All reasons from active challenges. Surfaces in Explanation.alternatives[].
  List<String> get challengeReasons =>
    activeResults.map((r) => r.reason).toList();
}
```

---

## 5. Challenge Pipeline

The pipeline runs after the Utility Scoring phase and before the `Decision` object is assembled. It operates on a single recommended candidate — the top-ranked `DecisionType` from the utility scorer.

```
Step 1: Receive recommended candidate
        Input: DecisionType (top utility score), FinancialReasoningContext

Step 2: Run all 6 challenges in parallel
        Each challenge receives: candidate, FinancialReasoningContext, FinancialPolicy
        Each challenge produces: ChallengeResult

Step 3: Evaluate challenge results
        If all 6 outcomes == confirmed → proceed to Step 5 (no change)
        If any outcome == replaced    → collect all replacement proposals
        If any outcome == modified    → apply modifications to candidate

Step 4: Resolve replacement conflict (when multiple challenges propose replacement)
        Priority order: Liquidity > Debt > Risk > Behavior > Tax > Timing
        The highest-priority replacement wins.
        Reason: Safety challenges (liquidity, debt, risk) override opportunity challenges.
        Record all losing replacement proposals in ChallengeLayerResult.results[].

Step 5: Assemble ChallengeLayerResult
        finalCandidate = winner (original or replacement)
        All 6 ChallengeResult objects are recorded regardless of outcome.
        totalConfidenceDelta is computed.

Step 6: Apply confidence delta
        The ChallengeLayerResult.totalConfidenceDelta is applied to the
        DecisionConfidenceReport.compoundConfidence of the final candidate.
        Floor: compoundConfidence cannot go below 0.03 (minimum displayable).

Step 7: Pass to Decision Assembly
        Output: finalCandidate (DecisionType), ChallengeLayerResult (for explanation)
```

The `ChallengeLayerResult` is attached to the `DecisionAudit` and surfaces challenge reasons in `Explanation.alternatives[]`. The user sees what was considered and rejected — this satisfies PennyWise Constitution Trust Law 1 (Explainability Before Action).

---

## 6. Challenge Trigger Conditions

Each challenge defines a specific trigger condition. A challenge only produces a non-`confirmed` outcome when its trigger condition evaluates to true. When the trigger condition is false, the challenge returns `ChallengeResult(outcome: confirmed, confidenceDelta: 0.0)`.

### LiquidityChallenge Trigger

```
TRIGGER when:
  emergencyFundMonths < FinancialPolicy.emergencyFundTargetMonths (default: 6.0)
  AND candidate != DecisionType.buildEmergencyFund
  AND candidate != DecisionType.reviewPastDecision

ACTION:
  Compute buildEmergencyFundUtility using FinancialReasoningContext.
  If buildEmergencyFundUtility > candidateUtility × 0.90:
    outcome = replaced, proposedReplacement = buildEmergencyFund
    confidenceDelta = -(1.0 - emergencyFundMonths / emergencyFundTargetMonths) × 0.30
  Else:
    outcome = modified (add liquidity warning to candidate explanation)
    confidenceDelta = -0.05
```

### DebtChallenge Trigger

```
TRIGGER when:
  debtRatio > 0.0 (any debt present)
  AND effectiveDebtRate > expectedReturnRate(candidate)
  AND candidate NOT IN [reduceDebt, buildEmergencyFund, getInsurance]

Where effectiveDebtRate is estimated from debtRatio and FinancialPolicy constants.
Where expectedReturnRate(candidate) = FinancialPolicy.returnRateForMonths(recommendationHorizon).

ACTION:
  If debtRatio > 0.40 (SAFE_EMI_INCOME_RATIO exceeded):
    outcome = replaced, proposedReplacement = reduceDebt
    confidenceDelta = -(debtRatio - 0.40) × 0.50
  Else if effectiveDebtRate > expectedReturnRate + 0.03 (3% spread threshold):
    outcome = replaced, proposedReplacement = reduceDebt
    confidenceDelta = -0.10
  Else:
    outcome = modified (add debt-priority warning)
    confidenceDelta = -0.03
```

### BehaviorChallenge Trigger

```
TRIGGER when:
  behaviorConfidenceFactor >= 0.50 (engine has run, behavioral data available)
  AND dominantBehaviorProfile is present
  AND candidateRequiresHighFrictionBehavior(candidate, dominantBehaviorProfile) == true

Where candidateRequiresHighFrictionBehavior() maps:
  - startGoalSip     → requires: consistent monthly commitment
  - stepUpSip        → requires: existing SIP history
  - buildEmergencyFund → low friction (always allowed)
  - reduceDebt       → requires: spending discipline
  - optimizeTax      → low friction (one-time action)

ACTION:
  If historicalSipCancellationRate > 0.50 AND candidate IN [startGoalSip, stepUpSip]:
    outcome = replaced, proposedReplacement = increaseSavingsRate (lower friction path)
    confidenceDelta = -behaviorConfidenceFactor × 0.15
  Else:
    outcome = modified (add behavioral friction warning)
    confidenceDelta = -0.05
```

### TaxChallenge Trigger

```
TRIGGER when:
  currentMonth IN [January, February, March] (Q4 of Indian financial year)
  AND taxEfficiency < 0.85 (80C capacity not fully utilized)
  AND remainingDaysToFinancialYearEnd <= 60
  AND candidate NOT IN [optimizeTax, reviewPastDecision]
  AND savingsRate >= FinancialPolicy.minSavingsRate (user can afford 80C investment)

ACTION:
  Compute section80CRemaining from FinancialPolicy.section80CLimit and taxEfficiency.
  Compute afterTaxUtility = candidateUtility + taxSavingEquivalent(section80CRemaining).
  If taxSavingEquivalent > candidateUtility × 0.20 (20% utility improvement):
    outcome = replaced, proposedReplacement = optimizeTax
    confidenceDelta = +0.05 (tax deadline adds urgency confidence)
  Else:
    outcome = confirmed (tax saving is real but minor)
    confidenceDelta = 0.0
```

Note: The TaxChallenge is unique in that it can produce a positive `confidenceDelta` when the replacement is confirmed — deadline-driven urgency increases confidence.

### TimingChallenge Trigger

```
TRIGGER when:
  candidate IN [startGoalSip, stepUpSip, rebalancePortfolio]
  AND candidate requires monthly surplus commitment

ACTION:
  Compute effectiveSurplus = monthlySurplus - nearTermObligationBurden30Days.
  If effectiveSurplus < recommendedCommitmentAmount × 1.20 (less than 20% buffer):
    outcome = modified (reduce recommended commitment amount, maintain candidate type)
    confidenceDelta = -0.08
  If effectiveSurplus <= 0:
    outcome = replaced, proposedReplacement = reviewPastDecision (no room to act now)
    confidenceDelta = -0.20
```

### RiskChallenge Trigger

```
TRIGGER when:
  instrumentRiskTier(candidate) > stateAppropriateRiskCeiling(financialState)

Where stateAppropriateRiskCeiling():
  Survive   → tier 1 only (liquid funds, FD, RD)
  Stabilize → tier 1–2 (+ debt mutual funds, balanced funds)
  Build     → tier 1–3 (+ equity mutual funds, ELSS)
  Optimize  → tier 1–4 (all instruments including direct equity)

ACTION:
  Find the highest-scoring instrument at or below stateAppropriateRiskCeiling.
  If such an instrument exists:
    outcome = modified (same candidate type, lower-risk instrument variant)
    confidenceDelta = -0.05
  If no instrument is available at appropriate tier:
    outcome = replaced, proposedReplacement = increaseSavingsRate
    confidenceDelta = -0.10
```

---

## 7. Integration — Where the Challenge Layer Sits

The Challenge Layer is inserted at a single, well-defined position in the v2 recommendation pipeline:

```
FinancialReasoningContext
        │
        ▼
[1] Axis Evaluation (6 axes × DecisionAxisResult)
        │
        ▼
[2] Compound Confidence Computation (DecisionConfidenceReport)
        │
        ▼
[3] Candidate Generation (all applicable DecisionType candidates)
        │
        ▼
[4] Utility Scoring (rank candidates by weighted axis scores)
        │
        ▼
[5] TOP CANDIDATE SELECTED ← utility winner exits here
        │
        ▼
[6] CHALLENGE LAYER ← runs here, BEFORE Decision assembly
        │  Inputs:  top candidate, FinancialReasoningContext, FinancialPolicy
        │  Outputs: ChallengeLayerResult (finalCandidate, all 6 ChallengeResults)
        │
        ▼
[7] Constitution Check (see Document 07 — Financial Constitution)
        │
        ▼
[8] Decision Assembly (Decision object, Explanation, TrustMetadata)
        │
        ▼
[9] Partner Matching (PartnerMatchingEngine → RankedPartnerProgram[])
        │
        ▼
[10] DecisionResponse envelope assembled
        │
        ▼
[11] UI Render (TodaysBestDecisionCard + BankProgramSlider)
```

The Challenge Layer must complete before the Constitution Check (Step 7), because the Challenge Layer may replace the candidate and the Constitution Check must evaluate the final candidate, not the original.

The Challenge Layer runs after Utility Scoring (Step 4) and not during axis evaluation (Step 1), because the challenges require a concrete candidate to argue against. Running challenges during axis evaluation would be premature — there is no candidate to challenge yet.

### What the Challenge Layer Does Not Do

The Challenge Layer does not re-evaluate all six `DecisionAxis` scores. It operates on the already-computed `DecisionConfidenceReport`. It uses axis scores as inputs to its trigger conditions; it does not recompute them.

The Challenge Layer does not rank multiple candidates. It receives one candidate (the utility winner) and either confirms it, modifies it, or replaces it with one specific alternative. The ranking responsibility belongs to the Utility Scorer.

---

## 8. Invariants

These invariants are non-negotiable properties of the Challenge Layer. A correct implementation must satisfy all of them.

**Invariant 1 — Termination**
The Challenge Layer must always terminate in O(6) challenge evaluations. It runs exactly six challenges, each of which performs a bounded computation against `FinancialReasoningContext`. No challenge may trigger another challenge. No challenge may request additional backend calls. No recursive or iterative challenge cycles are permitted.

**Invariant 2 — Single Replacement**
At most one replacement may be accepted. When multiple challenges propose replacement, the priority order defined in Step 4 of the pipeline (Liquidity > Debt > Risk > Behavior > Tax > Timing) determines the winner. All other proposed replacements are recorded in `ChallengeLayerResult.results[]` as `replaced` outcomes for audit and explanation purposes, but do not change the final candidate.

**Invariant 3 — The Replacement Must Outperform**
A challenge may only produce `outcome == replaced` if its proposed replacement has a demonstrably higher utility than the original candidate on the challenge's primary axis, computed using the same `FinancialReasoningContext`. A challenge may not propose a replacement on the basis of policy alone — it must show a utility differential.

Exception: `LiquidityChallenge` when `emergencyFundMonths < 1.0` (critical threshold). At extreme liquidity deficiency, the replacement is fiduciarily mandatory regardless of utility differential. This exception must be documented in the `ChallengeResult.reason`.

**Invariant 4 — The Confirmed Candidate is Unchanged**
When all six challenges return `confirmed`, the final candidate is identical to the input candidate. The Challenge Layer does not modify the candidate's type, instrument, or utility score when no challenge triggers. The only permitted output in this case is `ChallengeLayerResult(finalCandidate == originalCandidate, wasChanged == false)`.

**Invariant 5 — Confidence Can Only Decrease (Except Tax)**
The `totalConfidenceDelta` must be ≤ 0.0, except when the `TaxChallenge` produces a replacement with a positive delta. The Challenge Layer is a critic, not an amplifier. It cannot increase the overall recommendation confidence beyond the tax deadline urgency exception.

**Invariant 6 — All Results Are Recorded**
All six `ChallengeResult` objects must be included in `ChallengeLayerResult.results[]` regardless of their outcome. Confirmed challenges are not discarded. They are evidence that the recommendation survived scrutiny — which contributes to explainability.

**Invariant 7 — Challenge Reasons Are User-Readable**
Every `ChallengeResult.reason` must be written in plain language that could be shown in an explanation panel to the user. The Challenge Layer must not generate technical diagnostic strings — it generates human-readable explanations of why an alternative was or was not selected.

---

## 9. Migration from v1

The v1 reasoning pipeline has no Challenge Layer. The top-ranked candidate from the utility scorer is passed directly to Decision Assembly. The migration is additive — no existing code is removed.

### Migration Step 1 — Add `ChallengeType`, `ChallengeOutcome`, `ChallengeResult`, `ChallengeLayerResult` domain types

New files under `mobile/lib/domain/reasoning/`:
- `challenge_type.dart`
- `challenge_outcome.dart`
- `challenge_result.dart`
- `challenge_layer_result.dart`

### Migration Step 2 — Add `ChallengeLayerEngine` interface

New file: `mobile/lib/domain/engines/challenge_layer_engine.dart`

```
abstract class ChallengeLayerEngine {
  ChallengeLayerResult challenge({
    required DecisionType candidate,
    required FinancialReasoningContext context,
    required FinancialPolicy policy,
    required DecisionConfidenceReport confidenceReport,
  });
}
```

### Migration Step 3 — Add `RuleBasedChallengeLayerEngine` implementation

New file: `mobile/lib/infrastructure/engines/rule_based_challenge_layer_engine.dart`

Implements all six challenges using the trigger conditions defined in Section 6. No external dependencies — pure computation on `FinancialReasoningContext`.

### Migration Step 4 — Wire into `FinancialReasoningEngine`

In `mobile/lib/infrastructure/engines/financial_reasoning_engine.dart`:
1. After the utility scorer selects the top candidate
2. Before `Decision` object assembly
3. Pass `ChallengeLayerResult` to `DecisionAudit` and `Explanation`

### Migration Step 5 — Surface in Explanation

`Explanation.alternatives[]` already exists in the domain model. The challenge reasons from `ChallengeLayerResult.challengeReasons` are inserted here. Users see what was considered and why it was not selected.

### Feature Flag

The Challenge Layer is gated behind `EngineFlag.challengeLayerEnabled` (to be added to `engine_flags.dart`). Default: `false` (off in v1-compatible mode). When disabled, the engine skips Steps 6 and 7 of the pipeline and assembles the Decision directly from the utility-winner candidate. This allows a clean A/B test between v1 and v2 behavior.

### Backward Compatibility

When the Challenge Layer flag is off, the pipeline behaves identically to v1. When it is on, all previously valid `Decision` objects remain valid — the Challenge Layer can only change the `DecisionType` and `confidenceDelta`, both of which are already present in the domain model. No database schema changes are required.

---

## Appendix A — Challenge Priority Rationale

The challenge priority order (Liquidity > Debt > Risk > Behavior > Tax > Timing) reflects a deliberate hierarchy of financial harm:

| Priority | Challenge | Rationale |
|----------|-----------|-----------|
| 1 | Liquidity | No liquidity = financial emergency. Nothing else matters if the user cannot cover an unexpected expense. |
| 2 | Debt | High-cost debt at >12% annualised is a guaranteed negative return. No investment justifies ignoring it. |
| 3 | Risk | Mismatched risk destroys capital for users in Survive/Stabilize state. |
| 4 | Behavior | A recommendation that the user will not follow through with is not a recommendation — it is a prediction of failure. |
| 5 | Tax | Tax savings are real and time-sensitive but do not override safety or debt. |
| 6 | Timing | Timing adjustments are modifications, not replacements — lowest stakes. |

---

## Appendix B — Relationship to DecisionAxis Weights

The six challenges do not directly replicate the six `DecisionAxis` weights from `DecisionConfidenceReport`. The axes measure financial health; the challenges interrogate the recommendation's fitness. The mapping is:

| Challenge | Primary Axis | Why Different |
|-----------|-------------|---------------|
| LiquidityChallenge | `liquidity` | Axis measures health; challenge proposes a better action |
| DebtChallenge | `cashFlow` (debt component) | Axis aggregates cash flow; challenge isolates debt burden |
| BehaviorChallenge | `behavior` | Axis measures pattern quality; challenge predicts execution failure |
| TaxChallenge | `taxes` | Axis measures current efficiency; challenge identifies deadline urgency |
| TimingChallenge | `cashFlow` (commitment density) | Axis aggregates surplus; challenge identifies near-term obligation spikes |
| RiskChallenge | `opportunityCost` (risk-adjusted) | Axis measures growth; challenge checks state-appropriate risk ceiling |
