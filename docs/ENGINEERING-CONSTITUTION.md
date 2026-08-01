# The PennyWise Engineering Constitution

**Version 1.0 — Foundational Engineering Document**

*This document defines how PennyWise is built, how it scales, and the non-negotiable principles that govern every engineering decision. It is written to last 10 years, not to describe today's system.*

*The current system is a Spring Boot monolith serving hundreds of users. This document describes the architecture that serves hundreds of millions. The gap between the two is not closed in a rewrite — it is closed through deliberate, incremental evolution guided by these principles.*

---

## The Governing Idea

> Optimize for adding the next 10× of users without redesigning the platform.

Every architectural decision is evaluated against this criterion. An architecture that requires a complete rewrite to go from 100,000 users to 1,000,000 users has failed, regardless of how elegant it looks at 100,000.

The progression is not a target to design for all at once. It is a sequence of milestones, each of which the architecture must survive through incremental change:

```
TODAY      100s of users    Current monolith is correct
PHASE 1    10,000           Extract first domain services, add observability
PHASE 2    100,000          Multi-AZ, caching layer, read replicas
PHASE 3    1,000,000        Full domain service separation, Kafka event bus
PHASE 4    10,000,000       Multi-region active-passive, sharded storage
PHASE 5    100,000,000      Multi-region active-active, global edge
PHASE 6    500,000,000+     National infrastructure tier
```

The architecture described in this document is the destination. The migration strategy is the path. The monolith is not an embarrassment — it is the starting point. Premature extraction of microservices before product-market fit is one of the most common causes of early-stage engineering failure.

---

## The Ten Engineering Principles

These are constraints, not guidelines. Code that violates them does not ship.

### Principle 1 — Availability First

No single point of failure in any system path that serves users.

For every component: if this component fails completely, what happens to the user? If the answer is "the product stops working," that component must have a redundant path, a graceful degradation mode, or both.

The target availability by service tier:

```
TIER          SERVICE TYPE                        TARGET SLO
────────────────────────────────────────────────────────────
Critical      Authentication, Safe-to-Spend,      99.99%
              Core financial state display         (~52 min/year downtime)

High          Transaction sync, Tax Engine,        99.9%
              Goal tracking                        (~8.7 hrs/year downtime)

Standard      AI insights, Reports,                99.5%
              Document processing                  (~43 hrs/year downtime)

Background    Simulation Engine, Batch jobs,       99%
              Analytics                            (~87 hrs/year downtime)
```

99.99% does not happen accidentally. It requires redundant infrastructure, automatic failover, health checks with aggressive timeouts, and circuit breakers. It requires having failed over in practice — not just in theory.

### Principle 2 — Security by Design

Security is designed into the system before code is written, not added afterward.

For every new feature or service:
- Threat model before architecture
- Minimum necessary permissions (least privilege)
- No credentials in source code, configuration files, or logs — ever, without exception
- Every external input is untrusted until validated
- Every internal service-to-service call is authenticated

Zero Trust networking: no service trusts another service by virtue of network position. Every request carries identity, and every service verifies it. An attacker who compromises one service cannot freely move to another.

### Principle 3 — Privacy by Design

Refer to the Privacy & Security Constitution for full detail. The engineering summary:

- Collect the minimum data necessary for the stated function
- Encrypt at the field level for Class 2 data (financial records), not just at the database level
- Design APIs to return only the fields the caller needs, not full records
- Build deletion as a first-class feature from day one — retrofitting data deletion onto a mature system is expensive and error-prone
- Every data collection point has a defined retention period before the code is written

### Principle 4 — Observability Everywhere

You cannot operate what you cannot see.

Every service exposes three pillars of observability:

**Metrics** — quantitative signals about system behavior
- Request rate, error rate, latency (p50, p95, p99) for every endpoint
- Business metrics alongside technical metrics (Safe-to-Spend calculation time, tax estimate accuracy)
- Resource utilization, saturation, and error rates (USE method per service)

**Traces** — the path of a request through the system
- Distributed tracing across all service boundaries (OpenTelemetry)
- Every user-facing request traceable from API gateway to database and back
- Trace IDs present in all log lines for correlation

