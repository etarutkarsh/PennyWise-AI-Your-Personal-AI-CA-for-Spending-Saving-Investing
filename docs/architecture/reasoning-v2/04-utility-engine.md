# Utility Engine — Design Document
## PennyWise AI — Decision Engine v2

**Status:** Design / Pre-Implementation
**Phase:** Reasoning v2 — Sprint after Architecture Milestone 07
**Author:** Architecture (2026-08-05)
**Depends on:** `BehaviorInterpretation`, `BehavioralVector`, `FinancialFacts`, `DecisionAxis`, `DecisionConfidenceReport`, `LearningSnapshot`

---

## 1. Overview — Why Axis Scoring Alone Is Insufficient

The v1 `FinancialReasoningEngine` scores eight axes (`cashFlow`, `liquidity`, `goalImpact`, `behavior`, `taxes`, `opportunityCost`, `dataConfidence`, `historicalAccuracy`) and multiplies them into a compound confidence scalar. This is powerful for answering: "How confident are we that this recommendation is sound given the user's financial state?"

It cannot answer a different and more fundamental question: "Out of all candidate actions we could recommend today, which one produces the most value **for this specific user's psychology and preferences**?"

The gap is clearest in these scenarios:

**Scenario A — Same financial state, different psychology.** Two users both have a ₹15,000 monthly surplus, an emergency fund of 4 months, and a savings rate of 18%. The axis scores are identical. But User A has `lossAversion = 2.8` (guardian personality) and User B has `lossAversion = 1.2` (optimizer personality). The same ELSS SIP recommendation carries vastly different utility for each: User A experiences the equity volatility as pain disproportionate to the expected return; User B treats it as routine. Axis scoring produces the same answer for both. Utility modeling produces differentiated answers.

**Scenario B — Opportunity cost versus behavioral resistance.** A recurring-deposit step-up has positive `opportunityCost` and `goalImpact` scores. But the user has `statusQuoBias = 0.85` and has rejected the last three SIP recommendations. The axis score says "act." Utility modeling says "the behavioral resistance cost exceeds the expected benefit for this user at this moment — try the lower-friction fixed-deposit nudge instead."

**Scenario C — Time-sensitive states.** A tax-saving ELSS opportunity has high axis scores in March (tax season). But the user is in `BehaviorState.stressWindow` with a balance below 2× expenses. Axis scoring doesn't model the temporal penalty of acting under financial stress. Utility modeling captures this as elevated `Risk` and `LiquidityLoss` terms that reduce net utility below the threshold for recommendation.

**What utility modeling adds:**

1. **Personalized value measurement** — benefits and costs are weighted by the user's own preference structure, not a population average
2. **Psychological penalty modeling** — friction, regret, and resistance are first-class cost terms, not post-hoc filters
3. **Candidate ranking** — with a scalar utility score per candidate, ranking becomes deterministic and explainable: "We recommended the RD step-up over the ELSS because your utility score was 0.72 versus 0.48, primarily due to 31% lower behavioral resistance"
4. **Temporal discounting** — future benefits are discounted by the user's own present-bias coefficient, not a fixed population average
5. **Calibration loop** — utility model parameters improve from observed outcomes, creating the true AI moat

The v1 `compoundConfidence` scalar is preserved as `dataConfidence` × `historicalAccuracy` multipliers on the final utility score. The two systems are complementary, not competing.

---

## 2. Research Findings

### 2.1 Expected Utility Theory (EUT)

The standard von Neumann–Morgenstern formulation defines utility as:

```
EU(A) = Σ p_i · u(x_i)
```

Where `p_i` is the probability of outcome `x_i` and `u(·)` is a utility function that maps monetary outcomes to subjective value. The key insight for financial advisors is that `u(·)` is **concave** for risk-averse individuals — meaning a certain gain of ₹10,000 is preferred over a 50% chance of ₹20,000, even though the expected monetary values are equal.

**Application to financial recommendations:** For each candidate action, EUT requires: (a) enumerating the distribution of possible outcomes; (b) applying the user's utility function to each outcome; (c) computing the probability-weighted sum. In practice, advisors approximate this with an expected-value term adjusted by a risk penalty derived from the variance of outcomes.

**Limitation:** EUT assumes rational, consistent preferences. Empirical research (Kahneman, Thaler) shows humans systematically violate EUT. The Prospect Theory modification is required.

### 2.2 Prospect Theory — Loss Aversion and the Indian Context

Kahneman and Tversky (1979, 1992) demonstrated that humans evaluate outcomes as gains or losses relative to a reference point, not as absolute wealth levels. The value function is:

```
v(x) = x^α           for gains (x > 0)
v(x) = -λ · |x|^β    for losses (x < 0)
```

The empirically estimated global parameters: `α ≈ 0.88`, `β ≈ 0.88`, `λ ≈ 2.25` (Tversky & Kahneman 1992). This means a loss of ₹1,000 feels approximately 2.25× as painful as a gain of ₹1,000 feels good.

**Indian-specific calibration:** Research on Indian retail investors (SEBI Investor Survey 2021, Barberis et al. India-adapted studies, and Chauhan & Ahmad 2018 on NSE investor behavior) consistently finds loss aversion coefficients in the range `λ = 2.5–3.2` — materially higher than the Western population average of 2.25. Contributing factors:

- **Joint family financial interdependence:** Losses affect household honor and family reputation, not just individual wealth
- **Gold as mental anchor:** Physical gold ownership creates a near-zero-loss reference frame; equity fluctuations feel like losses against this mental benchmark
- **Limited insurance penetration:** Without adequate safety nets, financial losses have a higher marginal impact on survival
- **First-generation investors:** Many urban Indians are the first in their family to hold equity — absence of intergenerational experience amplifies perceived risk

**Implementation guidance:** The default `BehavioralVector.lossAversion` of 1.8 in the current codebase is the Kahneman-Tversky global baseline. For Indian users, the uncalibrated prior should be raised to `λ = 2.5`. The calibration loop should update this toward the individually observed value from the user's accept/reject pattern on volatile instrument recommendations.

**The probability weighting function:** Prospect Theory also shows that people overweight small probabilities and underweight large ones. For financial recommendations, this manifests as: users overestimate the probability of the worst-case loss scenario ("what if the market crashes the day I invest?") and underestimate the probability of consistent compounding benefit. The Utility Engine must account for this by applying the inverse probability weighting adjustment when computing `ExpectedBenefit` and `Risk` for equity-linked instruments.

### 2.3 Time Discounting and Present Bias

**Exponential discounting (EUT-consistent):** Classical economics assumes a constant discount rate `r` such that a benefit `B` received at time `t` has present value `B · e^(-r·t)`. At a 10% annual discount rate, ₹1,00,000 in 5 years is worth ₹60,650 today.

**Hyperbolic discounting (empirically observed):** Laibson (1997) and O'Donoghue & Rabin (1999) show that actual human discounting follows a quasi-hyperbolic form:

```
PV(B, t) = B · (β · δ^t)   for t > 0
PV(B, 0) = B               for t = 0
```

Where `β ∈ (0,1)` captures present bias (the extra weight placed on immediate vs. any future payoff) and `δ ∈ (0,1)` is the per-period exponential discount factor. A person with `β = 0.6` and `δ = 0.95` values a benefit in 1 year at `0.6 × 0.95 = 0.57` of its face value, but a benefit in 2 years at `0.6 × 0.95² = 0.54`. The key discontinuity is the jump from "now" to "any future" — captured by `β`.

