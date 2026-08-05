# Financial Constitution — v2 Reasoning Architecture

**Document:** `docs/architecture/reasoning-v2/07-financial-constitution.md`
**Status:** Design Specification
**Phase:** Pre-Implementation
**Depends on:** `FinancialReasoningContext`, `FinancialPolicy`, `DecisionType`, `PartnerProgram`, `MatchingPolicy`

---

## 1. Overview — Why the Financial Constitution Is Architecturally Significant

PennyWise already has a product-level constitution (`docs/PENNYWISE-CONSTITUTION.md`) that governs how PennyWise behaves as a company: what it will never recommend, what it will never monetize, how it handles trust. That is a constitution for the platform.

This document specifies a different and complementary concept: a **Financial Constitution** for the individual user. It is the set of rules that the user has declared inviolable about their own financial life — and that the recommendation engine must never violate, regardless of what its utility scoring or challenge layer produces.

### The Conceptual Distinction

Preferences are things the user would prefer. Constraints are things the user requires. A Financial Constitution contains only constraints.

"I prefer to invest in ESG funds" is a preference. The engine can satisfy it when convenient and trade it off when the preference conflicts with a stronger opportunity.

"I will never invest in tobacco or weapons stocks" is a constraint. The engine cannot trade it off. It must treat it as inviolable. If a tobacco fund produces the highest utility score in the recommendation pipeline, the engine must eliminate it before it exits — silently, completely, and with an audit trail that records why.

This distinction is architecturally significant because it changes where in the pipeline the check runs and how violations are handled. Preferences are inputs to utility scoring (they modify scores). Constraints are filters applied before scoring (they eliminate candidates from consideration). An engine that treats a constraint as a preference with high weight has a bug. The Financial Constitution exists to make that impossible.

### Why This Matters for PennyWise Specifically

PennyWise's recommendation surface is expanding. The Partner Matching Engine now ranks execution options. The Decision Engine selects from ten `DecisionType` candidates. Future phases will include insurance recommendations, loan recommendations, and portfolio rebalancing. As the recommendation surface expands, the surface area for constraint violations grows.

Without a Financial Constitution checked at the pipeline level, a constraint violation can occur through an entirely correct sequence of steps: each step obeys the rules it knows about, but no step is aware of the constraint that the overall recommendation violates.

The Financial Constitution is the architectural mechanism that makes constraint compliance mandatory at the pipeline boundary — not dependent on each engine knowing every user rule.

---

## 2. Research Findings

### 2.1 Values-Based Financial Planning

Values-based financial planning is a professional CFP discipline that integrates personal values, beliefs, and ethical constraints into financial planning alongside monetary goals. The CFP Board's professional literature describes it as: "aligning financial decisions with personal values, resulting in a plan that reflects both monetary objectives and personal ethics."

Critically, values-based planning distinguishes between values that influence priorities and values that create absolute constraints. A client who says "I do not want to own tobacco stocks" is not expressing a preference — they are expressing a value that creates a categorical exclusion. A properly trained CFP treats this as a hard constraint applied before any recommendation is made, not as a factor in the recommendation's utility calculation.

The implication for PennyWise is that the Financial Constitution must support both types: preference-level values that influence scoring, and constraint-level values that eliminate candidates. This document focuses exclusively on the constraint tier.

### 2.2 Hard vs. Soft Constraints in Optimization

In constraint satisfaction theory, hard constraints define the feasible region of the problem. A solution that violates a hard constraint is not a valid solution, even if it scores highly on all other dimensions. Soft constraints are preferences — violation is permitted at a cost.

The formal treatment: "Hard constraints must be satisfied for a solution to be valid. Soft constraints express preferences or penalties and can be violated but at a cost. Solving a CSP with soft constraints involves optimization of the objective function to minimize cost. Hard constraints can be incorporated by mapping consistent value combinations to cost 0, and inconsistent ones to cost ∞."

This is exactly the enforcement model the Financial Constitution uses: a constraint violation maps the candidate's utility to ∞ penalty — it is eliminated from the feasible set. The violation is not a score adjustment. It is a disqualification.

The engineering implication is that the Constitution Check must run before utility scoring, not after. If the Constitution Check runs after scoring, the engine has already done work on a candidate that will be eliminated. Worse, if the scoring process has side effects (e.g., partner program lookups, instrument calculations), those side effects have occurred for an ineligible candidate. Running the check early eliminates ineligible candidates before any computation is invested in them.

### 2.3 ESG Negative Screens and Exclusion Lists

The institutional investment management industry has operated exclusion lists for decades. An exclusion list "is a tool used in investment management to exclude certain companies, industries, or activities from an investment portfolio based on specific criteria, with the purpose of aligning investment decisions with ethical, social, or environmental considerations."

Negative screening (exclusion) is fundamentally different from positive screening (preference for qualifying investments): exclusion removes a security from the investable universe entirely; preference adjusts its weight within the universe. Over half of institutional investors apply negative screens, and these screens are enforced at the mandate level — before any portfolio construction or optimization occurs.