**Logs** — structured records of discrete events
- JSON-structured logs, never unstructured strings
- Correlation ID present on every log line
- Log levels enforced: DEBUG for development, WARN/ERROR for production
- Sensitive data never in logs (account numbers, tax IDs, amounts — obfuscated)

The alert standard: every SLO breach must trigger an alert before users notice. Alerts fire on symptoms (user-visible degradation), not causes (CPU usage). An alert that fires when CPU hits 80% but the p99 latency is fine is noise. An alert that fires when p99 latency exceeds 2 seconds when it is normally 200ms is signal.

### Principle 5 — Backward Compatibility

APIs evolve without breaking clients.

**The API versioning contract:**
- Version in the URL path (`/api/v1/`, `/api/v2/`)
- Two versions supported simultaneously (current + previous)
- Minimum 12-month deprecation notice before removing a version
- Breaking change definition: removing a field, changing a field type, changing authentication requirements, changing error response format
- Additive changes (new fields, new endpoints) are not breaking and do not require version increments

**The event schema contract:**
- Events are versioned and schema-registered (Apache Avro or Protocol Buffers)
- Consumers must handle unknown fields gracefully (schema evolution rule)
- Events are never deleted from the event bus — consumers that miss events can replay
- Event format changes follow the same 12-month deprecation cycle as APIs

**The internal consequence of this principle:** it costs more to maintain backward compatibility than to break it. We pay that cost. Downstream clients — partner integrations, CA platform users, enterprise dashboard customers — cannot absorb surprise breaking changes. The cost of breaking their systems is always greater than the cost of maintaining compatibility.

### Principle 6 — Automation First

Manual operational work decreases continuously. Toil is a debt that compounds.

The deployment pipeline is non-negotiable:

```
Developer pushes code
         │
         ▼
Automated tests (unit + integration + contract)
         │
         ▼
Security scan (SAST, dependency CVE check)
         │
         ▼
Build and containerize
         │
         ▼
Deploy to staging
         │
         ▼
Automated smoke tests on staging
         │
         ▼
Performance regression check
         │
         ▼
Canary deploy to 5% of production traffic
         │
         ▼
Monitor for 15 minutes (error rate, latency, business metrics)
         │
         ▼
Roll forward to 100%  ──OR──  Automatic rollback if alerts fire
```

No manual steps between code push and production. Human approval gates are acceptable at the staging → production boundary for major releases. They are not acceptable as a substitute for automated testing.

Runbooks for every operational procedure. If a human must perform a recurring operational task, that task has a runbook. If it has been performed more than three times from the same runbook, it is a candidate for automation.

### Principle 7 — Data Integrity Above Speed

Financial correctness always outweighs raw performance.

When there is a tradeoff between eventual consistency and strong consistency, financial data chooses strong consistency. A user's account balance must be correct, not fast. A tax calculation must be reproducible, not cached.

The practical implications:
- Use transactions (ACID) for financial writes — no eventual consistency for ledger data
- Prefer synchronous confirmation for money-related events over asynchronous fire-and-forget
- Cache derived data (dashboard summaries, insights), never authoritative data (balances, transaction records)
- When a cache is stale, show the staleness rather than showing stale data as current
- Every financial calculation must be idempotent — running it twice produces the same result, not double the result

### Principle 8 — Graceful Degradation

If one subsystem fails, the platform continues operating with reduced functionality rather than going fully offline.

The degradation tiers for each service:

```
SERVICE            PRIMARY FAILURE      DEGRADED BEHAVIOR
──────────────────────────────────────────────────────────────────────
Account Aggregator  Setu AA down        Show last-known balances
                                        with timestamp. SMS live.

LLM / AI Layer      API unavailable     Static insights from library.
                                        Numbers shown, no narrative.

Tax Engine          Service down        Show last calculation with
                                        staleness warning. No new
                                        estimates until restored.

Simulation Engine   Service down        Disable "What if" UI.
                                        Show static goal projections.

Notification Svc    Queue backup        Queue messages, deliver
                                        when restored. Not dropped.

Document Service    Storage unavailable Show cached document list.
                                        Uploads queued locally.
```

