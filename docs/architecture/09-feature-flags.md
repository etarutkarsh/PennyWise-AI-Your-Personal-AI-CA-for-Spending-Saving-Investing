# PennyWise Feature Flags

**Source:** `mobile/lib/domain/platform/engine_flags.dart` and `feature_flags.dart`

Every engine and capability in PennyWise is gated by an `EngineFlag`. The flags registry is the canonical source of truth for what is built, what is stubbed, and what is on the roadmap.

---

## Flag Registry

| EngineFlag | Status | Rollout Tier | What It Unlocks When Enabled |
|---|---|---|---|
| `decisionEngineV1` | **Built — in use** | production | Rule-based affordability/decision logic. Today's backend AffordabilityEngine is V1. |
| `smsIntelligence` | **Partial** | beta | Basic SMS parser. Needs NACH/ECS/UPI AutoPay rail detection and background listener. |
| `decisionEngineV2` | Not built (Tier 3) | experimental | Multi-axis decision matrix: Goal Impact, Monte Carlo, Stress Test, Opportunity Cost, Behavioral Framing, Commitment Logic. |
| `behavioralEngine` | Not built (Tier 5) | experimental | Calibrates BehavioralVector from observed transactions. Enables habit detection, personality classification, personalized framing. |
| `digitalTwin` | Stub — not calibrated | experimental | FinancialTwin with BehavioralVector history. Currently returns `BehavioralVector.uncalibrated`. |
| `partnerMatchingEngine` | Not built | experimental | Ranks PartnerPrograms by fit. Commission is never a signal (fiduciary invariant). |
| `knowledgeGraph` | Not built | experimental | Graphify-style financial knowledge graph. Provides richer user context to the Decision Engine. |
| `healthEngineV2` | Not built (Tier 2) | experimental | 10-dimension HealthScore (replaces the hardcoded 82). Dimensions: liquidity, debtQuality, savingsConsistency, goalFunding, insuranceCoverage, investmentDiversification, behavioralConsistency, incomeStability, financialAnxiety, taxEfficiency. |
| `accountAggregator` | Not built | experimental | Setu SDK RBI Account Aggregator integration — unlocks 12–24 months of bank history passively. |
| `stepUpSipFormula` | Not built (Tier 3) | experimental | Anti-Linear-Bias Step-Up SIP formula. Computes m0 (initial SIP) from target/horizon/stepUpRate. |
| `monteCarlo` | Not built | experimental | Monte Carlo simulation for SIP projections. Adds `monteCarlo85` (85th-percentile FV) to SIPCalculation. |
| `explainability` | Not built | experimental | ExplainabilityEngine generates full Explanation objects with evidence, alternatives, engine trace. |
| `eventSourcing` | Not built | experimental | All DecisionAudit entries become replayable. Enables full Decision Memory Loop audit. |
| `subscriptionIntelligence` | Not built | experimental | Detects forgotten, duplicate, price-increased subscriptions from SMS and AA data. Emits SubscriptionDetectedEvent. |
| `academyAi` | Not built | experimental | AI-generated contextual lessons triggered by LessonTrigger events. Replaces static lesson catalog. |

---

## Current Production Defaults

```dart
// from PennyWiseFeatureFlags.defaults
{
  EngineFlag.decisionEngineV1: true,   // ✅ in use
  EngineFlag.smsIntelligence: true,    // ✅ partial
  // all others: false
}
```

---

## Build Order for Enabling Flags

Follow the canonical build order from `project_build_order_and_maturity.md`:

```
Tier 0 (now):        decisionEngineV1 ✅, smsIntelligence ✅ (partial)
Tier 1 (SMS/AA):     smsIntelligence (complete), accountAggregator
Tier 2 (Health):     healthEngineV2
Tier 3 (Decision):   decisionEngineV2, stepUpSipFormula, monteCarlo
Tier 4 (Memory):     eventSourcing, explainability, reviewPastDecision flow
Tier 5 (Behavioral): behavioralEngine, digitalTwin, partnerMatchingEngine
Tier 6 (Academy):    academyAi, knowledgeGraph, subscriptionIntelligence
```

---

## How to Check a Flag

```dart
import 'package:pennywise_ai/domain/platform/feature_flags.dart';
import 'package:pennywise_ai/domain/platform/engine_flags.dart';

if (PennyWiseFeatureFlags.isEnabled(EngineFlag.decisionEngineV2)) {
  // run multi-axis engine
} else {
  // fall back to V1
}
```

---

## Fiduciary Invariant

`EngineFlag.partnerMatchingEngine` will never use `commissionRate` as a ranking signal. This is enforced at the domain level: `PartnerProgram.commissionRate` is always `0.0` with an assertion that throws if violated.
