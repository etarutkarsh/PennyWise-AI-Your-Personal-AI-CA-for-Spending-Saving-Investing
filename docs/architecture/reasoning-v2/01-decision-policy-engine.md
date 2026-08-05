# Decision Policy Engine — Design Specification

> **Status:** Design document — ready for implementation.
> **Authored:** 2026-08-05
> **Scope:** Adaptive axis weight system for `FinancialReasoningEngine`. Replaces static `DecisionAxis.weight` with a policy-driven `AxisWeightProfile` selected and evolved based on user profile, financial state, and life stage.
> **Depends on:** `DecisionAxis`, `FinancialReasoningContext`, `FinancialFacts`, `FinancialState`, `BehaviorProfile`, `FinancialPolicy`
> **Implemented by:** `RuleBasedFinancialReasoningEngine` (existing), `PolicyAwareReasoningEngine` (new)

---

## Table of Contents

1. [Overview — The Static Weight Ceiling](#1-overview--the-static-weight-ceiling)
2. [Research Findings — CFP Practice and Life Stage Frameworks](#2-research-findings--cfp-practice-and-life-stage-frameworks)
3. [Domain Model](#3-domain-model)
4. [Bounded Context](#4-bounded-context)
5. [Policy Types — Named Profiles](#5-policy-types--named-profiles)
6. [Axis Weights Per Policy — Concrete Tables](#6-axis-weights-per-policy--concrete-tables)
7. [Policy Evolution Rules](#7-policy-evolution-rules)
8. [Integration with FinancialReasoningContext](#8-integration-with-financialreasoningcontext)
9. [Invariants](#9-invariants)
10. [Migration from v1](#10-migration-from-v1)
11. [Testing Strategy](#11-testing-strategy)

---

## 1. Overview — The Static Weight Ceiling

### The Problem

The current `RuleBasedFinancialReasoningEngine` applies a single universal weight vector to all users across all life stages:

```
cashFlow        = 0.30
liquidity       = 0.25
goalImpact      = 0.20
behavior        = 0.10
taxes           = 0.05
opportunityCost = 0.10
```

This produces the same decision confidence geometry for a 22-year-old student with no income as for a 48-year-old pre-retiree with a 40% savings rate. The weights are not wrong for one average user — they are wrong for nearly every real user because no one is the average.

### Why Static Weights Are the Ceiling

**A student with zero income but growing financial awareness** should have their `goalImpact` and `behavior` axes weighted much more heavily than their `taxes` axis. They have no taxable income. Ranking `taxes` at 0.05 is already too generous — a student's tax exposure is nearly zero, so scoring this axis and folding it into confidence degrades signal quality.

**A freelancer with irregular income** needs `cashFlow` to carry enormous diagnostic weight because income volatility is the root cause of almost every financial decision they face. A month where they earned ₹2,40,000 versus a month where they earned ₹40,000 should produce dramatically different recommendations. The current 0.30 weight is not wrong — it just applies the same urgency whether the user has a government salary with NACH mandates or a consultant who invoices quarterly.

**A pre-retiree aged 55** has a different problem set entirely: their `liquidity` axis matters for building a 12-month retirement buffer (not a 6-month emergency fund), their `taxes` axis needs to score the efficiency of NPS/PPF/Section 80C/10(10D) payouts in the accumulation phase, and their `opportunityCost` axis must penalize equity-heavy allocations because they have an 8-year horizon rather than a 25-year one.

**A retiree** has no `opportunityCost` in the conventional growth sense — they are in the distribution phase. Penalizing a retiree for not having 10% of income in growth assets is actively harmful advice. The standard `opportunityCost` weight of 0.10 produces misleading confidence scores that could drive bad recommendations.

### What the Policy Engine Unlocks

Replacing `DecisionAxis.weight` — a compile-time constant baked into an enum — with a `DecisionPolicy` selected at runtime per user context enables:

1. **Accurate confidence scoring** for each user archetype
2. **Policy evolution** — the system upgrades a user's policy automatically as their financial maturity improves (Survive → Stabilize → Build → Optimize)
3. **Explainability** — "We are weighting liquidity heavily because you are in the Survive state" is now a traceable, auditable reason
4. **Behavioral adaptation** — the policy can be temporarily shifted by a behavioral state (e.g., an Impulse Window should increase the `behavior` axis weight to detect impulsive decision patterns before recommending anything)
5. **Foundation for Bayesian learning** — once the Decision Learning Engine accumulates enough outcome history, individual axis weights can be fine-tuned per user based on which axes actually predicted correct outcomes for that user

---

## 2. Research Findings — CFP Practice and Life Stage Frameworks

### 2.1 How CFPs Prioritize Decisions by User Type

Certified Financial Planners in India and globally use a structured prioritization hierarchy that varies by life stage, income stability, and family obligation. The following is synthesized from CFP curriculum frameworks (CFP Board, FPSB India), behavioral finance research, and Indian regulatory guidance (SEBI, RBI, AMFI).

#### The CFP Priority Hierarchy (Universal Foundation)

Every CFP applies the same foundation regardless of user type. These are not optional — they are prerequisite gates that must be met before any investment advice can be considered fiduciary:

1. **Income protection first** — term life insurance before any investment (especially for people with dependents)
2. **Emergency fund before SIP** — liquid savings equal to 3–6 months of expenses before any market instrument
3. **High-interest debt elimination before investment** — no investment recommendation is valid when the user is paying 36–42% annual interest on a credit card
4. **Tax efficiency before optimization** — ensure all mandated contributions (EPF, PPF) are in place before discussing alternatives
5. **Goal-linked investing** — every investment recommendation must connect to a named goal with a timeline

The key insight: **the sequence of these priorities changes dramatically by user type, but the set of priorities itself does not**. A student needs priority 2 (emergency fund) urgently but priority 4 (EPF) is irrelevant because they have no employer. A retiree has already met priority 2 but now must manage the reverse — distribution rather than accumulation.

#### Student / Young Professional (age 18–26, no dependents)

CFP practice for this cohort is dominated by three concerns:

- **Habit formation over optimization** — a student investing ₹500/month in a SIP at age 20 is more valuable to their financial future than the same amount invested at 40, even controlling for returns. The behavioral axis (consistency, discipline, impulse control) matters more than tax efficiency.
- **Emergency fund is the first and only goal** until it reaches 3 months of expenses
- **Tax optimization is minimal** — students typically fall in the 0–5% tax slab. Section 80C is relevant only once income exceeds ₹5L. The taxes axis is low priority.
- **Opportunity cost is meaningful** because compounding time is extremely long, but it must be framed as "start small, stay consistent" not "maximize allocation to equity"

Key CFP insight for students: **the behavior axis and the goal impact axis should dominate**. A recommendation that scores well on cash flow but the student has never followed through on a savings commitment is a bad recommendation.

#### Salaried Employee (age 25–45, stable income, may have dependents)

This is the largest cohort and closest to the current v1 universal weights. Key CFP principles:

- **Cash flow and liquidity are the core diagnostic axes** — monthly surplus and emergency fund coverage determine what is affordable
- **EMI-to-income ratio** is the primary debt quality signal (safe: <40%, risky: >50%)
- **Tax efficiency becomes materially important** once income crosses ₹10L per year — Section 80C, HRA, NPS 80CCD(1B) can save ₹50,000–₹1,50,000 per year in taxes
- **Goal impact rises with family obligations** — home purchase, children's education, spouse's career transitions create hard deadlines that must be funded
- **Opportunity cost** tracks whether the surplus is being deployed or sitting idle in a savings account

The salaried employee profile is closest to the current v1 weights but should emphasize `taxes` more aggressively than the current 0.05 once income crosses ₹10L.

#### Freelancer / Independent Contractor (income volatility)

This cohort has a fundamentally different problem structure. CFP practice for freelancers:

- **Income volatility is the meta-problem** — every other financial decision is contingent on resolving irregular income. `cashFlow` must carry the heaviest weight.
- **Emergency fund target is 9–12 months** (vs 6 months for salaried) because there is no employer during gaps. `liquidity` target is structurally higher.
- **Debt recommendations are particularly dangerous** — a freelancer with an EMI commitment has no guarantee of meeting it in a bad quarter. Conservative CFPs advise no EMIs until 12-month income history is established.
- **Tax obligations are quarterly** (advance tax installments in India: June 15, September 15, December 15, March 15). Failure to pay advance tax incurs 1% per month interest under Section 234B/234C. A recommendation that does not account for a ₹50,000 advance tax payment in September is actively harmful.
- **Behavioral patterns are highly diagnostic** — freelancer income patterns (feast/famine cycles, invoice delays, project gaps) require a high behavior axis weight to detect whether the user is in a flush period or a dry period

Key CFP insight for freelancers: **`cashFlow` should dominate all other axes**. Everything else depends on whether this month's income is normal, elevated, or a gap.

#### Business Owner / Entrepreneur

- **Liquidity is existential** — business cash flow crises can require personal funds. The personal emergency fund must be separate from business working capital.
- **Debt quality requires business-personal separation** — a business loan is not the same as a personal EMI but often appears in the same SMS parse. The debt axis needs special handling.
- **Tax optimization is material** — self-employed professionals with GST registration, presumptive taxation (Section 44ADA/44AD), and business expense deductions have complex tax planning needs. The taxes axis weight should be higher than for salaried employees.
- **Opportunity cost of retained earnings** — money left in a current account earns nothing. The opportunity cost axis needs to capture business cash sitting idle versus deployed in liquid instruments.

#### Retiree (age 60+, distribution phase)

The retiree profile is the most distinct departure from v1 weights:

- **Income replacement is the primary axis** — the cash flow axis must score against a retirement income replacement rate (typically 70–80% of pre-retirement income), not against savings rate or surplus rate
- **Capital preservation dominates** — liquidity and resilience take priority over growth. The emergency fund target shifts from "6 months of expenses" to "24 months of guaranteed withdrawal" plus medical reserve
- **Opportunity cost is inverted** — for a retiree, deploying capital into high-growth equity is a risk, not an opportunity. The opportunity cost axis must score against withdrawal sustainability, not growth maximization
- **Tax efficiency in distribution phase** — NPS annuity, SCSS, PMVVY, Senior Citizen FDs, and the standard deduction for senior citizens (₹75,000) are now the relevant tax instruments. Section 80C deductions decrease in importance as income shifts to pension/annuity
- **Behavioral pattern relevance changes** — impulse spending patterns that were a minor concern during accumulation become an existential risk during distribution. The behavior axis should score spending consistency, not just saving consistency.
- **Goal impact** for a retiree is about distribution goals (travel, healthcare, grandchildren's education). The goal horizon is typically 1–7 years, not 15–30. Short-horizon goals must be funded conservatively.

CFP consensus: **No equity recommendation for capital allocated to needs within 3 years. No recommendation increases portfolio risk for a retiree unless resilience score is already > 75.**

### 2.2 Life Stage Frameworks

#### The SMRT Protocol (already in PennyWise domain)

PennyWise already encodes a 4-state financial maturity model in `FinancialState`:

| State | Meaning | Primary Priority |
|---|---|---|
| Survive | No emergency fund or insurance | Build emergency fund + term insurance |
| Stabilize | High-interest debt present | Debt avalanche before any investment |
| Build | Foundation in place | Systematic investment compounding |
| Optimize | Built wealth base | Tax efficiency, asset location, estate |

This is the primary state that should drive policy selection. The SMRT states cut across user types — a salaried employee can be in Survive, and a freelancer can be in Optimize.

#### The Lifecycle Stage Overlay

The financial state captures *maturity* but not *horizon and obligation*. A second dimension — lifecycle stage — is needed:

| Stage | Age Range | Key Obligation Change |
|---|---|---|
| Foundation | 18–30 | Habit building, early compounding, student debt |
| Growth | 30–45 | Family formation, home, EMIs, children's education |
| Peak | 45–55 | Maximizing accumulation, tax efficiency plateau |
| Pre-Retirement | 55–60 | De-risking, NPS maturity, liquidity building |
| Retirement | 60+ | Distribution phase, capital preservation |

#### Indian Financial Behavior Context

The Indian financial context introduces three additional priority modifiers that CFPs routinely apply:

1. **Festival effect** — significant spending spikes in October–November (Dussehra, Diwali) and March (financial year end). A recommendation made in September should account for an upcoming consumption spike.
2. **Gold as safe asset** — a significant segment of Indian households treats physical gold as emergency savings. This affects effective liquidity calculation.
3. **Family financial obligations** — multigenerational financial support (elderly parents, extended family) is not discretionary for many users. This compresses the effective savings rate below what the transaction history suggests.

These modifiers are already partially captured in `IndianBehaviorContext` and should feed into policy selection.

### 2.3 Emergency Fund vs Investment vs Debt — Industry Consensus

The following hierarchy is near-universal consensus across CFP practice (India), Ramsey Solutions, and behavioral economics research (Thaler, Benartzi):

```
Priority Order (do not invert):
1. Minimum emergency fund (1 month)        — before ANY investment
2. High-interest debt elimination (>18%)   — before ANY investment
3. Full emergency fund (3–6 months)        — before EQUITY investment
4. Medium-interest debt (12–18%)           — before SIP
5. Tax-advantaged investing (80C, EPF)     — as income allows
6. Systematic investment (SIP)             — core of Build phase
7. Low-interest debt (home loan <9%)       — do not overpay, invest instead
8. Advanced optimization (tax harvesting)  — Optimize phase only
```

The key insight for the policy engine: the `liquidity` and `behavior` axes must score **blocking conditions** at steps 1–4 — a low score must prevent the decision confidence from reaching a threshold that would produce an investment recommendation.

### 2.4 How Financial Maturity Should Drive Policy Evolution

Financial literature (Stages of Financial Independence, Ramsey Baby Steps, SMRT) agrees on a pattern of graduated threshold crossings that unlock the next-stage policy:

- A user in Survive state who builds 1 month of emergency fund should see the policy **shift to acknowledge partial progress** without moving to Stabilize
- A user who crosses the full 6-month emergency fund threshold and has no debt above 18% should **automatically transition** from Survive/Stabilize to Build — this is a meaningful behavioral shift and the engine should recognize it
- A user who has been in Build for 12+ months and has achieved 80%+ of Section 80C capacity, a health score > 70, and savings rate > 25% should be **promoted to Optimize** policy

### 2.5 Explicit vs Inferred Policies

Should policies be user-selected or system-inferred?

**CFP consensus**: initial policy is system-inferred from objective facts (income, age, employment type, debt, emergency fund). User overrides are allowed but must be constrained — a user cannot elect to skip emergency fund requirements.

**PennyWise recommendation**: Policies are **primarily system-inferred** from `FinancialFacts`, `FinancialState`, and the lifecycle stage derived from `FinancialFacts.ageYears`. A user can provide a **profile hint** (employment type: student/salaried/freelancer/business/retired) that influences policy selection but does not override protective invariants like the liquidity floor.

The policy must never allow a user to self-select away from protective rules. A user who identifies as "freelancer" and explicitly disables the cash flow penalty for irregular income is receiving worse advice, not better.

---

## 3. Domain Model

All classes below live in the **domain layer** (`mobile/lib/domain/reasoning/policy/`). They are pure Dart — no Flutter, no get_it, no HTTP, no JSON. They are `@immutable` value objects.

---

### 3.1 `DecisionPolicy`

The primary output of the Policy Engine. Carries the axis weight profile for a specific user context plus the metadata explaining why this policy was selected.

```
DecisionPolicy
  id:                   PolicyId        — unique identifier (e.g. "freelancer_survive_v1")
  name:                 String          — human-readable name ("Freelancer — Survive")
  archetype:            UserArchetype   — employment type (student/salaried/freelancer/business/retired)
  financialState:       FinancialState  — SMRT state (survive/stabilize/build/optimize)
  lifecycleStage:       LifecycleStage  — age band (foundation/growth/peak/preRetirement/retirement)
  weights:              AxisWeightProfile
  thresholds:           PolicyThresholds  — numerical boundaries for axis health checks
  evolutionRules:       List<PolicyEvolutionRule>
  selectionReason:      String          — explainability ("Selected because: irregular income detected, FinancialState.survive")
  schemaVersion:        String          — for forward compatibility
  effectiveAt:          DateTime        — when this policy became active for this user
```

**Invariants:**
- `weights.sum` must equal 1.0 (±0.001 floating point tolerance)
- `archetype` + `financialState` must form a valid combination (not all combinations are legal — see Section 9)
- `schemaVersion` must match a known policy schema version
- `evolutionRules` list must not be empty — every policy must define a way to advance

---

### 3.2 `AxisWeightProfile`

Replaces the static `DecisionAxis.weight` getter. Carries per-axis weights for the 6 decision axes (the 2 external multipliers — `dataConfidence` and `historicalAccuracy` — are never assigned policy weights; they remain structural multipliers outside the weighted pool).

```
AxisWeightProfile
  cashFlow:         double    — 0.0–1.0
  liquidity:        double    — 0.0–1.0
  goalImpact:       double    — 0.0–1.0
  behavior:         double    — 0.0–1.0
  taxes:            double    — 0.0–1.0
  opportunityCost:  double    — 0.0–1.0
```

**Invariants:**
- All six weights must be ≥ 0.0 and ≤ 1.0
- `cashFlow + liquidity + goalImpact + behavior + taxes + opportunityCost` must equal 1.0 (±0.001)
- No single axis may have weight > 0.55 (prevents degenerate single-axis collapse)
- No single axis may have weight < 0.02 (prevents an axis from being effectively silenced — all axes provide signal; zero weight removes explainability)

The 0.02 minimum floor is a fiduciary safeguard: even a retiree who has no opportunity cost concern still has *some* stake in it (e.g., keeping cash in a savings account earning 3.5% instead of an FD at 7.5%). Silencing the axis entirely produces worse, less explainable outputs.

**Named constructor for validation:**

```
AxisWeightProfile.validated({
  required double cashFlow,
  required double liquidity,
  required double goalImpact,
  required double behavior,
  required double taxes,
  required double opportunityCost,
}) — throws PolicyWeightViolation if invariants fail
```

---

### 3.3 `PolicyThresholds`

Numerical parameters that accompany the weights. Different policies use different threshold values for the same facts — a freelancer's "acceptable" emergency fund is 9 months, not 6.

```
PolicyThresholds
  emergencyFundTargetMonths:    double    — minimum EF coverage that scores 1.0 on liquidity axis
  minSavingsRate:               double    — savings rate below which cash flow axis is penalized
  safeDebtRatio:                double    — EMI/income ratio above which debt penalty activates
  criticalDebtRatio:            double    — above this, liquidity axis signals blocking condition
  taxEfficiencyTarget:          double    — 80C utilization rate that scores 1.0 on tax axis
  minOpportunityCostRate:       double    — minimum investment ratio to avoid opportunity cost penalty
  behaviorMinimumConsistency:   double    — consistency score below which behavior axis signals warning
```

These thresholds override the hardcoded values in the axis analyzers (e.g., `LiquidityAxisAnalyzer._efScore()` currently hardcodes 6 months as the perfect score target). With the policy engine, the threshold comes from `PolicyThresholds.emergencyFundTargetMonths`.

---

### 3.4 `UserArchetype`

The employment/life-stage classification that is the primary input to `PolicySelector`.

```
enum UserArchetype {
  student,           // No or minimal income, in education
  youngProfessional, // Working, single, no dependents, age 22–28
  salariedWithFamily, // Salaried, dependents (spouse/children/parents)
  freelancer,        // Self-employed, irregular income
  businessOwner,     // Has a registered business, personal-business finance complexity
  preRetiree,        // 5–10 years from planned retirement
  retiree,           // Distribution phase, 60+ or retired early
}
```

**How archetype is determined:** Primarily from the user profile (employment type field set during onboarding). Partially inferred from `FinancialFacts` when profile data is missing — e.g., if `ageYears > 60` and income is labeled as pension/interest income in SMS parses, the system can infer `retiree`.

---

### 3.5 `LifecycleStage`

Age-band overlay that modifies but does not override the archetype-based policy.

```
enum LifecycleStage {
  foundation,     // 18–30: habit building, early compounding
  growth,         // 30–45: family formation, peak obligations
  peak,           // 45–55: maximum accumulation capacity
  preRetirement,  // 55–60: de-risking, liquidity building
  retirement,     // 60+: distribution phase
}
```

**Derivation from age:**
```
LifecycleStage fromAge(int age) {
  if (age < 30) return foundation;
  if (age < 45) return growth;
  if (age < 55) return peak;
  if (age < 60) return preRetirement;
  return retirement;
}
```

---

### 3.6 `PolicySelector`

The domain service that produces a `DecisionPolicy` from a `FinancialReasoningContext`. Pure function — no side effects, no persistence.

```
PolicySelector
  select(FinancialReasoningContext ctx, UserArchetype archetype) → DecisionPolicy
```

**Selection logic (ordered precedence):**

1. If `LifecycleStage == retirement` → always return `RetiredPolicy` regardless of archetype
2. If `LifecycleStage == preRetirement` → return `PreRetirementPolicy` modified by archetype
3. If `archetype == freelancer` → return `FreelancerPolicy` scaled by `FinancialState`
4. If `archetype == businessOwner` → return `BusinessOwnerPolicy` scaled by `FinancialState`
5. If `archetype == student` → return `StudentPolicy`
6. Default → return `SalariedPolicy` scaled by `FinancialState`

Each named policy is a preconfigured `DecisionPolicy` factory. "Scaled by FinancialState" means:
- Survive: increase liquidity and cash flow weights, decrease tax and opportunity cost
- Stabilize: increase cash flow, moderate liquidity
- Build: balanced weights (this is the "default" configuration)
- Optimize: increase taxes and opportunity cost

---

### 3.7 `PolicyEvolutionRule`

Defines when and how the policy engine should automatically advance a user to a better policy.

```
PolicyEvolutionRule
  triggerId:        String              — unique identifier for this rule
  description:      String              — human-readable trigger description
  fromPolicy:       PolicyId            — the policy this rule applies to
  toPolicy:         PolicyId            — the policy to graduate to
  conditions:       List<PolicyCondition>  — all must be true to trigger
  evaluationMode:   EvolutionEvalMode   — AllConditions | AnyCondition
  graduationLabel:  String              — user-facing message ("You've moved from Survive to Build!")
```

```
PolicyCondition
  factKey:    String    — which FinancialFact to check (e.g. "emergencyFundMonths")
  operator:   ConditionOp — GreaterThan | LessThan | Equals | GreaterThanOrEqual
  threshold:  double    — the numerical threshold
  sustained:  Duration? — optional: must be true for this long before triggering
```

---

### 3.8 `PolicyStateRecord`

Persisted record of the current active policy and evolution history for a user. Written by the infrastructure layer, read by the policy selector.

```
PolicyStateRecord
  userId:             UserId
  activePolicyId:     PolicyId
  activatedAt:        DateTime
  previousPolicyId:   PolicyId?
  graduatedAt:        DateTime?
  graduationReason:   String?
  overrideActive:     bool            — true if user has manually overridden the inferred policy
  overrideReason:     String?
```

---

### 3.9 Class Relationship Diagram

```
FinancialReasoningContext
        │
        ▼
   PolicySelector ──────────────────────────────┐
        │                                        │
        │ reads                                  │ reads
        ▼                                        ▼
  FinancialFacts                          PolicyStateRecord
  FinancialState                          (persisted via
  LifecycleStage                           PolicyRepository)
  UserArchetype
        │
        ▼
  DecisionPolicy
    ├── AxisWeightProfile    (replaces DecisionAxis.weight)
    ├── PolicyThresholds     (replaces hardcoded analyzer constants)
    └── List<PolicyEvolutionRule>
        │
        ▼
PolicyAwareReasoningEngine
  (feeds weights to axis analyzers at runtime)
        │
        ▼
DecisionConfidenceReport
  + policyId: String         (new field — which policy was active)
  + policyLabel: String      (new field — "Freelancer — Survive Phase")
```

---

## 4. Bounded Context

### Where Policy Lives

The `DecisionPolicy` domain model and all related types (`AxisWeightProfile`, `PolicyThresholds`, `PolicyEvolutionRule`, `PolicySelector`) live in the **Decision bounded context**, specifically in:

```
mobile/lib/domain/reasoning/policy/
  decision_policy.dart
  axis_weight_profile.dart
  policy_thresholds.dart
  policy_evolution_rule.dart
  policy_selector.dart
  user_archetype.dart
  lifecycle_stage.dart
```

This is correct DDD placement because:
- Policy is a *value object* relative to the Decision aggregate — it is a fact about how decisions should be weighted
- Policy has no identity of its own independent of a user + context pair
- Policy affects only the Decision bounded context (how axes are weighted when computing decision confidence)

### What Reads Policy

| Consumer | Purpose | Read Mechanism |
|---|---|---|
| `PolicyAwareReasoningEngine` | Applies weights to axis analyzers | Direct field access on `DecisionPolicy.weights` |
| `DecisionConfidenceReport` | Records which policy was active | `policyId` + `policyLabel` fields on report |
| `ExplainabilityEngine` | Builds "why this confidence" explanation | Policy selection reason from `DecisionPolicy.selectionReason` |
| Dashboard screen | Shows policy label in explanation panel | Via `DecisionConfidenceReport.policyLabel` |

### What Writes Policy

| Writer | Mechanism | Location |
|---|---|---|
| `PolicySelector` | Creates `DecisionPolicy` at reasoning time | Domain layer — pure function |
| `PolicyEvolutionEngine` | Upgrades `PolicyStateRecord` when conditions met | Application layer use case |
| User profile update | Can set `UserArchetype` hint | Application layer — `UpdateUserProfileUseCase` |

### What Must NOT Touch Policy

- **Widgets** — must never instantiate `PolicySelector` or read `AxisWeightProfile` directly
- **Repositories** — partner repository, hardcoded repositories — policy is not a partner concern
- **Infrastructure SMS/AA parsers** — ingestion layer must not consult policy; it only produces facts
- **Backend** — the policy engine is Flutter-side. The Spring Boot backend has its own `FinancialPolicy` (constants only). The two are separate concerns. Flutter policy = axis weight profiles; Spring policy = financial constants (EMI limits, SIP rates, 80C limit).

---

## 5. Policy Types — Named Profiles

Seven named policies cover the primary user archetypes. Each policy is a configuration of `AxisWeightProfile` + `PolicyThresholds` + `PolicyEvolutionRule[]`.

---

### 5.1 `StudentPolicy`

**Archetype:** Student, age 18–26, no income or stipend-level income, no dependents, no debt (or student loan only)

**Primary concern:** Building financial habits before wealth is available. Every behavior signal is more predictive of long-term outcomes than any single financial metric.

**What matters most:**
- Behavior — will they actually follow through on even a ₹500/month SIP? This is more valuable than optimizing the SIP rate.
- Goal impact — a student's "goal" is often the emergency fund itself. Progress toward that single goal is the key signal.
- Cash flow — what limited surplus exists must be tracked carefully. Even small surpluses compound meaningfully over time.

**What matters least:**
- Taxes — a student earning ₹2–4L/year pays zero or minimal tax. Tax efficiency advice is premature and distracting.
- Opportunity cost — a student cannot yet take meaningful opportunity cost risk. Advising on investment allocation before an emergency fund exists is contrary to CFP principles.

**FPSB India guidance:** Foundation stage clients should not receive investment recommendations that involve capital at risk until a 3-month emergency fund is established. Behavior and habit scores should be the dominant signal in recommendations to this cohort.

---

### 5.2 `SalariedPolicy` (four sub-policies by FinancialState)

**Archetype:** Salaried employee, stable monthly income, any dependent status, age 25–50

**Primary concern:** Optimizing the deployment of a reliable monthly surplus.

Four sub-policies based on FinancialState:

**SalariedSurvivePolicy:** Emergency fund building phase. Liquidity and cash flow dominate. Tax and opportunity cost are minimal until foundation is set.

**SalariedStabilizePolicy:** Debt elimination phase. Cash flow is the top priority — does the surplus support the debt avalanche? Goal impact is elevated because goals give debt elimination meaning.

**SalariedBuildPolicy:** The default steady-state for a salaried professional. Balanced weights with a modest tax boost above the universal v1 default once income crosses ₹10L.

**SalariedOptimizePolicy:** Tax efficiency, asset location, and rebalancing. Opportunity cost and taxes are elevated. Cash flow and liquidity are secondary (assumed to be well-managed by this stage).

---

### 5.3 `FreelancerPolicy` (four sub-policies by FinancialState)

**Archetype:** Self-employed, irregular income, any age

**Primary concern:** Income volatility means every recommendation must be conditioned on "is this month a good month?"

**FreelancerSurvivePolicy:** The most conservative configuration. Cash flow is extremely heavily weighted — without knowing whether this month is typical, all other axes are secondary. Liquidity target is elevated to 9 months.

**FreelancerStabilizePolicy:** Debt is particularly dangerous for freelancers. Cash flow stays heavily weighted. Behavior axis rises to detect income irregularity patterns.

**FreelancerBuildPolicy:** A freelancer who has reached Build has achieved the hardest thing — consistent income over 12+ months. The weights moderate toward salaried-build, but cash flow and behavior remain elevated.

**FreelancerOptimizePolicy:** Advance tax efficiency is added to the standard optimize mix. Freelancers in optimize stage have complex quarterly tax obligations.

---

### 5.4 `BusinessOwnerPolicy`

**Archetype:** Has a registered business, complex personal-business finance interface, any age 28–60

**Primary concern:** Personal-business finance separation. The business's cash flow cycles must not distort personal financial recommendations.

This is the most complex archetype. Key characteristics:
- The debt axis needs special treatment — business loans vs personal loans have different scoring
- Tax efficiency is materially higher than for salaried (GST, presumptive taxation, business expense deductions, dividends)
- Opportunity cost of idle business/personal cash is elevated
- Liquidity target must include a business disruption reserve (3 months of personal + 3 months of business fixed costs)

Business owners in the Build and Optimize states should see taxes and opportunity cost carry the highest combined weight of any archetype.

---

### 5.5 `PreRetirementPolicy`

**Archetype:** Age 55–60, or within 5 years of planned retirement date, any employment type

**Primary concern:** Transitioning from accumulation to preservation. De-risking the portfolio while maintaining compounding for remaining years.

Key characteristics:
- Liquidity target rises to 12 months
- Opportunity cost reframed: no new equity exposure for capital needed within 5 years
- Tax efficiency: NPS, PPF maturity planning, SCSS enrollment
- Goal impact: retirement corpus target becomes the dominant goal; must be funded adequately
- Behavior: spending discipline becomes more important (reduced income approaching)

---

### 5.6 `RetiredPolicy`

**Archetype:** Age 60+, or in explicit retirement/distribution phase

**Primary concern:** Capital preservation and sustainable withdrawal. No growth-at-risk recommendations.

Key characteristics:
- The `opportunityCost` axis is reinterpreted: scores withdrawal sustainability, not growth maximization
- Liquidity target: 24 months of expenses in immediately accessible instruments
- Cash flow axis: scores income replacement rate vs pre-retirement benchmark
- Behavior axis: scores spending consistency in distribution (overspending is the failure mode, not undersaving)
- Taxes: Section 80TTB (interest deduction), standard deduction, SCSS efficiency

**Critical invariant:** The `RetiredPolicy` must block any recommendation that would increase portfolio volatility or reduce the 24-month liquidity buffer. These blocks are encoded as `PolicyThresholds.criticalDebtRatio` and a new `maxEquityAllocationForHorizon` threshold.

---

### 5.7 `FamilyObligationOverlay`

This is not a standalone policy but a modifier applied on top of any base policy when the user has significant family financial obligations (elderly parents, children's education funding, extended family support).

The overlay increases `goalImpact` weight by +0.05 and decreases `opportunityCost` by -0.05 (reducing the signal weight for growth maximization in favor of goal funding certainty).

This is implemented as a `PolicyModifier` type applied post-selection:

```
PolicyModifier
  id:           ModifierId
  name:         String
  weightDeltas: Map<DecisionAxis, double>   — axis weight changes (positive or negative)
  thresholdOverrides: Map<String, double>   — threshold changes
  condition:    String                      — human-readable condition that triggered this
```

---

## 6. Axis Weights Per Policy — Concrete Tables

The following tables specify exact `AxisWeightProfile` values for each policy. All rows sum to 1.0.

Column abbreviations: CF = cashFlow, LQ = liquidity, GI = goalImpact, BH = behavior, TX = taxes, OC = opportunityCost

### 6.1 Student Policy

| Policy | CF | LQ | GI | BH | TX | OC |
|---|---|---|---|---|---|---|
| StudentPolicy | 0.20 | 0.25 | 0.30 | 0.20 | 0.02 | 0.03 |

Rationale:
- `goalImpact` is highest (0.30): emergency fund is the student's single goal; progress toward it is the most diagnostic signal
- `liquidity` (0.25): even at minimal income, building 3 months of reserves is the prerequisite gate
- `behavior` (0.20): habit formation at this stage has highest lifetime ROI; behavioral consistency is the leading indicator of long-term financial health
- `cashFlow` (0.20): limited surplus must be tracked; spending patterns matter
- `taxes` (0.02): near zero — at the absolute floor
- `opportunityCost` (0.03): minimal — investment optimization is premature without foundation

### 6.2 Salaried Policies by FinancialState

| Policy | CF | LQ | GI | BH | TX | OC |
|---|---|---|---|---|---|---|
| SalariedSurvive | 0.30 | 0.35 | 0.15 | 0.12 | 0.03 | 0.05 |
| SalariedStabilize | 0.35 | 0.25 | 0.18 | 0.12 | 0.04 | 0.06 |
| SalariedBuild | 0.28 | 0.22 | 0.20 | 0.12 | 0.08 | 0.10 |
| SalariedOptimize | 0.20 | 0.15 | 0.18 | 0.10 | 0.17 | 0.20 |

Rationale for SalariedBuild:
- Near-identical to v1 universal weights but taxes elevated from 0.05 → 0.08 (reflects income >₹10L where 80C matters materially)
- This is intentional: v1 weights were calibrated to a salaried/build archetype by instinct; the policy engine makes that explicit

Rationale for SalariedOptimize:
- Taxes and opportunity cost together reach 0.37 — this user is past foundational concerns
- Goal impact remains meaningful (goals shift from emergency fund to financial independence)
- Liquidity drops to 0.15 — a salaried optimize user has the EF handled

### 6.3 Freelancer Policies by FinancialState

| Policy | CF | LQ | GI | BH | TX | OC |
|---|---|---|---|---|---|---|
| FreelancerSurvive | 0.42 | 0.30 | 0.12 | 0.10 | 0.03 | 0.03 |
| FreelancerStabilize | 0.38 | 0.28 | 0.12 | 0.12 | 0.04 | 0.06 |
| FreelancerBuild | 0.33 | 0.25 | 0.16 | 0.15 | 0.06 | 0.05 |
| FreelancerOptimize | 0.25 | 0.20 | 0.15 | 0.13 | 0.15 | 0.12 |

Rationale for FreelancerSurvive:
- `cashFlow` at 0.42 is the highest of any policy configuration. This reflects the CFP principle that income volatility is the meta-problem; without resolving it, no other axis can produce reliable scores.
- `liquidity` at 0.30 reflects the 9-month EF target (vs 6 months for salaried)
- `taxes` and `opportunityCost` at 0.03 each — deliberate floor — a freelancer in Survive should not be receiving tax optimization or investment recommendations

### 6.4 Business Owner Policies

| Policy | CF | LQ | GI | BH | TX | OC |
|---|---|---|---|---|---|---|
| BusinessOwnerSurvive | 0.35 | 0.30 | 0.12 | 0.10 | 0.05 | 0.08 |
| BusinessOwnerBuild | 0.25 | 0.20 | 0.17 | 0.12 | 0.13 | 0.13 |
| BusinessOwnerOptimize | 0.18 | 0.15 | 0.15 | 0.10 | 0.22 | 0.20 |

Business owners have the most materially elevated tax weights in optimize phase — correctly reflecting the complexity of GST, presumptive taxation, and business structure decisions.

### 6.5 Pre-Retirement Policy

| Policy | CF | LQ | GI | BH | TX | OC |
|---|---|---|---|---|---|---|
| PreRetirement | 0.20 | 0.28 | 0.22 | 0.10 | 0.12 | 0.08 |

Rationale:
- `liquidity` rises to 0.28: building the 12-month retirement buffer is the primary accumulation goal
- `goalImpact` rises to 0.22: retirement corpus target is the dominant goal — it must be scored highly
- `taxes` at 0.12: NPS, PPF maturity, SCSS enrollment — tax efficiency in the de-risking phase matters
- `opportunityCost` drops to 0.08: no new equity exposure recommended for near-term capital; opportunity cost scoring is less relevant

### 6.6 Retired Policy

| Policy | CF | LQ | GI | BH | TX | OC |
|---|---|---|---|---|---|---|
| Retired | 0.25 | 0.32 | 0.18 | 0.13 | 0.08 | 0.04 |

Rationale:
- `liquidity` is the dominant axis (0.32) — maintaining 24 months of accessible withdrawal capacity is the primary safety metric
- `cashFlow` (0.25): income replacement rate scoring; are expenses being covered by pension/annuity/SCSS?
- `goalImpact` (0.18): distribution goals (healthcare, travel, grandchildren) need funding tracking
- `behavior` (0.13): spending discipline in distribution phase — overspending is the retirement failure mode
- `taxes` (0.08): Section 80TTB, SCSS efficiency, standard deduction for senior citizens
- `opportunityCost` (0.04): minimum floor; retirees should have minimal active investment optimization pressure

### 6.7 PolicyThresholds Per Policy

| Policy | EF Target (months) | Min Savings Rate | Safe Debt Ratio | Critical Debt Ratio | Tax Efficiency Target | Min Investment Ratio |
|---|---|---|---|---|---|---|
| Student | 3.0 | 0.05 | 0.20 | 0.35 | 0.30 | 0.02 |
| SalariedSurvive | 6.0 | 0.10 | 0.35 | 0.50 | 0.40 | 0.05 |
| SalariedStabilize | 6.0 | 0.12 | 0.35 | 0.50 | 0.40 | 0.05 |
| SalariedBuild | 6.0 | 0.15 | 0.40 | 0.50 | 0.70 | 0.10 |
| SalariedOptimize | 6.0 | 0.20 | 0.35 | 0.45 | 0.90 | 0.20 |
| FreelancerSurvive | 9.0 | 0.10 | 0.25 | 0.40 | 0.30 | 0.03 |
| FreelancerBuild | 9.0 | 0.15 | 0.30 | 0.45 | 0.60 | 0.08 |
| FreelancerOptimize | 9.0 | 0.20 | 0.30 | 0.45 | 0.85 | 0.15 |
| BusinessOwnerBuild | 9.0 | 0.15 | 0.35 | 0.50 | 0.75 | 0.12 |
| BusinessOwnerOptimize | 9.0 | 0.20 | 0.30 | 0.45 | 0.90 | 0.20 |
| PreRetirement | 12.0 | 0.25 | 0.30 | 0.40 | 0.85 | 0.15 |
| Retired | 24.0 | 0.0 | 0.20 | 0.30 | 0.70 | 0.02 |

Notes:
- Student min savings rate (0.05) is deliberately low — saving ₹1,000/month from a ₹20,000 stipend is already a strong signal
- Retired EF target (24.0) reflects the CFP consensus on retirement liquidity buffer
- Retired min savings rate (0.0) — retirees are not expected to be accumulating; they are distributing

---

## 7. Policy Evolution Rules

Policies must evolve automatically as the user's financial situation improves. Evolution is always forward (Survive → Stabilize → Build → Optimize); there is no automatic downgrade. Downgrade is only triggered manually (e.g., user reports a job loss) or through a significant financial state reversal rule (see Section 7.2).

### 7.1 Forward Evolution Rules

All conditions must be sustained for ≥ 30 days before triggering graduation. This prevents false promotions from a single good month.

---

#### Rule: SalariedSurvive → SalariedStabilize

**Trigger ID:** `salaried_survive_to_stabilize`
**Conditions (ALL required):**
1. `emergencyFundMonths >= 3.0` sustained for 30 days
2. `healthScore >= 45`

**Graduation message:** "You've built a 3-month safety net. Now it's time to tackle any high-interest debt before your next investment."

---

#### Rule: SalariedStabilize → SalariedBuild

**Trigger ID:** `salaried_stabilize_to_build`
**Conditions (ALL required):**
1. `emergencyFundMonths >= 6.0` sustained for 30 days
2. `debtRatio <= 0.30` sustained for 30 days
3. `savingsRate >= 0.12`

**Graduation message:** "Your foundation is solid — 6-month emergency fund, manageable debt. You're ready for systematic wealth building."

---

#### Rule: SalariedBuild → SalariedOptimize

**Trigger ID:** `salaried_build_to_optimize`
**Conditions (ALL required):**
1. `emergencyFundMonths >= 6.0`
2. `debtRatio <= 0.25`
3. `savingsRate >= 0.22`
4. `taxEfficiency >= 0.75`
5. `healthScore >= 72`

**Graduation message:** "You've achieved consistent wealth building with good tax efficiency. Time to optimize for maximum long-term compounding."

---

#### Rule: FreelancerSurvive → FreelancerStabilize

**Trigger ID:** `freelancer_survive_to_stabilize`
**Conditions (ALL required):**
1. `emergencyFundMonths >= 4.0` sustained for 45 days (higher bar for irregular income)
2. `positiveIncomeMonths >= 6` in the last 12 (income recorded in 6+ of last 12 months)

**Graduation message:** "You've shown consistent income and built a partial safety net. Ready to address any high-cost debt."

---

#### Rule: FreelancerBuild → FreelancerOptimize

**Trigger ID:** `freelancer_build_to_optimize`
**Conditions (ALL required):**
1. `emergencyFundMonths >= 9.0`
2. `debtRatio <= 0.25`
3. `savingsRate >= 0.18`
4. `taxEfficiency >= 0.60` (advance tax compliance)
5. Consistent income for 12+ months (behavioral signal)

**Graduation message:** "Exceptional financial discipline for a freelancer. You're ready for advanced tax optimization and systematic wealth compounding."

---

#### Rule: AnyPolicy → PreRetirement

**Trigger ID:** `any_to_pre_retirement`
**Conditions (ANY of):**
1. `ageYears >= 55`
2. `yearsToRetirement <= 5` (if explicitly set in user profile)

This rule overrides the archetype-specific states — a salaried employee at age 55 transitions to PreRetirementPolicy regardless of their Build/Optimize state.

**Graduation message:** "With retirement in the next 5–10 years, your financial strategy shifts from accumulation to preservation."

---

#### Rule: PreRetirement → Retired

**Trigger ID:** `pre_retirement_to_retired`
**Conditions (ALL required):**
1. `ageYears >= 60` OR `retirementDateReached == true`
2. `liquidityMonths >= 12` (retirement buffer partially built)

**Graduation message:** "Welcome to your retirement phase. Your financial strategy now focuses on sustainable income and capital preservation."

---

### 7.2 Protective Downgrade Rules

These are the only automatic downgrade paths and must fire faster than the forward rules — no 30-day sustain required.

---

#### Rule: Build → Stabilize (emergency fund collapse)

**Trigger ID:** `build_to_stabilize_ef_collapse`
**Condition:** `emergencyFundMonths < 2.0` for 7 consecutive days
**Reason:** A significant financial shock has depleted the emergency fund. Investment recommendations are inappropriate until restored.

**Downgrade message:** "Your emergency fund has dropped below 2 months. Rebuilding it takes priority over investments."

---

#### Rule: Optimize → Build (debt deterioration)

**Trigger ID:** `optimize_to_build_debt_spike`
**Condition:** `debtRatio > 0.50` sustained for 14 days
**Reason:** Debt has risen to a level that compromises the wealth-building thesis.

**Downgrade message:** "Your EMI-to-income ratio has risen significantly. Addressing this takes priority over optimization."

---

### 7.3 Behavioral State Temporary Modifiers

These are not policy changes but temporary weight adjustments that revert automatically. They activate when the `BehaviorProfile.currentState` signals a specific behavioral condition.

| BehaviorState | Weight Adjustment | Duration |
|---|---|---|
| `impulseWindow` | +0.05 to behavior, -0.05 from opportunityCost | Until state exits |
| `highLiquidity` | +0.03 to opportunityCost, -0.03 from liquidity | Until state exits |
| `taxSeason` (Feb–Mar) | +0.07 to taxes, -0.07 from cashFlow | Until April 1 |
| `festiveSeason` (Oct) | +0.04 to cashFlow, -0.04 from opportunityCost | November 1 |

These modifiers are applied as `PolicyModifier` overlays post-selection, not as separate policies.

---

## 8. Integration with FinancialReasoningContext

### 8.1 The Core Change

Currently, `RuleBasedFinancialReasoningEngine` reads axis weights from `DecisionAxis.weight` — a static compile-time constant:

```dart
// CURRENT (v1) — static weight from enum
for (final axis in DecisionAxis.values.where((a) => a.isDecisionAxis)) {
  final result = axes[axis]!;
  final effectiveWeight = axis.weight * result.confidence;  // ← static weight
  ...
}
```

The `PolicyAwareReasoningEngine` reads weights from `DecisionPolicy.weights`:

```dart
// v2 — policy-aware weight
for (final axis in DecisionAxis.values.where((a) => a.isDecisionAxis)) {
  final result = axes[axis]!;
  final policyWeight = ctx.policy.weights.weightFor(axis);  // ← from policy
  final effectiveWeight = policyWeight * result.confidence;
  ...
}
```

### 8.2 `FinancialReasoningContext` Changes

The context needs one new required field and one optional field:

```dart
class FinancialReasoningContext {
  const FinancialReasoningContext({
    required this.facts,
    required this.dataConfidence,
    required this.policy,          // NEW — required in v2
    this.behavior,
    this.learningSnapshot,
    this.goals = const [],
    this.contextLabel,
  });

  // ... existing fields ...

  final DecisionPolicy policy;    // NEW
```

`policy` is required (not nullable) because every reasoning context needs a policy. If no persisted policy exists for a user, `PolicySelector` constructs the appropriate default based on archetype inference from `facts`. There is always a valid policy available — the system never runs without one.

### 8.3 Axis Analyzers — Threshold Injection

Each axis analyzer currently has hardcoded thresholds. These must be made injectable from `PolicyThresholds`:

**`LiquidityAxisAnalyzer`** currently scores `months >= 6.0` as 1.0. Under the policy engine it should score against `policy.thresholds.emergencyFundTargetMonths`. This means a freelancer with 8 months of EF coverage does not score 1.0 — they score against a 9-month target and get approximately 0.85.

The axis analyzers must receive the policy as a parameter:

```dart
class LiquidityAxisAnalyzer {
  const LiquidityAxisAnalyzer();

  DecisionAxisResult analyze(
    FinancialReasoningContext ctx,
    PolicyThresholds thresholds,   // NEW parameter
  ) {
    final target = thresholds.emergencyFundTargetMonths;
    // scoring against target, not hardcoded 6.0
  }
}
```

Alternatively — and more architecturally consistent with the existing design — the `FinancialReasoningContext` carries the policy, and analyzers read it from the context:

```dart
DecisionAxisResult analyze(FinancialReasoningContext ctx) {
  final target = ctx.policy.thresholds.emergencyFundTargetMonths;
  ...
}
```

**Recommended approach:** Read from `ctx.policy.thresholds` inside each analyzer. This keeps the analyzer signatures unchanged (single context parameter) and ensures the policy is always available without requiring DI changes across all 8 analyzers.

### 8.4 `DecisionConfidenceReport` Additions

Two new fields must be added to the report to satisfy the explainability invariant (every axis weight must be traceable):

```dart
class DecisionConfidenceReport {
  // ... existing fields ...
  
  final String policyId;          // NEW — "salaried_build_v1"
  final String policyLabel;       // NEW — "Salaried Professional — Build Phase"
  final String policyReason;      // NEW — why this policy was selected
```

These fields enable:
1. The explanation panel to show "This recommendation was calibrated for a salaried professional in the Build phase"
2. The Digital Twin to record which policy was active at each decision point
3. Future A/B testing of policy configurations against outcome data

### 8.5 `PolicySelector` Construction Flow

The selector must run before the reasoning engine. Recommended call sequence in `GetDashboardFeedUseCase` or `GetTodayDecisionUseCase`:

```
1. Load FinancialFacts (from FinancialFactBuilder)
2. Load BehaviorProfile (from BehaviorRepository — may return uncalibrated default)
3. Load PolicyStateRecord (from PolicyRepository — may be null for new user)
4. PolicySelector.select(facts, behaviorProfile, userArchetype, existingRecord)
   → DecisionPolicy
5. Build FinancialReasoningContext with policy
6. FinancialReasoningEngine.reason(ctx)
   → DecisionConfidenceReport (now includes policyId/policyLabel)
```

The `PolicyRepository` (infrastructure layer) persists `PolicyStateRecord` and is queried at step 3. For new users, it returns null, and the selector builds a fresh policy from available facts.

---

## 9. Invariants

The following invariants must be enforced by the domain model. Violations must throw typed exceptions, not return null or silently fallback.

### 9.1 Weight Invariants

1. **Sum-to-one:** `AxisWeightProfile.sum` must equal 1.0 ± 0.001. Violation: `PolicyWeightSumViolation`
2. **Floor:** No axis weight may be below 0.02. Violation: `PolicyWeightFloorViolation`
3. **Ceiling:** No single axis weight may exceed 0.55. Violation: `PolicyWeightCeilingViolation`
4. **Non-negative:** All weights must be ≥ 0.0. Violation: `PolicyWeightNegativeViolation`

### 9.2 Structural Invariants

5. **External multipliers are never weighted:** `DecisionAxis.dataConfidence` and `DecisionAxis.historicalAccuracy` must never appear in `AxisWeightProfile`. The weight profile covers only the 6 decision axes. Violation: `PolicyExternalAxisWeightViolation`
6. **EvolutionRules are non-empty:** Every policy must declare at least one evolution rule (forward or terminal). Terminal policies (`RetiredPolicy`) declare a `PolicyEvolutionRule.terminal()` sentinel. Violation: `PolicyMissingEvolutionRules`
7. **PolicyId is globally unique:** Policy identifiers must not collide. Enforced by the `PolicySelector` at construction time.

### 9.3 Selection Invariants

8. **Retirement always wins:** If `LifecycleStage == retirement` or `ageYears >= 60`, `RetiredPolicy` is returned regardless of user preference or explicit override. No other policy may be active for this cohort.
9. **PreRetirement overrides state:** A user with `ageYears >= 55` cannot be on `SalariedBuild` or lower policies. `AnyToPreRetirementRule` fires automatically.
10. **Survive protection:** A user with `emergencyFundMonths < 1.0` and `FinancialState != retire` must always be on a Survive-category policy. No optimization, investment, or Build-phase recommendations are produced.

### 9.4 Behavioral Invariants

11. **PolicyModifier deltas sum to zero:** A behavioral state modifier that adds weight to one axis must subtract the same amount from another. The weight pool total must remain 1.0 after modifier application. Violation: `PolicyModifierDeltaViolation`
12. **No commission in policy weights:** Policy weights must never encode commission optimization. There is no axis named "commission" or "revenue". Any modification to weights must be driven by `FinancialFacts`, `FinancialState`, or `BehaviorState` exclusively.

### 9.5 Threshold Invariants

13. **EF target by archetype:** `FreelancerPolicy.thresholds.emergencyFundTargetMonths` must always be ≥ 9.0. `RetiredPolicy.thresholds.emergencyFundTargetMonths` must always be ≥ 24.0. `SalariedPolicy.thresholds.emergencyFundTargetMonths` must always be ≥ 6.0.
14. **Retired max equity:** `RetiredPolicy.thresholds.maxEquityAllocationForHorizon` must be computed as a function of years-to-age-90, not a fixed constant.

---

## 10. Migration from v1

The migration must be zero-breaking: the existing `RuleBasedFinancialReasoningEngine` must continue to work as-is. The policy engine is introduced as an additive layer.

### 10.1 Phase 1 — Add Domain Model, No Engine Changes (Sprint A)

**What ships:**
- All domain types in `mobile/lib/domain/reasoning/policy/`
- `PolicySelector` with all named policy factories
- `PolicyEvolutionEngine` interface (domain layer only)
- Tests verifying weight invariants and selection logic

**What does NOT change:**
- `RuleBasedFinancialReasoningEngine` — zero modification
- `DecisionAxis.weight` static constants — kept as fallback
- `FinancialReasoningContext` — not yet modified
- Any existing widget or use case

**Milestone:** `flutter analyze` passes with zero errors. All policy invariant tests pass.

### 10.2 Phase 2 — Add Policy to Context, Create PolicyAwareEngine (Sprint B)

**What ships:**
- `FinancialReasoningContext` gains optional `policy` field (nullable in v2a, required in v2b)
- `PolicyAwareReasoningEngine` implements `FinancialReasoningEngine` — reads from `ctx.policy.weights` when present, falls back to `DecisionAxis.weight` when `ctx.policy == null`
- `DecisionConfidenceReport` gains `policyId`, `policyLabel`, `policyReason` fields (nullable initially)
- DI: `sl.registerLazySingleton<FinancialReasoningEngine>(() => PolicyAwareReasoningEngine(...))`

**What does NOT change:**
- All existing use cases — they still pass `FinancialReasoningContext` without a policy field and receive correct behavior from the fallback
- All widgets — they now receive a report with optional policy fields; UI degrades gracefully when null

**Milestone:** Existing behavior is bit-for-bit identical for all existing users (policy is null → fallback to static weights). New users get policy-aware scoring. `flutter analyze` passes.

### 10.3 Phase 3 — Make Policy Required, Deprecate Static Weights (Sprint C)

**What ships:**
- `FinancialReasoningContext.policy` becomes required (non-nullable)
- All callers of `FinancialReasoningContext(...)` must now pass a policy
- `PolicySelector` is registered in DI and called from each use case before constructing the context
- `PolicyRepository` (infrastructure layer) persists and loads `PolicyStateRecord`
- `PolicyEvolutionEngine` implementation runs after each `reason()` call and triggers graduation if conditions are met
- `DecisionAxis.weight` getter is deprecated (marked `@Deprecated`) but not yet removed

**What does NOT change:**
- `RuleBasedFinancialReasoningEngine` remains in DI as an alternative (can be selected via feature flag)
- Widget interface is unchanged

**Milestone:** All users are now on a named policy. Policy is visible in the explanation panel. Decision audit includes policyId.

### 10.4 Phase 4 — Remove Static Weights, Full Policy-Driven System (Sprint D)

**What ships:**
- `DecisionAxis.weight` getter is removed
- `DecisionAxis.isDecisionAxis` is retained (structural, not weight-related)
- `RuleBasedFinancialReasoningEngine` is removed from production DI (retained in test utilities)
- Full test coverage for all 12 named policies

This is a breaking change in a strict sense, but because Phase 3 deprecated the static getter and all callers have been migrated in Sprint C, Phase 4 is a mechanical cleanup.

### 10.5 Compatibility Matrix

| Component | Sprint A | Sprint B | Sprint C | Sprint D |
|---|---|---|---|---|
| `DecisionAxis.weight` | unchanged | unchanged | @Deprecated | removed |
| `RuleBasedFinancialReasoningEngine` | unchanged | unchanged | available via flag | removed |
| `PolicyAwareReasoningEngine` | not yet | available | default | only option |
| `FinancialReasoningContext.policy` | not present | optional | required | required |
| Policy in explanation panel | no | partial | yes | yes |
| `flutter analyze` errors | 0 | 0 | 0 | 0 |

---

## 11. Testing Strategy

### 11.1 Unit Tests — Weight Invariants

**File:** `test/domain/reasoning/policy/axis_weight_profile_test.dart`

Test cases:
- `AxisWeightProfile.validated()` throws `PolicyWeightSumViolation` when weights sum to 1.001
- `AxisWeightProfile.validated()` throws `PolicyWeightFloorViolation` when any weight < 0.02
- `AxisWeightProfile.validated()` throws `PolicyWeightCeilingViolation` when any weight > 0.55
- All 12 named policy weight tables sum to exactly 1.0
- `FamilyObligationOverlay` deltas sum to zero
- All behavioral state modifiers maintain post-application sum of 1.0

### 11.2 Unit Tests — Policy Selection

**File:** `test/domain/reasoning/policy/policy_selector_test.dart`

Test cases for each selection invariant:
- `ageYears >= 60` always returns `RetiredPolicy` regardless of archetype
- `ageYears >= 55` returns `PreRetirementPolicy`
- `emergencyFundMonths < 1.0` always returns a Survive-category policy
- `archetype == freelancer + financialState == build` returns `FreelancerBuildPolicy`
- Missing facts (`FinancialFacts.empty`) returns `SalariedSurvivePolicy` as safe default
- `StudentPolicy` selected when archetype is student regardless of FinancialState

### 11.3 Integration Tests — Policy Produces Correct Confidence Geometry

These tests verify that a given user scenario produces the expected confidence report shape after the policy is applied.

**File:** `test/infrastructure/engines/policy_aware_reasoning_engine_test.dart`

**Scenario A: Student with no emergency fund**
```
Input:
  facts.monthlyIncome = ₹0 (no income)
  facts.emergencyFundMonths = 0.0
  archetype = student
  financialState = survive

Expected output:
  goalImpact axis contributes most to decisionConfidenceFactor
  taxes axis score is present but weighted at ~0.02 (minimal effect)
  liquidity axis score is low (0.0 months) and heavily weighted (0.25)
  recommendation strength: low (compound < 0.04 given minimal data)
```

**Scenario B: Salaried Build vs universal v1 comparison**
```
Input:
  facts.monthlyIncome = ₹80,000
  facts.emergencyFundMonths = 6.5
  facts.savingsRate = 0.22
  facts.taxEfficiency = 0.60
  archetype = salaried
  financialState = build

Expected output under SalariedBuildPolicy:
  decisionConfidenceFactor slightly different from v1 universal
  (taxes at 0.08 vs v1 0.05 — reflects material tax consideration)
  liquidity score: 1.0 (6.5 months >= 6.0 target) — same as v1
  Expect: policyLabel = "Salaried Professional — Build Phase"
```

**Scenario C: Freelancer Survive vs Salaried Survive — different confidence outputs from same facts**
```
Input (same facts for both tests):
  facts.monthlyIncome = ₹60,000 (this month)
  facts.emergencyFundMonths = 3.0
  facts.savingsRate = 0.10

Test C1 — FreelancerSurvivePolicy:
  cashFlow weight = 0.42
  liquidity axis scores 3.0/9.0 = 0.33 (against 9-month target)
  Expected: lower decisionConfidenceFactor than C2

Test C2 — SalariedSurvivePolicy:
  cashFlow weight = 0.30
  liquidity axis scores 3.0/6.0 = 0.50 (against 6-month target)
  Expected: higher liquidity contribution than C1

Key verification: same facts → different recommendations due to policy
```

**Scenario D: RetiredPolicy blocks opportunity cost pressure**
```
Input:
  facts.ageYears = 65
  facts.investmentRatio = 0.03 (minimal growth investment — correct for retiree)
  archetype = retiree

Expected output:
  opportunityCost axis weighted at 0.04 (minimum)
  No "underinvested" signal generated (would be harmful advice for retiree)
  liquidity score: requires 24-month buffer scoring
  Expect: policyLabel = "Retired — Distribution Phase"
```

**Scenario E: Behavioral state modifier — impulse window**
```
Input:
  policy = SalariedBuildPolicy
  behavior.currentState = BehaviorState.impulseWindow

Expected output:
  behavior effective weight = 0.12 + 0.05 = 0.17
  opportunityCost effective weight = 0.10 - 0.05 = 0.05
  weight sum still = 1.0
  limitations includes: "Impulse window detected — investment recommendations suppressed"
```

### 11.4 Policy Evolution Tests

**File:** `test/domain/reasoning/policy/policy_evolution_engine_test.dart`

Test cases:
- `SalariedSurviveToStabilize` triggers when `emergencyFundMonths >= 3.0` sustained 30 days
- Rule does NOT trigger at day 29 (must sustain exactly 30 days)
- `FreelancerSurviveToStabilize` requires 45 days sustained (not 30 like salaried)
- `AnyToPreRetirement` fires on `ageYears == 55` regardless of current policy
- `BuildToStabilizeEfCollapse` fires within 7 days, not 30
- Two simultaneous conditions — if `emergencyFundMonths < 2.0` AND `debtRatio > 0.50` both trigger, the more severe rule fires

### 11.5 Golden File Tests

For each of the 12 named policies, maintain a golden file containing the expected `DecisionConfidenceReport` for a canonical input scenario. This prevents silent regression if weights are accidentally modified.

**File pattern:** `test/golden/policies/{policy_id}_canonical_report.json`

Each golden file contains:
- Input `FinancialFacts` snapshot
- Expected `AxisWeightProfile` (from policy)
- Expected `decisionConfidenceFactor` range (±0.02)
- Expected top/bottom contributing axis

Golden files are generated once and committed. CI fails if any policy output deviates from the golden file without an explicit golden update command.

### 11.6 Property-Based Tests

Use `dart_check` (or manual parameterized tests) to verify:
- For any valid `FinancialFacts` input, `PolicySelector.select()` returns a policy whose weights sum to 1.0
- For any two policies A and B where A.financialState is more advanced than B.financialState (same archetype), A's `taxes + opportunityCost` sum is never less than B's
- For `RetiredPolicy`, `opportunityCost` weight is always ≤ `liquidity` weight (preservation dominates growth pressure)

---

## Appendix A — Policy ID Registry

| Policy ID | Archetype | FinancialState | Lifecycle Stage |
|---|---|---|---|
| `student_v1` | student | survive→build | foundation |
| `salaried_survive_v1` | salaried | survive | any |
| `salaried_stabilize_v1` | salaried | stabilize | any |
| `salaried_build_v1` | salaried | build | foundation/growth/peak |
| `salaried_optimize_v1` | salaried | optimize | growth/peak |
| `freelancer_survive_v1` | freelancer | survive | any |
| `freelancer_stabilize_v1` | freelancer | stabilize | any |
| `freelancer_build_v1` | freelancer | build | any |
| `freelancer_optimize_v1` | freelancer | optimize | any |
| `business_survive_v1` | businessOwner | survive/stabilize | any |
| `business_build_v1` | businessOwner | build | any |
| `business_optimize_v1` | businessOwner | optimize | any |
| `pre_retirement_v1` | any | build/optimize | preRetirement |
| `retired_v1` | any | optimize | retirement |

---

## Appendix B — Why Not Bayesian Weights Now?

The design explicitly defers Bayesian weight optimization to a future phase. The reasoning:

1. **Data requirements:** Bayesian per-user weight tuning requires a minimum of 30–50 completed decision cycles (Recommend → Observed → Outcome) per user to produce reliable parameter estimates. PennyWise has neither the data volume nor the closed decision loop yet.

2. **Cold start:** A new user has zero history. The policy engine provides structured prior weights (this document) that encode CFP knowledge. A Bayesian approach would produce random weights without a prior — worse than structured hardcoding.

3. **The policy engine is the prior:** When the Bayesian system ships, the named policy weights in this document become the prior distribution. The Bayesian update runs on top of the policy weights, nudging them based on individual outcome data. The policy engine is not replaced by Bayesian learning — it is the foundation it runs on.

4. **Explainability:** Policy-derived weights are explainable ("this axis carries 0.42 weight because irregular income is the most diagnostic signal for freelancers"). Bayesian-tuned weights for an individual user are interpretable but harder to audit. The policy layer ensures there is always a human-readable reason for the weight configuration.

---

*This document is the authoritative design spec for the Decision Policy Engine. Implementation proceeds against this document without redesign. Any deviation during implementation must be recorded as an amendment to this document.*
