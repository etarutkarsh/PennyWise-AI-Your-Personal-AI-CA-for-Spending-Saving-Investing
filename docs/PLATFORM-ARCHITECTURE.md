# PennyWise Platform Architecture

**Version 1.0 — Foundational Engineering Document**

*This document defines the technical architecture of the PennyWise Financial Decision Platform. It is written to be read by engineers building the system, architects evaluating it, and investors understanding the technical moat.*

*Every architectural decision in this document traces back to a principle in the PennyWise Constitution. Where a tradeoff exists, the Constitution is the tiebreaker.*

---

## I. Architectural Philosophy

### The Core Constraint

> Financial math is not an AI problem. It is a calculation problem.

This single constraint shapes the entire platform architecture.

LLMs are extraordinary at understanding language, generating explanations, and identifying patterns in unstructured data. They are not reliable at arithmetic, tax law interpretation, or financial simulation. A model that hallucinates a tax deduction or miscalculates an EMI does not make the financial future visible — it makes it dangerously wrong.

**The rule derived from this constraint:**

- Deterministic engines calculate. They produce numbers. They are auditable, reproducible, and provably correct.
- AI models explain, understand, and personalize. They produce language. They are reviewed, confidence-scored, and never trusted with arithmetic.
- These two systems are architecturally separate. They communicate through a defined contract. They are never merged.

### The Platform Model

PennyWise is not an application. It is a platform on which applications run.

```
┌─────────────────────────────────────────────────────────────────────┐
│                         PENNYWISE PLATFORM                          │
│                                                                     │
│  ┌───────────┐  ┌───────────┐  ┌───────────┐  ┌───────────────┐   │
│  │ Consumer  │  │    CA     │  │Enterprise │  │  Partner API  │   │
│  │    App    │  │ Platform  │  │ Dashboard │  │   (Fintechs,  │   │
│  │ (Flutter) │  │   (Web)   │  │   (Web)   │  │ Banks, etc.)  │   │
│  └─────┬─────┘  └─────┬─────┘  └─────┬─────┘  └──────┬────────┘   │
│        └──────────────┴──────────────┴────────────────┘            │
│                               │                                     │
│                    ┌──────────▼──────────┐                         │
│                    │    API Gateway &     │                         │
│                    │  Auth / Rate Limit   │                         │
│                    └──────────┬──────────┘                         │
│                               │                                     │
│        ┌──────────────────────▼──────────────────────────┐         │
│        │              INTELLIGENCE LAYER                  │         │
│        │  Decision Engine │ Simulation │ AI/LLM Layer     │         │
│        └──────────────────────┬──────────────────────────┘         │
│                               │                                     │
│        ┌──────────────────────▼──────────────────────────┐         │
│        │               MEMORY LAYER                       │         │
│        │  Financial Graph │ Identity Graph │ Audit Trail  │         │
│        └──────────────────────┬──────────────────────────┘         │
│                               │                                     │
│        ┌──────────────────────▼──────────────────────────┐         │
│        │             DATA INGESTION LAYER                 │         │
│        │    AA │ SMS │ PDF │ OCR │ Manual │ Partner APIs  │         │
│        └─────────────────────────────────────────────────┘         │
└─────────────────────────────────────────────────────────────────────┘
```

Every application — consumer budgeting, CA tax tools, enterprise wellness dashboards, third-party API integrations — calls the same platform. The intelligence layer is shared. The data model is shared. The trust rules are shared. Applications are thin shells on top.

---

## II. The Five Layers

### Layer 1 — Data Ingestion

This layer answers one question: what is the user's complete financial reality right now?

Financial data comes from multiple sources, each with different reliability, latency, and coverage. The ingestion layer aggregates all of them, resolves conflicts, and produces a unified financial state — never a partial view presented as complete.

**Source hierarchy (primary to fallback):**

