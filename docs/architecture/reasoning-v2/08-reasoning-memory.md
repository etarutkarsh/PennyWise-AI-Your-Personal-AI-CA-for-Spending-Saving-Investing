# Reasoning Memory — v2 Reasoning Architecture

**Document:** `docs/architecture/reasoning-v2/08-reasoning-memory.md`
**Status:** Design Specification
**Phase:** Pre-Implementation (Pre-11A Addition)
**Depends on:** `DecisionAudit`, `DecisionPolicy`, `FinancialBelief`, `DecisionCandidate`, `ConstitutionViolation`, `UtilityScore`, `CounterfactualSet`, `ChallengeLayerResult`, `ConfidenceGraph`, `RecommendationPortfolio`

---

## 1. Overview — Why Reasoning Memory Is Architecturally Necessary

### The Gap in v1

`DecisionAudit` already exists in the v1 codebase. It records which engines ran and how long each took. It contains `EngineContribution` (engineName, version, outputSummary, durationMs) and `DecisionAudit.engineTrace: List<EngineContribution>`. This is a lightweight event-sourcing structure suitable for tracing execution flow.

What it cannot answer:

- **Why was candidate A chosen over candidate B?** The audit records that `UtilityEngine` ran for 3ms. It does not record the utility scores of the five candidates it evaluated, let alone why they differed.
- **Which beliefs activated and how confident were they?** The audit records that `BeliefInferenceEngine` ran. It does not record that `UserIsFinanciallyFragile` activated at 0.78 confidence and drove the `buildEmergencyFund` preference.
- **What did the Constitution prune?** The audit records that `ConstitutionChecker` ran. It does not record that `StartEquitySIP` was eliminated because `UserConstitutionRule-03` prohibits equity exposure above 30% until emergency fund exceeds 6 months.
- **What did the Challenge Layer reject?** The audit records that `ChallengeLayer` ran. It does not record that `DebtChallenge` fired, proposed `accelerateDebtRepayment`, and was rejected because the user's debt carries 7.5% interest and the available SIP option compounds at 12%.

These are not implementation details — they are the reasoning. Every high-stakes financial recommendation in PennyWise v2 passes through a 10-step pipeline that makes dozens of intermediate decisions. Without storing those decisions, the recommendation is a black box.

### Why a Black Box Is Not Acceptable Here

Three contexts require full reasoning access:

**1. User Explainability.** Users who receive a recommendation and ask "Why?" deserve to understand what the engine evaluated and rejected, not just what it chose. The v2 pipeline's counterfactual narration ("Waiting 6 months costs ₹12L") can only be surfaced if the `CounterfactualSummary` is retrievable for that specific decision. Generating it on demand requires re-running the entire pipeline — expensive, non-deterministic if inputs have changed, and impossible to anchor to the original recommendation.

**2. ML Training.** The most valuable training signal for financial AI is not "user accepted recommendation X" but "user accepted recommendation X — and here is the full chain of reasoning that produced X, including all alternatives that were considered and rejected." Without the reasoning chain, outcome data is paired with a label (accepted/rejected) but not with features (what was the utility score difference between the winner and runner-up? how confident were the activated beliefs?). Reasoning Memory provides the feature vector that transforms a binary outcome label into rich ML supervision signal.

**3. Regulatory Audit.** SEBI's framework for registered investment advisers requires that advice be documented and retrievable. As PennyWise scales toward SEBI RIA compliance, being able to replay exactly what the engine reasoned at the time of a recommendation — including which financial rules were enforced and which data sources were active — is not a feature. It is a legal requirement.

### The Architectural Distinction

`DecisionAudit` answers: *Which engines ran, in what order, for how long?*

`ReasoningMemory` answers: *What did the engine reason, at each step, and why did it choose what it chose?*

These are separate domain types with separate purposes and separate storage strategies. `DecisionAudit` is part of the event-sourcing infrastructure. `ReasoningMemory` is part of the intelligence infrastructure. They can coexist on the same decision record without overlap.

---

## 2. Research Findings

### 2.1 Chain-of-Thought Reasoning in AI Systems

