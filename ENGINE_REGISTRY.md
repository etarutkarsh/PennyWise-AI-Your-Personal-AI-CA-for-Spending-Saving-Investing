# PennyWise AI — Engine Registry

**Living catalogue of all reasoning engines.**  
Update this file whenever an engine's interface, version, inputs, outputs, or status changes.  
Every engine must satisfy six invariants: deterministic · replayable · explainable · contract-isolated · versioned · tested.

**Last updated:** 2026-08-06  
**Architecture status:** v2 FROZEN — no new engines without Architecture Change Request (ACR)

---

## How to Read This Registry

| Field | Meaning |
|-------|---------|
| **Interface** | Domain contract (`domain/engines/`) |
| **Implementation** | Concrete class (`infrastructure/engines/`) |
| **Inputs** | What the engine receives |
| **Outputs** | What the engine returns |
| **Version** | Current `engineVersion` string |
| **Dependencies** | Other engines this engine's *output* depends on (not direct calls) |
| **Consumers** | What calls this engine |
| **Deterministic** | Same inputs → always same outputs |
| **Replayable** | Can reproduce past output given stored inputs |
| **Feature Flag** | Runtime on/off switch (if any) |
| **Status** | `active` · `frozen` · `stub` · `planned` |
| **Tests** | Test file location(s) |

---

## Platform Engines (Data + Facts Layer)

---

### 1. FinancialFactBuilder

| Field | Value |
|-------|-------|
| **Interface** | `domain/engines/financial_fact_builder.dart` |
| **Implementation** | `infrastructure/engines/rule_based_financial_fact_builder.dart` |
| **Inputs** | `List<StoredFinancialEvent>`, `FinancialFactGraph` |
| **Outputs** | `FinancialFacts` (income, expenses, surplus, EF months, debt ratio, savings rate, investment ratio, tax efficiency, goal snapshots) |
| **Version** | `fact-builder-rule-v1` |
| **Dependencies** | `FinancialFactGraph` (declarative dependency graph, no computation) |
| **Consumers** | `DataConfidenceEngine`, `HealthScoreEngine`, `FinancialReasoningEngine`, `BehaviorRuntimeEngine` |
| **Deterministic** | ✅ Yes |
| **Replayable** | ✅ Yes — input events are stored; same events → same facts |
| **Feature Flag** | None |
| **Status** | `active` |
| **Tests** | `test/infrastructure/engines/rule_based_financial_fact_builder_test.dart` *(planned)* |

---

### 2. DataConfidenceEngine

| Field | Value |
|-------|-------|
| **Interface** | `domain/engines/data_confidence_engine.dart` |
| **Implementation** | `infrastructure/engines/rule_based_data_confidence_engine.dart` |
| **Inputs** | `List<StoredFinancialEvent>`, source metadata (SMS connected, AA linked) |
| **Outputs** | `DataConfidenceReport` (recommendationConfidenceCap, hasSmsConnected, hasAaConnected, merchantResolutionRate, missingDataGaps) |
| **Version** | `data-confidence-rule-v1` |
| **Dependencies** | None — reads events directly |
| **Consumers** | `FinancialReasoningEngine`, `HealthScoreEngine` |
| **Deterministic** | ✅ Yes |
| **Replayable** | ✅ Yes |
| **Feature Flag** | None |
| **Status** | `active` |
| **Tests** | `test/infrastructure/engines/rule_based_data_confidence_engine_test.dart` *(planned)* |

---

### 3. EvidenceBuilder

| Field | Value |
|-------|-------|
| **Interface** | `domain/engines/evidence_builder.dart` |
| **Implementation** | `infrastructure/engines/financial_facts_evidence_builder.dart` |
| **Inputs** | `FinancialFacts`, `DataConfidenceReport` |
| **Outputs** | `List<EvidenceItem>` (fact → provenance chain for explainability) |
| **Version** | Not yet versioned — `engineVersion` getter missing ⚠️ |
| **Dependencies** | `FinancialFactBuilder` (output) |
| **Consumers** | `HealthScoreEngine` (dimension-level evidence), `ExplainabilityEngine` |
| **Deterministic** | ✅ Yes |
| **Replayable** | ✅ Yes |
| **Feature Flag** | None |
| **Status** | `active` |
| **Tests** | *(none — add in Sprint 11A)* |

---

### 4. MerchantResolver