```
┌─────────────────────────────────────────────────────────────────────┐
│                    DATA INGESTION WATERFALL                         │
│                                                                     │
│  1. Account Aggregator (RBI AA Framework)           ← Primary       │
│     Real-time balances, transactions, investments                   │
│     Coverage: All AA-enabled banks and institutions                 │
│     Latency: Near real-time                                         │
│     Confidence: High (bank-sourced)                                 │
│                             │                                       │
│                    [AA unavailable?]                                │
│                             │                                       │
│  2. SMS Transaction Parser                          ← Secondary     │
│     Pattern matching on bank SMS notifications                      │
│     Coverage: All banks that send SMS alerts                        │
│     Latency: Real-time (on-device parsing)                          │
│     Confidence: Medium (regex + ML classification)                  │
│                             │                                       │
│                    [SMS unavailable?]                               │
│                             │                                       │
│  3. PDF Statement Parser                            ← Tertiary      │
│     OCR + parsing of password-protected bank PDFs                   │
│     Coverage: Any bank offering statement download                  │
│     Latency: On-demand                                              │
│     Confidence: Medium-High (structured format)                     │
│                             │                                       │
│                    [No PDF available?]                              │
│                             │                                       │
│  4. Manual Entry                                    ← Last resort   │
│     User-entered transactions                                       │
│     Coverage: Complete (user-defined)                               │
│     Latency: On-entry                                               │
│     Confidence: Low (no verification)                               │
└─────────────────────────────────────────────────────────────────────┘
```

**Confidence tagging:** Every data point in the system carries a confidence label and source tag. The UI surfaces this when relevant. A tax estimate based on AA data shows differently than one based on SMS parsing. The user always knows what PennyWise knows and how well it knows it. (Trust Law 5 — Visible Uncertainty.)

**Data uncertainty handling:** The system never presents partial data as complete. If PennyWise has visibility into 3 of a user's 5 bank accounts, it says so. It does not extrapolate the missing accounts. It shows the 3 it knows with confidence and marks the gap explicitly.

**Government API connectors (Phase 2+):**

```
DigiLocker       → Identity documents, policy records
EPFO / NPS       → Retirement account balances
ITD / AIS / TIS  → Tax filing history, TDS credits
GST Portal       → GST filing records (freelancer/business)
CAMS / KFintech  → Consolidated mutual fund statements
CIBIL / Experian → Credit report (with explicit consent)
```

Each connector has its own circuit breaker and fallback. No single government API failure degrades the core product.

---

### Layer 2 — Memory Layer

The Memory Layer is the platform's long-term intelligence. It converts raw financial data into structured, queryable knowledge about a specific person's financial life — and it compounds over time.

Three components:

#### 2A. Financial Memory Graph

A graph database representing every financial entity in the user's life and the relationships between them.

```
                    ┌─────────────┐
                    │    USER     │
                    └──────┬──────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
   ┌────▼────┐       ┌──────▼──────┐    ┌────▼────┐
   │ INCOME  │       │   ASSETS    │    │LIABILITIES│
   │ Streams │       │ Bank Accts  │    │ Loans    │
   │ Salary  │       │ Investments │    │ Credit   │
   │ Freelance│      │ Real Estate │    │ EMIs     │
   └────┬────┘       └──────┬──────┘    └────┬────┘
        │                   │                │
        └───────────────────┼────────────────┘
                            │
                   ┌────────▼────────┐
                   │   OBLIGATIONS   │
                   │ Tax Deadlines   │
                   │ EMI Schedules   │
                   │ Insurance Renew │
                   │ Subscription    │
                   └────────┬────────┘
                            │
                   ┌────────▼────────┐
                   │     GOALS       │
                   │ House, Car, Ed  │
                   │ Retirement      │
                   │ Emergency Fund  │
                   └─────────────────┘
```

Nodes carry temporal history. The graph does not overwrite — it appends. A transaction from 3 years ago is as queryable as one from today. This is what makes the year-3 and year-5 retention moat real: the graph becomes the user's financial autobiography, and no competitor can replicate it.

#### 2B. Economic Identity Graph

A multi-dimensional model of how *this specific person* makes financial decisions — built passively from observed behavior, not from questionnaires.