The most impactful technique in modern AI reasoning quality is chain-of-thought prompting, originally described by Wei et al. (2022): "Chain-of-thought reasoning can be elicited in large language models via prompting. Chain-of-thought prompting decomposes multi-step problems into intermediate steps, enabling models to solve problems that require reasoning across multiple steps."

The key insight is that the quality of a decision is inseparable from the quality of the intermediate steps. A recommendation that arrives at the correct answer through incorrect intermediate reasoning is unreliable — it will produce wrong answers in adjacent cases. Conversely, a recommendation that stores its intermediate reasoning can be inspected, corrected, and improved at each step independently.

PennyWise's reasoning pipeline is architecturally analogous. The 10-step pipeline is the "chain." The `ReasoningMemory` stores the "thought" at each step. Without the stored chain, the recommendation is an answer without reasoning — not trustworthy, not auditable, not improvable.

### 2.2 Explanation-by-Example Systems in Financial Advisory

Research on explainable AI for financial advisory (XAI-FinAdv) identifies three categories of explanation: feature importance (which inputs mattered most), counterfactual explanations (what would have changed the output), and case-based explanations (similar past cases produced similar recommendations). All three are derivable from `ReasoningMemory`.

Feature importance: which activated beliefs carried the highest confidence and most directly drove candidate selection? Which utility component (benefit, cost, resistance, regret) was the margin between winner and runner-up?

Counterfactual: `CounterfactualSummary` is stored in `ReasoningMemory`; the narration is retrievable without recalculation.

Case-based: given the stored `policyId`, `activatedBeliefs`, and `winningActionType` for past decisions, Case-Based Reasoning (CBR) can find structurally similar decisions and estimate outcome probabilities before the current recommendation is made.

### 2.3 Interpretable Machine Learning and Audit Trails

Zachary Lipton's foundational paper on interpretability in ML (2016) distinguishes between a model being transparent (the mechanism itself can be inspected) and a model being post-hoc explainable (an explanation can be generated after the fact). The former is preferable but not always achievable for complex models.

`ReasoningMemory` implements transparency at the step level: each intermediate output of the 10-step pipeline is stored, making the mechanism inspectable at any granularity. This is architecturally stronger than post-hoc explanation because it stores the actual reasoning at decision time, not a reconstruction of it.

The practical implication: when the engine is later updated to v2.1 or v2.2, historical `ReasoningMemory` records remain anchored to their original pipeline version. Investigators can replay a 2026 decision with the 2027 engine and compare — or replay it with the 2026 engine to understand the original logic.

### 2.4 Decision Archaeology in High-Stakes Domains

Healthcare decision support systems use a concept called "decision archaeology" — the ability to reconstruct, retrospectively, exactly what the clinical decision support system recommended and why, including the data state at that moment. This is required because clinical decisions are revisited during adverse outcomes, quality reviews, and learning cycles.

The financial domain has equivalent requirements. When a user's goal fails — they didn't reach their retirement corpus, they couldn't sustain their SIP — the question is whether PennyWise's advice contributed to the failure or whether the user deviated from it. Without `ReasoningMemory`, this is unanswerable. With it, the `DecisionLearningEngine` can close the AAR loop: compare the original reasoning chain with the outcome and identify where the model's assumptions were wrong.

---

## 3. Domain Type Specification

### 3.1 Core Types