The architecture lesson: exclusion screens are enforced at the data provider or mandate level, not at the portfolio optimizer level. By the time the optimizer runs, excluded securities are not in the input set. The Financial Constitution implements the same architecture: by the time the utility scorer runs, constitutionally-excluded candidates are not in the input set.

### 2.4 The Pre-Mortem and Proactive Constraint Capture

A challenge in user-defined financial constitutions is that users often only discover they have a constraint after it is violated. "I didn't know I cared about that until PennyWise recommended it and I rejected it."

Gary Klein's pre-mortem technique surfaces risks proactively by asking "what would cause this to fail?" Applied to the Financial Constitution, the onboarding process should apply a structured pre-mortem for constraint discovery: "If PennyWise recommended X, would you reject it? Why?" This converts implicit values into explicit constraints before the user's first recommendation.

The domain implication: the Financial Constitution is not populated by the engine. It is populated through structured user onboarding, in-app constraint declaration, and rejection feedback loops.

### 2.5 SEBI's Fiduciary Framework and Indian Regulatory Context

SEBI's regulatory framework for financial advisors establishes a fiduciary duty that is itself a category of hard constraint. SEBI-registered investment advisors (RIAs) are prohibited from earning commissions on investments they recommend. They cannot prioritize their economic interest over client interest. These are legal hard constraints — not preferences.

PennyWise operates under SEBI's fiduciary principles for its decision layer. This means several constraints are not user-defined — they are system-level regulatory requirements. The Financial Constitution formalizes both: system-level constraints that apply to every PennyWise user (grounded in fiduciary duty) and user-defined constraints that apply only to that specific user.

The System Constitution is immutable and cannot be overridden by users. The User Constitution is modifiable by the user within the bounds of the System Constitution.

---

## 3. Constitution Types

The Financial Constitution is stratified into three levels. Each level has different ownership, mutability, and enforcement priority.

### Level 1 — System Constitution (Universal, Immutable)

Rules that apply to every PennyWise user. Grounded in fiduciary duty, SEBI regulations, and PennyWise's founding product constitution. These rules cannot be disabled, modified, or overridden by any user or by any feature configuration.

The System Constitution includes:
- Commission prohibition: no recommendation may benefit PennyWise financially at the user's expense
- Explainability requirement: no recommendation without an explanation (Trust Law 1)
- Reversibility requirement: no recommendation to take an irreversible action without explicit user acknowledgment
- State-appropriate risk ceiling: no recommendation of an instrument whose risk tier exceeds the user's `FinancialState`-appropriate ceiling
- Ponzi and fraud exclusion: no recommendation of any instrument that exhibits characteristics of a scheme promising guaranteed high returns without a regulated mechanism
- Unregistered entity exclusion: no recommendation to transact with a financial entity that is not registered with RBI, SEBI, IRDAI, or PFRDA as applicable

### Level 2 — User Constitution (User-Defined, Annual Review)

Rules declared by the specific user. These persist across all sessions and apply to all recommendations until the user explicitly modifies or removes them. They are stored as part of the user's profile and loaded into `FinancialReasoningContext` at the start of every recommendation cycle.

Example user constitution rules:
- "Never recommend credit cards or credit card instruments"
- "Never reduce emergency fund below 12 months of expenses"
- "Never recommend cryptocurrency or cryptocurrency-adjacent instruments"
- "Never recommend instruments with lock-in periods exceeding 3 years"
- "Never touch the education fund earmarked for child's education"
- "Only recommend SEBI-registered mutual funds (no direct stocks)"
- "Never recommend a new commitment that increases monthly obligations above ₹35,000"

### Level 3 — Goal Constitution (Goal-Specific, Duration-Bound)

Rules that apply specifically to a named financial goal and expire when the goal is achieved or abandoned. These are the most granular level and are typically set when the goal is created.

Example goal constitution rules:
- Goal: Child's Education Fund → "Never withdraw from this goal under any circumstances before 2031"
- Goal: Emergency Fund → "Never invest emergency fund assets in instruments with lock-in"
- Goal: Home Down Payment → "Never invest in equity instruments; capital preservation only"
- Goal: Retirement Corpus → "No withdrawals permitted before age 55"

Goal constitution rules are scoped to `GoalId`. When the engine evaluates an action that would affect a specific goal, it checks the goal's constitution before proceeding.

---

## 4. Domain Model

### 4.1 ConstitutionLevel

```
enum ConstitutionLevel {
  /// Applies universally. Cannot be overridden by user or goal rules.
  system,

  /// Applies to all recommendations for this user.
  user,

  /// Applies only to recommendations affecting a specific goal.
  goal,
}
```

### 4.2 RuleCategory