```
DIMENSION               SIGNAL SOURCES                    OUTPUT RANGE
─────────────────────────────────────────────────────────────────────
Liquidity Preference    AA balance patterns, idle cash    0.0 → 1.0
Debt Aversion           Loan prepayment behavior          0.0 → 1.0
Spending Impulsivity    Post-salary spend velocity        0.0 → 1.0
Risk Appetite           Investment product choices        Conservative → Aggressive
Family Priority Weight  Dependent expenses, education     0.0 → 1.0
Career Stability        Income variance, job changes      0.0 → 1.0
Health Spending Weight  Medical spend patterns            0.0 → 1.0
Tax Engagement          Filing timeliness, proactivity    Avoidant → Proactive
Savings Discipline      Savings rate consistency          0.0 → 1.0
```

This graph is never shown to users as a score or label. It is used internally to personalize every recommendation, every simulation, and every notification. The same financial event produces different recommendations for a person with high debt aversion versus low debt aversion.

The Economic Identity Graph takes approximately 90 days of behavior to build meaningful signal and 12+ months to reach high confidence. This is intentional. It means PennyWise becomes more valuable the longer someone uses it.

#### 2C. Audit Trail

Every recommendation, calculation, and AI output is permanently logged with its full input context, the version of the model or engine that produced it, and the user's response.

This serves three purposes:
1. Trust Law 6 (Auditable Calculations) — users can inspect any past recommendation.
2. Error Protocol — when a recommendation is wrong, the audit trail is how PennyWise understands what happened.
3. Model improvement — the audit trail is the ground truth dataset for improving every engine.

The audit trail is write-once, append-only. It cannot be modified by any internal process.

---

### Layer 3 — Intelligence Layer

This is the platform's core. It contains three distinct systems that must never be architecturally merged.

```
┌──────────────────────────────────────────────────────────────────────┐
│                        INTELLIGENCE LAYER                            │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │              DETERMINISTIC ENGINE CLUSTER                    │    │
│  │                                                              │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │    │
│  │  │  Tax Engine  │  │  Cash Flow   │  │   Goal Engine    │  │    │
│  │  │              │  │   Engine     │  │                  │  │    │
│  │  │ Tax slabs    │  │ Safe-to-Spend│  │ Corpus calc      │  │    │
│  │  │ 80C/80D/HRA  │  │ Bill reserve │  │ SIP projections  │  │    │
│  │  │ Advance tax  │  │ Runway calc  │  │ Goal feasibility │  │    │
│  │  │ Regime diff  │  │ Surplus calc │  │ Milestone track  │  │    │
│  │  └──────────────┘  └──────────────┘  └──────────────────┘  │    │
│  │                                                              │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │    │
│  │  │ Credit Engine│  │  Investment  │  │  Obligation      │  │    │
│  │  │              │  │   Engine     │  │  Engine          │  │    │
│  │  │ Utilization  │  │ Portfolio    │  │ Deadline track   │  │    │
│  │  │ EMI calc     │  │ Rebalancing  │  │ EMI schedule     │  │    │
│  │  │ Debt payoff  │  │ Corpus proj  │  │ Insurance renew  │  │    │
│  │  │ CIBIL impact │  │ XIRR/CAGR    │  │ Subscription map │  │    │
│  │  └──────────────┘  └──────────────┘  └──────────────────┘  │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                               │                                      │
│                    Verified numerical outputs only                   │
│                               │                                      │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │              SIMULATION ENGINE (Digital Twin)                │    │
│  │                                                              │    │
│  │  Monte Carlo simulator. Runs N scenarios (default: 500)      │    │
│  │  against the Financial Memory Graph.                         │    │
│  │                                                              │    │
│  │  Input:  Current financial state + variable + time horizon   │    │
│  │  Output: Probability distribution of outcomes               │    │
│  │                                                              │    │
│  │  "What if I quit my job?"                                    │    │
│  │  → Run 500 simulations varying income, expenses, timeline    │    │
│  │  → Output: 78% probability runway > 12 months               │    │
│  │  → Output: Median retirement impact: +2.3 years             │    │
│  │  → Confidence: High (AA data, 18 months history)            │    │
│  │                                                              │    │
│  │  Every simulation result is deterministic per seed.          │    │
│  │  Results are reproducible and auditable.                     │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                               │                                      │
│                    Numerical context passed to →                     │
│                               │                                      │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                   AI / LLM LAYER                             │    │
│  │                                                              │    │
│  │  Receives: Numerical outputs from engines above              │    │
│  │  Produces: Explanations, insights, recommendations in        │    │
│  │            natural language                                  │    │
│  │                                                              │    │
│  │  Responsibilities:                                           │    │
│  │  • Transaction categorization (unstructured → structured)    │    │
│  │  • SMS parsing (text → structured transaction)              │    │
│  │  • Recommendation explanation ("why this, not that")         │    │
│  │  • Chat interface (PennyWise AI assistant)                   │    │
│  │  • Narrative generation ("your money story this month")      │    │
│  │  • Document parsing (Form 16, bank PDFs)                     │    │
│  │                                                              │    │
│  │  Prohibitions:                                               │    │
│  │  • Never calculates a tax amount                             │    │
│  │  • Never computes a corpus projection                        │    │
│  │  • Never derives a Safe-to-Spend balance                     │    │
│  │  • Never asserts a regulatory interpretation as fact         │    │
│  │                                                              │    │
│  │  Every LLM output that reaches a user carries:               │    │
│  │  • A confidence label (High / Medium / Low / Estimated)      │    │
│  │  • A source reference (which engine produced the numbers)    │    │
│  │  • An audit ID (traceable in the Audit Trail)                │    │
│  └─────────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────────┘
```