**Indian present-bias observations:** Studies on Indian financial behavior (Ashraf et al. on savings commitment, Dupas & Robinson replicated in Indian urban contexts) estimate `β` values between 0.55 and 0.75 for urban salaried workers. This is consistent with the `BehavioralVector.presentBias` field currently stored in the domain (default `0.7`).

**Implementation guidance:** Long-term recommendations (SIP for 10+ years, term insurance, ELSS lock-in) must discount their future benefit by the user's `presentBias` coefficient. Short-term recommendations (liquid fund parking, immediate tax saving) should not apply present-bias discounting. The `timeDiscountRate` field in `UtilityModel` encodes the per-year `δ` factor; present bias `β` is sourced directly from `BehavioralVector.presentBias`.

### 2.4 Behavioral Resistance — Quantifying Implementation Friction

"Behavioral resistance" is the aggregate implementation friction a specific user faces when executing a recommendation. The academic foundations span three phenomena:

**Status quo bias (Samuelson & Zeckhauser 1988):** Users disproportionately prefer their current state. Kahneman, Knetsch & Thaler (1991) quantified this via endowment effect experiments. In finance: a user who has been parking savings in a savings account for 2 years faces status quo bias against switching to a liquid mutual fund, even when the rational benefit is clear. The `BehavioralVector.statusQuoBias` field (default `0.5`, range `0–1`) captures this directly.

**Inertia and action costs (Madrian & Shea 2001):** The canonical result: when US 401(k) plans changed the default from opt-in to opt-out, participation rates jumped from 49% to 86%. The recommendation required zero new benefit — just reduced inertia. For financial recommendations, inertia cost is the mental and administrative effort to execute: "Open a new account, submit KYC, set up an auto-pay mandate, hold through the first month of volatility." Each step is a friction cost.

**Complexity aversion (Iyengar & Lepper 2000):** The paradox of choice — more options reduces action likelihood. For recommendations: a "diversify across 3 funds" recommendation has higher complexity cost than a "increase your existing SIP by ₹500" recommendation, even if both produce similar financial outcomes. Complexity is measured as the number of distinct actions required to execute the recommendation.

**Fogg Behavior Model (B = MAP):** BJ Fogg's behavioral model states that behavior occurs when Motivation, Ability, and Prompt are all sufficient at the same moment. For financial recommendations:
- **Motivation** = financial urgency + emotional readiness (captured by `BehaviorState` and intent strength)
- **Ability** = inverse of complexity + behavioral discipline scores (high `savingDiscipline` → higher effective ability)
- **Prompt** = recommendation delivery timing and framing

**Implementation guidance:** The `BehavioralResistance` term in the utility formula is a composite of: `statusQuoBias`, `impulsiveness` (inversely — high impulsiveness reduces resistance to novel actions but increases regret), complexity steps, and whether the recommendation type has been previously rejected (from `LearningSnapshot.activeLessons`).

### 2.5 Regret Theory

Bell (1982) and Loomes & Sugden (1982) developed Regret Theory as an alternative to EUT that captures the psychological cost of making a decision that turns out worse than the forgone alternative.

**Anticipatory regret:** Users mentally simulate the most painful outcome of each candidate action before deciding. For financial recommendations:
- "I start a SIP and the market drops 30% in month one" → regret for having acted
- "I don't start the SIP and the market rises 40% in the next year" → regret for inaction
- The net expected regret = P(bad outcome if act) × regret_intensity_act − P(good forgone outcome if not act) × regret_intensity_inact

**Minimum-regret strategies:** Advisors and robo-platforms reduce anticipated regret through: (a) framing outcomes over long time horizons where the probability of net loss falls; (b) showing historical base rates ("only 3.5% of 10-year SIP periods in Nifty history ended in loss"); (c) recommending instruments with loss-protection features (systematic step-up, STP from liquid to equity) that reduce the peak regret scenario.

**Regret aversion coefficient `ρ`:** This is already present in `BehavioralVector.regretAversion` (default `0.5`). High `ρ` users (guardians, loss-avoiders) weight anticipated regret heavily. The Utility Engine's `Regret` term should scale with `regretAversion`.

**Implementation guidance:** For each candidate action, compute a base regret exposure score from: (a) instrument volatility class; (b) time horizon relative to user's nearest stated goal deadline; (c) whether prior similar recommendations were followed and produced negative outcomes (from `DecisionLesson` history). Scale this by `BehavioralVector.regretAversion`.

### 2.6 Opportunity Cost in Financial Planning

Opportunity cost is the value of the best forgone alternative. In financial recommendations, this is the compounded return differential between the recommended instrument and the next-best alternative the user could realistically execute.

**Quantification approach (Vanguard, Morningstar methodology):** Opportunity cost for a candidate action is:

```
OC(A) = FV(alternative) − FV(A)
```

Where FV is the expected future value at the user's relevant planning horizon. For a liquid savings amount, OC of keeping it in a savings account versus a liquid mutual fund at current interest rate differential × horizon.

**Opportunity cost of inaction:** The most powerful and underused framing in financial advice. If a user has ₹20,000/month surplus and no SIP, the opportunity cost of inaction over 10 years at 12% CAGR is ₹4.5L versus ₹46L — a ₹41.5L opportunity cost. This is the `ExpectedBenefit` of the action (the forgone compounding) expressed as the penalty for not acting.

**Implementation guidance:** The `ExpectedCost` term in the utility formula includes both the direct cost of acting (SIP amount, liquidity commitment) and the forgone-alternative cost. The `opportunityCost` axis from v1 scores the financial state; the utility engine converts this to a per-candidate monetary value using `FinancialPolicy.sipRateForHorizon()`.

### 2.7 Robo-Advisor Personalization Approaches

**Betterment (US):** Personalizes using goal-based time horizons, risk tolerance questionnaire, and tax situation. Utility is implicitly modeled through the goal-funding probability metric: "You have a 94% chance of reaching your retirement goal." Different users see the same underlying portfolio recommendation framed differently based on their stated risk preference. Betterment does not expose a utility scalar — it expresses utility as goal success probability.

**Wealthfront (US):** Uses a passive index allocation model with "Risk Score" (1–10) as the single personalization parameter. Utility modeling is minimal — the platform's differentiation is tax-loss harvesting, not behavioral personalization. Their Path tool does model scenario distributions for users, but this is scenario analysis, not utility optimization.

**Groww / Zerodha Coin (India):** No published utility modeling. Recommendation personalization is based on: stated risk appetite (conservative/moderate/aggressive), investment horizon, and instrument category. The Indian robo-advisor market has not yet delivered genuine behavioral utility personalization.

**The moat opportunity:** No Indian personal finance app has built a personalized utility engine that integrates loss aversion, present bias, behavioral resistance, and regret into a single scalar score per candidate recommendation. This is the architectural gap PennyWise's Utility Engine fills.

**Acorns / Stash (micro-investing):** These platforms have identified that behavioral resistance is the dominant barrier for young investors. Their "round-up" mechanic is a direct reduction of the Complexity term in utility: the execution friction approaches zero. The lesson: for users with high `statusQuoBias`, the Utility Engine should heavily penalize high-complexity recommendations even when their financial return is excellent.

---

## 3. The Utility Formula

### 3.1 Canonical Formula

```
Utility(candidate) = ExpectedBenefit − ExpectedCost − Risk − BehavioralResistance − Regret − Complexity − LiquidityLoss
```