```
enum RuleCategory {
  /// Excludes a class of financial instruments on ethical grounds.
  ethicalScreen,

  /// Sets a minimum floor value that must never be violated.
  safetyFloor,

  /// Protects a specific asset or goal fund from being touched.
  assetProtection,

  /// Prohibits a class of debt instrument.
  debtConstraint,

  /// Limits a quantitative parameter (max monthly commitment, max lock-in period, etc.)
  quantitativeCeiling,

  /// A custom rule that does not fit other categories.
  custom,
}
```

### 4.3 ViolationSeverity

```
enum ViolationSeverity {
  /// The recommendation is constitutionally impermissible.
  /// The candidate is eliminated from the pipeline.
  hard,

  /// The recommendation is permissible but carries a constitutional concern.
  /// The candidate is not eliminated but a warning is added to the Explanation.
  soft,
}
```

### 4.4 ConstitutionRule

```
ConstitutionRule {
  /// Unique identifier for this rule. ULID.
  final String ruleId;

  /// The level this rule operates at.
  final ConstitutionLevel level;

  /// The category of constraint this rule represents.
  final RuleCategory category;

  /// Short, human-readable description of this rule.
  /// Example: "Never recommend credit cards"
  final String description;

  /// The machine-evaluable constraint function signature.
  /// Evaluated against a CandidateContext (the recommendation candidate + FinancialReasoningContext).
  /// Returns true if the candidate VIOLATES this rule.
  /// (Note: returns violation, not compliance — consistent with filtering semantics.)
  final ConstitutionConstraint constraint;

  /// What happens when the constraint evaluates to true (violation detected).
  final ViolationSeverity violationSeverity;

  /// Human-readable explanation of why this rule exists.
  /// Shown to the user when a violation causes a candidate to be excluded.
  final String violationMessage;

  /// If level == goal, this is the GoalId this rule protects.
  /// Null for system and user rules.
  final String? protectedGoalId;

  /// When this rule was created. ISO 8601.
  final DateTime createdAt;

  /// When this rule expires (for goal-level rules) or null for permanent rules.
  final DateTime? expiresAt;

  /// Whether the rule is active. Soft-deleted rules are inactive but retained for audit.
  final bool isActive;
}
```

### 4.5 ConstitutionViolation

```
ConstitutionViolation {
  /// The rule that was violated.
  final ConstitutionRule rule;

  /// The DecisionType or FinancialInstrument that triggered the violation.
  final String violatingCandidate;

  /// The specific value or condition that triggered the rule.
  /// Example: "Recommended instrument: HDFC Credit Card (instrument type: creditCard)"
  final String violationDetail;

  /// Whether the violation resulted in candidate elimination (hard) or warning (soft).
  final ViolationSeverity severity;

  /// Timestamp of the violation. Used in audit trail.
  final DateTime detectedAt;
}
```

### 4.6 FinancialConstitution

```
FinancialConstitution {
  /// The userId this constitution belongs to.
  final String userId;

  /// All active rules across all levels.
  final List<ConstitutionRule> rules;

  /// Convenience accessor: system-level rules only.
  List<ConstitutionRule> get systemRules =>
    rules.where((r) => r.level == ConstitutionLevel.system && r.isActive).toList();

  /// Convenience accessor: user-level rules only.
  List<ConstitutionRule> get userRules =>
    rules.where((r) => r.level == ConstitutionLevel.user && r.isActive).toList();

  /// Convenience accessor: goal-specific rules for a given goalId.
  List<ConstitutionRule> rulesForGoal(String goalId) =>
    rules.where(
      (r) => r.level == ConstitutionLevel.goal
          && r.protectedGoalId == goalId
          && r.isActive
    ).toList();

  /// Hard rules only (violations eliminate candidates).
  List<ConstitutionRule> get hardRules =>
    rules.where((r) => r.violationSeverity == ViolationSeverity.hard && r.isActive).toList();

  /// Soft rules only (violations add warnings).
  List<ConstitutionRule> get softRules =>
    rules.where((r) => r.violationSeverity == ViolationSeverity.soft && r.isActive).toList();
}
```

### 4.7 ConstitutionCheckResult

```
ConstitutionCheckResult {
  /// The candidate that was evaluated.
  final DecisionType candidate;

  /// True if the candidate passed all hard rules (may have soft violations).
  final bool isPermissible;

  /// All violations detected (hard + soft).
  final List<ConstitutionViolation> violations;

  /// True if any hard violation was detected.
  bool get hasHardViolation =>
    violations.any((v) => v.severity == ViolationSeverity.hard);

  /// True if any soft violation was detected (warnings only).
  bool get hasSoftViolation =>
    violations.any((v) => v.severity == ViolationSeverity.soft);

  /// Messages to surface in Explanation.limitations[] for soft violations.
  List<String> get warningMessages =>
    violations
      .where((v) => v.severity == ViolationSeverity.soft)
      .map((v) => v.rule.violationMessage)
      .toList();
}
```

---

## 5. Rule Categories — Canonical Definitions