**Why the strict separation matters:**

An LLM asked "what is the tax on ₹18,50,000 under the New Regime?" will produce an answer. That answer may be wrong in ways that are not obvious to the user — wrong slab, missing cess, outdated rates. A tax engine asked the same question cannot hallucinate. It computes or it fails. Failures are caught before reaching the user. Hallucinations are not.

The rule is: if it's a number that affects a financial decision, it comes from a deterministic engine. The LLM tells the user what the number means, not what the number is.

---

### Layer 4 — API Gateway

The API Gateway is how PennyWise becomes infrastructure rather than an app.

```
┌─────────────────────────────────────────────────────────────────────┐
│                          API GATEWAY                                │
│                                                                     │
│  Authentication: JWT + OAuth 2.0 (user) / API Key (partners)        │
│  Rate Limiting:  Per-plan, per-endpoint, per-user                   │
│  Versioning:     Semantic versioning, 2-version backward compat      │
│  Audit:          Every API call logged with caller, timestamp, input │
│                                                                     │
│  CONSUMER ENDPOINTS (authenticated user context)                    │
│  ─────────────────────────────────────────────────────────          │
│  GET  /financial-state          → Unified balance snapshot          │
│  GET  /safe-to-spend            → Real-time spendable balance       │
│  POST /simulate                 → "What if" simulation trigger      │
│  GET  /tax-estimate             → Current year tax projection       │
│  GET  /goals                    → All goals with projections        │
│  POST /ai/chat                  → Conversational AI interface       │
│  GET  /insights                 → Personalized daily insights       │
│  GET  /audit/{recommendation_id}→ Full reasoning trace              │
│                                                                     │
│  PARTNER ENDPOINTS (API key, scoped consent)                        │
│  ─────────────────────────────────────────────────────────          │
│  GET  /api/v1/tax-health        → Tax readiness score + gaps        │
│  GET  /api/v1/financial-score   → Financial Resilience Score        │
│  POST /api/v1/affordability     → Purchase impact analysis          │
│  GET  /api/v1/spending-insights → AI-generated insight payload      │
│  POST /api/v1/simulate          → Digital Twin scenario run         │
│                                                                     │
│  CA PLATFORM ENDPOINTS (CA firm authentication)                     │
│  ─────────────────────────────────────────────────────────          │
│  GET  /ca/clients               → CA's client list                  │
│  GET  /ca/clients/{id}/tax      → Client tax profile                │
│  POST /ca/clients/{id}/review   → CA annotation on financial state  │
│  GET  /ca/insights/batch        → Bulk insight generation           │
└─────────────────────────────────────────────────────────────────────┘
```