Every degraded state has defined user-facing behavior and communication. "Service unavailable" is never the user experience. "We're updating your data — here's what we know so far" is always available as a fallback.

### Principle 9 — Cost-Aware Scalability

100 million users must be economically sustainable. Architecture that is technically correct but financially ruinous is not a success.

Cost modeling at each scale tier:

```
SCALE           INFRA COST TARGET     REVENUE CONTEXT
────────────────────────────────────────────────────────────────
10,000 users    < ₹50,000/month       Pre-revenue, investor-funded
100,000 users   < ₹3,00,000/month     CA platform revenue covers
1,000,000       < ₹15,00,000/month    Premium subscriptions cover
10,000,000      < ₹1,00,00,000/month  Enterprise contracts cover
100,000,000     Unit economics proven  Platform-level margins
```

Cost awareness is an engineering discipline:
- Every new service has a cost estimate before it is built
- Expensive operations (LLM inference, simulation runs) are metered and have fallbacks
- Data storage has TTLs — data that is not needed is not kept
- Compute autoscales down, not just up
- Reserved capacity for predictable baseline, spot/preemptible for burst

### Principle 10 — Continuous Verification

Regularly test failure scenarios, recovery, and security. Do not assume systems that have not been tested will work when needed.

**Game Days** — scheduled exercises where real failure modes are induced in controlled conditions:
- Once per quarter per critical service
- Scenarios: primary database failure, AZ outage, LLM provider outage, spike load (10x normal)
- Each game day produces a written report with what worked, what broke, what is being fixed

**Chaos Engineering** — automated, continuous low-level fault injection in non-production environments:
- Random service latency injection
- Random dependency failure injection
- Partial network partition simulation
- The goal: find failures before users do

**Recovery Testing** — backup and disaster recovery procedures are tested, not just documented:
- Backup restoration tested monthly
- Full DR failover drill twice per year
- RTO (Recovery Time Objective) and RPO (Recovery Point Objective) measured, not estimated

---

## The Platform Architecture

### The Layered System

```
┌─────────────────────────────────────────────────────────────────────┐
│                          USER LAYER                                 │
│                                                                     │
│  Flutter (iOS / Android / Web)    CA Web Platform    Partner SDKs  │
│                                                                     │
└─────────────────────────────────────────────┬───────────────────────┘
                                              │
┌─────────────────────────────────────────────▼───────────────────────┐
│                       GLOBAL API GATEWAY                            │
│                                                                     │
│  Authentication │ Rate Limiting │ Request Routing │ Response Cache  │
│  TLS Termination │ API Versioning │ Audit Logging │ Circuit Breaker │
│                                                                     │
└──────────────────────┬──────────────────────┬───────────────────────┘
                       │                      │
          ┌────────────▼──────────┐  ┌────────▼────────────┐
          │    DOMAIN SERVICES    │  │    AI PLATFORM      │
          │                       │  │                     │
          │  User Service         │  │  Tax Agent          │
          │  Transaction Service  │  │  Budget Agent       │
          │  Budget Service       │  │  Investment Agent   │
          │  Goal Service         │  │  Document Agent     │
          │  Tax Service          │  │  Fraud Agent        │
          │  Investment Service   │  │  Simulation Agent   │
          │  Notification Service │  │  Learning Agent     │
          │  Document Service     │  │  Retirement Agent   │
          │  Identity Service     │  └────────┬────────────┘
          │  Consent Service      │           │
          └────────────┬──────────┘           │
                       │                      │
          ┌────────────▼──────────────────────▼───────────┐
          │                 EVENT BUS (Kafka)              │
          │                                               │
          │  financial.transactions.created               │
          │  financial.salary.credited                    │
          │  tax.estimate.updated                         │
          │  goal.progress.changed                        │
          │  security.anomaly.detected                    │
          │  consent.revoked                              │
          └────────────────────────┬──────────────────────┘
                                   │
          ┌────────────────────────▼──────────────────────┐
          │               DATA LAYER                      │
          │                                               │
          │  PostgreSQL (users, transactions, goals)      │
          │  Distributed SQL (high-scale transactions)    │
          │  Redis (cache, sessions, rate limits)         │
          │  Object Storage (documents, encrypted)        │
          │  Vector DB (AI memory, embeddings)            │
          │  Search (Elasticsearch / OpenSearch)          │
          │  Data Warehouse (analytics, reporting)        │
          └───────────────────────────────────────────────┘
```