| Field | Value |
|-------|-------|
| **Interface** | `domain/engines/merchant_resolver.dart` |
| **Implementation** | `infrastructure/engines/learning_aware_merchant_resolver.dart` (wraps `HardcodedMerchantResolver`) |
| **Inputs** | Raw merchant string |
| **Outputs** | `ResolvedMerchant?` (canonical profile, category, confidence) |
| **Version** | Not versioned ⚠️ |
| **Dependencies** | `MerchantLearningQueue` |
| **Consumers** | `TransactionNormalizer` |
| **Deterministic** | ⚠️ Partially — hardcoded resolver is deterministic; LearningQueue state affects output |
| **Replayable** | ⚠️ Partial — requires frozen MerchantLearningQueue state at time of replay |
| **Feature Flag** | None |
| **Status** | `active` |
| **Tests** | *(none)* |

---

## Health Intelligence Engines

---

### 5. HealthScoreEngine

| Field | Value |
|-------|-------|
| **Interface** | `domain/engines/health_score_engine.dart` |
| **Implementation** | `infrastructure/engines/rule_based_health_score_engine.dart` |
| **Inputs** | `FinancialFacts`, `DataConfidenceReport`, `List<EvidenceItem>` |
| **Outputs** | `HealthScoreReport` (overallScore, 10 DimensionScores with trend + evidence + recommendation) |
| **Version** | `rule-based-v1` |
| **Dependencies** | `FinancialFactBuilder` (output), `EvidenceBuilder` (output) |
| **Consumers** | `GetHealthScoreUseCase`, `DecisionKPIEngine`, `ReasoningMemoryAssembler` |
| **Deterministic** | ✅ Yes |
| **Replayable** | ✅ Yes |
| **Feature Flag** | None |
| **Status** | `active` (Sprint 11 upgrade: `BehaviorInterpretation` inputs) |
| **Tests** | `test/infrastructure/engines/rule_based_health_score_engine_test.dart` *(planned)* |

---

### 6. ResilienceEngine

| Field | Value |
|-------|-------|
| **Interface** | `domain/engines/resilience_engine.dart` |
| **Implementation** | `infrastructure/engines/rule_based_resilience_engine.dart` |
| **Inputs** | `FinancialFacts` |
| **Outputs** | `ResilienceIndex` (shockAbsorptionScore, liquidityBuffer, incomeStabilityScore) |
| **Version** | `resilience-rule-v1` |
| **Dependencies** | `FinancialFactBuilder` (output) |
| **Consumers** | `GetResilienceIndexUseCase` |
| **Deterministic** | ✅ Yes |
| **Replayable** | ✅ Yes |
| **Feature Flag** | None |
| **Status** | `active` |
| **Tests** | *(none)* |

---

### 7. FinancialAgeEngine

| Field | Value |
|-------|-------|
| **Interface** | `domain/engines/financial_age_engine.dart` |
| **Implementation** | `infrastructure/engines/rule_based_financial_age_engine.dart` |
| **Inputs** | `FinancialFacts`, chronological age |
| **Outputs** | `FinancialAge` (chronologicalAge, behavioralFinancialAge, delta, interpretation) |
| **Version** | Not versioned ⚠️ |
| **Dependencies** | `FinancialFactBuilder` (output) |
| **Consumers** | `GetFinancialAgeUseCase` |
| **Deterministic** | ✅ Yes |
| **Replayable** | ✅ Yes |
| **Feature Flag** | None |
| **Status** | `active` |
| **Tests** | *(none)* |

---

### 8. MomentumEngine

| Field | Value |
|-------|-------|
| **Interface** | `domain/engines/momentum_engine.dart` |
| **Implementation** | `infrastructure/engines/rule_based_momentum_engine.dart` |
| **Inputs** | `List<HealthScoreSnapshot>` |
| **Outputs** | `MomentumReport` (direction, magnitude, trendLine, interpretation) |
| **Version** | Not versioned ⚠️ |
| **Dependencies** | `HealthScoreEngine` (historical snapshots) |
| **Consumers** | `GetMomentumUseCase` |
| **Deterministic** | ✅ Yes |
| **Replayable** | ✅ Yes — given same snapshot history |
| **Feature Flag** | None |
| **Status** | `active` |
| **Tests** | *(none)* |

---

## Behavioral Intelligence Engines

