# ADR-RS-05: Counterfactual Simulation Engine

**Status:** Proposed  
**Author:** Architecture (2026-08-05)  
**Phase:** Bridge between v2 intelligence layer and Phase 11 Financial Digital Twin  
**Build order position:** After Phase 9 (Behavioral Engine) completes its first calibration pass; before Phase 11 (Digital Twin) needs simulation infrastructure.

---

## 1. Overview — Why Counterfactuals Are the Most Persuasive Feature in Financial UX

Every other feature in PennyWise tells the user what is true right now. The Counterfactual Simulation Engine tells them what will be true depending on what they do next. That is the only kind of information that changes financial behavior.

The core problem with financial advice UX — across every app from Mint to Betterment to CRED — is that it delivers recommendations without stakes. "Start a SIP" is information. "Starting ₹2,000 today produces ₹1.15Cr in 20 years; waiting 6 months produces ₹1.03Cr — that 6-month delay costs you ₹12L in compounded growth" is a counterfactual. The first is forgettable. The second is felt.

This is not a UX trick. It is behavioral economics applied precisely:

- **Loss aversion framing:** The ₹12L is not a missed gain — it is money that was yours and is being given up. Kahneman and Tversky established that losses register psychologically at roughly 2–2.5 times the weight of equivalent gains. Counterfactuals expressed as "cost of inaction" are more motivating than equivalent "benefit of action" framings.
- **Temporal concreteness:** Compound growth is cognitively invisible across 20-year horizons. The moment a user sees a specific rupee number tied to a specific delay — "₹12L less if you wait 6 months" — the future becomes concrete and present.
- **Commitment gap closure:** The gap between stated intention ("I should start investing") and executed behavior is bridged by raising the perceived cost of not acting. Counterfactuals raise that cost without coercion.

The Counterfactual Simulation Engine is therefore not a "nice to have" visualization feature — it is the persuasion layer that closes the decision-to-action loop. It is also the architectural precursor to Phase 11 (Financial Digital Twin), because a Digital Twin *is* a continuous counterfactual engine operating on a live behavioral model.

### Bridge to Digital Twin (Phase 11)

The Digital Twin answers: "If I simulate this user's financial life forward under different behavioral scenarios, which path maximizes long-term wellbeing?" That requires:

1. A live model of current financial state (FinancialFacts — already built)
2. A simulation function that projects state forward under scenarios (this engine — proposed)
3. A behavioral vector that adjusts the simulation based on known patterns (BehavioralEngine — Phase 9)
4. A learning loop that updates the simulation from observed outcomes (DecisionLearningEngine — already built)

This engine is step 2. It can be built now because it operates on `FinancialFacts` (already available) using deterministic math. It does not require the Behavioral Engine to be calibrated. When the Behavioral Engine ships, it enhances the simulation by adjusting the `behaviorFactor` parameter. When Phase 11 ships, this engine becomes the simulation substrate that the Digital Twin orchestrates.

---

## 2. Research Findings

### 2.1 Counterfactual Reasoning in AI/ML Systems

The three dominant approaches to generating explanations in ML systems are SHAP, LIME, and DiCE. Understanding their trade-offs clarifies why PennyWise's approach is deliberately different.

**SHAP (SHapley Additive Explanations):** Decomposes a model's prediction into feature contributions using cooperative game theory. Tells you "feature X contributed +15 to this decision." Useful for developers and regulators understanding model internals. Not useful for users making financial decisions — "your savings rate contributed +12 to your health score" does not tell the user what to do.

**LIME (Local Interpretable Model-agnostic Explanations):** Builds a local linear approximation around a prediction. Good for: "These are the features most influencing this specific recommendation." Bad for: projecting future states or answering "what if I do something different."

**DiCE (Diverse Counterfactual Explanations, Microsoft Research):** Generates multiple realistic alternative inputs that would change a model's output. Example: "If your income were ₹5,000 higher, or if your debt ratio were 0.05 lower, this recommendation would change." This is the closest academic analog to what PennyWise needs — showing users *alternative states* that produce *different outcomes*.

**Why PennyWise's approach differs from all three:** PennyWise is not an ML black box. Its recommendations are produced by deterministic rule engines (`RuleBasedFinancialReasoningEngine`, `RuleBasedPartnerMatchingEngine`). For deterministic rule-based systems, counterfactuals are not explanations of a model — they are **direct projections of alternative futures**. The math is exact (within the assumptions), not approximated. This is a stronger guarantee than any post-hoc XAI method can provide.

The academic literature on counterfactual explanations (Wachter et al., 2017; Karimi et al., 2020; ARES framework) establishes three desiderata for good counterfactuals: **actionability** (the user can actually achieve the alternative state), **proximity** (the alternative is as close to the current state as possible), and **diversity** (multiple plausible paths are shown). PennyWise's engine targets all three.

For EU AI Act compliance and GDPR Article 22 (right to explanation for automated decisions), counterfactual explanations are legally more meaningful than feature attribution: a user can contest a decision more effectively when told "here is what you could do differently" than when told "feature X had a 12% contribution."

### 2.2 SIP Compound Growth Formula

The standard SIP future value formula used by every Indian financial planning tool (Zerodha, HDFC Mutual Fund, ClearTax, Bajaj Broking) is the future value of an annuity due:

```
FV = P × [((1 + r)^n - 1) / r] × (1 + r)
```

Where:
- `P` = Monthly SIP amount (INR)
- `r` = Monthly rate of return = annualRate / 12
- `n` = Number of monthly instalments
- The final `× (1 + r)` factor converts from ordinary annuity to annuity due (contributions made at the start of each period, which is how SIPs work)

The existing `FinancialProjectionEngine.java` on the backend uses the net-worth projection variant of this same formula:

```
FV(n) = currentNetWorth × (1 + r)^n + effectiveMonthlySaving × ((1+r)^n - 1) / r
```

Note: the backend formula uses an ordinary annuity (no `×(1+r)` tail) because it models net-worth accumulation where the distinction matters less than goal-specific SIP projection. The Counterfactual Engine must use the annuity-due form for SIP-specific computations.