All terms are normalized to a common scale: **INR equivalent value per month over the user's planning horizon**, then divided by monthly income to produce a dimensionless utility score `U ∈ [−1.0, +1.0]`.

Negative utility means the candidate action costs more (in the full behavioral-financial sense) than it returns. The engine should never surface a candidate with negative utility unless no positive-utility candidate exists.

### 3.2 Term-by-Term Definitions

#### Term 1: ExpectedBenefit (EB)

The total expected value delivered by the recommended action, discounted to present value using the user's `presentBias` and `timeDiscountRate`.

```
EB = raw_financial_benefit × PV_discount_factor × probability_weight_correction
```

**raw_financial_benefit** by candidate type:

| Candidate Type | raw_financial_benefit Calculation |
|---|---|
| Start SIP | `FV(amount, rate=sipRateForHorizon(months), horizon) − totalAmountInvested` = net compounding gain |
| Emergency Fund step-up | `target_months × monthlyExpenses × 0.07` = cost of credit avoided (proxy: emergency credit at 18% per annum applied against probability of needing it) |
| Tax saving (ELSS/80C) | `taxableAmount × marginalTaxRate` = direct tax saved this year + ELSS expected return |
| Debt reduction (prepay EMI) | `outstandingPrincipal × interestRate × remainingMonths / 12` = total interest saved |
| Increase savings rate | `additionalMonthlySavings × 12 × compoundingYears × riskFreeRate` = additional corpus at planning horizon |
| SIP step-up | Incremental compounding gain from the step-up amount over remaining horizon |
| Insurance (term/health) | `coverageAmount × P(claim) − premium` where P(claim) actuarially derived; minimum floor = stress reduction value |

**PV_discount_factor** for a benefit at horizon `T` months in the future:

```
PV_discount_factor = β × δ^(T/12)
```

Where `β = BehavioralVector.presentBias` and `δ = 1 − UtilityModel.timeDiscountRate`. Benefits realised immediately (tax refund, emergency fund utilisation avoided) use `PV_discount_factor = 1.0`.

**probability_weight_correction:** Applies the Prospect Theory inverse probability weighting for equity-linked instruments to correct for the user's tendency to overweight downside probability. For risk-free instruments (FD, RD, PPF), correction = 1.0. For equity instruments:

```
probability_weight_correction = 1 − (lossAversion − 2.25) × 0.05
```

This applies a small downward correction to expected benefit for users whose loss aversion exceeds the population baseline, acknowledging that their subjective probability weighting systematically undervalues the compounding upside.

#### Term 2: ExpectedCost (EC)

```
EC = directCost + opportunityCostOfCapital
```

**directCost:** The actual rupee outflow committed by the action:
- SIP: `monthly_sip_amount × 1` (one month commitment as proxy)
- EMI prepayment: `prepayment_amount`
- Tax saving: `investment_amount`
- Insurance: `annual_premium / 12` (monthly cost)
- Emergency fund: `additional_deposit_amount`

All expressed as fraction of `monthlyIncome` for normalization.

**opportunityCostOfCapital:** What the same rupee could have earned in the next-best liquid alternative. Proxy: `directCost × (riskFreeRate − savingsAccountRate)` per month. For most Indian users: liquid fund at ~7% p.a. versus savings account at ~3.5% p.a. → monthly opportunity cost differential = `directCost × 0.035 / 12`.

#### Term 3: Risk (R)

The financial risk exposure introduced or increased by the action.

```
R = (marketRisk × marketRiskWeight) + (liquidityRisk × liquidityRiskWeight) + (debtRisk × debtRiskWeight)
```

All terms normalized to [0,1] then scaled by `UtilityModel.lossAversionCoefficient`:

```
R_total = R × lossAversionCoefficient / 2.25
```

The `/2.25` normalization ensures that a user with the population-average loss aversion (λ=2.25) experiences a standard risk penalty. A guardian with λ=3.1 experiences 38% higher risk penalty for the same instrument.

**marketRisk** by instrument class:
- Liquid fund, FD, RD, PPF: 0.0
- Debt mutual fund: 0.1
- Balanced/Hybrid fund: 0.3
- Large-cap equity SIP: 0.4
- Mid/small-cap equity: 0.6
- ELSS (3-year lock-in): 0.5 (lock-in amplifies perceived risk even for large-cap exposure)

**liquidityRisk:** How much the action reduces the user's liquid buffer below target. Calculated as:
```
liquidityRisk = max(0, (targetLiquidBuffer − currentBuffer + actionLiquidityDrain) / targetLiquidBuffer)
```

Where `targetLiquidBuffer = 6 × monthlyExpenses` per `FinancialPolicy.TARGET_EMERGENCY_FUND_MONTHS`.

**debtRisk:** For new EMI / credit recommendation only. `= newEMI / monthlySurplus`. Zero for all non-debt actions.

#### Term 4: BehavioralResistance (BR)

The probability that this specific user will not follow through on this recommendation, expressed as a cost (value lost to non-execution).

```
BR = resistanceScore × ExpectedBenefit
```

Where `resistanceScore ∈ [0, 1]` and represents the fraction of the expected benefit that will be lost to behavioral friction. `resistanceScore = 0` means the user will almost certainly execute. `resistanceScore = 0.8` means 80% of the benefit is expected to be lost due to non-execution.

**resistanceScore computation** — see Section 7 (Behavioral Resistance Calculation) for the full derivation. The inputs are drawn from `BehaviorInterpretation`.

#### Term 5: Regret (Rg)

Anticipated regret if the recommendation is followed and produces a worse-than-expected outcome.

```
Rg = P(badOutcome) × regretIntensity × BehavioralVector.regretAversion
```

**P(badOutcome):** Probability that the action produces a materially negative outcome over the recommendation horizon. By instrument:
- FD/RD/PPF: 0.01 (failure limited to bank insolvency, rare)
- Liquid fund: 0.02
- Large-cap equity SIP (10-year horizon): 0.04 (historical: 3.5% of 10-year Nifty rolling windows negative)
- Large-cap equity SIP (1-year horizon): 0.35
- ELSS (3-year): 0.12
- EMI prepayment: 0.03 (opportunity cost regret if rate environment changes)

**regretIntensity:** The severity of the user's regret response if the bad outcome occurs. Driven by:
- `BehavioralVector.lossAversion`: higher λ → higher regret intensity
- Whether this is the user's first investment of this type (first-timer penalty: +0.2)
- Whether the recommendation size exceeds 15% of monthly income (large-bet penalty: +0.15)

```
regretIntensity = 0.5 + (lossAversion − 1.8) × 0.2 + firstTimerPenalty + largeBetPenalty
```

The full `Rg` term is then:
```
Rg = P(badOutcome) × regretIntensity × regretAversion × ExpectedBenefit
```

This ensures regret is proportionate to the size of the bet, not an absolute value.

#### Term 6: Complexity (C)

The implementation friction cost — the expected value lost because the action requires multiple steps and some users will abandon mid-execution.

```
C = actionStepCount × stepCostCoefficient × (1 − UserAbility)
```

**actionStepCount:** Count of distinct actions the user must take to fully execute the recommendation:

| Recommendation | Steps |
|---|---|
| Increase existing SIP by ₹500 | 1 (tap in existing app) |
| Start new SIP on existing platform | 2 (fund selection + mandate) |
| Start first SIP — new AMC account | 5 (KYC + account open + mandate + fund select + first debit) |
| ELSS via new platform | 6 |
| Term insurance — new insurer | 7 (form + medical + payment + nominee + document upload + verification) |
| EMI prepayment to existing lender | 2 |
| FD at existing bank | 1 |

**stepCostCoefficient:** = `0.03 × monthlyIncome` per step. This is a monetary equivalent of the user's time and mental energy per step, calibrated to 30 minutes of effort at median urban Indian opportunity cost of time.

**UserAbility:** `= 0.4 × savingDiscipline/100 + 0.3 × investmentDiscipline/100 + 0.3 × consistency/100`

High-discipline users have lower effective complexity cost because they have established routines and follow through.

#### Term 7: LiquidityLoss (LL)

The value of reduced financial flexibility caused by the action.

```
LL = liquidityDrainAmount × UtilityModel.liquidityPreference × liquidityPremium
```

**liquidityDrainAmount:** Monthly equivalent of liquid funds committed away. For a ₹3,000/month SIP in an ELSS with 3-year lock-in, the drain is `3,000 × 36 = 1,08,000` over the lock-in period, expressed as monthly equivalent `= 3,000`.

**UtilityModel.liquidityPreference** `∈ [0,1]`: User's relative preference for maintaining liquid buffer over deploying capital. `1.0` = extreme liquidity preference (never tie up funds); `0.3` = low preference (comfortable with illiquid assets).

**liquidityPremium:** The marginal value of one rupee of liquidity at the user's current liquidity state:
```
liquidityPremium = max(1.0, 3 − emergencyFundMonths / FinancialPolicy.MIN_EMERGENCY_FUND_MONTHS)
```

When emergency fund < 3 months: `liquidityPremium ≈ 2–3×`. When emergency fund ≥ 6 months: `liquidityPremium = 1.0`. This means liquidity loss costs more when the user can least afford it.

### 3.3 Final Normalized Utility

After computing all terms:

```
rawUtility = EB − EC − R − BR − Rg − C − LL

normalizedUtility = rawUtility / monthlyIncome

U = clamp(normalizedUtility, -1.0, 1.0)
```

The `clamp` operation enforces the `[−1, 1]` invariant. In practice, for well-formed candidates, `U` will typically fall in `[−0.3, 0.8]`.

### 3.4 Confidence-Adjusted Final Utility

The raw utility is further multiplied by a `calibrationConfidence` factor that reflects how confident the engine is in its utility model parameters:

```
finalUtility = U × calibrationConfidence
```

Where `calibrationConfidence = 0.5 × (1 − behaviorUncertainty) + 0.5 × learningMaturity`

- `behaviorUncertainty` = `BehaviorInterpretation.dimensions[presentBias].uncertainty` (proxy for overall parameter uncertainty)
- `learningMaturity` = `LearningSnapshot.maturity`

For a new user: `calibrationConfidence ≈ 0.5 × (1 − 0.95) + 0.5 × 0.0 = 0.025`. This correctly produces very conservative utility estimates for uncalibrated users, preventing the engine from overconfidently recommending complex actions before it knows the user.

---

## 4. UtilityModel — User Preference Domain Object

`UtilityModel` is the personalization kernel. It captures the user's preference structure — how they weigh competing values. It is distinct from `BehavioralVector` (which describes observed behavioral tendencies) in that it captures **preference** — what the user wants to optimize — rather than **pattern** — what they actually do.

```
UtilityModel {
  // Identity
  userId: UserId
  version: String                      // semantic version for calibration tracking
  calibratedAt: DateTime
  calibrationSource: UtilityCalibrationSource   // QUESTIONNAIRE | INFERRED | LEARNED

  // Loss sensitivity (from Prospect Theory)
  lossAversionCoefficient: double      // λ, default 2.5 (Indian prior). Range: 1.0–4.0.
                                       // Sourced from BehavioralVector.lossAversion.
                                       // Updated by DecisionLearningEngine via observed accept/reject patterns.

  // Time preference
  timeDiscountRate: double             // annual rate δ, default 0.10 (10% p.a.)
                                       // Range: 0.05–0.30. Higher = more future-discounting.
  presentBiasCoefficient: double       // β, default 0.70. Sourced from BehavioralVector.presentBias.
                                       // Used to penalize benefits that arrive > 1 month away.

  // Liquidity preference
  liquidityPreference: double          // 0.0–1.0. Higher = more value on keeping cash liquid.
                                       // Default 0.5 for new user. Calibrated from: FinancialFacts.emergencyFundMonths
                                       // (below target → infer high preference), BehaviorState frequency in stressWindow.

  // Complexity tolerance
  complexityTolerance: double          // 0.0–1.0. Higher = handles multi-step recommendations better.
                                       // Default 0.4 for new user. Calibrated from:
                                       // investmentDiscipline + consistency dimension scores.

  // Regret sensitivity
  regretSensitivity: double            // 0.0–1.0. Sourced from BehavioralVector.regretAversion.
                                       // Default 0.5. Amplifies the Regret term.

  // Growth vs. safety weighting
  growthOrientation: double            // 0.0–1.0. Higher = willing to accept more risk for more return.
                                       // Default 0.5. Derived from FinancialPersonality:
                                       //   guardian→0.15, accumulator→0.45, builder→0.65, optimizer→0.85.

  // Behavioral consistency (affects resistanceScore floor)
  behavioralConsistencyScore: double   // 0.0–1.0. = BehaviorInterpretation.overallBehavioralScore / 100.

  // Archetype (see Section 6)
  archetype: UtilityArchetype

  // Recency weight for calibration updates
  learningRate: double                 // default 0.15. Controls how fast new outcomes shift parameters.
                                       // Decreases as calibration matures.
}
```

### Derivation from existing domain objects

At initialization (new user, no calibration):
1. `lossAversionCoefficient` ← `BehavioralVector.uncalibrated.lossAversion` = 1.8, then immediately corrected to Indian prior 2.5
2. `presentBiasCoefficient` ← `BehavioralVector.uncalibrated.presentBias` = 0.70
3. `liquidityPreference` ← computed from `FinancialFacts.emergencyFundMonths`: below 3 months → 0.85, 3–6 months → 0.55, above 6 months → 0.30
4. `complexityTolerance` ← 0.4 (uniform prior)
5. `growthOrientation` ← from declared `riskProfile` in user registration: conservative→0.2, moderate→0.5, aggressive→0.75
6. `archetype` ← derived from `growthOrientation` and `lossAversionCoefficient` (see Section 6)

After behavioral calibration (BehavioralEngine has run):
1. `lossAversionCoefficient` ← `BehavioralVector.lossAversion` (behaviorally observed)
2. `presentBiasCoefficient` ← `BehavioralVector.presentBias`
3. `complexityTolerance` ← derived from `BehaviorDimensionType.consistency.score` and `BehaviorDimensionType.investmentDiscipline.score`
4. `regretSensitivity` ← `BehavioralVector.regretAversion`

---

## 5. UtilityScore — Per-Candidate Output Domain Object