---

### 9. BehaviorRuntimeEngine

| Field | Value |
|-------|-------|
| **Interface** | None — concrete class only (Sprint 9.2) |
| **Implementation** | `infrastructure/engines/behavior_runtime_engine.dart` |
| **Inputs** | `List<StoredFinancialEvent>` |
| **Outputs** | `EngineExecutionResult<BehaviorRuntimeOutput>` (26 signal readings, rule firings, runtime metrics) |
| **Version** | `9.2` |
| **Dependencies** | `ExtractorRegistry` (26 extractors), `SignalAggregator`, `BehaviorRules` |
| **Consumers** | `RunBehaviorAnalysisUseCase` → `BehaviorInterpretationEngine` |
| **Deterministic** | ✅ Yes |
| **Replayable** | ✅ Yes — same events → same signals |
| **Feature Flag** | None |
| **Status** | `frozen` — v1 frozen 2026-08-05 |
| **Tests** | *(planned — 26 extractor unit tests)* |

---

### 10. BehaviorInterpretationEngine

| Field | Value |
|-------|-------|
| **Interface** | None — concrete class only (Sprint 9.3) |
| **Implementation** | `infrastructure/engines/behavior_interpretation_engine.dart` |
| **Inputs** | `BehaviorRuntimeOutput` (signal readings) |
| **Outputs** | `BehaviorInterpretation` (dimensions, personality, state, intents, overallConfidence) |
| **Version** | `9.3` |
| **Dependencies** | `DimensionMapper`, `ProfileClassifier`, `BehaviorStateEngine`, `IntentEngine` |
| **Consumers** | `RunInterpretationUseCase` → `FinancialReasoningEngine` (as optional input) |
| **Deterministic** | ✅ Yes |
| **Replayable** | ✅ Yes |
| **Feature Flag** | None |
| **Status** | `frozen` — behavioral architecture frozen 2026-08-04 |
| **Tests** | *(planned — dimension mapping + interpretation invariants)* |

---

## Learning Engines

---

### 11. DecisionLearningEngine

| Field | Value |
|-------|-------|
| **Interface** | `domain/engines/decision_learning_engine.dart` |
| **Implementation** | `infrastructure/engines/rule_based_decision_learning_engine.dart` |
| **Inputs** | `DecisionExecution`, `DecisionOutcome` |
| **Outputs** | `LearningResult` (DecisionLesson, BehaviorAdjustment, TwinCalibration, LearningConfidence) |
| **Version** | `learning-rule-v1` |
| **Dependencies** | None — pure computation on execution + outcome pair |
| **Consumers** | `EvaluateOutcomeUseCase`, `DecisionKPIEngine` |
| **Deterministic** | ✅ Yes |
| **Replayable** | ✅ Yes |
| **Feature Flag** | None |
| **Status** | `active` |
| **Tests** | *(none)* |

---

## Partner Intelligence Engines

---

### 12. PartnerMatchingEngine

| Field | Value |
|-------|-------|
| **Interface** | `domain/engines/partner_matching_engine.dart` |
| **Implementation** | `infrastructure/engines/rule_based_partner_matching_engine.dart` |
| **Inputs** | `MatchingContext` (derived from FinancialFacts), `List<PartnerProgram>` |
| **Outputs** | `List<MatchResult>` (ranked by policy score, commission never in ranking) |
| **Version** | `rule-based-v1` |
| **Dependencies** | `MatchingContextBuilder` (output) |
| **Consumers** | `HardcodedPartnerRepository`, `GetPartnerProgramsUseCase` |
| **Deterministic** | ✅ Yes |
| **Replayable** | ✅ Yes |
| **Feature Flag** | None |
| **Status** | `active` |
| **Tests** | *(none)* |

---

## Reasoning Engines (v1 Frozen, v2 In Sprint)

---

### 13. FinancialReasoningEngine v1

