# Decision Lifecycle

## Overview

Every financial recommendation in PennyWise is a `Decision` object that travels through a defined lifecycle. This lifecycle closes the Decision Memory Loop: the outcome of every decision feeds back into the Behavioral Engine, recalibrating the Digital Twin and improving future recommendations.

**Source:** `mobile/lib/domain/decision/decision.dart` — `DecisionLifecycleState`

---

## Lifecycle States

```
                   ┌──────────────────────────────────────────────────────┐
                   │                  Decision Memory Loop                 │
                   │                                                        │
 [Decision Engine] │                                                        │
        │          │                                                        │
        ▼          │                                                        │
   GENERATED ──────┤──▶ VIEWED ──▶ ACCEPTED ──▶ EXECUTED ──▶ OBSERVED ──▶ REVIEWED ──▶ LEARNED
                   │                   │
                   │               REJECTED
                   │               DEFERRED
                   └──────────────────────────────────────────────────────┘
```

---

## State-by-State Guide

### `generated`
**What happened:** The Decision Engine computed a recommendation.  
**Domain event:** `DecisionGeneratedEvent` (includes `engineVersion`, `decisionType`)  
**AAR purpose:** Record what data was available, which engines ran, what was missing.  
**File:** `domain/events/domain_events.dart`

---

### `viewed`
**What happened:** The user saw the Decision card in the feed.  
**Domain event:** `DecisionViewedEvent`  
**AAR purpose:** Track view-to-action conversion. If a decision is viewed but never acted on, surface a follow-up nudge.

---

### `accepted`
**What happened:** User tapped "Accept" or "Start SIP".  
**Domain event:** `DecisionAcceptedEvent` (includes `channelUsed`)  
**AAR purpose:** Record which channel they used (in-app, partner deeplink). Acceptance without execution is a behavioral signal — the user agreed but didn't follow through.

---

### `rejected`
**What happened:** User explicitly rejected the recommendation.  
**Domain event:** `DecisionRejectedEvent` (optional `reason`)  
**AAR purpose:** The rejection reason (if provided) is a calibration signal for the Behavioral Engine. "Too much money" → lower monthly SIP. "Not the right time" → surface again in 30 days.

---

### `deferred`
**What happened:** User asked to be reminded later.  
**AAR purpose:** Track deferral count. Three deferrals = the decision is wrong for this user right now. Escalate or replace it.

---

### `executed`
**What happened:** User confirmed they carried out the action (started the SIP, opened the RD).  
**Domain event:** `DecisionExecutedEvent` (optional `evidenceNote`)  
**AAR purpose:** T=0 baseline. What was the financial state at execution? This becomes the comparison point for `observed`.

---

### `observed`
**What happened:** Time has passed since execution. The system observed the outcome (SIP still running, goal progress updated).  
**AAR purpose:** Did the predicted outcome match reality? Compute the `decisionExpectationVariance`.

---

### `reviewed`
**What happened:** After-Action Review (AAR) completed — expected vs. actual outcome compared.  
**Domain event:** `DecisionReviewedEvent` (includes `decisionExpectationVariance`)  
**AAR purpose:** This is the core of the memory loop. A positive variance means the recommendation was better than predicted. A negative variance means the model needs calibration. Feed the variance into the Behavioral Engine.

---

### `learned`
**What happened:** The lesson from this Decision has been written back into the Digital Twin.  
**Domain event:** `DecisionLearnedEvent` (includes the extracted `lesson` string)  
**AAR purpose:** Closes the loop. The Twin is now more accurate for this user. The next Decision Engine run will have better inputs.

---

## The AAR (After-Action Review) Design Principle

The AAR is not a feedback form. It is:

1. **Automatic observation** — the system monitors whether the SIP started, whether the emergency fund grew, whether the goal is on track
2. **Variance computation** — `projectedHealthScore` vs. `actualHealthScore` after N months
3. **Signal extraction** — what did we learn? Was the recommendation too aggressive? Too conservative?
4. **Twin calibration** — the lesson is written back to `BehavioralVector` via `TwinCalibratedEvent`

This mirrors the Decision Memory Loop described in the research file: **Recommended → Accepted → Executed → Observed → Reviewed → Learned → [next Decision is smarter]**.

---

## Implementation Status

| State | Backend | Mobile | Event Emitted |
|-------|---------|--------|---------------|
| generated | ❌ Not built | ❌ Not built | Domain class defined |
| viewed | ❌ | ❌ | Domain class defined |
| accepted | ❌ | ❌ | Domain class defined |
| rejected | ❌ | ❌ | Domain class defined |
| deferred | ❌ | ❌ | — |
| executed | ❌ | ❌ | Domain class defined |
| observed | ❌ | ❌ | — |
| reviewed | ❌ | ❌ | Domain class defined |
| learned | ❌ | ❌ | Domain class defined |

**Phase 1 minimum viable lifecycle:** generated → viewed → accepted/rejected

**Reference files:**
- `mobile/lib/domain/decision/decision.dart` — `DecisionLifecycleState` enum
- `mobile/lib/domain/decision/repositories/decision_repository.dart` — `recordLifecycleEvent()`
- `mobile/lib/domain/events/domain_events.dart` — all lifecycle event classes