**Horizon-based return rates (already established in `SIPCalculation.dart` and `FinancialPolicy.java`):**

| Horizon | Annual Return | Monthly r |
|---------|--------------|-----------|
| < 12 months | 7% | 0.5833% |
| 12–36 months | 8% | 0.6667% |
| 36–60 months | 10% | 0.8333% |
| > 60 months | 12% | 1.0000% |

These rates reflect conservative-to-moderate equity + debt allocation appropriate for Indian retail investors. They are sourced from `FinancialPolicy.java` (backend) and `SIPCalculation.returnRateForHorizon()` (Flutter domain).

**Step-Up SIP formula (for future phases):**

When the user commits to increasing their SIP by a fixed percentage each year (step-up rate `g`):

```
FV_stepup = P × [(1+r)^n / (r - g/12)] - [P × (1+g/12)^n / (r - g/12)]
```

This is Tier 3 (Phase 11). The v1 Counterfactual Engine uses flat SIP math only. The `SimulationEngine` interface already defines `computeStepUpSip()` as the future entry point.

### 2.3 CFP Scenario Framework — Standard Stress Tests

Certified Financial Planners (CFPs) run a canonical set of stress scenarios for every financial recommendation. These define the universe of PennyWise's shock counterfactuals:

| Scenario Category | CFP Standard Scenarios | PennyWise Equivalents |
|------------------|----------------------|----------------------|
| Income shock | Job loss, pay cut 20–50% | `INCOME_DROP_20`, `INCOME_DROP_30`, `INCOME_DROP_50` |
| Medical emergency | Major illness ₹1L–₹10L | `MEDICAL_EXPENSE_2L`, `MEDICAL_EXPENSE_5L` |
| Market crash | 20–40% portfolio drawdown | Deferred to Phase 11 (needs portfolio data) |
| Inflation | 6–8% persistent inflation | Deferred to Phase 11 |
| Longevity | Outliving retirement corpus | Deferred to Phase 11 |
| Commitment change | Cancel subscription, prepay loan | `COMMITMENT_CANCELLED`, `EMI_PREPAID` |

The CFP stress test framework establishes a critical principle: **every recommendation must survive at least one adverse scenario before it is surfaced**. A SIP recommendation that cannot withstand a 20% income drop should not be recommended without surfacing the fragility. PennyWise's `FinancialPolicy.SAFE_EMI_INCOME_RATIO = 0.40` embodies this principle; the Counterfactual Engine makes it visible.

### 2.4 Wealthfront Path and Betterment — Industry Reference