| Field | Value |
|-------|-------|
| **Interface** | `domain/engines/financial_reasoning_engine.dart` |
| **Implementation** | `infrastructure/engines/rule_based_financial_reasoning_engine.dart` |
| **Inputs** | `FinancialReasoningContext` (FinancialFacts + DataConfidenceReport + BehaviorInterpretation? + LearningSnapshot? + goals) |
| **Outputs** | `DecisionConfidenceReport` (8 axis results, 4-factor compound confidence, RecommendationStrength) |
| **Version** | `10.0` |
| **Dependencies** | 8 axis analyzers (internal, not separate engines) |
| **Consumers** | `RunFinancialReasoningUseCase` |
| **Deterministic** | ✅ Yes |
| **Replayable** | ✅ Yes |
| **Feature Flag** | None — v2 will introduce `POLICY_AWARE_ENGINE_ENABLED` |
| **Status** | `frozen` — v1 frozen commit b77bc59 (2026-08-05). Do not add heuristics. |
| **Tests** | *(planned — Sprint 11A adds regression baseline)* |

---

### 14. PolicySelector *(Sprint 11A — planned)*

| Field | Value |
|-------|-------|
| **Interface** | `domain/reasoning/policy/policy_selector.dart` *(new)* |
| **Implementation** | `infrastructure/engines/rule_based_policy_selector.dart` *(new)* |
| **Inputs** | `FinancialFacts`, `BehaviorInterpretation?`, `UserArchetype`, `PolicyStateRecord?` |
| **Outputs** | `DecisionPolicy` (AxisWeightProfile, PolicyThresholds, EvolutionRules) |
| **Version** | `policy-rule-v1` *(to be set)* |
| **Dependencies** | `FinancialFactBuilder` (output) |
| **Consumers** | `FinancialReasoningEngine v2` (Step 1) |
| **Deterministic** | ✅ Required |
| **Replayable** | ✅ Required |
| **Feature Flag** | None at Sprint 11A |
| **Status** | `planned` — Sprint 11A |
| **Tests** | 14 policy invariants, weight-sum golden tests, archetype selection tests |

---

### 15. BeliefInferenceEngine *(Sprint 11B — planned)*

| Field | Value |
|-------|-------|
| **Interface** | `domain/engines/belief_inference_engine.dart` *(new)* |
| **Implementation** | `infrastructure/engines/rule_based_belief_inference_engine.dart` *(new)* |
| **Inputs** | `FinancialFacts`, `DecisionPolicy` |
| **Outputs** | `BeliefSet` (34 named beliefs, confidence-tagged, with evidence) |
| **Version** | `belief-rule-v1` *(to be set)* |
| **Dependencies** | `FinancialFactBuilder` (output), `PolicySelector` (output) |
| **Consumers** | `FinancialReasoningEngine v2` (Step 2) |
| **Deterministic** | ✅ Required |
| **Replayable** | ✅ Required |
| **Feature Flag** | Shadow mode: compute but don't consume until Sprint 11C |
| **Status** | `planned` — Sprint 11B |
| **Tests** | 26 rule tests, confidence cap invariant, lifeStage ordering |

---

### 16. CandidateGenerator *(Sprint 11C — planned)*

| Field | Value |
|-------|-------|
| **Interface** | `domain/engines/candidate_generator.dart` *(new)* |
| **Implementation** | `infrastructure/engines/rule_based_candidate_generator.dart` *(new)* |
| **Inputs** | `FinancialReasoningContext`, `BeliefSet` |
| **Outputs** | `CandidateSet` (27 ActionType values, viable + pruned lists, pyramid-sorted) |
| **Version** | `candidate-rule-v1` *(to be set)* |
| **Dependencies** | `BeliefInferenceEngine` (output) |
| **Consumers** | `FinancialReasoningEngine v2` (Step 3) |
| **Deterministic** | ✅ Required |
| **Replayable** | ✅ Required |
| **Feature Flag** | None |
| **Status** | `planned` — Sprint 11C |
| **Tests** | 27 applicability conditions, pyramid invariant, minimum viable set fallback |

---

### 17. ConstitutionEngine *(Sprint 11D — planned)*

| Field | Value |
|-------|-------|
| **Interface** | `domain/engines/constitution_engine.dart` *(new)* |
| **Implementation** | `infrastructure/engines/rule_based_constitution_engine.dart` *(new)* |
| **Inputs** | `CandidateSet`, `FinancialReasoningContext`, `FinancialConstitution?` |
| **Outputs** | `ConstitutionResult` (permissibleCandidates, violations, fallbackTriggered) |
| **Version** | `constitution-rule-v1` *(to be set)* |
| **Dependencies** | `CandidateGenerator` (output) |
| **Consumers** | `FinancialReasoningEngine v2` (Step 4) |
| **Deterministic** | ✅ Required — SYS rules always applied even when constitution is null |
| **Replayable** | ✅ Required |
| **Feature Flag** | None — system rules are always active |
| **Status** | `planned` — Sprint 11D |
| **Tests** | 8 system rule tests, empty-set fallback, null-constitution system-rules-still-apply |