### 5.1 Ethical Screens

Ethical screens eliminate candidates involving a specific instrument class regardless of financial utility. They answer the question: "Does this recommendation involve something the user has declared they will not participate in?"

**Examples:**

```
Rule: NoCryptoScreen
  category: ethicalScreen
  level: user
  description: "Never recommend cryptocurrency or crypto-adjacent instruments"
  constraint: candidate.instrument IN [crypto, cryptoFund, nft]
  violationSeverity: hard
  violationMessage: "This option involves cryptocurrency, which you've excluded from your financial plan."

Rule: NoAlcoholTobaccoScreen
  category: ethicalScreen
  level: user
  description: "Never recommend stocks or funds with >5% exposure to alcohol or tobacco"
  constraint: candidate.instrument.sectorExposure(tobacco, alcohol) > 0.05
  violationSeverity: hard
  violationMessage: "This fund has material exposure to sectors you've excluded (tobacco/alcohol)."

Rule: EsgOnlyScreen
  category: ethicalScreen
  level: user
  description: "Only recommend ESG-rated instruments"
  constraint: candidate.instrument.esgRating == null
  violationSeverity: soft (warning, not elimination — ESG rating may be unavailable)
  violationMessage: "ESG rating unavailable for this instrument. You've requested ESG-only recommendations."

Rule: NoDirectEquityScreen
  category: ethicalScreen
  level: user
  description: "Only recommend mutual funds, not direct equity"
  constraint: candidate.instrument.type == FinancialInstrumentType.directEquity
  violationSeverity: hard
  violationMessage: "You've requested only mutual fund instruments, not direct equity."
```

### 5.2 Safety Floors

Safety floors protect quantitative minimums that must never fall below a threshold. Unlike the `LiquidityChallenge` (which compares candidates by utility), a safety floor rule is a categorical prohibition: any action that would reduce a metric below the floor is constitutionally impermissible.

**Examples:**

```
Rule: EmergencyFundFloor_12Months
  category: safetyFloor
  level: user
  description: "Never reduce emergency fund below 12 months of expenses"
  constraint: postActionEmergencyFundMonths < 12.0
  violationSeverity: hard
  violationMessage: "This action would reduce your emergency fund below your 12-month floor."

Rule: EmergencyFundFloor_6Months (default system rule)
  category: safetyFloor
  level: system
  description: "Never recommend an action that reduces EF below 3 months"
  constraint: postActionEmergencyFundMonths < 3.0
  violationSeverity: hard
  violationMessage: "This action would reduce your emergency fund to a critically low level."

Rule: MaxCommitmentCeiling
  category: quantitativeCeiling
  level: user
  description: "Never increase total monthly commitments above ₹35,000"
  constraint: postActionTotalCommitments > 35000
  violationSeverity: hard
  violationMessage: "This action would push your total monthly commitments above your ₹35,000 ceiling."
```

### 5.3 Asset Protection Rules

Asset protection rules prevent the recommendation engine from touching specific named funds, accounts, or goals. They are the strongest category of user-defined constraint — they do not depend on quantitative thresholds but on categorical identity.

**Examples:**

```
Rule: EducationFundProtection
  category: assetProtection
  level: goal
  protectedGoalId: [goal-id-for-child-education-fund]
  description: "Never withdraw from, reduce, or redirect the education fund"
  constraint: action.affectedGoalId == protectedGoalId
              AND action.type IN [withdrawal, redirect, rebalance, pause]
  violationSeverity: hard
  violationMessage: "This action would affect your child's education fund, which you've protected from changes."

Rule: RetirementCorpusProtection
  category: assetProtection
  level: goal
  protectedGoalId: [goal-id-for-retirement-corpus]
  description: "Never withdraw from retirement corpus before age 55"
  constraint: action.affectedGoalId == protectedGoalId
              AND userAge < 55
              AND action.type == withdrawal
  violationSeverity: hard
  violationMessage: "Withdrawals from your retirement corpus are protected until age 55."

Rule: PfWithdrawalProtection (system rule)
  category: assetProtection
  level: system
  description: "Never recommend premature EPF/PPF withdrawal without acknowledging tax penalty"
  constraint: action.instrument IN [epf, ppf]
              AND action.type == withdrawal
              AND action.isAcknowledgedIrreversible == false
  violationSeverity: hard
  violationMessage: "EPF/PPF withdrawal has tax implications and lock-in rules that require your explicit acknowledgment."
```

### 5.4 Debt Constraints

Debt constraints prohibit the recommendation of specific categories of debt instruments the user has declared they will not use.

**Examples:**