```
UtilityScore {
  // Identity
  candidateId: String                  // identifies the action candidate
  candidateType: CandidateType         // SIP | EMERGENCY_FUND | TAX_SAVING | DEBT_REDUCTION | etc.
  computedAt: DateTime

  // Final scores
  netUtility: double                   // final U ∈ [−1.0, 1.0] after calibration confidence adjustment
  rawUtility: double                   // pre-confidence-adjustment
  calibrationConfidence: double        // 0.0–1.0

  // Component breakdown (all in INR-per-month equivalent, before normalization)
  expectedBenefit: double
  expectedCost: double
  riskPenalty: double
  behavioralResistancePenalty: double
  regretPenalty: double
  complexityPenalty: double
  liquidityLossPenalty: double

  // Rankings
  percentileRank: double               // 0.0–1.0 — relative to all candidates evaluated this session
  rank: int                            // 1 = best candidate

  // Explainability
  topBenefit: String                   // "₹46L additional corpus over 10 years at 12% CAGR"
  topCostFactor: String                // "High behavioral resistance (72%) due to low SIP discipline"
  utilityNarrative: String             // One-sentence explanation of why this score

  // Sensitivity
  sensitivityToLossAversion: double    // How much U changes per unit increase in λ
  sensitivityToPresentBias: double     // How much U changes per unit change in β

  // Behavioral state modifier
  stateModifierApplied: bool           // True if BehaviorState triggered a penalty
  stateModifierReason: String?         // "impulseWindow: 20% utility penalty applied"
}
```

### BehaviorState modifiers to netUtility

The current `BehaviorState` applies multiplicative modifiers to the raw utility before normalization:

| BehaviorState | Modifier | Rationale |
|---|---|---|
| `financiallyStable` | 1.0 (no change) | Baseline |
| `salaryReceived` | 1.15 | Elevated cash + positive emotional state → amplify growth recommendations |
| `bonusReceived` | 1.20 | Maximum liquidity window; highest utility for deployment recommendations |
| `taxSeason` | 1.10 (tax candidates only) | Immediate tax benefit amplifies EB for ELSS/80C candidates |
| `impulseWindow` | 0.75 | Cognitive load elevated; reduce utility of complex/new commitments |
| `highLiquidity` | 0.85 | Impulse risk; conservative dampener on complex actions |
| `stressWindow` | 0.50 | Financial stress; block new commitments |
| `liquidityConstrained` | 0.30 | Near-zero utility for any new commitment; only emergency fund candidates positive |
| `monthEnd` | 0.90 | Mild caution |
| `festivalMode` | 0.80 | Elevated discretionary; dampen investment commitments |
| `coolingDown` | 0.95 | Near-normal |

---

## 6. User Utility Archetypes

Each archetype represents a distinct preference cluster. The `UtilityModel.archetype` field determines default parameter values before calibration, and governs which utility formula terms are most heavily weighted in ranking.

### Archetype 1: GrowthMaximizer

**Profile:** Optimizes for maximum long-horizon wealth accumulation. Accepts volatility. Uncomfortable with idle cash.

**Behavioral signature:**
- `BehavioralVector.lossAversion` < 1.8
- `BehavioralVector.riskToleranceDrift` > 0.65
- `FinancialPersonality.optimizer`
- High `investmentDiscipline`, high `consistency`, low `presentBias`

**Utility model parameters:**
```
lossAversionCoefficient: 1.5
timeDiscountRate: 0.08
presentBiasCoefficient: 0.85
liquidityPreference: 0.20
complexityTolerance: 0.75
regretSensitivity: 0.25
growthOrientation: 0.90
```

**Utility formula weighting:** `ExpectedBenefit` dominates. `Risk` and `Regret` terms are subdued by low λ and ρ. `LiquidityLoss` is near-zero. `BehavioralResistance` is low due to high discipline.

**Recommended candidates:** Equity SIP step-up, mid-cap allocation, ELSS, direct equity. Tax-efficient rebalancing.

**Warning:** Do not recommend ultra-conservative instruments as "top pick" — the GrowthMaximizer will correctly identify these as negative-utility (leaving growth on the table).

---

### Archetype 2: LossAvoider

**Profile:** Prioritizes capital preservation above all. Losses feel disproportionately painful. Needs to "see the floor" before acting.

**Behavioral signature:**
- `BehavioralVector.lossAversion` > 2.8
- `FinancialPersonality.guardian`
- High `financialStress`, high `regretAversion`
- Repeated SIP rejections in `DecisionLesson` history

**Utility model parameters:**
```
lossAversionCoefficient: 3.2
timeDiscountRate: 0.12
presentBiasCoefficient: 0.60
liquidityPreference: 0.75
complexityTolerance: 0.30
regretSensitivity: 0.85
growthOrientation: 0.20
```

**Utility formula weighting:** `Risk` and `Regret` terms dominate. Even moderate-volatility instruments score negative utility for this archetype. `LiquidityLoss` is heavily penalized. `BehavioralResistance` is high for equity instruments.

**Recommended candidates:** FD, RD, PPF, liquid funds, debt mutual funds. Insurance step-up. Emergency fund completion. Term insurance (converts tail risk into certainty — reduces regret exposure).

**Special rule:** Reframe equity recommendations as "floor with upside" (e.g., hybrid balanced advantage fund) before stepping up to pure equity. The safety floor reduces `Regret` term by reducing `P(badOutcome)`.

---

### Archetype 3: LiquidityPreserver

**Profile:** Values cash optionality above return. Maximizes ability to respond to opportunities or emergencies. Uncomfortable with lock-ins.

**Behavioral signature:**
- `BehavioralFacts.emergencyFundMonths` hoarded well above 6 months
- History of early FD breaks or SIP pauses
- High `BehavioralVector.statusQuoBias`
- `BehaviorState.liquidityConstrained` appears frequently in history (anxiety-driven hoarding when buffer drops)

**Utility model parameters:**
```
lossAversionCoefficient: 2.2
timeDiscountRate: 0.15
presentBiasCoefficient: 0.65
liquidityPreference: 0.90
complexityTolerance: 0.45
regretSensitivity: 0.60
growthOrientation: 0.35
```

**Utility formula weighting:** `LiquidityLoss` dominates. Any recommendation that ties up capital receives severe penalty. `ExpectedBenefit` is heavily discounted by high `timeDiscountRate` and low `presentBiasCoefficient`.

**Recommended candidates:** Liquid mutual funds (T+1 redemption), sweep-in FD, SIP in liquid/ultra-short category, overnight fund. NOT: ELSS, PPF, locked-in RD.

**Special rule:** Frame as "liquid but growing" — the highest-utility action for this archetype is often parking surplus in a liquid fund rather than a savings account, with zero lock-in but meaningful return differential.

---

### Archetype 4: TaxOptimizer

**Profile:** Focus on after-tax returns. Maximizes tax efficiency within risk tolerance. Often a salaried professional in the 30% bracket.

**Behavioral signature:**
- `FinancialFacts.taxEfficiency` below 0.60 (not fully using 80C)
- `FinancialPersonality.optimizer`
- `BehaviorState.taxSeason` triggers unusually high action rate in `LearningSnapshot`
- High `investmentDiscipline`

**Utility model parameters:**
```
lossAversionCoefficient: 2.0
timeDiscountRate: 0.09
presentBiasCoefficient: 0.75
liquidityPreference: 0.30
complexityTolerance: 0.65
regretSensitivity: 0.40
growthOrientation: 0.65
```

**Utility formula weighting:** `ExpectedBenefit` for tax candidates includes the direct tax saving, which for a 30% taxpayer substantially elevates EB for 80C instruments even accounting for lock-in (`LiquidityLoss` offset by tax benefit).