```dart
/// Full chain-of-reasoning stored per v2 pipeline execution.
///
/// Distinct from DecisionAudit which records engine names and durations.
/// ReasoningMemory records what each engine reasoned and decided.
/// Immutable. Serializable. Permanently associated with one decision execution.
@immutable
class ReasoningMemory {
  final String id;              // ULID — globally unique
  final String? decisionId;    // links to Decision/DecisionResponse if available
  final String userId;
  final DateTime reasonedAt;
  final String pipelineVersion; // e.g. '2.0', '2.1' — tracks schema compatibility
  final String engineVersion;   // e.g. '11H.3' — tracks implementation version

  // ── Step 1: Policy Selection ────────────────────────────────────────────
  final String policyId;             // e.g. 'salaried_build_v1'
  final String policyLabel;          // e.g. 'Salaried Builder'
  final String userArchetypeLabel;   // e.g. 'SalariedWithFamily'
  final String smrtState;            // 'survive' | 'stabilize' | 'build' | 'optimize'
  final bool policyWasInherited;     // true if no policy record existed; default applied

  // ── Step 2: Belief Activation ────────────────────────────────────────────
  final List<ActivatedBeliefRecord> activatedBeliefs;
  final int totalBeliefsEvaluated;
  final double beliefSetConfidence;  // BeliefSet.overallConfidence

  // ── Step 3: Candidate Generation ────────────────────────────────────────
  final List<CandidateRecord> generatedCandidates;   // all candidates generated
  final List<PrunedCandidateRecord> prunedByContext; // pruned before constitution
  final int viableCandidateCount;

  // ── Step 4: Constitution Check ───────────────────────────────────────────
  final List<ConstitutionCheckRecord> constitutionChecks; // one per candidate
  final int hardViolationCount;
  final int softViolationCount;
  final int permissibleCandidateCount;
  final bool fallbackTriggered; // true if all candidates were eliminated

  // ── Step 5: Utility Scoring ──────────────────────────────────────────────
  final List<UtilityBreakdownRecord> utilityBreakdowns; // one per permissible candidate
  final String utilityArchetypeLabel; // e.g. 'LossAvoider', 'GrowthMaximizer'
  final double lossAversionLambda;    // e.g. 2.8 (Indian prior)

  // ── Step 6: Counterfactuals ──────────────────────────────────────────────
  final List<CounterfactualRecord> counterfactuals; // for top 3 candidates
  final bool counterfactualsGenerated;

  // ── Step 7: Challenge Layer ──────────────────────────────────────────────
  final List<ChallengeRecord> challengeResults; // always 6 records
  final bool challengeOverrodeOriginal;
  final String? originalActionTypeLabel;    // set only if challenge overrode
  final String? challengeReplacementLabel;  // the replacement type, if any
  final String? challengeOverrideReason;

  // ── Step 8: Confidence Aggregation ──────────────────────────────────────
  final double decisionConfidenceFactor;
  final double dataConfidenceFactor;
  final double behaviorConfidenceFactor;
  final double historicalAccuracyFactor;
  final double compoundConfidence;
  final String strengthLabel; // 'Low' | 'Medium' | 'High' | 'VeryHigh'

  // ── Step 10: Output ──────────────────────────────────────────────────────
  final String winningActionTypeLabel;  // e.g. 'startSip', 'buildEmergencyFund'
  final String? winningInstrumentLabel; // e.g. 'HDFC Balanced Advantage Fund'
  final int winningRankInGenerated;     // position in original generated list

  // ── Metadata ─────────────────────────────────────────────────────────────
  final Duration pipelineDuration;
  final String? contextLabel;       // from FinancialReasoningContext.contextLabel
  final String? limitationSummary;  // concatenated pipeline limitations
}
```

### 3.2 Supporting Record Types