```
Rule: NoCreditCard
  category: debtConstraint
  level: user
  description: "Never recommend credit cards or credit card-linked instruments"
  constraint: candidate.instrument.type == FinancialInstrumentType.creditCard
  violationSeverity: hard
  violationMessage: "You've excluded credit cards from your financial plan."

Rule: NoPaydayLoan
  category: debtConstraint
  level: system
  description: "Never recommend payday loans, NBFC advances, or instruments with APR > 36%"
  constraint: candidate.instrument.effectiveApr > 0.36
  violationSeverity: hard
  violationMessage: "This instrument's effective interest rate exceeds the safe ceiling."

Rule: NoUnsecuredDebtAddition
  category: debtConstraint
  level: user
  description: "Never recommend taking on new unsecured debt when existing debtRatio > 0.30"
  constraint: action.type == newDebtRecommendation
              AND action.instrument.isUnsecured == true
              AND facts.debtRatio > 0.30
  violationSeverity: hard
  violationMessage: "You've set a rule against new unsecured debt while existing debt-to-income exceeds 30%."
```

### 5.5 Lock-In Constraints

Lock-in constraints prevent recommendations of instruments with illiquidity periods that exceed the user's tolerance.

**Examples:**

```
Rule: MaxLockInPeriod_3Years
  category: quantitativeCeiling
  level: user
  description: "Never recommend instruments with lock-in periods exceeding 3 years"
  constraint: candidate.instrument.lockInMonths > 36
  violationSeverity: hard
  violationMessage: "This instrument has a lock-in period longer than your 3-year maximum."

Rule: NoLockInForEmergencyFund
  category: assetProtection
  level: system
  description: "Emergency fund instruments must have zero lock-in"
  constraint: action.affectedGoalId == emergencyFundGoalId
              AND candidate.instrument.lockInMonths > 0
  violationSeverity: hard
  violationMessage: "Emergency fund must remain liquid. This instrument has a lock-in period."
```

### 5.6 System-Level Universal Rules (Non-Overridable)

These rules apply to every PennyWise user and cannot be removed or overridden. They encode the fiduciary standard and regulatory minimum.

| Rule | Category | Description |
|------|----------|-------------|
| `NoCommissionConflict` | ethicalScreen | No recommendation whose ranking is influenced by PennyWise's revenue |
| `NoUnregisteredEntity` | ethicalScreen | No recommendation to transact with entities not registered with RBI/SEBI/IRDAI/PFRDA |
| `NoGuaranteedHighReturn` | ethicalScreen | No instrument claiming guaranteed returns above 12% p.a. (Ponzi screen) |
| `ExplainabilityRequired` | custom | No recommendation without a populated `Explanation.because[]` array |
| `EmergencyFundMinimum_3Months` | safetyFloor | No action reducing EF below 3 months |
| `NoEpfPpfWithdrawalWithoutAck` | assetProtection | EPF/PPF withdrawal requires explicit irreversibility acknowledgment |
| `NoPaydayLoan` | debtConstraint | No instrument with APR > 36% |
| `RiskCeilingByState` | quantitativeCeiling | No instrument exceeding state-appropriate risk tier |

---

## 6. Enforcement Pipeline

The Constitution Check runs at a specific, mandatory position in the recommendation pipeline: **after candidate generation and before utility scoring**.

```
FinancialReasoningContext + FinancialConstitution
        │
        ▼
[1] Axis Evaluation (6 axes)
        │
        ▼
[2] Compound Confidence (DecisionConfidenceReport)
        │
        ▼
[3] Candidate Generation — all applicable DecisionType candidates
        │
        ▼
[4] CONSTITUTION CHECK ← runs here, BEFORE utility scoring
        │  Input:  List<DecisionType> candidates, FinancialConstitution
        │  Output: List<DecisionType> permissibleCandidates (hard violations eliminated)
        │          List<ConstitutionViolation> hardViolations (for audit log)
        │          Map<DecisionType, List<String>> softWarnings (for explanation)
        │
        ▼
[5] Utility Scoring — runs ONLY on permissibleCandidates
        │
        ▼
[6] TOP CANDIDATE SELECTED from permissible set
        │
        ▼
[7] CHALLENGE LAYER (see Document 06)
        │
        ▼
[8] Decision Assembly (Decision object, Explanation, TrustMetadata)
        │  softWarnings are injected into Explanation.limitations[]
        │
        ▼
[9] Partner Matching (also checked against Constitution for instrument-level rules)
        │
        ▼
[10] DecisionResponse envelope assembled
```

### Why Before Utility Scoring (Not After)

The check runs before utility scoring for four reasons:

**1. Correctness.** A constitutionally impermissible candidate should never receive a utility score. If it scores first and is then eliminated, the engine has done wasted computation. Worse, the challenger in the Challenge Layer might reference the eliminated candidate's score in its reasoning — a score that was never valid.

**2. Efficiency.** The Utility Scorer and Challenge Layer are the most computationally intensive steps. Pruning early reduces the work.

**3. Audit integrity.** If a candidate is eliminated by a constitution rule, that elimination must be recorded before any scoring occurs. A candidate that "almost" passed utility scoring but was constitutionally prohibited must not appear in any intermediate result.