### Layer 1 — User Layer

One backend platform. Multiple client surfaces.

The client surfaces are thin. They render data and capture user intent. They do not contain business logic. Tax calculations, goal projections, financial rules — none of these live in the client. This means:

- A bug in a calculation is fixed in one place, instantly affecting all clients
- A new client surface (wearable, voice assistant, partner white-label) inherits all intelligence immediately
- The Flutter app is the first client, not the only client

Client responsibilities:
- Authentication (biometric, PIN, OTP flows)
- Rendering data from API responses
- Local-first caching with defined staleness behavior
- On-device processing (OCR, SMS parsing, notification display)
- User intent capture and API call dispatch

### Layer 2 — API Gateway

Every request from every client passes through the API Gateway. No client calls a domain service directly.

The Gateway provides:

**Authentication** — JWT verification, OAuth token validation, API key validation for partners. The gateway rejects unauthenticated requests before they reach services.

**Rate Limiting** — per-user, per-partner, per-endpoint. Financial APIs have lower rate limits than informational APIs. Simulation requests (expensive) have lower limits than balance requests (cheap). Rate limit headers are returned on every response so clients can self-throttle.

**Routing** — request routing to the correct domain service version. Canary routing (5% of traffic to new version during deployment). A/B test traffic splitting.

**Caching** — response caching for safe, idempotent endpoints. Cache keys include the user identity and relevant parameters. Cache invalidation triggered by domain events.

**Audit Logging** — every request logged with: timestamp, endpoint, user/partner identity, response code, latency, request size. This is the foundation of the Trust Ledger.

**Circuit Breaker** — if a downstream service begins failing, the gateway opens the circuit and returns the defined degraded response rather than queuing requests that cannot be served.

### Layer 3 — Domain Services

Domain services own a bounded context. They do not share databases. They communicate through events or synchronous API calls, never through shared database access.

**Service Ownership Rules:**
- One team owns one service
- The team that owns a service owns its database schema, its API contract, and its deployment
- No service reads another service's database — it calls that service's API
- Services are sized by business domain, not by technical function

**Service catalogue (target state):**

```
SERVICE              OWNS                        EVENTS PUBLISHED
───────────────────────────────────────────────────────────────────────
User Service         User profile, preferences   user.created
                     Onboarding state            user.profile.updated
                                                 user.deleted

Transaction Svc      All financial transactions  transaction.created
                     Categorization              transaction.categorized
                     Merchant data               transaction.disputed

Budget Service       Budget limits               budget.limit.set
                     Budget alerts               budget.threshold.breach

Goal Service         Financial goals             goal.created
                     Progress tracking           goal.milestone.reached
                     Contribution schedules      goal.completed

Tax Service          Tax profile                 tax.estimate.updated
                     Deduction tracking          tax.deadline.approaching
                     Advance tax schedule        tax.document.generated

Investment Svc       Portfolio state             portfolio.synced
                     SIP schedules               portfolio.rebalanced
                     Asset allocation

Notification Svc     Notification queue          (consumer only)
                     Delivery status
                     User preferences

Document Service     Document metadata           document.uploaded
                     Storage references          document.processed
                     OCR job management          document.deleted

Identity Service     Authentication              auth.login.success
                     Session management          auth.anomaly.detected
                     Device registry             auth.session.revoked

Consent Service      AA consent records          consent.granted
                     Partner permissions         consent.revoked
                     Trust Ledger entries        consent.expired
```

**Service migration strategy (from current monolith):**

The Strangler Fig pattern. New services are carved out of the monolith one domain at a time, starting with the domains that need independent scaling and the domains with the clearest boundaries.