---

### 18. UtilityEngine *(Sprint 11E — planned)*

| Field | Value |
|-------|-------|
| **Interface** | `domain/engines/utility_engine.dart` *(new)* |
| **Implementation** | `infrastructure/engines/rule_based_utility_engine.dart` *(new)* |
| **Inputs** | `List<DecisionCandidate>` (permissible only), `FinancialReasoningContext`, `DecisionPolicy` |
| **Outputs** | `List<UtilityScore>` (netUtility, component breakdown, resistance, narrative — one per candidate) |
| **Version** | `utility-rule-v1` *(to be set)* |
| **Dependencies** | `ConstitutionEngine` (output), `PolicySelector` (output) |
| **Consumers** | `FinancialReasoningEngine v2` (Step 5) |
| **Deterministic** | ✅ Required |
| **Replayable** | ✅ Required |
| **Feature Flag** | `UTILITY_ENGINE_ENABLED` (shadow mode during 11E) |
| **Status** | `planned` — Sprint 11E |
| **Tests** | Worked example golden test, archetype differentiation, netUtility bounds |

---

### 19. CounterfactualEngine *(Sprint 11F — planned)*

| Field | Value |
|-------|-------|
| **Interface** | `domain/engines/counterfactual_engine.dart` *(extends SimulationEngine)* |
| **Implementation** | `infrastructure/engines/simulation/deterministic_counterfactual_engine.dart` *(new)* |
| **Inputs** | Top-3 `DecisionCandidate` list, `FinancialReasoningContext` |
| **Outputs** | `CounterfactualSet` per candidate (action/delay/magnitude/shock/commitment scenarios + narrations) |
| **Version** | `counterfactual-deterministic-v1` *(to be set)* |
| **Dependencies** | `UtilityEngine` (output ranking), `GoalImpactAnalyzer` (adapter) |
| **Consumers** | `FinancialReasoningEngine v2` (Step 6) |
| **Deterministic** | ✅ Required — no Monte Carlo until Phase 11 |
| **Replayable** | ✅ Required |
| **Feature Flag** | None |
| **Status** | `planned` — Sprint 11F |
| **Tests** | 7 golden SIP FV tests, narration template completeness, < 50ms perf |

---

### 20. ChallengeLayerEngine *(Sprint 11G — planned)*

| Field | Value |
|-------|-------|
| **Interface** | `domain/engines/challenge_layer_engine.dart` *(new)* |
| **Implementation** | `infrastructure/engines/rule_based_challenge_layer_engine.dart` *(new)* |
| **Inputs** | Top-ranked `DecisionCandidate`, `FinancialReasoningContext`, all `UtilityScore` results |
| **Outputs** | `ChallengeLayerResult` (always exactly 6 `ChallengeResult` objects) |
| **Version** | `challenge-rule-v1` *(to be set)* |
| **Dependencies** | `UtilityEngine` (output), `CounterfactualEngine` (output) |
| **Consumers** | `FinancialReasoningEngine v2` (Step 7) |
| **Deterministic** | ✅ Required |
| **Replayable** | ✅ Required |
| **Feature Flag** | `EngineFlag.challengeLayerEnabled` (default: false at 11G) |
| **Status** | `planned` — Sprint 11G |
| **Tests** | 6 challenge unit tests, Liquidity priority invariant, override audit |

---

### 21. ReasoningMemoryAssembler *(Sprint 11H — planned)*

| Field | Value |
|-------|-------|
| **Interface** | None — assembler (not an engine) |
| **Implementation** | `infrastructure/engines/reasoning_memory_assembler.dart` *(new)* |
| **Inputs** | Outputs of all 7 pipeline steps |
| **Outputs** | `ReasoningMemory` (written async via `ReasoningMemoryRepository`) |
| **Version** | `memory-assembler-v1` *(to be set)* |
| **Dependencies** | All prior pipeline steps (data-only, no calls) |
| **Consumers** | `RecommendationPipeline` (fire-and-forget side-output), `ExplainabilityEngine`, `DecisionKPIEngine` |
| **Deterministic** | ✅ Yes — assembly from deterministic inputs |
| **Replayable** | N/A — is the replay source, not a replayer |
| **Feature Flag** | None — always writes |
| **Status** | `planned` — Sprint 11H |
| **Tests** | RM-1 through RM-6 invariants, storage failure isolation |