```dart
/// A belief that fired during Step 2.
@immutable
class ActivatedBeliefRecord {
  final String beliefType;      // e.g. 'UserIsFinanciallyFragile'
  final double confidence;      // 0.0–1.0
  final bool isPresent;         // true = belief holds; false = belief is absent
  final List<String> evidenceFacts; // fact names that drove this belief
  final String? candidateInfluence; // e.g. 'drove buildEmergencyFund to rank 1'
}

/// A candidate that was generated in Step 3 (viable list).
@immutable
class CandidateRecord {
  final String actionTypeLabel;
  final String pyramidLayer;   // 'Layer1' | 'Layer2' | 'Layer3'
  final double magnitudeAmount; // rupee amount or percentage
  final String magnitudeLabel;  // human-readable
  final String riskClass;       // 'safe' | 'conservative' | 'balanced' | 'aggressive'
}

/// A candidate pruned before constitution check.
@immutable
class PrunedCandidateRecord {
  final String actionTypeLabel;
  final String rejectionReason; // from CandidateGenerator pruning rules
}

/// Constitution check result for one candidate.
@immutable
class ConstitutionCheckRecord {
  final String actionTypeLabel;
  final bool isPermissible;
  final String? violationRuleId;    // e.g. 'SYS-004' or 'USR-003'
  final String? violationLabel;     // human-readable
  final String violationLevel;      // 'hard' | 'soft' | 'none'
}

/// Full utility breakdown for one candidate.
@immutable
class UtilityBreakdownRecord {
  final String actionTypeLabel;
  final double expectedBenefit;
  final double expectedCost;
  final double riskPenalty;
  final double behavioralResistancePenalty;
  final double regretPenalty;
  final double complexityPenalty;
  final double liquidityLossPenalty;
  final double netUtility;
  final double calibrationConfidence;
  final int finalRank; // 1 = selected
}

/// One counterfactual scenario for one candidate.
@immutable
class CounterfactualRecord {
  final String actionTypeLabel;
  final String scenarioType; // 'Action' | 'Delay' | 'Magnitude' | 'Shock' | 'Commitment'
  final String narration;    // the user-facing text
  final double acceptedFV;
  final double ignoredFV;
  final double deltaRupees;
}

/// One challenge result (always 6 present).
@immutable
class ChallengeRecord {
  final String challengeType; // 'Liquidity' | 'Debt' | 'Risk' | 'Behavior' | 'Tax' | 'Timing'
  final bool fired;           // true if challenger found a credible alternative
  final String? challengerActionTypeLabel; // proposed replacement
  final String verdict;       // 'Original wins' | 'Original replaced' | 'No challenge'
  final String? reasonOriginalWon;
  final double confidenceDelta; // negative = challenge reduced confidence
}
```

### 3.3 ReasoningMemoryRepository Interface

```dart
abstract class ReasoningMemoryRepository {
  /// Store the memory for a completed pipeline execution.
  /// Returns immediately — write is async and does not block the reasoning pipeline.
  Future<void> store(ReasoningMemory memory);

  /// Retrieve the most recent N memory records for a user.
  Future<List<ReasoningMemory>> getRecent({
    required String userId,
    int limit = 20,
  });

  /// Retrieve one specific memory record by ID.
  Future<ReasoningMemory?> getById(String id);

  /// Retrieve all memories where the winning action type matches.
  /// Used by Case-Based Reasoning in Decision History Search (Phase 12).
  Future<List<ReasoningMemory>> getByActionType({
    required String userId,
    required String actionTypeLabel,
  });

  /// Retrieve memories for ML export — winning action types, beliefs, utility margins.
  /// Phase 12 only. Returns compact training records, not full memory objects.
  Future<List<ReasoningMemoryTrainingRecord>> getForMLExport({
    required String userId,
    required DateTime since,
  });
}
```

---

## 4. Integration with the v2 Pipeline

### 4.1 Where ReasoningMemory Is Assembled

`ReasoningMemory` is not a domain engine — it does not drive the pipeline. It is assembled by the pipeline orchestrator (`RecommendationPipeline`, Sprint 11H) as a side-output of running all 10 steps.

Conceptually:

```
RecommendationPipeline.run(ctx):
  1. policyResult    = policySelector.select(ctx)
  2. beliefResult    = beliefEngine.infer(ctx, policyResult.policy)
  3. candidateResult = candidateGenerator.generate(ctx, beliefResult.beliefs)
  4. constitutionResult = constitutionChecker.check(candidateResult.viable, ctx)
  5. utilityResult   = utilityEngine.score(constitutionResult.permissible, ctx, policyResult.policy)
  6. counterfactualResult = counterfactualEngine.generate(utilityResult.top3, ctx)
  7. challengeResult = challengeLayer.challenge(utilityResult.top1, ctx)
  8. confidenceGraph = confidenceAggregator.aggregate(all above results)
  9. portfolio       = portfolioAssembler.assemble(all above results)

  // Side-output — does not affect pipeline result:
  10. memory = ReasoningMemoryAssembler.assemble(
       policyResult, beliefResult, candidateResult, constitutionResult,
       utilityResult, counterfactualResult, challengeResult, confidenceGraph,
       portfolio, pipelineDuration
     )
  11. memoryRepository.store(memory) // async, fire-and-forget

  return portfolio
```