Extraction order (recommended):
1. Identity Service — Authentication is the most critical and most independent
2. Notification Service — Fully decoupled, safe to extract first
3. Document Service — Independent storage concerns, no complex dependencies
4. Tax Service — Clear domain boundary, high-value independent scaling
5. Goal Service — Moderate dependencies, extractable
6. Transaction Service — High volume, needs independent scaling, higher extraction complexity
7. Budget Service — Depends on transactions, extract after Transaction Service
8. Investment Service — Complex AA dependencies, extract with AA integration work

The monolith remains authoritative until a service is fully extracted and verified. The strangler fig means the monolith shrinks, it is never replaced all at once.

### Layer 4 — Event-Driven Architecture

Services communicate asynchronously through events for all non-real-time interactions.

**The event model:**

```
EVENT SCHEMA (Apache Avro / Protocol Buffers)
─────────────────────────────────────────────
{
  "event_id":        UUID        // globally unique
  "event_type":      string      // "transaction.created"
  "event_version":   string      // "1.0"
  "occurred_at":     timestamp   // when the fact happened
  "published_at":    timestamp   // when the event was published
  "source_service":  string      // "transaction-service"
  "user_id":         string      // owner of the affected data
  "correlation_id":  string      // traces the original request
  "payload":         object      // event-specific data
}
```

**Key event flows:**

```
SALARY CREDITED
──────────────────────────────────────────────────────────────
Transaction Service  → publishes: transaction.created (type: CREDIT)
                     → publishes: financial.salary.credited

Tax Service          → consumes: financial.salary.credited
                     → recalculates advance tax estimate
                     → publishes: tax.estimate.updated

Goal Service         → consumes: financial.salary.credited
                     → checks if auto-contribution scheduled
                     → publishes: goal.contribution.queued

Notification Service → consumes: financial.salary.credited
                     → consumes: tax.estimate.updated
                     → assembles: "Salary of ₹X credited. Tax vault
                                   updated. ₹Y safe to spend."
                     → publishes: notification.push.requested

Budget Service       → consumes: financial.salary.credited
                     → resets monthly budget periods if applicable
```

No service calls another synchronously for this flow. Each service does its job independently. If the Tax Service is slow, it does not slow down the Transaction Service. If the Notification Service is down, events queue and deliver when it recovers.

**Event bus governance:**
- Topic naming: `{domain}.{entity}.{verb}` (e.g., `tax.estimate.updated`)
- Retention: 7 days minimum, 30 days for financial events
- Consumer groups: each consumer has a named group for independent offset tracking
- Schema registry: all schemas versioned and registered before use
- Dead letter queues: events that fail processing after N retries go to DLQ for manual review

### Layer 5 — Multi-Region

The goal is active-passive multi-region by Phase 3 (1,000,000 users), active-active by Phase 5.

**Phase 2 (100,000 users) — Multi-AZ single region:**
- Primary database with synchronous replication to standby
- Application deployed across 3 availability zones
- Load balanced across AZs
- Automated AZ failover (< 30 second RTO for AZ failure)

**Phase 3 (1,000,000 users) — Active-passive multi-region:**
- Primary region (India) handles all writes
- Secondary region (India different zone or Singapore) receives replication
- Read traffic can be served from secondary
- Automated failover to secondary for primary region failure (< 5 minute RTO)
- RBI data residency: all Indian user financial data stored on Indian soil

**Phase 5 (100,000,000 users) — Active-active multi-region:**
- Writes routed to nearest region
- Conflict resolution for distributed writes to financial ledgers
- Global load balancing with latency-based routing
- Per-region compliance (data that must stay in India stays in India)

### Layer 6 — Data Architecture

Each data type uses the storage system designed for its access patterns.