Every partner API call operates under explicit user consent scoped to that partner. A bank integration that calls `/financial-score` only receives data the user has consented to share with that bank. Consent is revocable at any time. Revocation is immediate and complete.

---

### Layer 5 — Infrastructure

**Technology choices are justified by the Constitution, not by trend.**

```
COMPONENT            CHOICE              REASON
─────────────────────────────────────────────────────────────────────
Primary Database     PostgreSQL          ACID compliance for financial
                                         data. No eventual consistency
                                         in a ledger.

Graph Database       Neo4j / ArangoDB    Financial Memory Graph and
                                         Economic Identity Graph
                                         require native graph traversal.

Cache                Redis               Session state, real-time
                                         Safe-to-Spend computation,
                                         rate limiting.

Message Bus          Apache Kafka        Event-driven architecture for
                                         transaction ingestion, AA
                                         webhook processing, async jobs.

AI Inference         LLM API (primary)   GPT-4o-mini or equivalent.
                     Local (fallback)    Quantized model for offline/
                                         degraded operation.

Document Storage     Encrypted S3-compat Zero-knowledge encryption.
                                         User data unreadable at rest
                                         without user key.

Search               Elasticsearch       Full-text search across
                                         transactions, documents.

Mobile               Flutter (Dart)      Single codebase: iOS + Android
                                         + Web.

Backend              Spring Boot / Java  Type safety for financial
                     (Current Phase)     calculations. Strongly typed
                                         decimal arithmetic.

Future Backend       Modular migration   Tax Engine, Simulation Engine
                     to domain services  extracted as independent
                                         services as scale requires.
```

---

## III. The Simulation Engine — Technical Detail

The Financial Digital Twin is the platform's highest-value technical component and deserves specific attention.

### How It Works

A simulation is a forward projection of the user's Financial Memory Graph under a defined variable.

```
INPUT SCHEMA
────────────────────────────────────────────
{
  "scenario": "job_change",
  "variables": {
    "new_monthly_income": 0,           // ₹0 for quit scenario
    "transition_months": 3,            // months until new income
    "new_income_after_transition": 150000
  },
  "horizon_months": 60,
  "simulations": 500,
  "seed": null                         // null = random, set for reproducibility
}

SIMULATION PROCESS
────────────────────────────────────────────
For each of N simulations:
  1. Apply variable to current financial state
  2. Model income stochastically (variance from history)
  3. Model expenses stochastically (variance from history)
  4. Apply all known fixed obligations (EMIs, SIPs, rent)
  5. Apply tax changes (new income bracket)
  6. Project forward month by month for horizon
  7. Record: runway, net worth at 12/24/60 months,
             retirement impact, goal impact

OUTPUT SCHEMA
────────────────────────────────────────────
{
  "scenario": "job_change",
  "simulations_run": 500,
  "confidence": "HIGH",               // based on data quality
  "outcomes": {
    "runway_months": {
      "p10": 8, "p50": 14, "p90": 22
    },
    "retirement_impact_years": {
      "p10": -0.5, "p50": +2.3, "p90": +5.1
    },
    "goal_impact": [
      { "goal": "house_down_payment", "delay_months_p50": 4 },
      { "goal": "emergency_fund", "impact": "none" }
    ]
  },
  "narrative_context": {
    "engine_output_id": "sim_a1b2c3",  // passed to LLM for explanation
    "key_driver": "transition_period_cash_burn"
  }
}
```

The narrative context is passed to the LLM layer, which generates the user-facing explanation:

> *"If you left your job today and took 3 months to find a new role at ₹1.5L/month, there's a 50% chance your cash runway would last 14 months — well above your 6-month emergency target. Your house down payment goal would be delayed by about 4 months. The biggest risk is the transition period: those 3 months of zero income would burn through roughly ₹1.8L of your buffer."*