The memory write is asynchronous and does not block the caller. If the write fails, the pipeline result is unaffected. The failure is logged and retried by an in-memory queue.

### 4.2 Relationship to DecisionAudit

```
DecisionAudit (existing):
  - Lives in: domain/decision/decision_audit.dart
  - Purpose: event-sourcing audit (which engines ran, how long)
  - Granularity: engine-level (name, version, duration)
  - Consumers: DecisionLearningEngine (replay), audit logs
  - Written: at Decision aggregate level, one per domain event

ReasoningMemory (new):
  - Lives in: domain/reasoning/memory/reasoning_memory.dart
  - Purpose: reasoning chain (what was thought at each step)
  - Granularity: step-level (beliefs, candidates, utility scores, challenges)
  - Consumers: ExplainabilityEngine, MLTrainingExporter, CBR (Phase 12)
  - Written: at pipeline execution level, one per reasoning run
```

One decision can trigger multiple reasoning runs (e.g., initial recommendation + morning refresh). Each run produces one `ReasoningMemory`. They share a `decisionId` when the decision record is available.

### 4.3 Relationship to RecommendationPortfolio

`RecommendationPortfolio` is the user-facing output. It contains the ranked recommendations with narrations, counterfactuals, and confidence scores — the minimal subset of reasoning data needed to display the recommendation.

`ReasoningMemory` is the full engineering record. It contains everything `RecommendationPortfolio` contains, plus every candidate that was generated, why each was scored the way it was, and every intermediate step.

Users see `RecommendationPortfolio`. Regulators, ML training pipelines, and the "Why did PennyWise recommend X?" explainability panel access `ReasoningMemory`.

---

## 5. Storage Strategy

### Phase 11H (Sprint Implementation) — In-Memory with LRU

At Sprint 11H, `ReasoningMemory` is stored in-memory with an LRU eviction policy. The default: retain the 50 most recent records per user session. This satisfies the explainability panel requirement (user opens the app, asks "why?", record is available) without requiring SQLite integration.

```dart
class InMemoryReasoningMemoryRepository implements ReasoningMemoryRepository {
  final _cache = LinkedHashMap<String, ReasoningMemory>();
  static const _maxSize = 50;

  @override
  Future<void> store(ReasoningMemory memory) async {
    if (_cache.length >= _maxSize) {
      _cache.remove(_cache.keys.first); // evict oldest
    }
    _cache[memory.id] = memory;
  }
}
```

### Phase 12 (Behavioral Intelligence Upgrade) — SQLite Persistence

Phase 12 introduces `SqliteReasoningMemoryRepository`. Records are persisted to a local SQLite database with a 90-day retention policy. This enables:
- Cross-session "Why?" queries
- CBR: finding structurally similar past decisions
- ML training data export
- Long-term calibration of belief accuracy

Schema: one `reasoning_memory` table with JSON-serialized records. Indexes on `(userId, reasonedAt)` and `(userId, winningActionTypeLabel)`.

---

## 6. Explainability Surface

`ReasoningMemory` enables three user-facing explainability surfaces that `DecisionAudit` cannot provide:

### 6.1 "Why This Recommendation?" Panel

```
── Why Start SIP? ─────────────────────────────────────────────────────────

Your financial engine evaluated 7 options today.

Activated signals:
  ✓ "You have 6.5 months of emergency fund" — above the 6-month safe threshold
  ✓ "Your cash flow surplus is ₹18,000/month" — enough to start a ₹5,000 SIP
  ✓ "Your retirement goal is 34% underfunded" — closing this gap is urgent
  ✗ "High debt ratio detected" — not applicable (your EMI is only 21%)

What the engine considered:
  1. Start SIP                    — chosen    (utility: 0.71)
  2. Maximize Section 80C         — 2nd best  (utility: 0.63)
  3. Increase Emergency Fund      — not applicable (already at 6.5 months)
  4. Accelerate Debt Repayment    — not applicable (EMI ratio is healthy)

Why SIP over 80C?
  Your 80C is 68% utilized (₹1.03L used of ₹1.5L limit). The remaining ₹47,000
  saves ₹14,100 in tax at your slab. But your retirement corpus shortfall of
  ₹42L creates a larger long-term opportunity with SIP compounding at 12%.

Challenge Layer verdict: Start SIP survived all 6 challenges.
  → Liquidity: Emergency fund is adequate. ✓
  → Debt: EMI ratio is 21%, below the 35% threshold. ✓
  → Behavior: Your SIP discipline score is 71. Moderate resistance noted. (-0.04 confidence)
```