**Recommended candidates (in season):** ELSS SIP (best: 80C + equity return), NPS (Tier I, additional ₹50,000 deduction under 80CCD), tax-saving FD (lower priority — 5-year lock-in, no inflation-beating return), health insurance premium (80D). Out of season: rebalancing, step-up of existing 80C investments.

---

### Archetype 5: BalancedGrowth

**Profile:** The median archetype. Wants growth but not at the cost of emotional distress. Accepts moderate volatility if the horizon is long enough. Responds well to systematic, automated recommendations.

**Behavioral signature:**
- `FinancialPersonality.builder` or `accumulator`
- Moderate scores across all behavioral dimensions (no extreme outliers)
- History of following through on some but not all recommendations

**Utility model parameters:**
```
lossAversionCoefficient: 2.5  (Indian prior — unchanged until calibration)
timeDiscountRate: 0.10
presentBiasCoefficient: 0.70
liquidityPreference: 0.50
complexityTolerance: 0.50
regretSensitivity: 0.50
growthOrientation: 0.55
```

**Utility formula weighting:** Balanced across all terms. No single penalty term dominates. This is the default archetype for new users before calibration.

**Recommended candidates:** Large-cap SIP (low volatility for their risk), emergency fund step-up, ELSS in tax season, recurring deposit for short-term goals.

---

## 7. Behavioral Resistance Calculation

`resistanceScore ∈ [0, 1]` is the core behavioral personalization signal. It represents the probability that this user will NOT follow through on a given recommendation type. High resistance means the expected benefit should be heavily discounted.

### Base Resistance by Recommendation Type

Each recommendation type has a default population-level resistance score derived from SEBI and BSE investor survey data:

| Recommendation Type | Population Base Resistance |
|---|---|
| Increase existing SIP | 0.18 |
| Start new SIP (existing platform) | 0.32 |
| Start new SIP (new AMC) | 0.55 |
| Open ELSS account | 0.50 |
| Buy term insurance | 0.65 |
| Buy health insurance | 0.58 |
| EMI prepayment | 0.25 |
| Park in liquid fund | 0.22 |
| Open FD | 0.15 |
| Start RD | 0.20 |

### User-Specific Adjustments from BehaviorInterpretation

The base resistance is then adjusted using the user's behavioral signals:

#### Adjustment 1: Impulsiveness vs. Discipline

```
disciplineAdjustment = (spendingDiscipline.score + savingDiscipline.score + consistency.score) / 300
resistanceAfterDiscipline = baseResistance × (1.8 − disciplineAdjustment)
```

High-discipline users (all three scores > 70) → multiplier ≈ 0.83 (17% reduction in resistance).
Low-discipline users (all three scores < 40) → multiplier ≈ 1.47 (47% increase in resistance).

#### Adjustment 2: Status Quo Bias

```
statusQuoAdjustment = BehavioralVector.statusQuoBias × 0.30
```

Applied only if the recommendation requires a NEW account or instrument the user has never held. If the user already has this instrument type (from transaction history), `statusQuoAdjustment = 0`.

#### Adjustment 3: Prior Rejection Pattern (from LearningSnapshot)

If the `LearningSnapshot.activeLessons` contains a `LessonType.rejectionPattern` for this recommendation type:

```
rejectionPenalty = lesson.confidence.score × 0.40
```

A high-confidence rejection pattern (user has rejected 3+ similar recommendations) adds up to 0.40 to resistance.

#### Adjustment 4: BehaviorState Friction

| BehaviorState | Resistance Multiplier |
|---|---|
| `salaryReceived` | 0.70 (high motivation window — reduce resistance) |
| `bonusReceived` | 0.65 |
| `taxSeason` (for tax instruments) | 0.75 |
| `impulseWindow` | 1.30 (poor execution window) |
| `stressWindow` | 1.50 |
| `liquidityConstrained` | 1.80 |
| `monthEnd` | 1.15 |
| `financiallyStable` | 1.00 |

#### Adjustment 5: Intents Alignment

If the primary `BehaviorIntent` is aligned with the recommendation (e.g., intent = `accelerateSaving` and recommendation = SIP step-up):
```
intentAlignmentBonus = primaryIntent.strength × 0.25
```

Subtract from resistance. If intent conflicts (e.g., intent = `protectCash` and recommendation = new ELSS with lock-in):
```
intentConflictPenalty = primaryIntent.strength × 0.20
```

Add to resistance.

#### Adjustment 6: Contradiction Amplifier

If `BehaviorInterpretation.hasCriticalContradictions` and the recommendation touches the contradicted dimensions (e.g., "High Investor / Low Saver" contradiction → SIP recommendation falls squarely in the contradicted zone):

```
contradictionPenalty = 0.15
```

#### Final resistanceScore

```
resistanceScore = clamp(
  baseResistance
  × disciplineMultiplier
  + statusQuoAdjustment
  + rejectionPenalty
  + stateMultiplierEffect
  − intentAlignmentBonus
  + intentConflictPenalty
  + contradictionPenalty,
  0.05,
  0.95
)
```

The `0.05` floor prevents the engine from treating any recommendation as zero-resistance (there is always some friction). The `0.95` ceiling prevents a recommendation from being dismissed purely on behavioral grounds — if the financial case is strong enough, the engine should still surface it with appropriate framing.

---

## 8. Integration — How Utility Scores Feed into Ranking

### 8.1 Relationship to v1 CompoundConfidence

The v1 `compoundConfidence` scalar (the product of `dataConfidence × decisionConfidence × behaviorConfidence × historicalAccuracy`) measured the quality of the reasoning process. The v2 `netUtility` measures the value of the recommendation outcome.

These are **orthogonal dimensions** and both must be preserved:

| | v1 Confidence | v2 Utility |
|---|---|---|
| Question answered | "How well-founded is this reasoning?" | "How much value does this action deliver to THIS user?" |
| Input | Data quality, axis scores, behavioral calibration, learning history | FinancialFacts, BehavioralVector, UtilityModel, candidate properties |
| Output | `compoundConfidence ∈ [0, 0.45]` | `netUtility ∈ [−1.0, 1.0]` |
| Used for | Recommendation strength label ("High Confidence") | Candidate ranking, recommendation selection |
| Failure mode | Low when data is sparse | Low when recommendation doesn't fit user preference |

### 8.2 The Combined Ranking Signal

The final ranking signal for candidate selection is:

```
rankingScore = netUtility × min(1.0, compoundConfidence / 0.20)
```

The `min(1.0, compoundConfidence / 0.20)` term scales the confidence factor to [0, 1] using 0.20 as the "good enough" confidence threshold. A candidate with excellent utility but very low data confidence is ranked conservatively. A candidate with good utility and strong confidence ranks highest.

### 8.3 The Recommendation Selection Rule

```
selectedCandidate = candidates
  .where((c) => c.utilityScore.netUtility > 0)        // only positive-utility candidates
  .sortByDescending((c) => c.utilityScore.rankingScore)
  .first
```

If no candidate has positive utility (rare — means all actions are net-negative given current state), the engine should output a "stay the course" recommendation with an explicit explanation: "Based on your current financial state and preferences, no new commitments are recommended today. Your existing plan is working."

### 8.4 Runner-Up Surfacing

The second-ranked candidate is surfaced as an "Alternative Action" in the `DecisionResponse.explanation.alternatives[]` array. This allows the user to see that the engine considered multiple options and provides transparency on why the top candidate won.