**4. Pipeline purity.** Each step in the pipeline receives a clean input set. The Utility Scorer only sees permissible candidates. The Challenge Layer only challenges permissible candidates. The Constitution Check's job is to ensure the invariant holds.

### The Empty-Set Problem

If the Constitution Check eliminates all candidates, the pipeline has no candidates to score. This is a design-time and runtime concern.

**At design time:** System constitution rules must be designed to never eliminate all `DecisionType` candidates simultaneously. `reviewPastDecision` must be constitutionally permissible under all system rules — it is the universal fallback.

**At runtime:** If user-defined constitution rules eliminate all candidates, the engine falls back to `reviewPastDecision` (a safe, low-stakes action). The `ConstitutionCheckResult` is flagged with `allCandidatesEliminated: true` and the user is shown an explanation: "Your financial rules have excluded all available recommendations at this time. We recommend reviewing a past decision instead."

**After fallback:** The empty-set event is recorded in the `DecisionAudit` and surfaced to the user as a notification: "Your financial constitution ruled out all recommendations today. Consider reviewing your rules if this happens repeatedly."

---

## 7. Violation Handling

### Hard Violation — Candidate Elimination

When a hard constitution rule fires against a candidate:

1. The candidate is removed from the `permissibleCandidates` list
2. A `ConstitutionViolation` object is created with `severity: hard`
3. The violation is added to the `DecisionAudit.constitutionViolations[]` array
4. The `violationMessage` is stored for explanation purposes
5. The candidate does not appear in any explanation as "considered and rejected" — it is eliminated silently. The user is not told "PennyWise considered X but eliminated it" because that would reveal that the engine even generated an impermissible candidate, which could be alarming. Instead, the eliminated candidate simply does not exist in the user's recommendation surface.

Exception: if the user specifically asks "why wasn't X recommended?", the Constitution Check's audit trail is available to answer that question transparently.

### Soft Violation — Warning Addition

When a soft constitution rule fires against a candidate:

1. The candidate remains in `permissibleCandidates`
2. A `ConstitutionViolation` object is created with `severity: soft`
3. The violation's `violationMessage` is added to `Explanation.limitations[]`
4. The candidate may still be selected if it wins utility scoring

Example: a user has requested ESG-only instruments. A candidate fund has no ESG rating (not the same as failing ESG). This is a soft violation: the fund is permissible (its ESG status is unknown, not negative), but the user is warned that the fund lacks an ESG certification.

### The Audit Trail

All `ConstitutionViolation` objects (hard and soft) are stored in `DecisionAudit.constitutionViolations[]`. This array is part of the permanent audit trail for the Decision lifecycle. It is used for:

- Answering "why wasn't X recommended?" queries
- Annual constitution review (showing the user which rules fired most frequently)
- System constitution analytics (identifying if a system rule is too broad and is eliminating too many valid candidates)
- Regulatory audit trail demonstrating that the engine operated within fiduciary and regulatory constraints

---

## 8. Constitution Evolution

### Who Can Change What

| Level | Who Can Change | How | Immutability |
|-------|---------------|-----|--------------|
| System | PennyWise founding team only | Code deploy + explicit version bump | Permanent once set; can only be strengthened (more restrictive), never weakened |
| User | The user | In-app Constitution settings screen | Any time, with annual review prompt |
| Goal | The user, at goal creation or in goal settings | In-app goal settings | Persists until goal is achieved or explicitly removed |

The asymmetry for system rules is deliberate and mirrors the PennyWise product constitution's amendment rule: "Any revision that weakens a user protection, removes a prohibition, or expands PennyWise's ability to benefit at the user's expense is not a revision. It is a violation."

### Adding a User Rule

User rules are added through a structured UI flow, not free-text input:

1. The user selects a rule category (ethical screen, safety floor, asset protection, debt constraint, quantitative ceiling, custom)
2. The user selects the specific constraint from a template library (e.g., "Never recommend credit cards")
3. For quantitative rules, the user specifies the threshold (e.g., "12 months" for emergency fund floor)
4. The rule is previewed: "This rule means PennyWise will never recommend [description]. [N] products in the current recommendation set would be affected."
5. The user confirms or adjusts

The preview step is critical. It converts an abstract declaration into a concrete consequence: the user sees what they are actually prohibiting, not just the principle. This prevents rules that accidentally eliminate desirable recommendations.

### Removing a User Rule

Removing a rule requires a deliberate confirmation step:
- "You are removing the rule: 'Never recommend cryptocurrency.' This means cryptocurrency instruments may appear in future recommendations. Confirm?"

Removal is soft-deleted: the rule becomes `isActive: false` but is retained in the database for audit purposes. The user's history of constitutional choices is preserved.

### Annual Review

Once per year (or after 12 months from creation), the user is prompted to review their User Constitution:

- Rules that fired most frequently (affected the most recommendations)
- Rules that never fired (may be redundant)
- Rules created more than 12 months ago (values may have changed)