```
DATA TYPE               STORAGE             REASON
──────────────────────────────────────────────────────────────────────
User profiles           PostgreSQL          ACID, relational, moderate
                                            scale, strong consistency

Transactions            PostgreSQL          ACID required, financial
(< 10M users)           (partitioned)       data integrity

Transactions            Distributed SQL     Horizontal scale, ACID
(> 10M users)           (CockroachDB /      maintained, multi-region
                         PlanetScale)

Documents               Encrypted object    Content-addressable,
                         storage            append-only, any size

Search index            Elasticsearch /     Full-text search across
                         OpenSearch         transactions, insights

AI memory /             Vector database     Semantic similarity,
embeddings              (Pinecone / Weaviate) embedding storage for
                                            AI context retrieval

Analytics               Data warehouse      Columnar, append-only,
                         (BigQuery /         not transactional
                         ClickHouse)

Sessions / Cache        Redis               Sub-millisecond, evictable,
                                            no durability requirement

Event stream            Apache Kafka        High-throughput, ordered,
                                            replayable
```

**Database-per-service rule:** When a domain service is extracted, its data moves with it. The Tax Service owns its tax data in its own database. No other service reads that database directly. This enables:
- Independent schema migration
- Independent scaling
- Failure isolation (Tax Service database issue does not affect Transaction Service)

### Layer 7 — AI Agent Platform

The AI layer is not a single model. It is a collection of specialized agents, each with a defined scope and a hard prohibition on making financial calculations.

```
AGENT              ROLE                          PROHIBITED FROM
────────────────────────────────────────────────────────────────────
Tax Agent          Explains tax concepts and      Calculating actual
                   answers tax questions.         tax liability.
                   Reads Tax Engine outputs.      (Tax Engine does this.)

Budget Agent       Personalized budget advice.    Calculating budget
                   Behavioral insights.           limits. (Budget
                   Spending pattern analysis.     Service does this.)

Investment Agent   Investment education.          Recommending specific
                   Product explanations.          investment amounts.
                   Suitability awareness.         (Investment Engine
                                                  does this.)

Fraud Agent        Transaction anomaly flags.     Blocking transactions.
                   Scam pattern detection.        (Identity Service
                   Alert generation.              does this.)

Document Agent     Form 16 parsing.               Calculating TDS
                   Receipt extraction.            amounts from parsed
                   PDF data extraction.           forms. (Tax Engine
                                                  does this.)

Simulation Agent   "What if" question handling.   Running simulations.
                   Scenario explanation.          (Simulation Engine
                   Result narration.              does this.)

Retirement Agent   Retirement planning guidance.  FIRE corpus
                   Life stage coaching.           calculation.
                   Goal milestone coaching.       (Goal Engine
                                                  does this.)
```

**Agent communication model:**

```
User question: "What happens if I invest ₹5,000/month in an index fund for 15 years?"

                              │
                              ▼
                    ROUTER (LLM classifier)
                    "This is a simulation + investment question"
                              │
               ┌──────────────┼──────────────┐
               ▼              ▼              ▼
      Simulation Engine   Investment     Goal Engine
      (runs corpus calc)  Agent context  (goal alignment)
               │              │              │
               └──────────────┼──────────────┘
                              ▼
                    Simulation Agent receives:
                    - Corpus at 15 years: ₹16,22,000 (deterministic)
                    - XIRR assumption: 12% (engine input)
                    - Goal alignment: covers 73% of retirement target
                              │
                              ▼
                    Agent generates explanation:
                    "At 12% assumed annual returns, ₹5,000/month
                     for 15 years compounds to approximately
                     ₹16.2 lakhs. This covers about 73% of your
                     retirement target based on your current goal.
                     Here's how the contributions break down..."
```

The number (₹16,22,000) comes from the engine. The explanation comes from the agent. They are never the same process.

### Layer 8 — Security Architecture

**Zero Trust model:** Every service call is authenticated. Network position grants no trust. An attacker who compromises a service in the internal network cannot call other services without valid credentials.

**Service-to-service authentication:** mTLS between all services. Each service has a certificate. Certificates are rotated automatically. Expired certificates cause authentication failure, not silent fallback.

**Secret management:** No secrets in code, configuration files, environment variables passed directly, or container images. All secrets managed via a secrets management system (HashiCorp Vault or cloud-equivalent). Secrets accessed at runtime, not at build time. Secrets rotated automatically where possible.

**HSM for critical keys:** Document encryption keys, AA consent tokens, and authentication signing keys are managed in Hardware Security Modules where available. Keys are never exported from the HSM.