The `UtilityScore.utilityNarrative` for both top candidate and runner-up should explain the delta: "We chose the RD step-up over the ELSS because your utility score was 0.72 versus 0.48, primarily because the ELSS lock-in removes 36 months of liquidity (LiquidityLoss = ₹1,08,000) at a time when your emergency fund is below target."

### 8.5 Backward Compatibility with v1 Confidence Model

The v1 `DecisionConfidenceReport` is NOT replaced. It continues to feed the confidence label displayed to the user ("High Confidence"). The utility engine adds a second output layer. The `DecisionResponse` envelope should be extended with a `utilityBreakdown` field, populated only when the Utility Engine has run:

```
DecisionResponse {
  ...existing fields...
  utilityBreakdown?: UtilityScore   // null until Utility Engine ships
}
```

The `PartnerRecommendation.matchScore` continues to use the v1 PartnerMatchingEngine scoring. The Utility Engine ranks the primary financial action candidate — it does not re-rank partner programs.

---

## 9. Calibration — How Parameters Improve Over Time

The Utility Engine's moat deepens through continuous calibration of `UtilityModel` parameters from observed decision outcomes. This is the learning loop that differentiates PennyWise from static robo-advisors.

### 9.1 Observable Calibration Signals

| User Action | Signal | Parameter Updated |
|---|---|---|
| Accepts recommendation | Positive execution signal | `resistanceScore` base for this type decreases |
| Rejects recommendation | Negative execution signal | `rejectionPenalty` increases for this type |
| Executes successfully, outcome positive | Positive outcome | `lossAversionCoefficient` nudged down slightly (user proves more comfortable with risk than λ predicted) |
| Executes, outcome negative, no regret expressed | `regretSensitivity` was overestimated | Nudge `regretSensitivity` down |
| Executes, outcome negative, user reviews negatively in Financial Journal | `regretSensitivity` was correctly estimated | No change to regret; increase `lossAversionCoefficient` |
| User consistently delays SIPs but eventually completes | `complexityTolerance` is lower than estimated | Decrease `complexityTolerance`; recommend simpler execution paths |
| User sets up SIP with very small amount (below recommendation) | `liquidityPreference` higher than modeled | Increase `liquidityPreference` |
| User breaks FD / pauses SIP at month end | High `liquidityPreference` confirmed | Increase `liquidityPreference`; flag for `LiquidityPreserver` archetype |
| User takes up upsized recommendation (accepts larger amount than suggested) | `growthOrientation` is higher than modeled | Increase `growthOrientation`; potentially migrate toward `GrowthMaximizer` archetype |

### 9.2 Update Formula

All parameter updates use an exponential weighted moving average:

```
parameter_new = parameter_current × (1 − learningRate) + observed_signal × learningRate
```

Where `learningRate = UtilityModel.learningRate` (default 0.15, decreasing as `LearningSnapshot.maturity` increases).

The decreasing learning rate mirrors Bayesian belief updating: early observations shift parameters significantly; later observations fine-tune a well-calibrated model.

### 9.3 Calibration Source Hierarchy

Parameters have three provenance levels, tracked in `UtilityModel.calibrationSource`:

1. **QUESTIONNAIRE** — directly stated by user (risk appetite: conservative/moderate/aggressive, stated financial goals)
2. **INFERRED** — derived from behavioral analysis without outcome feedback (BehavioralVector from transaction patterns)
3. **LEARNED** — updated from completed decision cycles in the learning loop (highest trust — the user has revealed their actual preference through action)

The Explainability Engine should cite calibration source in explanations: "We estimated your behavioral resistance at 62% based on your previous 3 rejections of similar recommendations" is more trustworthy than "We estimated your resistance at 62% based on population averages."

### 9.4 Archetype Migration

As parameters calibrate, the archetype should be re-evaluated after every 5 completed decision cycles:

```
newArchetype = UtilityArchetype.deriveFrom(updatedUtilityModel)
```

If the archetype changes, a system notification should be generated: "Your financial behavior profile has evolved. You've moved from BalancedGrowth to GrowthMaximizer — your recent decision history shows higher comfort with equity investments."

Archetype migrations are logged in `LearningSnapshot` for audit and explainability.

---

## 10. Migration from v1 — Incremental Introduction

The Utility Engine must be introduced without breaking the existing `DecisionConfidenceReport` and without any regression in recommendation quality during the transition period.

### Phase A — Dark Mode Computation (Sprint N)

The Utility Engine runs in parallel with v1. It computes `UtilityScore` for each candidate but does NOT influence recommendation selection. Output is stored in the decision record for retrospective analysis.

**Acceptance criteria for Phase A exit:**
- Utility Engine runs on 100% of `TodayDecisionService` calls without exception
- `UtilityScore.netUtility` is populated for all candidates
- Correlation between v1 `compoundConfidence` and `netUtility` is measured — if they rank candidates identically >85% of the time, Phase B is safe

### Phase B — Complementary Ranking (Sprint N+1)

The ranking signal becomes `rankingScore = netUtility × min(1, compoundConfidence / 0.20)`. If the top-ranked candidate by utility score and the top-ranked candidate by v1 confidence agree, the utility-ranked candidate is served. If they disagree (utility picks different candidate than confidence), a kill-switch flag `utilityEngineOverrideEnabled` in `FinancialPolicy` (or feature flags — `09-feature-flags.md`) controls which to trust.

**Acceptance criteria for Phase B exit:**
- ≥30 completed decision cycles across test users with outcome tracking
- Utility-ranked recommendations show measurably higher acceptance rate than confidence-ranked recommendations (statistically significant at 90% confidence)

### Phase C — Utility-Primary (Sprint N+2)

Utility score is the primary ranking signal. CompoundConfidence remains as the explanation-layer confidence label. `UtilityScore` is surfaced in the `DecisionResponse.utilityBreakdown` field. The "Why we recommend this" explanation panel references both utility narrative and confidence.

### Kill Switch

`FinancialPolicy` should define a constant `UTILITY_ENGINE_ENABLED: bool` (or backed by `09-feature-flags.md`). When `false`, the system falls back to v1 confidence-ranked candidates. This ensures zero-downtime rollback if the utility engine produces unexpected rankings in production.

### Invariants During Migration

- `DecisionConfidenceReport` is NEVER modified or removed — it remains the source of the user-facing confidence label
- `UtilityScore.netUtility` is NEVER directly shown to users as a number — it is a ranking signal only; user-facing language uses the `utilityNarrative` string
- `UtilityModel` parameters are NEVER reset on a system upgrade — calibration is a user asset

---

## 11. Invariants

The following invariants must hold for every `UtilityScore` object produced by the engine:

```
1. netUtility ∈ [−1.0, 1.0]
   Enforced by: clamp(normalizedUtility, -1.0, 1.0)

2. rawUtility = ExpectedBenefit − ExpectedCost − Risk − BehavioralResistance − Regret − Complexity − LiquidityLoss
   All terms are non-negative. rawUtility may be negative.

3. All component terms are expressed in the same units (INR/month) before normalization.
   Normalization: term / monthlyIncome.
   monthlyIncome ≥ 1 (floor: FinancialFacts.monthlyIncomeValue.clamp(1, double.infinity))

4. calibrationConfidence ∈ [0.0, 1.0]

5. netUtility = rawUtility / monthlyIncome × calibrationConfidence, clamped.

6. percentileRank ∈ [0.0, 1.0]
   Computed as: rank(this candidate) / totalCandidates

7. resistanceScore ∈ [0.05, 0.95] (enforced by clamp in BehavioralResistancePenalty calculation)

8. lossAversionCoefficient ∈ [1.0, 4.0]
   Values outside this range indicate a calibration error. Clamp and log a warning.

9. presentBiasCoefficient ∈ (0, 1)
   A value of 0 would make all future benefits zero; a value of 1 means no present bias.

10. Utility Engine never produces a recommendation without a human-readable utilityNarrative.
    The explanation is a first-class output, not optional.

11. When LearningSnapshot.maturity == 0 (new user), calibrationConfidence ≤ 0.10.
    New users receive conservative utility estimates. The engine should express this via
    UtilityScore.stateModifierReason: "Early calibration — utility estimates will improve
    as we learn your financial behavior."

12. A candidate with netUtility < 0 may only be selected as the top recommendation if
    ALL candidates have netUtility < 0. In this case, the "stay the course" recommendation
    is emitted instead of any candidate.
```

---

## 12. Appendix: Worked Example

**User profile:**
- Monthly income: ₹80,000
- Emergency fund: 2.5 months (below 3-month minimum)
- Savings rate: 12% (below 20% target)
- `BehavioralVector`: λ=2.8, β=0.65, statusQuoBias=0.70, regretAversion=0.75
- `FinancialPersonality`: guardian
- `BehaviorState`: financiallyStable
- `LearningSnapshot`: 2 completed cycles (early calibration)
- Has never started a SIP

**Candidates evaluated:**
1. Start SIP in large-cap fund, ₹2,000/month
2. Step up emergency fund by ₹3,000/month into liquid fund
3. Park this month's surplus in FD

**Candidate 1: Start SIP — Large Cap, ₹2,000/month**

```
EB: FV(₹2,000, 12%, 10yr) = ₹4,64,000 total; net gain ≈ ₹2,24,000
    PV_discount = 0.65 × 0.90^10 = 0.65 × 0.349 = 0.227
    PV-adjusted EB = ₹2,24,000 × 0.227 / 12 months = ₹4,241/month
    → normalized: ₹4,241 / ₹80,000 = 0.053

EC: directCost = ₹2,000/month; OC differential = ₹2,000 × 0.035/12 = ₹5.8/month
    → normalized: ₹2,005 / ₹80,000 = 0.025

Risk: marketRisk=0.40; liquidityRisk≈0 (EF already below target, but SIP not draining EF)
    R_total = 0.40 × (2.8/2.25) = 0.498
    → normalized risk penalty = 0.498 × (₹2,000/₹80,000) = 0.0124

BehavioralResistance:
    baseResistance (new SIP, new AMC) = 0.55
    disciplineAdjustment = moderate discipline → multiplier ≈ 1.1
    statusQuoAdjustment = 0.70 × 0.30 = +0.21 (new instrument)
    stateMultiplier = 1.0 (stable)
    resistanceScore = clamp(0.55 × 1.1 + 0.21, 0.05, 0.95) = clamp(0.815, 0.05, 0.95) = 0.815
    BR = 0.815 × 0.053 = 0.043

Regret:
    P(badOutcome for LCap SIP, 10yr) = 0.04
    regretIntensity = 0.5 + (2.8−1.8)×0.2 + 0.20 (first-timer) = 0.90
    Rg = 0.04 × 0.90 × 0.75 × 0.053 = 0.00143

Complexity: 5 steps (new AMC SIP)
    UserAbility = 0.4×0.50 + 0.3×0.45 + 0.3×0.55 = 0.50
    C = 5 × (0.03 × ₹80,000) × (1−0.50) = 5 × ₹2,400 × 0.50 = ₹6,000
    → normalized: ₹6,000 / ₹80,000 = 0.075

LiquidityLoss: monthly drain = ₹2,000; liquidityPremium = 3 − 2.5/3 = 2.17 (EF below target)
    liquidityPreference (guardian) ≈ 0.75
    LL = (₹2,000 / ₹80,000) × 0.75 × 2.17 = 0.025 × 0.75 × 2.17 = 0.041

rawUtility = 0.053 − 0.025 − 0.012 − 0.043 − 0.001 − 0.075 − 0.041 = −0.144
stateModifier = 1.0; calibrationConfidence = 0.5×(1−0.6)+0.5×0.15 = 0.275
netUtility = −0.144 × 0.275 = −0.040

→ Negative utility. SIP is NOT the top recommendation for this user today.
```

**Candidate 2: Step up Emergency Fund, ₹3,000/month to liquid fund**

```
EB: EF credit avoided = 3.5 months shortfall; monthly benefit = 3.5×₹80,000×0.015 = ₹4,200
    (stress reduction + credit cost avoidance proxy)
    PV_discount = 1.0 (immediate benefit — EF is near-term)
    normalized: ₹4,200 / ₹80,000 = 0.053

EC: directCost = ₹3,000/month; OC differential = ₹3,000 × 0.035/12 = ₹8.75
    normalized: ₹3,008 / ₹80,000 = 0.038

Risk: marketRisk=0.02 (liquid fund); liquidityRisk≈0 (increasing EF reduces liquidity risk)
    R_total = 0.02 × (2.8/2.25) = 0.025; normalized = 0.025 × 0.038 = 0.00095

BehavioralResistance:
    baseResistance (liquid fund) = 0.22
    statusQuoAdjustment = 0 (existing liquid fund or bank account mapping — minimal new account friction)
    disciplineMultiplier = 1.1
    stateModifier = 1.0
    resistanceScore = clamp(0.22 × 1.1, 0.05, 0.95) = 0.242
    BR = 0.242 × 0.053 = 0.013

Regret: P(badOutcome liquid fund) = 0.02; regretIntensity = 0.5 + 0.2 = 0.70
    Rg = 0.02 × 0.70 × 0.75 × 0.053 = 0.00056

Complexity: 1 step (SB account → liquid fund at existing platform)
    C = 1 × ₹2,400 × 0.50 = ₹1,200; normalized = 0.015

LiquidityLoss: negative liquidity loss (increasing EF increases liquidity buffer)
    LL = −0.020 (bonus term: EF step-up earns a liquidity gain credit)

rawUtility = 0.053 − 0.038 − 0.001 − 0.013 − 0.001 − 0.015 + 0.020 = 0.005
stateModifier = 1.0; netUtility = 0.005 × 0.275 = 0.0014

→ Positive. Emergency fund step-up is net-positive utility.
```

**Candidate 3: Park in FD**

Yields a netUtility of approximately 0.003 — less than the liquid fund option because the FD lock-in creates a `LiquidityLoss` penalty even for a short-term FD (penalty outweighs the slight interest rate differential for this LiquidityPreserver-adjacent archetype).

**Ranking:**

1. Emergency Fund step-up: netUtility = 0.0014 (ranked #1)
2. FD: netUtility = 0.0008 (ranked #2)
3. SIP: netUtility = −0.040 (excluded — negative utility)

**Engine output:** "Strengthen your emergency cushion by setting aside ₹3,000/month in a liquid fund. You're 3.5 months below your 6-month safety target, and this is the highest-value action for your financial situation today."

The SIP candidate is preserved as a `DecisionResponse.explanation.alternatives[]` entry with the note: "We recommend starting a SIP once your emergency fund reaches 4 months — your utility score for this action will improve significantly once the liquidity risk is resolved."

---

*End of document — Utility Engine Design v1.0*