This annual review is a UX feature, not a technical enforcement mechanism. Rules do not expire automatically. The user must explicitly remove or modify a rule.

### Goal Constitution at Goal Completion

When a goal is marked as achieved or abandoned:
- All goal-level rules for that `GoalId` are automatically set to `isActive: false`
- The user is notified: "Your goal 'Child's Education Fund' has completed. The protection rules for this goal have been deactivated. You can restore them in your Constitution settings."

---

## 9. Integration with `FinancialReasoningContext` and `DecisionPolicy`

### 9.1 Adding `FinancialConstitution` to `FinancialReasoningContext`

`FinancialReasoningContext` is the universal input to the `FinancialReasoningEngine`. The `FinancialConstitution` is added as an optional field:

```
FinancialReasoningContext {
  final FinancialFacts facts;
  final DataConfidenceReport dataConfidence;
  final BehaviorInterpretation? behavior;
  final LearningSnapshot? learningSnapshot;
  final List<GoalSnapshot> goals;
  final String? contextLabel;

  // NEW: User's financial constitution. If null, only system rules apply.
  final FinancialConstitution? constitution;  ← ADD THIS
}
```

When `constitution` is null, the engine applies only the System Constitution (hardcoded in `ConstitutionEngine.systemRules`). This ensures system rules always apply, even when the user has not yet defined any personal rules.

### 9.2 `FinancialPolicy` vs. `FinancialConstitution`

These two domain objects serve different purposes and must not be conflated:

| Aspect | `FinancialPolicy` | `FinancialConstitution` |
|--------|-------------------|-------------------------|
| Owns | Financial constants (rates, thresholds, weights) | Constraint rules (what must never happen) |
| Mutability | Updated with RBI policy changes; shared across all users | Per-user; modifiable by the individual user |
| Role in pipeline | Inputs to utility scoring and challenge trigger conditions | Filter applied before utility scoring |
| Example content | `emergencyFundTargetMonths = 6.0` | "Never reduce EF below 12 months" (user's personal floor) |
| What happens on change | Recommendation utility scores shift | Recommendation candidate set shrinks |

`FinancialPolicy` governs the math. `FinancialConstitution` governs the ethics and personal values.

### 9.3 Adding `ConstitutionEngine` Interface

New engine interface: `mobile/lib/domain/engines/constitution_engine.dart`

```
abstract class ConstitutionEngine {
  /// Check all active constitution rules against the given candidates.
  /// Returns a ConstitutionCheckResult for each candidate.
  /// Hard-violated candidates must be removed from the permissible set by the caller.
  List<ConstitutionCheckResult> check({
    required List<DecisionType> candidates,
    required FinancialReasoningContext context,
    required FinancialConstitution constitution,
  });

  /// The immutable system-level rules applied to every check, regardless
  /// of whether the user has a personal constitution.
  List<ConstitutionRule> get systemRules;
}
```

Implementation: `mobile/lib/infrastructure/engines/rule_based_constitution_engine.dart`

This implementation evaluates each rule's `constraint` function against each candidate. System rules are hardcoded in the implementation. User rules are loaded from `FinancialConstitution.userRules` and `FinancialConstitution.rulesForGoal()`.

### 9.4 Partner Program Constitution Check

The Constitution Check runs a second time during Partner Matching (Step 9 of the pipeline). At this stage, the check evaluates instrument-level rules against specific `PartnerProgram` objects, not `DecisionType` candidates.

This second check is necessary because the first check operates at the decision type level ("should we recommend an ELSS?"), while the Partner Matching phase operates at the instrument level ("should we recommend this specific Axis ELSS?"). A user's ethical screen for a specific fund family cannot be evaluated at the `DecisionType` level.

The `PartnerMatchingEngine` receives the `FinancialConstitution` and applies it as an additional rejection filter in addition to its existing `MatchingPolicy` rejection logic.

---

## 10. Invariants

These invariants define the correctness properties of the Financial Constitution system.

**Invariant 1 — System Rules Are Immutable**
System constitution rules cannot be modified at runtime, disabled by users, or overridden by user rules. They are hardcoded in `RuleBasedConstitutionEngine.systemRules` and deployed as part of the application binary. A user rule that attempts to contradict a system rule is rejected at creation time with an error: "This rule conflicts with a platform protection that cannot be overridden."

**Invariant 2 — The System Constitution Always Applies**
Even when `FinancialReasoningContext.constitution` is null (user has no personal constitution), the system rules are applied. The `ConstitutionEngine` never skips the system check. The null check on `constitution` only determines whether user and goal rules are evaluated — not whether the system rules are.

**Invariant 3 — `reviewPastDecision` Is Always Permissible**
The `reviewPastDecision` decision type must pass all system constitution rules by design. It is the universal fallback for the empty-set problem (Section 6). If a system rule is added that would block `reviewPastDecision`, the rule is architecturally incorrect and must be revised. This invariant must be tested in the system rule test suite.

**Invariant 4 — Hard Violations Are Never Scored**
A candidate that receives a hard constitution violation must be removed from the candidate list before utility scoring begins. The Utility Scorer must never receive a hard-violated candidate. This is enforced by the pipeline structure (Constitution Check runs in Step 4, Utility Scoring in Step 5) and must be verified in integration tests.

**Invariant 5 — Violations Are Always Audited**
Every violation — hard or soft — must be recorded in `DecisionAudit.constitutionViolations[]`. Violations must not be silently discarded. This enables the audit trail, the annual review, and the "why wasn't X recommended?" query.

**Invariant 6 — User Rules Are Annual-Review-Prompted**
Rules older than 12 months without user interaction are flagged for review. This flag does not disable the rule — it surfaces a prompt in the Constitution settings UI. The rule remains active until the user explicitly confirms, modifies, or removes it.

**Invariant 7 — System Rules Can Only Be Strengthened**
A future version of the System Constitution may add new rules or tighten existing thresholds. It may never remove a rule or loosen a threshold. Any pull request that weakens a system constitution rule must be rejected in code review. This invariant mirrors the PennyWise product constitution's amendment rule.

**Invariant 8 — Goal Rules Expire with Goals**
When a goal transitions to `achieved` or `abandoned`, its associated goal constitution rules must be set to `isActive: false` within the same transaction. A goal that no longer exists must not continue to block recommendations through its constitution rules. This is enforced by the goal lifecycle event handler.

**Invariant 9 — Soft Violations Surface in Explanation**
Every soft violation's `violationMessage` must appear in `Explanation.limitations[]`. The user must be informed when a recommendation exists under a constitutional concern they have expressed, even if the recommendation is permissible. Hiding soft violations from the explanation is a violation of Trust Law 5 (Visible Uncertainty).

---

## Appendix A — Default System Constitution Rules (v1)

The initial system constitution ships with the following hardcoded rules. This list may only expand in future versions.

| Rule ID | Category | Description | Violation Severity |
|---------|----------|-------------|-------------------|
| `SYS-001` | ethicalScreen | No recommendation whose ranking is influenced by PennyWise revenue | hard |
| `SYS-002` | ethicalScreen | No instruments not registered with RBI/SEBI/IRDAI/PFRDA | hard |
| `SYS-003` | ethicalScreen | No instruments claiming guaranteed returns above 12% p.a. | hard |
| `SYS-004` | custom | No recommendation without a populated Explanation | hard |
| `SYS-005` | safetyFloor | No action reducing EF below 3 months of expenses | hard |
| `SYS-006` | assetProtection | EPF/PPF withdrawal requires irreversibility acknowledgment | hard |
| `SYS-007` | debtConstraint | No instrument with APR > 36% p.a. | hard |
| `SYS-008` | quantitativeCeiling | No instrument exceeding state-appropriate risk tier | hard |
| `SYS-009` | custom | `reviewPastDecision` is always a permissible fallback | (enforced by design, not as a runtime rule) |

---

## Appendix B — Constitution Onboarding Flow

When a user first reaches the Dashboard after completing account setup, they are offered a Constitution Onboarding flow. This is optional (can be skipped) but recommended.

The flow presents scenarios in a pre-mortem frame:

1. "If PennyWise recommended investing in a fund that holds tobacco company stocks, what would you do?" → [Accept] [Decline — add a rule]
2. "If PennyWise recommended a credit card for cashback benefits, what would you do?" → [Accept] [Decline — add a rule]
3. "How many months of expenses do you want to always keep available in liquid form?" → [3 months (default)] [6 months] [12 months] [Custom]
4. "Are there any goals you want to protect from any changes, withdrawals, or redirects?" → (select from goal list)
5. "Are there any instruments you would never use regardless of the financial case?" → (select from instrument category list)

Each "Decline — add a rule" response creates a `ConstitutionRule` with `level: user` and the appropriate `category`. The onboarding flow is the primary mechanism for populating the User Constitution before the user encounters their first recommendation.

---

## Appendix C — Relationship to the PennyWise Product Constitution

The PennyWise product constitution (`docs/PENNYWISE-CONSTITUTION.md`) and the Financial Constitution are related but distinct:

| Dimension | PennyWise Product Constitution | User Financial Constitution |
|-----------|-------------------------------|----------------------------|
| Whose values | PennyWise's values as a company | The individual user's values |
| Who enforces | The founding team (via code review, ADRs) | The `ConstitutionEngine` at runtime |
| Scope | Every feature, business decision, partnership | Every financial recommendation for this user |
| Modifiability | Founding team only; never weakened | User-modifiable for their own rules |
| Example | "No advertising. Ever." | "Never recommend crypto. Ever." |

The product constitution governs PennyWise's behavior toward users. The Financial Constitution governs PennyWise's recommendations toward that specific user. Both are respected simultaneously. A recommendation that violates either constitution must not be shown.