**Supply chain security:**
- Dependency lock files committed and enforced
- All dependencies scanned for CVEs on every build
- No dependency updated without a human review of the changelog
- Container base images pinned to digests, not tags
- SBOM (Software Bill of Materials) generated and stored for every release

### Layer 9 — Reliability Engineering

**SLO monitoring:** Every SLO has an error budget. If the error budget is consumed faster than expected, feature development pauses and reliability work takes priority. This is a hard rule, not a guideline.

**Deployment strategy:**

```
CHANGE TYPE          DEPLOYMENT STRATEGY        ROLLBACK TIME
─────────────────────────────────────────────────────────────
Bug fix              Canary (5% → 25% → 100%)  Immediate
New feature          Canary + feature flag      Immediate (flag off)
Schema migration     Backward-compatible first  Hours (multi-step)
Breaking API change  New version parallel run   Days (versioning)
Infrastructure       Blue-green                 Minutes
```

**Incident severity levels:**

```
SEV-1  Data loss or corruption, authentication failure,
       financial calculation errors affecting users.
       Response: immediate all-hands, user notification within 1 hour.

SEV-2  Core feature unavailable for >10% of users (Safe-to-Spend
       down, transaction sync down).
       Response: on-call engineer + backup within 15 minutes.

SEV-3  Degraded feature, increased latency, isolated failures.
       Response: on-call engineer within 1 hour, business hours fix.

SEV-4  Non-critical feature degraded, cosmetic issues.
       Response: next business day.
```

**Post-incident protocol:**
- Every SEV-1 and SEV-2 produces a blameless post-mortem within 48 hours
- Post-mortem includes: timeline, root cause, impact, contributing factors, action items
- Action items have owners and deadlines, tracked to completion
- Post-mortems are shared internally — a culture of learning, not blame

### Layer 10 — Platform Engineering

The goal: developers think about product, not servers.

**Developer experience targets:**
- Time from code push to production: < 30 minutes for standard changes
- Time to spin up a local development environment: < 15 minutes
- Time to run the full test suite: < 10 minutes
- Time to debug a production issue with traces and logs: < 5 minutes to identify the relevant service

**Infrastructure as Code:** Every infrastructure resource defined in code (Terraform or equivalent). No manually-created cloud resources in production. If it is not in version control, it does not exist.

**Environment parity:** Development, staging, and production are architecturally identical. The only difference is scale. A bug that cannot be reproduced in development because the environment is different is a platform failure.

---

## The Scale Architecture Studies

Before building at each scale tier, the engineering team studies how world-class systems solved the same problems. Not to copy — to understand the principles.

```
STUDY TARGET         KEY PRINCIPLES TO EXTRACT
──────────────────────────────────────────────────────────────────────
Google (Borg/        Container orchestration, large-scale distributed
Kubernetes, Spanner) consensus, global consistent distributed databases,
                     SRE practices and error budget model

Amazon               Two-pizza team + microservices origin, event-driven
                     decoupling, "you build it, you run it" culture,
                     six-page memo culture for technical decisions

Netflix              Chaos engineering as discipline, resilience patterns
                     (hystrix, circuit breaker patterns), cache
                     architecture for global scale

Stripe               Financial platform architecture, API versioning at
                     scale, handling payment idempotency, compliance
                     without sacrificing developer experience

Visa                 High-availability payment processing at extreme scale
                     (24,000+ TPS peak), global redundancy, sub-100ms
                     authorization at planetary scale

Cloudflare           Edge architecture, anycast routing, DDoS mitigation,
                     zero-trust networking implementation

Uber                 Distributed systems under extreme consistency
                     requirements, geospatial data at scale,
                     real-time matching architecture

India Stack          UPI architecture, Account Aggregator technical
                     specification, DigiLocker integration patterns,
                     OCEN protocol, ONDC architecture
```

The India Stack study is not optional. PennyWise is built on top of Indian financial infrastructure. Understanding how UPI, AA, and OCEN are architected is not background reading — it is prerequisite knowledge for every engineer who works on integrations.

---

## Non-Negotiable Technical Standards

### Code Standards