This panel is rendered entirely from `ReasoningMemory` without re-running the pipeline.

### 6.2 Counterfactual Stakes (from CounterfactualRecord)

```
If you start today:   ₹2,000/month × 20 years at 12% = ₹1.15 Cr
If you wait 6 months: ₹2,000/month × 19.5 years at 12% = ₹1.06 Cr

Cost of waiting: ₹9L in permanently lost compounding.
```

### 6.3 "What Changed Since Last Time?" (Delta View, Phase 12)

When `ReasoningMemory` records are persisted, the explainability panel can compare today's reasoning against last week's:

```
Since last week:
  ↑ Cash flow improved (salary credit detected) → Start SIP moved from rank 2 → rank 1
  ↓ Behavior confidence fell (-0.06) → SIP acceptance probability reduced 73% → 68%
  Unchanged: Emergency fund, constitution rules, 80C utilization
```

---

## 7. Invariants

**RM-1:** Every `ReasoningMemory.challengeResults` always contains exactly 6 `ChallengeRecord` objects — one per challenge type. This matches the invariant in the Challenge Layer spec.

**RM-2:** `ReasoningMemory.compoundConfidence` equals the product of its four factors: `dataConfidenceFactor × decisionConfidenceFactor × behaviorConfidenceFactor × historicalAccuracyFactor`. Verified in ReasoningMemoryAssembler.

**RM-3:** `ReasoningMemory.winningActionTypeLabel` must appear in `ReasoningMemory.generatedCandidates` (it was generated) and in `ReasoningMemory.constitutionChecks` where `isPermissible == true` (it passed constitution). Verified in assembler.

**RM-4:** If `challengeOverrodeOriginal == true`, then `originalActionTypeLabel != winningActionTypeLabel`. Verified in assembler.

**RM-5:** `utilityBreakdowns.length == permissibleCandidateCount`. Only permissible candidates receive utility scores. Verified in assembler.

**RM-6:** The memory write is async and fire-and-forget. A storage failure must never propagate to the calling use case or surface as a pipeline error. Failures are logged to the diagnostics layer only.

---

## 8. Sprint 11H Deliverables

`ReasoningMemory` is delivered in Sprint 11H alongside `RecommendationPortfolio` and `ConfidenceGraph`. It requires all prior sprint components to be complete because it records the output of every step.

**New files:**
- `mobile/lib/domain/reasoning/memory/reasoning_memory.dart` — all domain types above
- `mobile/lib/domain/reasoning/memory/reasoning_memory_repository.dart` — abstract repository interface
- `mobile/lib/infrastructure/repositories/in_memory_reasoning_memory_repository.dart` — in-memory LRU
- `mobile/lib/infrastructure/engines/reasoning_memory_assembler.dart` — assembles from step outputs

**Updated files:**
- `mobile/lib/infrastructure/engines/recommendation_pipeline.dart` — calls assembler + async write
- `mobile/lib/core/di/injection.dart` — registers `ReasoningMemoryRepository`

**Acceptance criteria:**
- `RM-1` through `RM-6` verified by unit tests
- Memory assembly adds `< 2ms` to pipeline execution (performance test)
- Storage failure does not propagate to `GetDashboardFeedUseCase` return path (error isolation test)
- `ReasoningMemory.pipelineVersion` matches `RecommendationPipeline.version` constant (integration test)
- `flutter analyze`: 0 errors

---

*This document defines `ReasoningMemory` as the full chain-of-reasoning storage layer for the v2 pipeline. It is architecturally distinct from `DecisionAudit` and must not be merged into it. `DecisionAudit` serves event-sourcing; `ReasoningMemory` serves explainability, ML, and regulatory audit. Both coexist on the same decision record.*