The numbers come from the simulation. The language comes from the LLM. They are never mixed.

### Validation Requirements

Per the Constitution and strategic research, the simulation engine requires external validation before being shown to users as a planning tool.

Validation protocol:
1. **Backtesting:** Run simulations against 50–100 users' historical data (with consent) and compare predictions to actual outcomes. Target: p50 prediction within 15% of actual at 12-month horizon.
2. **Expert review:** Validation by at least two qualified financial planners and one academic economist before public launch.
3. **Confidence gating:** Simulations are only shown to users when the underlying data confidence is High or Medium-High. Low-confidence simulations are not surfaced — they are surfaced as data gaps instead.
4. **Annual recalibration:** Model parameters reviewed annually against aggregate outcomes data.

---

## IV. The Trust Architecture

Trust is not a feature. It is an engineering property.

### The Recommendation Chain

Every recommendation shown to a user is traceable through the following chain:

```
Raw Data (AA / SMS / PDF)
         │
         ▼
Ingestion + Confidence Tagging
         │
         ▼
Financial Memory Graph (structured facts)
         │
         ▼
Deterministic Engine (numerical output)
         │  ← This is the trust boundary.
         ▼    Numbers above here are facts.
         │    Numbers below here are derived.
Simulation / Recommendation Engine (derived insight)
         │
         ▼
LLM Layer (language output, references engine IDs)
         │
         ▼
Confidence + Audit ID attached
         │
         ▼
User-facing recommendation
         │
         ▼
Audit Trail (permanent log)
```

At any point in this chain, a user can request the full trace for any recommendation they have received. The audit trail stores it. The system retrieves it. This is Trust Law 6 — Auditable Calculations — as an engineering reality.

### The Confidence System

Every piece of information shown to a user carries one of four labels:

```
VERIFIED    → From AA, bank API, or government API. High confidence.
             Displayed: normal weight, no qualifier.

ESTIMATED   → From SMS parsing, PDF OCR, or pattern inference.
             Displayed: italicized or with "Est." marker.

PROJECTED   → From simulation or calculation based on historical
             patterns. Displayed with confidence range.
             (e.g., "₹4.2L–₹4.8L projected corpus at 3 years")

UNVERIFIED  → User-entered. Not cross-referenced.
             Displayed: marked "You entered this".
```

The UI is designed so that users always know which category they are looking at. No styling choice should make Estimated look like Verified.

### The Explainability Interface

Every recommendation in the app has an expandable "Why this?" section. Tapping it shows:

1. What data inputs drove this recommendation
2. Which engine computed the underlying numbers
3. What assumptions were made (and what happens if they're wrong)
4. What alternatives were considered
5. The confidence level and its basis

This is not a legal disclaimer. It is a genuine transparency mechanism. It should be readable by someone with no financial background and take under 60 seconds to understand.

---

## V. Resilience Architecture

The platform must remain valuable when components fail. This maps to Paper 4 from the strategic resilience research: technology infrastructure resilience.

### Degradation Tiers

```
TIER 1 — FULL OPERATION
All data sources live. All engines running. All AI active.
User sees: Complete financial picture, simulations, AI chat.

TIER 2 — AA DEGRADED
Account Aggregator down. SMS + PDF + cached data active.
User sees: Last-known balances with timestamp, SMS-derived
           real-time transactions, no simulation (data gap).
Notification: "Bank connections are refreshing. Showing last
              updated [timestamp]. Transactions from SMS are live."

TIER 3 — AI LAYER DEGRADED
LLM API unavailable. All deterministic engines active.
User sees: Calculated numbers and structured data without
           narrative explanations. Static insight library served.
Notification: Silent — no error shown. User sees numbers, not prose.

TIER 4 — SIGNIFICANT DEGRADATION
Only cached data available. Deterministic engines operating on stale data.
User sees: Last known state with clear staleness indicator.
           No new recommendations. Alerts for upcoming obligations
           (from cached schedule) still active.
Notification: "PennyWise is reconnecting. Your data is safe.
              Showing last updated [date/time]."

TIER 5 — MINIMAL OPERATION
Application boots, user is authenticated, no live data.
User sees: Upcoming obligations (stored locally), document vault,
           educational content. No financial calculations.
Notification: "We're experiencing connectivity issues.
              Your stored documents and upcoming dates are available."
```

The principle: PennyWise must always be more useful than a blank screen. At every tier, there is something valuable to show.

### Circuit Breakers

Every external dependency has a circuit breaker with:
- Failure threshold (e.g., 5 failures in 30 seconds)
- Open state duration (e.g., 60 seconds before retry)
- Half-open probe (1 request to test recovery)
- Fallback action (specific to each dependency)

External dependencies and their fallbacks:

```
DEPENDENCY              FALLBACK
─────────────────────────────────────────────────────────────────
Setu AA API             → Cached data + SMS parsing
OpenAI / LLM API        → Static insight library + no prose
CIBIL API               → Last known score with date
Government APIs         → Cached compliance deadlines
Payment Gateway         → Queue action, retry on restore
Email / Push Provider   → Queue notification, deliver on restore
```

---

## VI. Security and Privacy Architecture

### Data Classification

```
CLASS 1 — CRITICAL (highest protection)
  Bank credentials, AA consent tokens, authentication tokens.
  Storage: Never persisted. Session-only. Encrypted in transit only.

CLASS 2 — SENSITIVE (strong protection)
  Account balances, transaction history, tax data, income figures.
  Storage: Encrypted at rest (AES-256). Encrypted in transit (TLS 1.3).
           Database-level encryption + application-level encryption.
           User key derived from biometric/PIN for local decrypt.

CLASS 3 — PERSONAL (standard protection)
  Name, phone number, email, profile preferences.
  Storage: Encrypted at rest. Standard access controls.

CLASS 4 — BEHAVIORAL (aggregate only)
  Economic Identity Graph dimensions, spending patterns.
  Storage: User-linked but never shared. Used only for personalization.
           Never sold. Never used for advertising. Never aggregated
           for commercial purposes.
```

### Zero-Knowledge Design (Document Vault)

Documents stored in PennyWise (Form 16, rent receipts, medical bills) are encrypted with a key derived from the user's authentication credential. PennyWise infrastructure cannot read these documents. If a breach occurs at the infrastructure level, documents remain encrypted and unreadable.

This means:
- PennyWise cannot read your tax documents.
- PennyWise cannot hand your tax documents to a third party.
- A PennyWise employee cannot access your tax documents.
- Only you can decrypt them, with your credential.

The tradeoff: AI-powered document parsing must happen client-side or with explicit "unlock for parsing" consent where the user's key temporarily authorizes server-side decryption for that operation only.

### Consent Architecture

Every data access has a corresponding consent record:

```
CONSENT RECORD SCHEMA
──────────────────────────────────────────────────
{
  "user_id": "...",
  "data_type": "bank_transactions",
  "source": "hdfc_aa",
  "granted_at": "2026-01-15T09:32:00Z",
  "granted_for": ["pennywise_core"],
  "scope": "read_only",
  "revocable": true,
  "revoked_at": null,
  "expires_at": "2027-01-15T09:32:00Z"
}
```

Revoking consent immediately stops all data fetching from that source, triggers deletion of cached data from that source within 72 hours, and logs the revocation in the user's consent history.

---

## VII. The CA Platform Architecture

The CA Platform is architecturally a privileged application layer on top of the core platform — not a separate system.

```
┌─────────────────────────────────────────────────────────────────────┐
│                         CA PLATFORM                                 │
│                                                                     │
│  Authentication: CA firm account + client delegation consent        │
│                                                                     │
│  CA sees:                                                           │
│  • Client financial state (what client has consented to share)      │
│  • Tax profile: income, deductions, estimated liability             │
│  • Document status: what's uploaded, what's missing                 │
│  • AI-generated draft tax return (CA reviews and approves)          │
│  • Bulk insight generation for portfolio review                     │
│                                                                     │
│  CA does not see:                                                   │
│  • Data the client has not consented to share                       │
│  • Other clients' data                                              │
│  • Behavioral or psychological profile data                         │
│                                                                     │
│  CA can:                                                            │
│  • Annotate financial data with professional notes                  │
│  • Override an AI recommendation with professional judgment         │
│  • Request client action (document upload, signature)               │
│  • Export compliant tax filing documents                            │
│                                                                     │
│  Client consent for CA access:                                      │
│  • Explicit, per-CA, per-data-type                                  │
│  • Revocable instantly from the consumer app                        │
│  • Scoped: client can share tax data without sharing investments    │
└─────────────────────────────────────────────────────────────────────┘
```

When a CA overrides an AI recommendation, both the AI recommendation and the CA override are stored in the audit trail, with the CA's professional note. This creates a hybrid human-AI audit record that satisfies both user trust requirements and regulatory documentation standards.

---

## VIII. Sequencing — What Gets Built When

The architecture above describes the complete platform. Not all of it is built at once.

### Phase 1 — Foundation (Current → Month 12)

Build the parts that every other component depends on:

```
✓ Data Ingestion: SMS parser (live)
✓ Manual entry and categorization
✓ Basic Financial Memory Graph (transactions, goals, budgets)
◻ Account Aggregator integration (Setu AA)
◻ Tax Engine (deterministic: slabs, 80C/80D, HRA, advance tax)
◻ Cash Flow Engine (Safe-to-Spend calculation)
◻ Goal Engine (corpus projection, feasibility scoring)
◻ Audit Trail (foundational — must be built before recommendations)
◻ Confidence tagging system
◻ API Gateway (v1)
```

### Phase 2 — Intelligence (Month 6–18)

```
◻ Economic Identity Graph (passive behavioral tracking)
◻ LLM Layer (explanation, categorization, chat)
◻ Recommendation Engine (combines deterministic + LLM)
◻ Investment Engine (portfolio, SIP, rebalancing)
◻ Credit Engine (utilization, payoff optimization)
◻ Government API connectors (ITD/AIS, EPFO, DigiLocker)
◻ CA Platform (v1)
```

### Phase 3 — Simulation (Month 12–24)

```
◻ Simulation Engine (Financial Digital Twin, Monte Carlo)
◻ "What if" interface
◻ External validation of simulation accuracy
◻ PDF Statement Parser
◻ Document Vault (zero-knowledge encryption)
◻ Partner API Platform (external fintech integrations)
```

### Phase 4 — Infrastructure (Month 18–36)

```
◻ Enterprise API (employer wellness integrations)
◻ Banking API integrations (white-label financial health)
◻ Payroll provider integrations
◻ Domain service extraction (Tax Engine as independent service)
◻ Advanced Economic Identity Graph (high-confidence behavioral model)
```

---

## IX. Governing Principles for Every Engineering Decision

When an architectural decision is unclear, these questions are applied in order:

1. **Does this violate the Constitution?** If yes, the answer is no, full stop.

2. **Does this make the financial future more visible for the user?** If it doesn't serve the mission, the complexity cost is not justified.

3. **Is the math deterministic?** Any financial calculation must be in a deterministic engine. Never in an LLM.

4. **What is the degraded experience?** Every component must have a defined fallback. Build the fallback before the primary.

5. **Can we audit it?** If the system cannot explain why it showed a recommendation, the recommendation does not ship.

6. **What happens when this breaks?** Not if. When. Design for failure before designing for success.

---

*This document is version 1.0. It will be updated as the platform evolves.*

*Updates to the Security and Privacy sections, the Trust Architecture, and the Simulation Engine validation requirements require review by the founding team and, where applicable, qualified legal and regulatory counsel.*

*Any update that reduces user data protection, removes an audit capability, or relaxes the deterministic/AI boundary is not an update. It is a violation of the Constitution.*