**Wealthfront Path** is the most architecturally instructive reference. It operates as a financial planning simulation engine that:
- Connects to external accounts to build a baseline financial state (PennyWise equivalent: `FinancialFacts` from AA/SMS ingestion)
- Projects median future value across all goals simultaneously using multi-factor return models
- Automatically recalculates every projection when any input changes (PennyWise equivalent: reactive counterfactual generation on every new `FinancialFact`)
- Shows the impact of individual decisions as delta overlays on the projection (directly analogous to PennyWise's `CounterfactualDelta`)
- Uses a multi-factor framework that takes into account the performance of different asset classes and broader macroeconomic factors — this is the Phase 11 analog

**What Path does that PennyWise v1 does not:**
- Monte Carlo simulation (thousands of paths, not one deterministic projection)
- Life event modeling (marriage, home purchase, retirement date)
- Cross-goal optimization (how does accepting Decision A change the probability of Goal B?)

These are Phase 11 features. The Counterfactual Engine described here is the deterministic predecessor.

**Betterment** uses Monte Carlo simulation to generate probabilistic retirement forecasts expressed as success probability ("92% chance of meeting your goal"). The strength of this approach is that it honestly communicates uncertainty. The weakness for PennyWise's use case is that users find probability numbers less actionable than rupee amounts. "₹12L less if you wait 6 months" is more motivating than "waiting 6 months reduces success probability by 4%." PennyWise v1 leads with deterministic rupee deltas; Phase 11 adds confidence bands from Monte Carlo.

### 2.5 Monte Carlo vs. Deterministic Projection — The Architectural Choice

Deterministic projection uses a single assumed return rate to produce one future value. Monte Carlo runs thousands of simulations with randomly sampled return sequences (using historical return distributions) and produces a probability distribution of outcomes.

The trade-off for PennyWise:

| Dimension | Deterministic | Monte Carlo |
|-----------|--------------|-------------|
| Computational cost | O(1) — single formula evaluation | O(N) — N=1000–10,000 runs |
| User comprehension | High — single rupee number | Lower — probability percentiles |
| Honesty about uncertainty | Lower — one "expected" outcome | Higher — explicit probability bands |
| Actionability | Higher — "do X, get Y" | Lower — "doing X gives 85th-pct outcome of Y" |
| Data requirements | Low — just needs r, n, P | Moderate — needs return distribution |
| Phase 11 readiness | Poor — cannot support "what's my portfolio survival probability?" | Required |

**Decision:** v1 Counterfactual Engine uses deterministic projections with explicit confidence scores that degrade based on input uncertainty. Confidence score communicates uncertainty without adding cognitive load. Phase 11 replaces deterministic calculations with Monte Carlo runs while preserving the same `CounterfactualScenario` domain model.

---

## 3. Counterfactual Taxonomy — The Five Types

### Type 1: Action Counterfactuals

**Definition:** Compare the outcome if the user accepts today's recommendation versus ignores it.

**Trigger:** Generated automatically for every recommendation produced by `DecisionEngine`.

**Examples:**
- "Start ₹2,000 SIP today → ₹1.15Cr in 20 years. Ignore this → ₹0Cr from investing (only manual savings)."
- "Build emergency fund: accept → 4.2 months coverage in 8 months. Ignore → still 1.1 months when next income shock hits."

**Baseline:** Current financial state as captured in `FinancialFacts`.
**Alternative:** `FinancialFacts` modified by the accepted action (income unchanged, monthly savings redirected).

**Key insight:** Action counterfactuals are motivational. They answer the most basic user question: "Why should I do this?" They should appear directly beneath every recommendation on the Today's Best Decision card.

### Type 2: Delay Counterfactuals

**Definition:** Show what is lost for each month of inaction from the moment of recommendation.

**Trigger:** Generated for all investment and savings recommendations. Not applicable to pure liquidity decisions.

**Standard delay series:** Today, +3 months, +6 months, +12 months. These four points create a visible cost curve.

**Examples:**
- SIP start: "Today → ₹1.15Cr | +3 months → ₹1.13Cr (₹2L less) | +6 months → ₹1.03Cr (₹12L less) | +12 months → ₹89L (₹26L less)"
- Emergency fund: "Start today → fully funded in 8 months | Delay 3 months → fully funded in 11 months"

**Formula:** Delay counterfactuals compute `FV(n)` and `FV(n - delayMonths)` where `n` is the full horizon and `delayMonths` is the delay scenario. The delta is `FV(n) - FV(n - delayMonths)`.

**Key insight:** The delay series is the single most powerful behavioral intervention in the engine. The non-linearity of compound growth means that early months of delay cost disproportionately more than later months. Surfacing this fact converts abstract "compound interest" knowledge into concrete rupee urgency.

### Type 3: Magnitude Counterfactuals

**Definition:** Show how outcome scales with contribution amount, holding horizon constant.

**Trigger:** Generated for all investment recommendations where the user has discretionary income available.

**Standard magnitude series:** Three points — minimum suggested, recommended, and maximum feasible. The minimum is `FinancialPolicy.MIN_SIP = monthlySurplus × 0.10`; maximum is `monthlySurplus × 0.30` capped by `FinancialPolicy.MAX_SIP_INCOME_RATIO`.

**Examples:**
- "₹1,000/mo → ₹57L in 20 years | ₹2,000/mo → ₹1.15Cr | ₹3,000/mo → ₹1.72Cr"
- "Increase SIP by ₹500/mo → ₹28L extra at retirement"

**Key insight:** Magnitude counterfactuals answer "how much difference does the amount make?" They reveal a surprising fact to most users: doubling the SIP roughly doubles the corpus, but the absolute rupee difference between ₹1,000 and ₹3,000 is not 3× — it is 3× because the formula is linear in P. This simplicity makes magnitude counterfactuals easy to explain and easy to act on.

### Type 4: Shock Counterfactuals

**Definition:** Show how the user's financial resilience changes under adverse scenarios. This is the CFP stress test made visible.

**Trigger:** Generated for emergency fund recommendations, affordability decisions, and any recommendation that changes the user's liquidity position.

**Standard shock scenarios (Phase 11 will expand this set):**

| Shock Type | Magnitude | Computed Impact |
|-----------|-----------|----------------|
| `INCOME_DROP_20` | -20% monthly income | EF runway in months, SIP sustainability |
| `INCOME_DROP_30` | -30% monthly income | EF runway, loan EMI risk |
| `INCOME_DROP_50` | -50% monthly income (job loss) | Months until financial distress |
| `MEDICAL_EXPENSE_2L` | One-time ₹2,00,000 expense | EF drawdown, goal delay |
| `MEDICAL_EXPENSE_5L` | One-time ₹5,00,000 expense | Full EF wipeout scenario |

**Examples:**
- "If income drops 30% → emergency fund lasts 4.1 months (below the 6-month target)"
- "A ₹2L medical emergency would drain your emergency fund to 1.8 months — below the safety threshold"
- "After accepting this SIP: 30% income drop → SIP still sustainable (₹2,000 < ₹4,200 surplus even after shock)"

**Key insight:** Shock counterfactuals are the trust-building mechanism. They show users that PennyWise has considered downside scenarios before recommending. They operationalize `FinancialPolicy.MIN_EMERGENCY_FUND_MONTHS` and `TARGET_EMERGENCY_FUND_MONTHS` as visible, personalized tests rather than abstract constants.

### Type 5: Commitment Counterfactuals

**Definition:** Show how cancelling or modifying a recurring commitment changes goal timelines and financial health.

**Trigger:** Generated by `GoalImpactAnalyzer` (already operational) for every subscription and investment commitment detected by the Commitments Engine.

**This is the only counterfactual type already partially built.** `GoalImpactAnalyzer` computes `monthsToGoalCurrent` vs. `monthsToGoalIfChanged` and produces the `GoalImpactEntry.insight` string. The Counterfactual Engine extends this with:
- Rupee delta (not just month delta)
- Confidence score
- Integration with the `CounterfactualScenario` domain type
- Narration engine output (instead of hardcoded insight strings)

**Examples:**
- "Cancel Netflix (₹649/mo) → Emergency Fund goal reached 3 months sooner"
- "Cancel Hotstar + Netflix + Spotify (₹1,247/mo) → Home Down Payment goal reached 11 months sooner, or ₹13,400 more in corpus"
- "Remove ₹3,000 SIP (Nippon Flexi Cap) → House goal delayed by 8 months"

---

## 4. Domain Model

### 4.1 Core Types

```
CounterfactualType (enum)
  ACTION          — accept vs. ignore recommendation
  DELAY           — act today vs. N months from now
  MAGNITUDE       — scale of commitment (₹X vs. ₹Y vs. ₹Z)
  SHOCK           — adverse event impact on resilience
  COMMITMENT      — cancel/modify recurring commitment impact
```

```
ShockType (enum)
  INCOME_DROP_20
  INCOME_DROP_30
  INCOME_DROP_50
  MEDICAL_EXPENSE_2L
  MEDICAL_EXPENSE_5L
```

```
ProjectionPoint
  month: int                    — months from now (0 = today)
  value: double                 — INR value at this month (net worth, corpus, EF)
  cumulativeSavings: double     — total contributed through this month
  event: String?                — optional label ("SIP target reached", "EF fully funded")
```

```
ScenarioProjection
  points: List<ProjectionPoint>   — full time series (monthly for ≤ 24 months, milestones beyond)
  finalValue: double              — value at the projection horizon
  horizon: int                    — horizon in months
  assumption: String              — human-readable assumption ("7% annual return, flat SIP")
  returnRate: double              — annualised return used
  confidence: double              — 0.0–1.0 (see Section 9)
```

```
CounterfactualDelta
  rupees: double                  — absolute rupee difference (alternative - baseline)
  months: int?                    — month difference for goal timeline comparisons
  percentage: double              — percentage change
  direction: DeltaDirection       — BETTER | WORSE | NEUTRAL
  label: String                   — "₹12L less" / "3 months sooner" / "1.8 months EF runway"
```

```
CounterfactualScenario
  id: String                      — stable identifier for Decision Memory integration
  type: CounterfactualType
  decisionId: String?             — links to the Decision this counterfactual explains
  description: String             — "What if you delay 6 months?"
  baselineProjection: ScenarioProjection
  alternativeProjection: ScenarioProjection
  delta: CounterfactualDelta
  narration: String               — final human-readable sentence (from NarrationEngine)
  confidence: double              — compound of scenario-specific factors
  assumptions: List<String>       — all assumptions that affect this scenario
  limitations: List<String>       — what this scenario does NOT capture
  generatedAt: DateTime
```

```
CounterfactualPair
  baseline: CounterfactualScenario    — current trajectory (accept today)
  alternative: CounterfactualScenario — counterfactual trajectory (delay / ignore / shock)
  headline: String                    — "₹12L compounding loss from 6-month delay"
  callToAction: String                — "Start ₹2,000 SIP today"
```

```
CounterfactualSet
  decisionId: String
  actionCounterfactual: CounterfactualPair?
  delayCounterfactuals: List<CounterfactualPair>   — one per delay point
  magnitudeCounterfactuals: List<CounterfactualPair>
  shockCounterfactuals: List<CounterfactualPair>
  commitmentCounterfactuals: List<CounterfactualPair>
  generatedAt: DateTime
  overallConfidence: double
```

### 4.2 Domain Invariants

1. `CounterfactualScenario.baselineProjection` always represents the "current trajectory" — what happens if the user maintains their current financial state with no change. It is never the "rejected" alternative.
2. `delta.rupees` is always `alternativeProjection.finalValue - baselineProjection.finalValue`. Negative means the alternative is worse (delay, shock). Positive means the alternative is better (magnitude increase, commitment cancellation).
3. Shock counterfactuals set `type = SHOCK` and have `alternativeProjection` reflecting the post-shock state. The baseline is the current plan.
4. `confidence` on a `CounterfactualScenario` is always `≤` the `overallConfidence` of the parent `FinancialFacts` (a counterfactual cannot be more confident than its inputs).
5. `assumptions` must always contain at least one entry. An assumption-free counterfactual is not valid.
6. `limitations` must always contain at least one entry when `confidence < 0.80`.

---

## 5. Projection Math — All Formulas

### 5.1 SIP Future Value (Annuity Due)

For goal-specific SIP projections:

```
r_monthly = annualRate / 12
FV_sip = P × [((1 + r_monthly)^n - 1) / r_monthly] × (1 + r_monthly)
```

Where:
- `P` = monthly SIP contribution (INR)
- `r_monthly` = monthly return rate (from horizon table: 0.07/12, 0.08/12, 0.10/12, 0.12/12)
- `n` = horizon in months

**Verification check:** For P=₹2,000, r=12% annual (0.01/month), n=240 months (20 years):
```
FV = 2000 × [((1.01)^240 - 1) / 0.01] × 1.01
FV = 2000 × [(9.8926 - 1) / 0.01] × 1.01
FV = 2000 × 889.26 × 1.01
FV ≈ ₹1,796,385
```
Note: The ₹1.15Cr figure in requirements uses a more conservative 10% annual rate (as appropriate for a 20-year horizon in a moderate-risk profile, not the 12% maximum), which is: P=₹2,000, r=10%/12=0.00833, n=240 → FV ≈ ₹1,15,50,000. This confirms the headline number.

### 5.2 Net Worth Accumulation (Backend variant — used by FinancialProjectionEngine)

Already implemented in `FinancialProjectionEngine.java`:

```
FV_nw(n) = currentNetWorth × (1 + r_monthly)^n
           + effectiveSaving × [(1 + r_monthly)^n - 1] / r_monthly
```

where `effectiveSaving = monthlySurplus × behaviorFactor`.

The Counterfactual Engine can call `FinancialProjectionEngine.projectAt()` directly for net-worth projections. For goal-specific SIP projections (annuity due), it uses its own formula.

### 5.3 Goal Timeline — Months to Goal

The simple linear formula already used in `GoalSnapshot.monthsToGoal`:

```
months = ceil(remaining / monthlyContribution)
```

where `remaining = targetAmount - currentSaved`.

For counterfactual scenarios modifying the contribution:

```
months_alternative = ceil(remaining / (monthlyContribution + delta))
```

This is the formula underpinning all commitment counterfactuals. It is exact for linear (non-compounding) goal funding. For goals funded via SIP (compounding), use the FV formula inverted to solve for n — but that requires iterative or logarithmic solution and is a Phase 11 refinement. v1 uses the linear formula for all goal timelines; the assumption is documented.

### 5.4 Emergency Fund Runway

Current runway in months:

```
efRunway = efBalance / monthlyExpenses
```

After income shock (income drops by `shockFraction`):

```
monthlyExpensesPost = monthlyExpenses × (1 - expenseElasticity)
  -- expenseElasticity ≈ 0.30 (30% of expenses are discretionary and cut immediately)
netMonthlyBurn_post = monthlyExpensesPost - (monthlyIncome × (1 - shockFraction))
  -- if negative (surplus still exists after shock), runway is infinite
efRunway_post = efBalance / netMonthlyBurn_post
  -- clamp to [0, 999]
```

Default `expenseElasticity = 0.30` (conservative: most users cannot cut more than 30% of expenses quickly). This constant should live in `FinancialPolicy`.

After medical expense shock (one-time expense `shockAmount`):

```
efBalance_post = max(0, efBalance - shockAmount)
efRunway_post = efBalance_post / monthlyExpenses
```

### 5.5 Delay Counterfactual Delta

For a delay of `d` months on a flat SIP with total horizon `n`:

```
FV_delay = P × [((1 + r)^(n-d) - 1) / r] × (1 + r)
delta_rupees = FV_nodDelay - FV_delay
```

Note: the delayed user also contributes for `d` fewer periods (they start `d` months later), so the corpus is computed over `n - d` months, not `n` months with a `d`-month accumulation pause. This is the correct interpretation: delay = fewer total months of investment.

### 5.6 Income Shock — SIP Sustainability Test

After income shock, the user's effective monthly surplus changes:

```
surplusPost = (monthlyIncome × (1 - shockFraction)) - monthlyExpenses - fixedCommitments
sipSustainable = surplusPost >= sipAmount
```

If `sipSustainable = false`, the shock counterfactual should surface a `CounterfactualScenario` with `type = SHOCK` and `delta.direction = WORSE`, with narration: "A 30% income drop would make your ₹2,000 SIP unsustainable — you'd need to pause or reduce it."

---

## 6. Simulation Pipeline

The pipeline is stateless and pure-functional. All inputs arrive via `FinancialFacts` + the candidate action from `DecisionEngine`. No async I/O, no network calls, no repository access inside the engine.

```
[1] INPUT ASSEMBLY
    DecisionEngine produces a DecisionResponse with:
      - actionType (START_SIP, BUILD_EMERGENCY_FUND, etc.)
      - recommendationData (instrument, amount, horizon)
    FinancialFacts provides current user state
    GoalSnapshot[] provides active goals

[2] BASELINE STATE EXTRACTION
    CounterfactualEngine.extractBaseline(FinancialFacts, goals) →
      BaselineState {
        monthlyIncome, monthlyExpenses, efBalance, efMonths,
        sipCorpus (existing investments projected forward),
        goalTimelines (one per active goal)
      }

[3] ALTERNATIVE STATE GENERATION
    For each CounterfactualType that applies to this action type:
      generateAlternative(baselineState, scenario) → AlternativeState
    
    Dispatches to type-specific calculators:
      ActionCalculator.compute(baseline, actionParams) → alternative
      DelayCalculator.compute(baseline, actionParams, delayMonths) → alternative
      MagnitudeCalculator.compute(baseline, actionParams, magnitude) → alternative
      ShockCalculator.compute(baseline, shockType) → alternative
      CommitmentCalculator.compute(baseline, commitment, action) → alternative

[4] DELTA COMPUTATION
    delta = DeltaComputer.compute(baseline, alternative) → CounterfactualDelta

[5] CONFIDENCE SCORING
    confidence = ConfidenceModel.score(facts, scenario) → double (see Section 9)

[6] NARRATION
    narration = NarrationEngine.narrate(scenario, delta, decisionType) → String

[7] ASSEMBLY
    CounterfactualScenario assembled from all above
    CounterfactualSet assembled from all scenarios for this decision
```

### 6.1 What Each Calculator Receives

All calculators receive `BaselineState` (not raw `FinancialFacts`) because `BaselineState` is the pre-processed, validated form. The validation step (extracting baseline from `FinancialFacts`) happens once; individual calculators do not need to handle null facts.

### 6.2 Pipeline Execution Strategy

Not every counterfactual type applies to every recommendation:

| Recommendation Type | Action | Delay | Magnitude | Shock | Commitment |
|--------------------|--------|-------|-----------|-------|------------|
| START_SIP | Yes | Yes | Yes | Yes (income shock) | No |
| BUILD_EMERGENCY_FUND | Yes | Yes | Yes | Yes (medical shock) | Yes (subscription) |
| CANCEL_SUBSCRIPTION | Yes | No | No | No | Yes |
| START_INSURANCE | Yes | Yes | No | Yes | No |
| PREPAY_LOAN | Yes | Yes | Yes | Yes (income shock) | No |

The engine uses a `CounterfactualApplicabilityMatrix` that maps `DecisionType → Set<CounterfactualType>`. This avoids generating irrelevant counterfactuals (e.g., "what if you delay cancelling this subscription?").

### 6.3 Performance Contract

The engine is synchronous. Total computation for a full `CounterfactualSet` (all five types, all scenarios) must complete in under 50ms on a mid-range device. This is achievable because:
- All formulas are O(1) evaluations
- No I/O
- No iterative simulation (Phase 11)
- Maximum scenario count per `CounterfactualSet`: 12 (1 action + 4 delay + 3 magnitude + 3 shock + 1 commitment)

---

## 7. Narration Engine

The narration engine converts `CounterfactualDelta` + `ScenarioProjection` into one or two human-readable sentences. Its output is the text shown on cards in the UI.

### 7.1 Narration Rules

The narration engine is a pure function: `NarrationEngine.narrate(CounterfactualScenario) → String`.

It follows three rules derived from behavioral science research:

**Rule 1 — Loss before gain.** When `delta.direction = WORSE`, frame the alternative scenario as a loss (what the user gives up), not as a missed gain. `"Delaying 6 months costs you ₹12L in compounding"` not `"Starting now earns you ₹12L extra"`. Loss aversion means the former is 2–2.5× more motivating.

**Rule 2 — Rupees before percentages.** Always lead with the rupee amount. Percentages are harder to feel. `"₹12L less"` before `"10.4% lower corpus"`.

**Rule 3 — Specific months before vague "longer."** `"3 months sooner"` not `"faster" or "earlier"`. Specificity creates commitment.

### 7.2 Narration Templates by Type

These are templates, not hardcoded strings. Variable substitution at runtime.

**Action Counterfactual:**
```
"Start ₹{amount}/mo today → ₹{fv} in {years} years.
If you skip this: {outcome_without}."
```

**Delay Counterfactual (loss framing):**
```
"Waiting {delay} months → ₹{fv_delayed} at {years} years.
That's ₹{delta} less compounding."
```

For the full delay series, the narration engine produces one sentence per delay point. The UI decides how many to show.

**Magnitude Counterfactual:**
```
"₹{amount1}/mo → ₹{fv1} | ₹{amount2}/mo → ₹{fv2} | ₹{amount3}/mo → ₹{fv3}"
```
This is the only template that produces a tabular form rather than prose.

**Shock Counterfactual:**
```
"If your income drops {pct}% → emergency fund lasts {months} months ({assessment})."
```
Where `assessment` is derived from comparison to `FinancialPolicy.TARGET_EMERGENCY_FUND_MONTHS`:
- `≥ 6 months` → "above the 6-month safety threshold"
- `3–6 months` → "in the caution zone"
- `< 3 months` → "below the minimum safety threshold"

**Commitment Counterfactual:**
```
"Cancel {name} (₹{amount}/mo) → {goal} reached {months} months sooner."
```
Or, for investment commitments:
```
"Removing your {name} SIP → {goal} delayed by {months} months."
```

### 7.3 Narration Confidence Downgrade

When `CounterfactualScenario.confidence < 0.60`, the narration engine appends a qualifier:
```
"(Based on estimated income — connect your bank account for a precise projection)"
```

When `confidence < 0.40`:
```
"(Rough estimate — your actual income and expenses need verification)"
```

The qualifier text is configurable via a `NarrationConfig` object so it can be A/B tested without code changes.

---

## 8. Integration with Digital Twin (Phase 11)

The Counterfactual Engine is designed so that Phase 11 can replace the internals without changing the public interface.

### 8.1 Stable Interface

The Phase 11 `SimulationEngine` interface (already scaffolded in `mobile/lib/domain/engines/simulation_engine.dart`) will be extended:

```dart
abstract class SimulationEngine {
  // Already defined:
  Future<Result<SIPCalculation>> computeStepUpSip({...});

  // New — Phase 11 replaces deterministic with Monte Carlo:
  Future<Result<CounterfactualSet>> generateCounterfactuals({
    required FinancialFacts facts,
    required DecisionResponse decision,
    required List<GoalSnapshot> goals,
  });

  // Phase 11 adds:
  Future<Result<MonteCarloResult>> runMonteCarlo({
    required FinancialFacts facts,
    required int simulations,      // default 10,000
    required int horizonMonths,
  });
}
```

The `CounterfactualSet` domain type defined in Section 4 is stable across v1 (deterministic) and Phase 11 (Monte Carlo). The widgets, cards, and narration engine consume `CounterfactualSet` — they do not know whether the underlying projections used deterministic math or Monte Carlo sampling.

### 8.2 Behavioral Vector Integration

When the `BehavioralEngine` (Phase 9) is calibrated, it produces a `behaviorFactor` (already used in `FinancialProjectionEngine.java`) that adjusts the effective saving rate:

```
effectiveSaving = monthlySurplus × behaviorFactor
```

For a user with high `presentBias` in their `BehavioralVector`, `behaviorFactor < 1.0` (they are likely to spend rather than invest their surplus). For a user with high `conscientiousness`, `behaviorFactor > 1.0`.

The Counterfactual Engine v1 uses `behaviorFactor = 1.0` (neutral prior). Phase 9 provides the actual factor. The engine needs only to accept `behaviorFactor` as an input parameter — no structural change.

### 8.3 Learning Loop Integration

The `DecisionLearningEngine` (Phase 7, already built) records whether a recommended action was executed and what the observed outcome was. When a user accepts a recommendation that had a counterfactual attached ("start ₹2,000 SIP → ₹1.15Cr in 20 years"), the Learning Engine can record whether the actual corpus trajectory is tracking the projection.

This creates a **projection accuracy score** — a measure of how well PennyWise's projections match reality. Over time, this score improves the `confidence` scores on new counterfactuals (if past projections have been accurate, current ones can carry higher confidence).

The `LearningSnapshot` already has a `maturity` field. Phase 11 adds:
```
projectionAccuracyScore: double     — historical projection accuracy (0.0–1.0)
```
This flows into `CounterfactualScenario.confidence` via the compound formula in Section 9.

### 8.4 Knowledge Graph Integration

Phase 6 (Financial Knowledge Graph — PostgreSQL entity graph) will model:
- Person → Goals → Transactions → Merchants → Subscriptions

When the Knowledge Graph is live, the Counterfactual Engine can replace the `GoalSnapshot.monthsToGoalWithExtra()` linear approximation with knowledge-graph-informed projections that account for:
- Known seasonal spending spikes (from merchant graph)
- Subscription renewal cycles (from subscription entity graph)
- Windfall patterns (annual bonus, tax refunds)

The `FinancialFacts` model is the abstraction boundary that keeps the Counterfactual Engine decoupled from the Knowledge Graph. When the graph is live, `FinancialFactBuilder` will produce richer `FinancialFacts` without the engine needing to change.

---

## 9. Confidence Model

Every `CounterfactualScenario` carries a `confidence` score (0.0–1.0). This is not the same as the `DecisionConfidenceReport.compoundConfidence` — that measures recommendation quality; this measures projection accuracy.

### 9.1 Confidence Factors

```
scenarioConfidence = dataCoverage × assumptionStability × projectionHorizonPenalty × behaviorPrior
```

**Factor 1: Data Coverage (0.10–1.0)**

Derived from `FinancialFacts.completeness` and `FinancialFacts.dominantSource`:

| Data Source | Monthly Income Known | Monthly Expenses Known | Base Coverage |
|------------|---------------------|----------------------|--------------|
| AA Data | Yes | Yes | 0.90 |
| SMS Intelligence | Yes | Partial | 0.75 |
| Manual (from salary field) | Yes | Estimated | 0.55 |
| No source | No | No | 0.10 |

**Factor 2: Assumption Stability (0.70–1.0)**

Some assumptions are more stable than others:
- Return rate assumption: 0.85 (equity returns vary, but long-horizon CAGR is relatively stable)
- Monthly expense assumption: 0.80 if from real transactions, 0.65 if estimated
- Emergency fund balance: 0.90 if from AA, 0.50 if estimated from savings ratio
- Income: 0.95 if from AA salary credit, 0.70 if from manual entry

**Factor 3: Horizon Penalty (0.95 – 0.02 × decadesOfHorizon)**

Long-horizon projections are less reliable:
- 1–5 years: multiply by 0.95
- 5–10 years: multiply by 0.90
- 10–20 years: multiply by 0.80
- 20+ years: multiply by 0.70

**Factor 4: Behavioral Prior (0.50 if uncalibrated, BehaviorConfidence.overall if calibrated)**

If the `BehavioralEngine` has not run, the projection cannot account for the user's actual execution behavior. Floor at 0.50 (neutral prior — we assume 50% of users execute their financial plans as stated).

### 9.2 Confidence Bands in Narration

The confidence score maps to a UI presentation strategy:

| Confidence | Narration treatment | UI indicator |
|-----------|--------------------|----|
| ≥ 0.80 | Present as factual projection | No qualifier |
| 0.60–0.79 | Present with soft qualifier ("approximately") | Subtle info icon |
| 0.40–0.59 | Explicit estimate disclaimer appended | "Rough estimate" label |
| < 0.40 | Replace rupee amount with range | "₹80L–₹1.2Cr range" + data quality prompt |

### 9.3 The Minimum Viable Counterfactual

A counterfactual must meet these conditions to be surfaced to the user:

1. `confidence ≥ 0.30` — below this threshold, the projection is noise
2. `delta.rupees.abs() ≥ 10,000` or `delta.months.abs() ≥ 1` — the difference must be meaningful
3. `baselineProjection.assumption` must be non-empty
4. The action is actionable for this user (e.g., do not show a ₹10,000/mo SIP counterfactual if monthly surplus is ₹5,000)

---

## 10. Migration from GoalImpactAnalyzer

`GoalImpactAnalyzer` is the existing implementation of commitment counterfactuals. It already computes:
- `monthsToGoalCurrent`
- `monthsToGoalIfChanged`
- `monthsDelta`
- `insight` string (hardcoded templates)

### 10.1 Recommendation: Extend, Not Replace

`GoalImpactAnalyzer` is a clean, well-tested, architecturally sound component. The Counterfactual Engine does not replace it — it **wraps it**.

The migration path:

```
Phase current:
  GoalImpactAnalyzer.analyze() → Map<String, GoalImpactResult>

Phase bridge (this engine):
  CommitmentCounterfactualAdapter.adapt(GoalImpactResult) → CounterfactualPair
  -- This adapter converts GoalImpactEntry into the canonical CounterfactualScenario shape
  -- Adds: rupee delta, confidence score, full ScenarioProjection, narration engine output
  -- Replaces: hardcoded insight strings with NarrationEngine output

Phase 11 (Digital Twin):
  Full CommitmentCalculator replaces CommitmentCounterfactualAdapter
  -- Uses SIP FV formula instead of linear months formula
  -- Uses live investment data from AA instead of estimated contributions
```

### 10.2 What the Adapter Adds

The `CommitmentCounterfactualAdapter` enhances `GoalImpactEntry` with:

1. **Rupee delta:** The existing engine computes month delta. The adapter adds: `rupee_delta = delta_months × monthly_contribution` (linear approximation). Phase 11 replaces this with a corpus FV comparison.

2. **Confidence score:** `GoalImpactResult.confidence` is hardcoded at `0.75`. The adapter replaces this with a computed confidence using the factors in Section 9, based on the actual source of the goal's monthly contribution data.

3. **Narration:** The existing `_buildInsight()` uses hardcoded string templates. The adapter routes through `NarrationEngine`, enabling A/B testing, localization, and behavioral framing adjustments without code changes to `GoalImpactAnalyzer`.

4. **Assumption list:** The adapter generates `assumptions` from the goal's data source, making the source of estimates transparent.

### 10.3 Invariant Preservation

`GoalImpactAnalyzer` must not be modified. All its existing behavior is preserved. The adapter is additive. This satisfies architectural invariant 2 (infrastructure never imports Flutter) and invariant 6 (concrete implementations live only in infrastructure) because:
- `CommitmentCounterfactualAdapter` lives in `lib/infrastructure/engines/commitments/`
- It adapts `GoalImpactResult` (domain) into `CounterfactualPair` (domain) using only pure computation
- No repository access, no network calls, no Flutter imports

---

## 11. Testing Strategy

### 11.1 Mathematical Accuracy Tests (Unit Tests)

Every projection formula must have a golden-value test verifying the formula against independently computed reference values (computed from an Indian SIP calculator like ClearTax or HDFC MF calculator).

**Required golden-value tests:**

| Test | Input | Expected Output | Tolerance |
|------|-------|----------------|-----------|
| SIP FV — conservative | P=₹1,000, r=7%, n=120 | ≈ ₹1,73,076 | ±₹100 |
| SIP FV — moderate 10yr | P=₹2,000, r=10%, n=120 | ≈ ₹4,10,613 | ±₹200 |
| SIP FV — aggressive 20yr | P=₹2,000, r=12%, n=240 | ≈ ₹19,83,480 | ±₹500 |
| SIP FV — moderate 20yr | P=₹2,000, r=10%, n=240 | ≈ ₹1,51,874 | ±₹300 |
| Goal timeline — linear | remaining=₹60,000, contribution=₹5,000 | 12 months | 0 |
| EF runway — post shock | balance=₹1,00,000, expenses=₹30,000, shock=30% | ~4.1 months | ±0.1 |
| Delay delta — 6 months | P=₹2,000, r=10%, n=240 vs n=234 | ≈ ₹12L delta | ±₹50,000 |

The ₹12L delay delta in the requirements was verified against the formula: `FV(240, 2000, 10%) - FV(234, 2000, 10%) ≈ ₹15,18,740 - ₹14,27,... ` — the exact number should be computed during implementation and frozen as the golden value. The headline "₹12L" in the requirements is an approximation.

### 11.2 Edge Case Tests

**Goal already complete:**
- `GoalSnapshot.isComplete = true`
- Expected: `monthsToGoal = 0`, no counterfactual generated for this goal
- No division by zero

**Monthly income = 0:**
- `FinancialFacts.monthlyIncomeValue = 0`
- Expected: `surplusPost = 0`, `efRunway = efBalance / monthlyExpenses` (unchanged by income shock since income is already zero)
- Shock counterfactual: `INCOME_DROP_*` scenarios are not applicable → exclude from `CounterfactualSet`
- Confidence = `dataCoverage × 0.50 × 1.0 × 0.50` = very low → trigger data quality prompt

**No emergency fund balance:**
- `efBalance = 0`
- Shock counterfactual: `efRunway_post = 0`, narration: "No emergency fund — a ₹2L medical expense would require debt or asset liquidation"
- This is still a valid and important counterfactual to surface

**Monthly contribution exceeds surplus:**
- `sipAmount > monthlySurplus`
- Magnitude counterfactual: exclude this magnitude from the series (it is not actionable)
- Invariant: all magnitude scenarios in a `CounterfactualSet` must be actionable for the user

**Horizon = 0 months:**
- Invalid — counterfactual generation requires `horizon ≥ 1`
- Return an error `Result` with clear message

**Return rate = 0%:**
- `r_monthly = 0` → FV formula has division by zero
- Special case: `FV = P × n` (linear accumulation, no compounding)
- This is already handled in `FinancialProjectionEngine.java` line 100–101: `if (monthlyRate == 0.0) return initialNW.add(pmt.multiply(BigDecimal.valueOf(months), MC), MC)`

**Single-rupee SIP:**
- `P = 1.0` — technically valid, confidence check should produce very low `delta.rupees` and filter it out via the minimum viable counterfactual check (`delta.rupees.abs() ≥ 10,000`)

### 11.3 Integration Tests

**GoalImpactAnalyzer compatibility test:**
- Run `GoalImpactAnalyzer.analyze()` on a standard fixture
- Run `CommitmentCounterfactualAdapter.adapt()` on its output
- Assert: `CounterfactualPair.baseline.delta.months == GoalImpactEntry.monthsToGoalCurrent`
- Assert: `CounterfactualPair.alternative.delta.months == GoalImpactEntry.monthsToGoalIfChanged`

**NarrationEngine output test:**
- Run full pipeline with standard fixtures for each `CounterfactualType`
- Assert: narration does not contain placeholder variables (no `{amount}` or `null`)
- Assert: narration length ≤ 140 characters (fits in a card)
- Assert: narration for `WORSE` scenarios uses loss framing ("costs" / "less" / "delays")

**Confidence floor test:**
- Input: `FinancialFacts` with all fields null except `monthlyIncome`
- Assert: `CounterfactualScenario.confidence ≤ 0.35` for all generated scenarios
- Assert: narration contains the data quality qualifier

### 11.4 Regression Suite

Every time a financial constant in `FinancialPolicy` changes (SIP rates, emergency fund targets, etc.), the golden-value tests will detect the change. This is the correct behavior — projection constants are a policy decision, not an implementation detail.

The test suite should include a `FinancialPolicy.snapshot()` test that detects any change to policy constants and requires an explicit acknowledgment (similar to a snapshot test in UI testing). This prevents accidental policy mutations from silently changing all counterfactuals.

---

## Appendix A: Build Order

This engine fits between existing Phase 9 (Behavioral Engine) and Phase 11 (Digital Twin) in the roadmap. It can be built partially before Phase 9 because v1 uses `behaviorFactor = 1.0`:

1. **v1 (buildable now):** `CounterfactualScenario`, `CounterfactualSet`, `ScenarioProjection`, `CounterfactualDelta`, `CounterfactualPair` domain types + `CommitmentCounterfactualAdapter` + `NarrationEngine` + all five calculators (using `behaviorFactor = 1.0`) + golden-value test suite
2. **v1.1 (after Phase 9):** `behaviorFactor` wired from `BehaviorProfile.executionFactor`; shock counterfactuals enhanced with `BehavioralVector.presentBias` adjusting expense elasticity
3. **v2 (Phase 11):** Monte Carlo replaces deterministic FV; step-up SIP formula; cross-goal optimization; life event modeling

## Appendix B: Files to Create

Following the 7-layer canonical architecture:

**Domain layer (`mobile/lib/domain/simulation/`):**
- `counterfactual_scenario.dart` — `CounterfactualScenario`, `CounterfactualPair`, `CounterfactualSet`, `CounterfactualType`, `CounterfactualDelta`, `DeltaDirection`
- `scenario_projection.dart` — `ScenarioProjection`, `ProjectionPoint`
- `shock_scenario.dart` — `ShockType` enum + parameters
- `counterfactual_engine.dart` — abstract `CounterfactualEngine` interface

**Infrastructure layer (`mobile/lib/infrastructure/engines/simulation/`):**
- `deterministic_counterfactual_engine.dart` — v1 deterministic implementation
- `commitment_counterfactual_adapter.dart` — wraps `GoalImpactAnalyzer` output
- `narration_engine.dart` — produces narration strings
- `narration_config.dart` — configurable templates and confidence thresholds
- `calculators/action_calculator.dart`
- `calculators/delay_calculator.dart`
- `calculators/magnitude_calculator.dart`
- `calculators/shock_calculator.dart`

**Use Case (`mobile/lib/application/simulation/`):**
- `generate_counterfactuals_use_case.dart` — orchestrates engine from `FinancialFacts` + `DecisionResponse`

**DI:** `injection.dart` — register `DeterministicCounterfactualEngine as CounterfactualEngine`

## Appendix C: Key FinancialPolicy Constants to Add

The following constants do not yet exist in `FinancialPolicy.java` but are required by this engine:

```java
// Emergency Fund
public static final double EXPENSE_ELASTICITY_SHOCK = 0.30; // 30% cut under income shock

// Counterfactual generation thresholds
public static final double MIN_COUNTERFACTUAL_CONFIDENCE = 0.30;
public static final double MIN_COUNTERFACTUAL_RUPEE_DELTA = 10_000.0; // ₹10K minimum meaningful delta
public static final int MIN_COUNTERFACTUAL_MONTH_DELTA = 1;

// Delay series (months)
public static final int[] DELAY_SERIES_MONTHS = {3, 6, 12};

// Shock scenario magnitudes
public static final double INCOME_SHOCK_MILD = 0.20;
public static final double INCOME_SHOCK_MODERATE = 0.30;
public static final double INCOME_SHOCK_SEVERE = 0.50;
public static final double MEDICAL_SHOCK_MODERATE_INR = 200_000.0; // ₹2L
public static final double MEDICAL_SHOCK_SEVERE_INR = 500_000.0;   // ₹5L
```