---

### 22. DecisionKPIEngine *(Sprint 11H — planned)*

| Field | Value |
|-------|-------|
| **Interface** | `domain/engines/decision_kpi_engine.dart` *(new)* |
| **Implementation** | `infrastructure/engines/rule_based_decision_kpi_engine.dart` *(new)* |
| **Inputs** | `List<ReasoningMemory>`, `List<DecisionOutcome>`, `List<HealthScoreSnapshot>`, `KPIWindow` |
| **Outputs** | `DecisionKPIs` (5 categories, 20+ metrics, engine health grade A–F) |
| **Version** | `kpi-rule-v1` *(to be set)* |
| **Dependencies** | `ReasoningMemoryRepository` (read), `DecisionLearningEngine` (outcome records) |
| **Consumers** | `GetDecisionKPIsUseCase` (engineering monitoring, not user-facing in Sprint 11H) |
| **Deterministic** | ✅ Yes — given same memory + outcome records |
| **Replayable** | ✅ Yes |
| **Feature Flag** | None |
| **Status** | `planned` — Sprint 11H |
| **Tests** | Grade F dominance, calibration error computation, < 100ms perf for 500 records |

---

## Commitment Intelligence Engine

---

### 23. RecurringCommitmentsIntelligenceEngine

| Field | Value |
|-------|-------|
| **Interface** | None — concrete class |
| **Implementation** | `infrastructure/engines/commitments/recurring_commitments_intelligence_engine.dart` |
| **Inputs** | `List<StoredFinancialEvent>` |
| **Outputs** | `CommitmentIntelligenceResult` (detected recurring commitments, GoalImpactAnalysis, total exposure) |
| **Version** | Not versioned ⚠️ |
| **Dependencies** | 11 internal analyzers (GoalImpactAnalyzer, RecurringPatternDetector, etc.) |
| **Consumers** | `RunCommitmentIntelligenceUseCase`, Dashboard `_CommitmentsCard` |
| **Deterministic** | ✅ Yes |
| **Replayable** | ✅ Yes |
| **Feature Flag** | None |
| **Status** | `frozen` — v1 frozen 2026-08-05 |
| **Tests** | *(none)* |

---

## Version Debt (⚠️ Missing `engineVersion` — fix in Sprint 11A)

The following engines lack `engineVersion` on their interface or implementation. Add before Sprint 11A work touches these files:

| Engine | File | Action |
|--------|------|--------|
| `EvidenceBuilder` | `domain/engines/evidence_builder.dart` | Add `String get engineVersion` to interface |
| `MerchantResolver` | `domain/engines/merchant_resolver.dart` | Add `String get engineVersion` to interface |
| `FinancialAgeEngine` | `domain/engines/financial_age_engine.dart` | Add `String get engineVersion` to interface |
| `MomentumEngine` | `domain/engines/momentum_engine.dart` | Add `String get engineVersion` to interface |
| `RecurringCommitmentsIntelligenceEngine` | `infrastructure/engines/commitments/...` | Add `engineVersion` field |

---

## Engine Communication Rules

```
✅ Allowed:
  Engine A produces Output A (value object)
  Output A passed as parameter to Engine B
  Engine B produces Output B
  → Communication through data contracts

❌ Forbidden:
  Engine A calls Engine B.method() directly
  Engine A imports Engine B's implementation class
  Engine A has a reference to Engine B instance
  → Cross-engine coupling, breaks replay and isolation
```

The pipeline orchestrator (`RecommendationPipeline`) is the only component that holds references to multiple engines. It calls them sequentially and passes outputs as inputs.

---

## Status Legend

| Status | Meaning |
|--------|---------|
| `active` | Built, in production DI, in use |
| `frozen` | Built and locked — no new heuristics or structural changes |
| `stub` | Built but returns hardcoded/placeholder output |
| `planned` | Specified in architecture doc, not yet implemented |

---

*This registry is the ground truth for engine status. If an engine exists in code but not in this registry, add it. If an entry disagrees with the code, the code is authoritative — update this registry.*
