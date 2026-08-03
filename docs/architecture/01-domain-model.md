# PennyWise Domain Model — Bounded Context Overview

## The 8 Bounded Contexts

```
┌──────────────────────────────────────────────────────────────────────┐
│                         PennyWise Platform                           │
│                                                                      │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────────────────┐ │
│  │   Decision   │──▶│  Behavioral  │──▶│      Financial Twin      │ │
│  │  (Aggregate) │   │   Profile    │   │    (Digital Twin stub)   │ │
│  └──────────────┘   └──────────────┘   └──────────────────────────┘ │
│         │                  │                        │                │
│         ▼                  ▼                        ▼                │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────────────────┐ │
│  │   Partner    │   │   Finance    │   │        Knowledge         │ │
│  │  Matching    │   │ (HealthScore,│   │  (Lessons, LearningPath) │ │
│  │  Engine      │   │  GoalSummary)│   └──────────────────────────┘ │
│  └──────────────┘   └──────────────┘                                │
│         │                                                            │
│  ┌──────────────┐   ┌──────────────────────────────────────────────┐ │
│  │  Platform    │   │                 Domain Events                │ │
│  │ (EngineFlags │   │  (16 event classes covering all lifecycle    │ │
│  │  FeatureFlags│   │   transitions and observations)              │ │
│  └──────────────┘   └──────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────┘
```

### Bounded Context Descriptions

| Context | Directory | Purpose |
|---------|-----------|---------|
| **Decision** | `domain/decision/` | Aggregate root. Generates, tracks, and closes the loop on financial recommendations. |
| **Behavioral** | `domain/behavioral/` | BehavioralVector (θ_user), habits, personality, BehaviorProfile. |
| **Financial Twin** | `domain/twin/` | Digital Twin stub — calibrated BehavioralVector + state history. |
| **Finance** | `domain/finance/` | FinancialState (Survive/Stabilize/Build/Optimize), HealthScore, SIPCalculation. |
| **Partner** | `domain/partner/` | FinancialInstrument, PartnerProgram, RankedPartnerProgram. |
| **Knowledge** | `domain/knowledge/` | Lessons, LearningPaths, BehavioralInterventions. |
| **Platform** | `domain/platform/` | EngineFlag, FeatureFlag, PennyWiseFeatureFlags defaults. |
| **Events** | `domain/events/` | 16 domain events covering all lifecycle transitions. |

---

## The Decision Aggregate Root

`domain/decision/decision.dart` — `Decision`

The Decision is the central aggregate. Every financial recommendation is a Decision containing:

- **Recommendation** — what action to take, how much, via which instrument
- **Explanation** — headline, evidence, alternatives, tradeoffs, engine trace
- **GoalImpact[]** — projected effect on each active goal
- **BehavioralContext** — behavioral parameters at decision time
- **TrustMetadata** — provenance, data freshness, fiduciary statement
- **DecisionAudit** — event-sourcing trail, engine contributions
- **DecisionLifecycleState** — Generated → Viewed → Accepted → ... → Learned

The **DecisionResponse** envelope (`decision_response.dart`) wraps a Decision with:
- `List<RankedPartnerProgram>` — execution options (never ranked by commission)
- `List<NextAction>` — CTA actions for the UI

---

## Bounded Context Map

```
Decision ──uses──▶ BehavioralContext (flattened from Behavioral)
Decision ──uses──▶ Finance (FinancialState, GoalSummary via GoalRepository)
Decision ──emits──▶ Events (DecisionGeneratedEvent, DecisionViewedEvent, ...)

Behavioral ──calibrates──▶ FinancialTwin (BehavioralVector updates)
Behavioral ──informs──▶ Knowledge (FinancialPersonality → LearningPath)

Partner ──ranked by──▶ PartnerMatchingEngine (not built)
Partner ──serves──▶ DecisionResponse (execution options)

Platform ──gates──▶ All engines via PennyWiseFeatureFlags.isEnabled()
```

---

## Key Domain Files

| Concept | File |
|---------|------|
| Decision aggregate | `domain/decision/decision.dart` |
| DecisionResponse envelope | `domain/decision/decision_response.dart` |
| DecisionFeed | `domain/decision/decision_feed.dart` |
| BehavioralVector (θ_user) | `domain/behavioral/behavioral_vector.dart` |
| FinancialState | `domain/finance/financial_state.dart` |
| HealthScore | `domain/finance/health_score.dart` |
| PartnerProgram | `domain/partner/partner_program.dart` |
| All domain events | `domain/events/domain_events.dart` |
| EngineFlag registry | `domain/platform/engine_flags.dart` |
| Feature flag defaults | `domain/platform/feature_flags.dart` |