- **No magic numbers in financial calculations.** Every constant has a named variable with a comment explaining its source (e.g., `SECTION_80C_LIMIT = 150_000 // Income Tax Act Section 80C annual limit`)
- **Decimal arithmetic for all money.** Never floating point for financial values. `BigDecimal` in Java, `Decimal` in Python, `numeric` in PostgreSQL. A floating point rounding error in a tax calculation is a compliance failure.
- **Idempotency keys on all financial writes.** A retry of a failed request must not create a duplicate transaction.
- **Timeouts on all external calls.** No call to an external service without a defined timeout and defined behavior on timeout.
- **No synchronous calls in event consumers.** Event processors must not make synchronous calls that can fail and block the consumer group.

### Testing Standards

```
TEST TYPE              COVERAGE TARGET      APPLIES TO
──────────────────────────────────────────────────────────────────────
Unit tests             All business logic   Deterministic engines
                       (tax calculations,    required: 100% of
                       corpus projections,   calculation paths
                       EMI formulas)

Integration tests      All service-to-      Domain services,
                       service contracts    API contracts

Contract tests         All published APIs   API Gateway,
                       and events           service boundaries

End-to-end tests       Critical user        Authentication flow,
                       journeys             Safe-to-Spend display,
                                           Goal creation,
                                           Tax estimate

Performance tests      P95 latency < 500ms  All user-facing
                       P99 latency < 2s     endpoints
                       Before every release

Security tests         OWASP Top 10 check   Every release
                       Penetration test      Before major releases
```

Tax engine tests deserve special attention. Every tax calculation rule must have a test. When the Finance Minister changes a tax slab in the Budget, the broken test is how the engineering team knows exactly what to update.

### API Design Standards

```
PRINCIPLE             RULE
──────────────────────────────────────────────────────────────────────
Resource naming       Plural nouns: /transactions, /goals, /budgets
                      Never verbs: not /getTransactions, /createGoal

HTTP semantics        GET = safe and idempotent
                      POST = create (may not be idempotent)
                      PUT = replace (idempotent)
                      PATCH = partial update (idempotent)
                      DELETE = remove (idempotent)

Error responses       RFC 7807 Problem Details format
                      Machine-readable code + human-readable message
                      Never expose internal stack traces

Pagination            Cursor-based for large collections
                      Limit default: 20, max: 100
                      Never offset-based pagination for financial data

Amounts               Always in paise (smallest unit), never rupees
                      Display formatting is client responsibility
                      "amount": 150000 = ₹1,500.00

Timestamps            ISO 8601 with timezone: "2026-07-22T10:32:00+05:30"
                      Never Unix epoch in user-facing APIs

Versioning            /api/v1/, /api/v2/ — major version in path
                      Minor versions via headers, not path
```

---

## The Engineering Decision Framework

When an architectural decision is unclear, ask these questions in order:

1. **Does this violate the Privacy & Security Constitution?** If yes: no.

2. **Does this violate the 10 Engineering Principles?** If yes: no.

3. **What happens when this fails?** Not if. When. Is the failure mode acceptable?

4. **What does this look like at 10x our current scale?** If the answer is "we'd need to redesign it," we are either building it wrong now or we document explicitly that this is a known tech debt with a defined migration path.

5. **Can we test that it works?** If it cannot be tested automatically, it should not be in production unmonitored.

6. **Is this the boring solution?** In financial infrastructure, boring is a virtue. A well-understood, widely-deployed technology with known failure modes is almost always preferable to a novel technology with unknown failure modes. Choose boring. The product innovation happens in the product. The infrastructure should be invisible.

---

*This document describes the architecture PennyWise is building toward, not the system that exists today. The gap between them is closed through the Strangler Fig migration, the extraction of domain services, and the layering of infrastructure capabilities as scale requires them.*

*No architectural decision is permanent. This document will be revised as the system evolves, as new scale requirements emerge, and as the engineering team learns from operating the system in production.*

*What is permanent is the principles. The specific technology choices will change. PostgreSQL may become CockroachDB. Spring Boot may become a mix of services in multiple languages. The API Gateway will change. The event bus will evolve. The principles — availability, integrity, privacy, observability, reversibility — do not change.*
