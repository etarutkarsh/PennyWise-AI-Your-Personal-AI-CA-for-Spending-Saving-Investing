# API Contracts

This document is the contract surface between the Flutter app and the Spring Boot backend.
It is a **living record of what the app expects** — not a wishlist. If a field is here, the
backend either implements it today or a `TODO` note explains the Phase in which it will.

Baseline URL: `${API_BASE_URL}/api` (see `mobile/lib/core/constants/api_constants.dart`).
Every non-public endpoint requires a Bearer JWT in `Authorization`.

---

## Decision Endpoints

### `GET /decisions/today`

Returns the single highest-priority decision the engine believes the user should act on today.
This is the source of truth for the "Today's Best Decision" card on the dashboard.

**Request:** no body.

**Response `200 OK`** — `TodayDecisionResponse`:

| Field | Type | Notes |
|---|---|---|
| `decisionId` | string | Stable identifier; may be `local-<timestamp>` when the engine returns an ephemeral suggestion. |
| `priority` | string | `HIGH` / `MEDIUM` / `LOW`. |
| `icon` | string | Single emoji used in the card header. |
| `headline` | string | 4–8 word action-oriented sentence. |
| `subheadline` | string | 1 sentence of context. |
| `reasons` | string[] | Bullet reasons (2–4 items) explaining *why today*. |
| `recommendedAction` | object | `{actionType, instrument, monthlyAmount, timeline}`. |
| `impact` | object | `{healthScoreCurrent, healthScoreAfter, goalSuccessRateCurrent, goalSuccessRateAfter, runwayMonthsAdded}`. |
| `partnerOptions` | object[] | `{partner, rate, feature, minAmount, ctaLabel}`. Ranked, never sorted by commission. |

The mobile client maps this DTO to the domain `DecisionResponse` via `DecisionMapper`
(`mobile/lib/infrastructure/mappers/decision_mapper.dart`). Any field added here must have a
mapping rule in that class.

### `POST /decisions/{decisionId}/lifecycle`

Records that the user reached a lifecycle state for a given decision. Called fire-and-forget
from the mobile client; failures **must not** break the UI.

**Path parameters**

| Name | Type | Notes |
|---|---|---|
| `decisionId` | string | Value from `GET /decisions/today`. |

**Request body** — JSON:

```json
{ "state": "VIEWED" }
```

Allowed states (match `DecisionLifecycleState` in
`mobile/lib/domain/decision/decision.dart`):

- `GENERATED`
- `VIEWED`
- `ACCEPTED`
- `REJECTED`
- `DEFERRED`
- `EXECUTED`
- `OBSERVED`
- `REVIEWED`
- `LEARNED`

**Response `200 OK`** — acknowledgement:

```json
{ "status": "accepted", "decisionId": "...", "state": "VIEWED" }
```

**Phase 1:** the backend logs the event and returns 200. No persistence. This is the seam
for the future Decision Memory Engine — persistence + Digital Twin feedback loop are wired
in a later phase (see `07-decision-lifecycle.md`).

---

## Notes for future writers

- Never add a field to a response without also adding a mapper rule in the mobile
  `infrastructure/mappers/` layer. Presentation code must not read raw DTOs.
- If a new decision or partner surface is introduced, extend the sequence in
  `08-recommendation-flow.md` before implementing.
- Partner-related fields must never surface commission or referral fees — the mobile layer
  enforces `commissionRate == 0.0` as an assert.
