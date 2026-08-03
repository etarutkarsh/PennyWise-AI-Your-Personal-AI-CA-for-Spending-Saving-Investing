# PennyWise — Formal Domain-Driven Design Specification

> **Status:** Authoritative architecture reference. Updated post-Sprint 4 (2026-08-03).  
> **Purpose:** Blueprint for all future sprints. Read before designing any new aggregate, service, event, or API.  
> **Scope:** 10 bounded contexts, all aggregates with invariants, state machines, sagas, ownership matrix, context map.

---

## Table of Contents

1. [Core Principle](#core-principle)  
2. [Context Map](#context-map)  
3. [Bounded Contexts](#bounded-contexts)  
   - 1. Decision (Core Domain)  
   - 2. Finance (Supporting)  
   - 3. Behavioral (Supporting)  
   - 4. Partner (Supporting)  
   - 5. Digital Twin (Generic Subdomain)  
   - 6. Knowledge Graph (Generic Subdomain)  
   - 7. Financial Data Platform (Foundation)  
   - 8. Financial Event Store (Infrastructure)  
   - 9. Knowledge (Generic Subdomain)  
   - 10. Platform (Cross-cutting)  
4. [Cross-Cutting Services](#cross-cutting-services)  
5. [Sagas and Process Managers](#sagas-and-process-managers)  
6. [State Machines](#state-machines)  
7. [Specification Pattern](#specification-pattern)  
8. [Ownership Boundaries](#ownership-boundaries)  
9. [Architecture Decision Records](#architecture-decision-records)  

---

## Core Principle

**PennyWise is a Decision Platform, not a recommendation engine.**

Every output — recommendation, partner program, behavioral insight, health score, alert — is a consequence of a `Decision`. `Decision` is the aggregate root. Every other context either feeds into decisions or is derived from them.

The long-term vision: a Financial Digital Twin that knows the user so well it can autonomously recommend, and eventually execute, the optimal financial action at the optimal moment.

---

## Context Map

Formal upstream/downstream relationships between all bounded contexts.

```
                    ┌─────────────────────────────────┐
                    │    Financial Data Platform      │
                    │  (SMS → AA → Email → OCR →      │
                    │   Manual → Merchant Graph)      │
                    └──────────────┬──────────────────┘
                                   │ publishes DomainEvents
                                   ▼
                    ┌─────────────────────────────────┐
                    │     Financial Event Store       │  ← append-only, immutable
                    └──┬──────────────────────────────┘
                       │ events consumed by all contexts
          ┌────────────┼────────────┬──────────────────────┐
          ▼            ▼            ▼                      ▼
  ┌──────────────┐  ┌──────────┐  ┌────────────────┐  ┌──────────────┐
  │  Knowledge   │  │ Finance  │  │   Behavioral   │  │  Decision    │
  │    Graph     │  │ Context  │  │   Context      │  │  (Core)      │
  │ (entity rel) │  │ (Health  │  │ (BehaviorProf) │  │              │
  │              │  │  Score,  │  │                │  │              │
  └──────┬───────┘  │  Goals)  │  └───────┬────────┘  └──────┬───────┘
         │          └──────────┘          │                   │
         │                                ▼                   │
         │                       ┌────────────────┐          │
         └──────────────────────▶│ Digital Twin   │◀─────────┘
                                 │ (θ calibration)│
                                 └────────────────┘

  ┌──────────────┐     queried by     ┌──────────────┐
  │   Partner    │◀────────────────── │   Decision   │
  │   Context    │                    │   (Core)     │
  └──────────────┘                    └──────────────┘

  ┌──────────────────────────────────────────────────┐
  │              Evidence Builder                    │
  │  (cross-cutting service — reads all contexts,    │
  │   assembles Evidence[] for Explanation)          │
  └──────────────────────────────────────────────────┘

  ┌──────────────────────────────────────────────────┐
  │              Platform Context                    │
  │  (feature flags, engine registry, rollout)       │
  └──────────────────────────────────────────────────┘
```

### Relationship Types

| Upstream | Downstream | Relationship | Anti-Corruption Layer |
|----------|-----------|--------------|----------------------|
| Financial Data Platform | Financial Event Store | Published Language | IngestionEventTranslator |
| Financial Event Store | Knowledge Graph | Event subscriber | GraphUpdateProjector |
| Financial Event Store | Finance Context | Event subscriber | HealthScoreProjector |
| Financial Event Store | Behavioral Context | Event subscriber | BehaviorPatternDetector |
| Financial Event Store | Decision Context | Event subscriber | DecisionFeedProjector |
| Knowledge Graph | Decision Context | Query API | GraphQueryAdapter |
| Behavioral Context | Decision Context | Read model | BehavioralContextAssembler |
| Finance Context | Decision Context | Read model | FinancialStateAssembler |
| Partner Context | Decision Context | Query API | PartnerMatchingAdapter |
| Decision Context | Digital Twin | Domain events | TwinUpdateSaga |
| Platform Context | All Contexts | Synchronous check | FeatureFlagService.isEnabled() |

---

## Bounded Contexts

---

### Context 1: Decision — Core Domain

The most important context. Every other context serves this one.

#### Aggregate: `Decision`

**Aggregate Root. Controls the recommendation lifecycle end-to-end.**

```
Identity:        DecisionId (ULID)
Correlation:     CorrelationId (UUID — same across all decisions in a user session)
Session:         SessionId (UUID — user session)
Event Handle:    EventId (ULID — for event store replay)

userId:          UserId
type:            DecisionType
priority:        Priority (HIGH / MEDIUM / LOW)
financialState:  FinancialState (SURVIVE / STABILIZE / BUILD / OPTIMIZE)
generatedAt:     Instant
expiresAt:       Instant (invariant: generatedAt < expiresAt ≤ generatedAt + 72h)
engineVersion:   String

recommendation:  Recommendation         (value object)
explanation:     Explanation            (value object)
confidence:      Confidence             (value object)
goalImpacts:     List<GoalImpact>       (value objects)
behavioralCtx:   BehavioralContext      (value object, snapshot at generation time)
partnerPrograms: List<RankedPartnerProgram>
nextActions:     List<NextAction>
trust:           TrustMetadata
audit:           DecisionAudit
lifecycleState:  DecisionLifecycleState
```

**Invariants:**
1. `expiresAt` must satisfy: `generatedAt < expiresAt ≤ generatedAt + 72h`
2. `trust.commissionConflict` must always be `false`
3. All items in `partnerPrograms` must have `commissionRate == 0.0`
4. `lifecycleState` can only advance forward (no regression)
5. Once `LEARNED`, the aggregate is sealed (no further state changes)
6. `engineVersion` in `audit.engineTrace` must match the version that produced `explanation`

#### DecisionType (enum — 10 types)

```
buildEmergencyFund   → Priority 1 (SURVIVE/STABILIZE)
getInsurance         → Priority 2 (SURVIVE)
reduceDebt           → Priority 3 (STABILIZE)
increaseSavingsRate  → Priority 4 (STABILIZE/BUILD)
startGoalSip         → Priority 5 (BUILD)
stepUpSip            → Priority 6 (BUILD)
optimizeTax          → Priority 7 (BUILD/OPTIMIZE)
optimizeSubscription → Priority 8 (OPTIMIZE)
rebalancePortfolio   → Priority 9 (OPTIMIZE)
reviewPastDecision   → Priority 10 (any state — triggered by memory loop)
```

#### DecisionLifecycleState (state machine — see §6)

```
GENERATED → VIEWED → ACCEPTED → EXECUTED → OBSERVED → REVIEWED → LEARNED
                   ↘ REJECTED
                   ↘ DEFERRED → VIEWED (when re-surfaced)
```

#### Value Object: `Explanation`

```
headline:           String (≤ 80 chars)
summary:            String (2–3 sentences)
because:            List<String>    (why this was recommended)
evidence:           List<EvidenceItem>
assumptions:        List<String>    (what the engine assumed)
alternatives:       List<AlternativeAction>
whyNot:             List<String>    (why alternatives were ranked lower)
tradeoffs:          List<TradeoffItem>
confidenceDrivers:  List<String>
limitations:        List<String>    (data gaps)
engineTrace:        List<String>    (which engines contributed)
```

#### Value Object: `EvidenceItem`

```
label:      String   ("Emergency fund coverage")
value:      String   ("2.1 months")
source:     DataSource (TRANSACTION_HISTORY | AA_DATA | GOAL_DATA | MANUAL | BEHAVIORAL)
freshness:  Instant  (when this data point was last updated)
```

**Invariant:** `freshness` must be ≤ now. Stale evidence (> 7 days) reduces `Confidence.score`.

#### Value Object: `Confidence`

```
score:               Double 0.0–1.0
tier:                ConfidenceTier (HIGH ≥ 0.80 / MEDIUM ≥ 0.60 / LOW < 0.60)
dataCompleteness:    Double (fraction of ideal evidence we have)
missingDataPenalty:  Double (how much was docked for missing inputs)
evidenceCount:       Int
```

**Invariant:** `score = f(dataCompleteness, evidenceCount) - missingDataPenalty`. Never hardcoded.

#### Value Object: `Recommendation`

```
id:            RecommendationId (ULID)
action:        RecommendedAction (START_SIP | START_RD | INCREASE_SIP | PAY_DEBT | ...)
monthlyAmount: Money
instrument:    FinancialInstrument
horizon:       TimeHorizon
stepUpRate:    Double? (% annual, for SIP step-up)
M0:            Money? (initial SIP using SIP formula — never linear math)
```

**Invariant:** When `action = START_SIP` or `INCREASE_SIP`, `M0` must be computed using the compound SIP formula, not `outstanding / months`.

#### Repository: `DecisionRepository`

```dart
abstract class DecisionRepository {
  Future<Result<DecisionResponse>> getTodaysDecision();
  Future<Result<DecisionResponse>> getById(DecisionId id);
  Future<Result<List<DecisionResponse>>> getHistory({int limit, int offset});
  Future<Result<void>> recordLifecycle(DecisionId id, DecisionLifecycleState state);
  Future<Result<DecisionFeed>> getFeed({int limit});
}
```

#### Domain Events

```
DecisionGeneratedEvent  { decisionId, userId, type, engineVersion, generatedAt }
DecisionViewedEvent     { decisionId, userId, viewedAt, surface }
DecisionAcceptedEvent   { decisionId, userId, acceptedAt, channelUsed }
DecisionRejectedEvent   { decisionId, userId, rejectedAt, reason }
DecisionDeferredEvent   { decisionId, userId, deferredAt, deferUntil }
DecisionExecutedEvent   { decisionId, userId, executedAt, evidenceUrl }
DecisionObservedEvent   { decisionId, userId, observedAt, outcomeMetric, outcomeDelta }
DecisionReviewedEvent   { decisionId, userId, reviewedAt, dev, deviationType }
DecisionLearnedEvent    { decisionId, userId, learnedAt, lesson, twinParametersUpdated }
```

---

### Context 2: Finance — Supporting Domain

#### Aggregate: `Goal`

```
Identity:            GoalId (ULID)
userId:              UserId
name:                String
targetAmount:        Money
savedAmount:         Money     (invariant: savedAmount ≤ targetAmount)
monthlyContribution: Money     (invariant: > 0 when status = ACTIVE)
deadline:            LocalDate (invariant: deadline > createdAt)
status:              GoalStatus
category:            GoalCategory (EMERGENCY_FUND | EDUCATION | TRAVEL | RETIREMENT | CUSTOM)
createdAt:           Instant
lastUpdated:         Instant
```

**Invariants:**
1. `savedAmount ≤ targetAmount` — excess contributions go to overflow pool (future)
2. `monthlyContribution > 0` when `status = ACTIVE`
3. `deadline` must be in the future at time of creation
4. Cannot transition from `COMPLETED` back to `ACTIVE`

#### Computed Value: `HealthScore`

**Never stored. Always derived on request.** Stored only as a time-series snapshot.

```
overallScore:  Int 0–100
dimensions:    Map<HealthDimension, DimensionScore>
computedAt:    Instant
engineVersion: String
```

**10 Dimensions (Tier 2 build — each scored 0–100 independently):**

| # | Dimension | Data Required | Today's Status |
|---|-----------|--------------|---------------|
| 1 | LIQUIDITY | emergencyFundMonths (from goals + transactions) | Partial |
| 2 | DEBT_QUALITY | EMI/income ratio (from commitments) | Partial |
| 3 | SAVINGS_CONSISTENCY | monthly savings rate (from transactions) | Partial |
| 4 | GOAL_FUNDING | activeGoals + contributions | Available |
| 5 | INSURANCE_COVERAGE | insurance data (not collected) | Missing |
| 6 | INVESTMENT_DIVERSIFICATION | portfolio breakdown (not collected) | Missing |
| 7 | BEHAVIORAL_CONSISTENCY | SIP adherence, budget breach rate | Future |
| 8 | INCOME_STABILITY | income variance (from transactions) | Partial |
| 9 | FINANCIAL_ANXIETY | FAM metric (from behavioral patterns) | Future |
| 10 | TAX_EFFICIENCY | 80C utilization, regime | Partial |

#### Domain Events

```
GoalCreatedEvent        { goalId, userId, targetAmount, deadline }
GoalUpdatedEvent        { goalId, updatedFields }
GoalFundedEvent         { goalId, contributionAmount, newSavedAmount }
GoalCompletedEvent      { goalId, completedAt, finalAmount }
GoalAbandonedEvent      { goalId, abandonedAt, progressPct }
HealthScoreChangedEvent { userId, previousScore, newScore, dimensionDeltas, trigger }
```

---

### Context 3: Behavioral — Supporting Domain

#### Aggregate: `BehaviorProfile`

```
Identity:              BehaviorProfileId (userId-based, one per user)
userId:                UserId
vector:                BehavioralVector
detectedHabits:        List<Habit>
financialPersonality:  FinancialPersonality
lastCalibrated:        Instant
calibrationVersion:    String (semver — increments on every recalibration)
calibrationState:      CalibrationState
```

**Invariants:**
1. `vector` values must be within defined ranges (see BehavioralVector below)
2. `lastCalibrated ≤ now` always
3. `calibrationVersion` must increment monotonically
4. `financialPersonality` is derived from `vector` — never set directly

#### Value Object: `BehavioralVector` (θ_user)

```
lossAversion          : Double λ    range [1.0, 4.0]  default 1.8
riskToleranceDrift    : Double R_t  range [0.0, 1.0]  default 0.5
impulseVolatility     : Double I_v  range [0.0, 1.0]  default 0.5
presentBias           : Double β    range [0.0, 1.0]  default 0.7
overconfidenceCalib   : Double O_c  range [0.0, 1.0]  default 0.5
statusQuoBias         : Double σ    range [0.0, 1.0]  default 0.5
mentalAcctRigidity    : Double μ    range [0.0, 1.0]  default 0.5
regretAversion        : Double ρ    range [0.0, 1.0]  default 0.5
salienceSusceptibility: Double s    range [0.0, 1.0]  default 0.5
hyperbolicDiscounting : Double γ    range [0.0, 1.0]  default 0.5
```

**All values must satisfy range invariants. Calibration clamps to range on update.**

#### Entity: `Habit`

```
habitId:       HabitId
type:          HabitType
description:   String
confidence:    Double 0.0–1.0 (requires evidenceCount ≥ 3 to surface to user)
detectedAt:    Instant
evidenceCount: Int
lastConfirmed: Instant
```

**HabitType (enum):**
```
IMPULSE_WINDOW          ("Overspends 3 days after salary")
LOSS_AVERSION_TRIGGER   ("Cancels SIP during market drawdowns")
SIP_ADHERENCE           ("Never missed a SIP in 18 months")
SUBSCRIPTION_BLOAT      ("Paying for 4 streaming services")
SALARY_BOUNCE           ("Spends 40% of salary in first 5 days")
BUDGET_DISCIPLINE       ("Stays within budget 9 of 12 months")
RECURRING_SAVER         ("Saves before spending — auto-transfers on salary day")
```

#### CalibrationState (state machine — see §6)

```
UNCALIBRATED → PARTIALLY_CALIBRATED → CALIBRATED → DRIFT_DETECTED → RECALIBRATING → CALIBRATED
```

#### Domain Events

```
BehaviorProfileCreatedEvent { userId, initialVector }
HabitDetectedEvent          { userId, habitType, confidence, evidence }
HabitConfirmedEvent         { userId, habitId, newConfidence }
VectorUpdatedEvent          { userId, dimension, previousValue, newValue, trigger }
CalibrationCompletedEvent   { userId, calibrationVersion, dimensionsUpdated }
FinancialPersonalityChangedEvent { userId, from, to }
```

---

### Context 4: Partner — Supporting Domain

#### Aggregate: `PartnerProgram`

```
Identity:              ProgramId (stable string, e.g. "hdfc_rd")
brand:                 PartnerBrand
productName:           String
instrument:            FinancialInstrument
suitableDecisionTypes: List<String>
keyMetric:             String
keyMetricLabel:        String
returnRate:            Double?
minAmount:             Money
riskLevel:             RiskLevel
taxBenefit:            Boolean
active:                Boolean
commissionRate:        Double  (invariant: always 0.0)
metadata:              ProductMetadata
lastUpdated:           LocalDate
```

**Invariant:** `commissionRate == 0.0` enforced in constructor. This is a fiduciary invariant, not a business rule — it is structural.

#### Value Object: `MatchingContext`

The user-perspective input to the Partner Matching Engine. All fields have safe defaults so the engine can operate on partial data.

```
primaryGoal:              DecisionType
horizonMonths:            Int      default 12
goalAmountTarget:         Double   default 0
monthlySurplus:           Double   default 0
emergencyFundMonths:      Double   default 0
riskProfile:              String   ('conservative' | 'moderate' | 'aggressive')
healthScore:              Double   default 50
existingInvestmentTotal:  Double   default 0
monthlyCommitmentsTotal:  Double   default 0
ageYears:                 Int      default 30
monthlySavingsRate:       Double   default 0.10
dominantBehaviorProfile:  String?  null until Behavioral Engine calibrated
```

**Design principle:** As more data sources are connected (AA, goals, health engine), fields fill in from defaults to real values — improving recommendation quality automatically, without code changes.

#### Domain Services

**`PartnerMatchingEngine`** — ranks catalog programs by fit for a MatchingContext.

```dart
abstract class PartnerMatchingEngine {
  String get engineVersion;
  List<RankedPartnerProgram> rank({
    required List<PartnerProgram> catalog,
    required MatchingContext context,
    int limit = 6,
  });
}
```

**`MatchingPolicy`** — evaluates and rejects programs per goal type.

```dart
abstract class MatchingPolicy {
  Set<DecisionType> get targetGoals;
  RejectionReason? reject(PartnerProgram program, MatchingContext context);
  MatchResult? evaluate(PartnerProgram program, MatchingContext context);
}
```

**Current implementations:**
- `EmergencyFundPolicy` — real logic
- `WealthCreationPolicy` — real logic
- `TaxSavingPolicy` — real logic
- `RetirementPolicy` — stub
- `InsurancePolicy` — stub
- `DebtReductionPolicy` — stub

---

### Context 5: Digital Twin — Generic Subdomain

#### Aggregate: `FinancialTwin`

```
Identity:      TwinId (UserId-derived, one per user)
userId:        UserId
vector:        BehavioralVector  (snapshot from Behavioral Context)
state:         FinancialState
history:       List<TwinSnapshot>   (immutable past states, append-only)
lastUpdated:   Instant
twinVersion:   String
```

**Invariants:**
1. `history` is append-only — no snapshot is ever modified or removed
2. `vector` and `state` reflect the latest calibration only
3. Every `history` entry has a `trigger` explaining why the snapshot was taken

**Today:** Stub — returns uncalibrated defaults.  
**Tier 5:** Real calibration from Behavioral Engine output.

#### Value Object: `TwinSnapshot`

```
snapshotId:  SnapshotId (ULID)
vector:      BehavioralVector    (immutable copy at snapshot time)
state:       FinancialState
capturedAt:  Instant
trigger:     SnapshotTrigger (MARKET_DRAWDOWN | SALARY_INCREASE | SIP_MISSED | MANUAL_REVIEW | CALIBRATION)
```

#### Domain Events

```
TwinCreatedEvent      { twinId, userId, initialState }
TwinUpdatedEvent      { twinId, userId, previousVector, newVector, trigger, decisionId? }
TwinSnapshotEvent     { twinId, snapshotId, capturedAt, trigger }
```

---

### Context 6: Knowledge Graph — Generic Subdomain

The semantic layer that every intelligence engine queries. Contains relationships, not raw data.

#### Node Types

```
UserNode        { userId, ageYears, riskProfile, financialState }
AccountNode     { accountId, type, institutionId, balance? }
GoalNode        { goalId, category, targetAmount, fundingStatus }
IncomeNode      { incomeId, type, monthlyAmount, stability }
CommitmentNode  { commitmentId, type, monthlyAmount, endDate? }
MerchantNode    { merchantId, normalizedName, category, impulseScore, necessityScore }
SubscriptionNode{ subscriptionId, merchantId, monthlyAmount, utilization? }
LoanNode        { loanId, outstandingAmount, interestRate, emiAmount, lender }
InsuranceNode   { insuranceId, type, coverAmount, premium }
AssetNode       { assetId, type, currentValue, lastValued }
InstrumentNode  { FinancialInstrument, riskLevel, regulatoryBody, minHorizonMonths, liquidityScore }
RegulatorNode   { name, jurisdiction }
LifeEventNode   { eventId, type, detectedAt, confidence }
```

#### Relationship Types (Edges)

```
OWNS              (UserNode → AccountNode, AssetNode, InstrumentNode)
FUNDS             (AccountNode → GoalNode)
SERVICES          (AccountNode → LoanNode)
SUBSCRIBED_TO     (UserNode → SubscriptionNode)
COVERED_BY        (UserNode → InsuranceNode)
EARNS_FROM        (UserNode → IncomeNode)
TRANSACTS_WITH    (UserNode → MerchantNode)
IMPACTS_GOAL      (CommitmentNode → GoalNode, positive or negative)
DEPENDS_ON        (UserNode → UserNode, family dependency graph)
BELONGS_TO        (SubscriptionNode → MerchantNode)
OFFERED_BY        (InstrumentNode → PartnerNode)
REGULATED_BY      (InstrumentNode → RegulatorNode, PartnerNode → RegulatorNode)
SUITABLE_FOR      (InstrumentNode → GoalNode by GoalCategory)
TRIGGERED         (LifeEventNode → GoalNode, UserNode)
```

#### Domain Service: `ProductKnowledgeGraph`

```dart
abstract class ProductKnowledgeGraph {
  List<FinancialInstrument> instrumentsFor(DecisionType goal);
  RiskLevel riskFor(FinancialInstrument instrument);
  double liquidityFor(FinancialInstrument instrument);
  String regulatorFor(FinancialInstrument instrument);
  bool isCapitalGuaranteed(FinancialInstrument instrument);
  int minHorizonMonthsFor(FinancialInstrument instrument);
}
```

**Today:** `HardcodedProductKnowledgeGraph` returns static values.  
**Phase 6:** PostgreSQL entity graph backing these queries.

---

### Context 7: Financial Data Platform — Foundation Domain *(Not Yet Built)*

The single entry point for all financial data. Normalizes, enriches, and publishes everything as domain events. Owns the data quality contract for all downstream engines.

#### Aggregate: `IngestionJob`

```
Identity:    JobId (ULID)
userId:      UserId
source:      IngestionSource (SMS | ACCOUNT_AGGREGATOR | EMAIL | OCR | MANUAL)
rawPayload:  String    (immutable once set)
status:      IngestionStatus
parsedAt:    Instant?
normalizedAt: Instant?
enrichedAt:  Instant?
failedAt:    Instant?
failureReason: String?
retryCount:  Int       (invariant: retryCount ≤ 3)
```

**Invariants:**
1. `rawPayload` is immutable after creation
2. Status advances forward only (no regression): PENDING → PARSING → PARSED → NORMALIZING → NORMALIZED → ENRICHING → ENRICHED | FAILED
3. A FAILED job is never mutated — retry creates a new job
4. `retryCount ≤ 3` — after 3 failures, job enters DEAD_LETTER state

#### Entity: `NormalizedTransaction`

```
txnId:           TransactionId (ULID)
userId:          UserId
amount:          Money
direction:       Direction (DEBIT | CREDIT)
merchant:        MerchantProfile
category:        TransactionCategory
transactedAt:    Instant
rawDescription:  String
source:          IngestionSource
railType:        PaymentRail (UPI | NACH | NEFT | IMPS | CARD | CASH)
upiVpa:          String?
balanceAfter:    Money?
isRecurring:     Boolean
recurringPattern: RecurringPattern?
```

#### Entity: `MerchantProfile`

```
merchantId:      MerchantId (ULID)
rawName:         String      ("AMZ PAY INDIA PVT LTD")
normalizedName:  String      ("Amazon")
category:        MerchantCategory
impulseScore:    Double 0.0–1.0  (1.0 = pure impulse, 0.0 = essential)
necessityScore:  Double 0.0–1.0
aliases:         List<String>
upiVpas:         List<String>
lastSeen:        Instant
```

#### Ingestion Pipeline (ordered)

```
1. Raw data received (SMS text | AA JSON | email attachment | OCR image)
2. IngestionJob created (status = PENDING)
3. Source parser runs (SMS parser | AA adapter | Email parser | OCR engine)
   → Produces RawTransaction (amount, direction, timestamp, raw description)
   → Status = PARSED
4. Merchant normalization
   → MerchantProfile.lookup(rawDescription) or create
   → Status = NORMALIZED
5. Category assignment (rule-based → ML in Tier 2)
6. Pattern detection
   → Is this a recurring payment? (SIP, rent, subscription, EMI)
   → Is this a salary credit?
   → Status = ENRICHED
7. Publish: TransactionNormalizedEvent → Financial Event Store
8. Publish: SubscriptionDetectedEvent (if new)
9. Publish: SalaryDetectedEvent (if salary pattern matched)
```

#### Domain Events

```
RawDataReceivedEvent        { jobId, userId, source, receivedAt }
TransactionParsedEvent      { jobId, txnId, userId, amount, direction, rawDesc }
TransactionNormalizedEvent  { txnId, userId, merchantId, category, railType }
SubscriptionDetectedEvent   { txnId, userId, merchantId, estimatedMonthly, confidence }
SalaryDetectedEvent         { txnId, userId, amount, source, estimatedCycleDay }
MerchantProfileCreatedEvent { merchantId, normalizedName, category, impulseScore }
IngestionFailedEvent        { jobId, userId, reason, retryCount }
```

---

### Context 8: Financial Event Store — Infrastructure Domain *(Not Yet Built)*

The immutable, append-only history of everything that happened to a user's financial life. Every engine can replay history. The Digital Twin can reconstruct any point in time.

#### Core Rules

1. **Append-only.** Events are never updated or deleted.
2. **Immutable.** An event payload is sealed at publication time.
3. **Ordered.** Events within a stream are strictly ordered by sequence number.
4. **Replayable.** Any projection can be rebuilt by replaying events from position 0.
5. **Versioned.** Schema changes produce new `schemaVersion` — old events are never back-filled.

#### Value Object: `DomainEvent`

```
eventId:        EventId (ULID — sortable, globally unique)
streamId:       StreamId (userId — one stream per user)
aggregateId:    String (DecisionId, GoalId, etc.)
aggregateType:  AggregateType
eventType:      EventType
sequenceNumber: Long    (monotonically increasing per stream)
occurredAt:     Instant
publishedAt:    Instant
schemaVersion:  String  ("1.0", "1.1", etc.)
payload:        Map<String, Object>  (event-specific data)
correlationId:  CorrelationId?  (links events within a saga)
causationId:    EventId?  (the event that caused this one)
```

#### EventStore Repository

```java
interface EventStoreRepository {
  void append(DomainEvent event);                          // publish
  List<DomainEvent> replay(StreamId stream, long fromSeq); // full replay from position
  List<DomainEvent> replayFrom(StreamId stream, Instant from); // replay from timestamp
  Optional<DomainEvent> findById(EventId id);
  List<DomainEvent> findByType(StreamId stream, EventType type);
}
```

**Invariant:** `append` only. No `update`, no `delete` methods on this interface.

#### The Full Event Catalog

```
// Data Platform events
RawDataReceivedEvent, TransactionParsedEvent, TransactionNormalizedEvent,
SubscriptionDetectedEvent, SalaryDetectedEvent, MerchantProfileCreatedEvent,
IngestionFailedEvent

// Finance events
GoalCreatedEvent, GoalUpdatedEvent, GoalFundedEvent, GoalCompletedEvent,
GoalAbandonedEvent, HealthScoreChangedEvent, BudgetBreachEvent,
SalaryUpdatedEvent

// Decision events
DecisionGeneratedEvent, DecisionViewedEvent, DecisionAcceptedEvent,
DecisionRejectedEvent, DecisionDeferredEvent, DecisionExecutedEvent,
DecisionObservedEvent, DecisionReviewedEvent, DecisionLearnedEvent

// Partner events
PartnerViewedEvent, PartnerOpenedEvent, PartnerApplicationStartedEvent

// Behavioral events
HabitDetectedEvent, HabitConfirmedEvent, VectorUpdatedEvent,
CalibrationCompletedEvent, FinancialPersonalityChangedEvent

// Twin events
TwinCreatedEvent, TwinUpdatedEvent, TwinSnapshotEvent

// Market events (future)
MarketDrawdownEvent, InterestRateChangedEvent, GoalValueUpdatedEvent
```

---

### Context 9: Knowledge — Generic Subdomain

Manages educational content, learning paths, and behavioral interventions.

#### Entity: `Lesson`

```
lessonId:     LessonId
title:        String
module:       LessonModule (SALARY | SAVINGS | INVESTMENT | BUDGET | TAX | DEBT | INSURANCE)
content:      String (Markdown)
xpReward:     Int
trigger:      LessonTrigger? (DECISION_TYPE → lesson shows when decision is of this type)
```

#### Entity: `LearningPath`

```
pathId:        PathId
userId:        UserId
currentLesson: LessonId
completed:     List<LessonId>
xpTotal:       Int
streak:        Int (consecutive days with activity)
```

---

### Context 10: Platform — Cross-cutting

#### FeatureFlag

```
flag:          EngineFlag (enum)
enabled:       Boolean
rolloutPct:    Double 0.0–1.0  (for gradual rollout)
userOverrides: Map<UserId, Boolean>
```

**EngineFlag values:**
```
DECISION_ENGINE_V1          // current: enabled
DECISION_ENGINE_V2          // Tier 3: multi-axis pipeline
BEHAVIORAL_ENGINE           // Tier 5: pattern detection
DIGITAL_TWIN_CALIBRATION    // Tier 5: real vector updates
PARTNER_MATCHING_V1         // current: enabled (policy-based)
KNOWLEDGE_GRAPH             // Phase 6: PostgreSQL entity graph
HEALTH_ENGINE_V2            // Tier 2: 10-dimension computation
ACCOUNT_AGGREGATOR          // Tier 1: Setu SDK
SMS_INTELLIGENCE            // Tier 1: background listener
STEP_UP_SIP_FORMULA         // Tier 3: compound formula
MONTE_CARLO                 // Phase 6
EVIDENCE_BUILDER            // Phase 3
EVENT_SOURCING              // Phase 8
OPPORTUNITY_COST_CALCULATOR // Phase 5
```

**Usage rule:** Every engine must check `FeatureFlagService.isEnabled(flag)` before executing. If disabled, return stub/fallback. Never `if (DEBUG)` — always through flags.

---

## Cross-Cutting Services

### Evidence Builder

The Evidence Builder is a **domain service** in the Decision context. It reads signals from all other contexts and assembles the `evidence: List<EvidenceItem>` that appears in every `Explanation`.

**Responsibilities:**
- Query the Knowledge Graph for the user's entity relationships
- Query transaction history for spending patterns (via Finance context)
- Query goal repository for goal state and funding gaps
- Query behavioral profile for calibrated vector values
- Query decision memory for past recommendation outcomes
- Apply freshness rules: evidence older than 7 days gets a freshness penalty
- Return structured `EvidenceItem[]` with source and freshness metadata

**Design rule:** The Evidence Builder never computes — it assembles. Each source context is the authority on its own data.

```dart
abstract class EvidenceBuilder {
  Future<List<EvidenceItem>> buildFor({
    required UserId userId,
    required DecisionType decisionType,
    required MatchingContext context,
  });
}
```

**Confidence output:** The number, recency, and source diversity of `EvidenceItem`s directly feeds `Confidence.score`.

### SIPCalculationService

**Domain service in Finance context.** Computes SIP parameters using the compound formula — never linear math.

```
SIPFormula: M0 = FV × r / ((1+r)^n − 1)
  where:
    FV = goalAmountTarget - savedAmount
    r  = monthlyRate (annual / 12)
    n  = horizonMonths

Rate by horizon (FinancialPolicy):
  < 12 months:  7%
  12–36 months: 8%
  36–60 months: 10%
  > 60 months:  12%

Constraint: M0 ≤ 10% of discretionary income
  where: discretionary = salary × (1 - expense_ratio - commitment_ratio)
```

---

## Sagas and Process Managers

### Saga 1: Decision Memory Loop

A long-running process that closes the recommendation feedback loop. One saga instance per Decision.

```
START:   DecisionGeneratedEvent

Step 1 (immediate):
  - Create DecisionMemoryRecord { decisionId, type, recommendation, confidence, generatedAt }
  - Start 24h expiry timer

Step 2 (event-driven, user interaction):
  - On DecisionViewedEvent    → record viewedAt, surface = dashboard
  - On DecisionAcceptedEvent  → record acceptedAt, channelUsed
  - On DecisionRejectedEvent  → record rejectedAt, reason; saga continues for learning
  - On DecisionDeferredEvent  → record deferredAt; restart visibility timer

Step 3 (timer — 30 days after ACCEPTED):
  - Query: Has a matching transaction appeared? (e.g., new SIP detected)
  - If yes: emit DecisionExecutedEvent
  - If no: emit reminder / surface "Did you start your SIP?" card

Step 4 (timer — 60 days after EXECUTED):
  - Compute outcomeMetric: current healthScore vs healthScore at generation time
  - Compute outcomeDelta
  - emit DecisionObservedEvent

Step 5 (analysis):
  - Compute DEV = outcomeMetric.actual - recommendation.projectedGoalImpact
  - If |DEV| > threshold: surface AAR card in journal
  - emit DecisionReviewedEvent { dev, deviationType: BETTER | WORSE | AS_EXPECTED }

Step 6 (learning):
  - Extract lesson from DEV
  - Update BehavioralVector if behavioral pattern contributed to deviation
  - emit DecisionLearnedEvent { lesson, twinParametersUpdated }
  - Update DigitalTwin (via TwinUpdateSaga)

END: DecisionLearnedEvent
```

### Saga 2: Ingestion Pipeline

```
START:   RawDataReceivedEvent { source, rawPayload }

Step 1: Parse (source-specific parser)
  - SMS → SmsParser
  - AA  → AccountAggregatorAdapter (anti-corruption layer)
  - OCR → OcrResultParser
  → Emit: TransactionParsedEvent

Step 2: Merchant Normalization
  → MerchantNormalizationService.lookup(rawDescription)
  → Create or update MerchantProfile
  → Emit: MerchantProfileCreatedEvent (if new)

Step 3: Categorization
  → RuleCategorizer (fast, synchronous)
  → Emit: TransactionNormalizedEvent

Step 4: Pattern Detection
  → RecurringPaymentDetector.check(txnId, userId)
  → SalaryPatternDetector.check(txnId, userId)
  → If subscription: emit SubscriptionDetectedEvent
  → If salary: emit SalaryDetectedEvent

END: TransactionNormalizedEvent (published to all subscribers)

Subscribers:
  - Knowledge Graph updater (adds/updates MerchantNode, updates TRANSACTS_WITH edge)
  - Health Score projector (recalculates relevant dimensions)
  - Behavioral Engine listener (checks for habit patterns)
  - Commitment Intelligence (checks for new recurring patterns)
```

### Saga 3: Twin Calibration

```
START:   VectorUpdatedEvent (from Behavioral Engine) | CalibrationTriggerEvent

Step 1: Validate new vector values (clamp to invariant ranges)
Step 2: Compare to current twin vector
  - If |delta| > calibration_threshold for any dimension: proceed
  - Else: discard (noise reduction)
Step 3: Take TwinSnapshot (before update)
Step 4: Update FinancialTwin with new vector
Step 5: Recompute FinancialPersonality
  - If personality changed: emit FinancialPersonalityChangedEvent
Step 6: Emit TwinUpdatedEvent

END: TwinUpdatedEvent

Effect: Next DecisionGeneratedEvent will include the updated BehavioralContext
```

---

## State Machines

### Decision Lifecycle

See `07-decision-lifecycle.md` for full diagram. Summary:

```
GENERATED
   ↓ (always, on dashboard render)
VIEWED
   ↓                  ↓               ↓
ACCEPTED          REJECTED         DEFERRED
   ↓                                  ↓
EXECUTED                          VIEWED (re-surfaced)
   ↓
OBSERVED (30-day check)
   ↓
REVIEWED (DEV computed)
   ↓
LEARNED (twin updated, saga closed)
```

**Valid transitions only.** Rejected decisions can still reach LEARNED (the rejection itself is a signal).

### Goal Lifecycle

```
DRAFT → ACTIVE → PAUSED → ACTIVE  (resumable)
              ↓
           COMPLETED (savedAmount = targetAmount)
              ↓
           ARCHIVED (after 90-day review window)

ACTIVE  → ABANDONED (user explicitly cancels)
ABANDONED cannot transition to ACTIVE (create new goal instead)
```

### Ingestion Job Lifecycle

```
PENDING → PARSING → PARSED → NORMALIZING → NORMALIZED → ENRICHING → ENRICHED
                                                                        ↓
any state → FAILED (on unrecoverable error) → DEAD_LETTER (retryCount ≥ 3)
```

### BehaviorProfile Calibration State

```
UNCALIBRATED (< 30 transactions, < 60 days data)
    ↓ (data threshold met)
PARTIALLY_CALIBRATED (30–90 transactions, 60–180 days data)
    ↓ (calibration threshold met)
CALIBRATED (≥ 90 transactions, ≥ 180 days data, vector confidence ≥ 0.7)
    ↓ (significant behavioral change detected — > 0.3 delta on any dimension)
DRIFT_DETECTED
    ↓ (recalibration started)
RECALIBRATING
    ↓ (new calibration complete)
CALIBRATED
```

---

## Specification Pattern

The Specification pattern allows business rules to be composed and reused across policies, repositories, and UI filters. **Backend: Java. Flutter domain: Dart.**

### Java (Backend)

```java
interface Specification<T> {
  boolean isSatisfiedBy(T candidate);
  default Specification<T> and(Specification<T> other) {
    return candidate -> this.isSatisfiedBy(candidate) && other.isSatisfiedBy(candidate);
  }
  default Specification<T> or(Specification<T> other) {
    return candidate -> this.isSatisfiedBy(candidate) || other.isSatisfiedBy(candidate);
  }
  default Specification<T> not() {
    return candidate -> !this.isSatisfiedBy(candidate);
  }
}

// Example specifications
class LiquidSpecification implements Specification<PartnerProgram> {
  boolean isSatisfiedBy(PartnerProgram p) {
    return p.metadata.liquidityScore >= 0.6 && p.metadata.lockInDays <= 30;
  }
}

class CapitalGuaranteedSpecification implements Specification<PartnerProgram> {
  boolean isSatisfiedBy(PartnerProgram p) {
    return p.metadata.capitalGuarantee;
  }
}

class TaxBenefitSpecification implements Specification<PartnerProgram> {
  boolean isSatisfiedBy(PartnerProgram p) {
    return p.taxBenefit && "SEBI".equals(p.metadata.regulator);
  }
}

// Usage in EmergencyFundPolicy:
Specification<PartnerProgram> emergencyFundSpec =
    new LiquidSpecification().and(new CapitalGuaranteedSpecification());
```

### Dart (Flutter Domain)

Implement as simple `bool Function(T)` predicates composed via extension methods — no interface overhead in Dart.

---

## Ownership Boundaries

The matrix of what each context **owns** (sole authority) vs **reads** (downstream consumer).

| Entity / Concept | Owned By | May Be Read By |
|-----------------|----------|----------------|
| Decision aggregate | Decision Context | Journal, Dashboard (read model) |
| DecisionMemoryRecord | Decision Context | Behavioral (outcome signals) |
| BehavioralVector | Behavioral Context | Decision (via BehavioralContext snapshot), Twin |
| BehaviorProfile | Behavioral Context | Decision (via snapshot), Digital Twin |
| FinancialTwin | Twin Context | Decision (snapshot), Dashboard |
| TwinSnapshot | Twin Context | Audit, Replay |
| Goal | Finance Context | Decision (goal impact), Knowledge Graph (GoalNode) |
| HealthScore | Finance Context (computed) | Decision (input to confidence), Dashboard |
| PartnerProgram | Partner Context | Decision (via matching engine) |
| MatchingPolicy | Partner Context | Partner Matching Engine |
| RawTransaction | Data Platform | Never exported raw — only NormalizedTransaction |
| NormalizedTransaction | Data Platform | Finance (budget/health), Behavioral (patterns) |
| MerchantProfile | Data Platform | Knowledge Graph copies enriched data |
| DomainEvent | Event Store | All contexts (read-only, via replay API) |
| KnowledgeGraph nodes | Knowledge Graph | Decision, Behavioral, Finance (query API) |
| EvidenceItem[] | Decision Context (assembled) | Explanation only |
| FeatureFlag | Platform Context | All contexts (synchronous check) |
| Lesson / LearningPath | Knowledge Context | Dashboard (triggered by decision type) |

**Boundary rules:**
1. A context never directly queries another context's database.
2. Communication across context boundaries happens through: domain events, read models, or explicit query APIs.
3. Never share database tables between contexts — each context owns its schema.
4. Anti-corruption layers (ACLs) translate external data (AA, SMS) to domain events before they enter the platform.

---

## Architecture Decision Records

**ADR-001:** `Decision` is the aggregate root, not `Recommendation`.  
*Rationale:* PennyWise is a decision platform. Every recommendation, program, explanation, behavioral insight, and memory record is a consequence of a Decision.

**ADR-002:** `DecisionResponse` is the single API envelope for all engines.  
*Rationale:* Prevents per-engine DTOs that diverge. All screens consume the same structure. Affordability, SIP, goal, tax — same envelope.

**ADR-003:** `Money` is always a value object, never a bare `double`.  
*Rationale:* Currency precision bugs are silent and catastrophic in financial software.

**ADR-004:** `FinancialState` (SURVIVE/STABILIZE/BUILD/OPTIMIZE) drives both recommendation logic and UI copy.  
*Rationale:* From Wealth Recommendation Engine research — determines which engines are relevant and what tone to use. No growth products in SURVIVE.

**ADR-005:** `commissionRate` is always `0.0` — enforced structurally, not by policy.  
*Rationale:* Fiduciary invariant. Enforced in constructor assert, not via if-statements in ranking logic.

**ADR-006:** Stub implementations behind interfaces, switched via `FeatureFlag`.  
*Rationale:* Engine-by-engine activation without breaking the app. No `if (DEBUG)` inside business logic.

**ADR-007:** ULIDs for all Decision, Recommendation, and Event IDs.  
*Rationale:* Time-sortable, URL-safe, no database coordination. Critical for event log ordering.

**ADR-008:** `MatchingPolicy` produces `MatchResult` (reasons-first); score is derived.  
*Rationale:* Score-first produces post-hoc rationalisations. Reasons-first produces genuine explanations. This is the architectural difference between a recommendation engine and a financial advisor.

**ADR-009:** Financial Event Store is append-only. No update, no delete.  
*Rationale:* Event sourcing requires an immutable, replayable history. Mutations destroy the ability to replay any point in time or audit what happened.

**ADR-010:** Anti-corruption layers (ACLs) at all external data boundaries.  
*Rationale:* SMS text, AA JSON, and OCR output are not domain language. They must be translated before entering the domain. The ACL is the translation layer — not the domain service.

**ADR-011:** `MatchingContext` has safe defaults so the engine degrades gracefully.  
*Rationale:* As data sources are connected (AA, SMS, goals), context fields fill in from defaults to real values. Recommendation quality improves automatically without code changes.

**ADR-012:** The Knowledge Graph uses PostgreSQL (not Neo4j) initially.  
*Rationale:* Premature graph database adoption. PostgreSQL with typed entity/edge tables and recursive CTEs handles the query patterns needed through Phase 6. Migrate to Neo4j/Neptune when query complexity justifies it.

---

*Next sprint: Financial Knowledge Graph schema (PostgreSQL) + Evidence Builder domain service.*  
*Reference this document before designing any new aggregate, service, event, or API.*
