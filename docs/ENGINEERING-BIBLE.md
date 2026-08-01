# The PennyWise Engineering Bible

**Version 1.0 — Engineering Standards Document**

_This document is the engineering equivalent of the PennyWise Constitution. Where the Constitution governs what PennyWise promises users, this document governs how every engineer builds toward those promises._

_It is not a feature specification. It is not a roadmap. It is a set of engineering standards that apply to every line of code, every database change, every AI prompt, and every deployment — from the first engineer to the hundredth._

_Every new engineer reads this before writing production code. Every PR is evaluated against it. Every technical decision is traceable to a principle within it._

---

## The Eight-Question PR Gate

Before any code merges to main, the author answers these questions. If any answer is No, the PR does not merge.

```
1. Is it secure?
   Does this introduce a vulnerability, expose a secret, or weaken
   an existing control?

2. Is it observable?
   Will we know if this breaks? Are there metrics, traces, and logs?

3. Is it testable?
   Does it have unit tests? Integration tests where needed?

4. Is it scalable?
   Does it introduce an N+1 query, an unbounded list, or a blocking
   call that will degrade under load?

5. Is it backwards compatible?
   Does it break existing API clients, mobile app versions, or
   partner integrations?

6. Does it reduce technical debt?
   If it adds debt, is that debt documented and scheduled for
   resolution?

7. Does it respect privacy?
   Does it collect only necessary data? Is sensitive data protected?
   Is it logged safely?

8. Is it explainable?
   For AI features: can we explain the output? For financial
   features: can the user understand the result?
```

These are not aspirational. They are merge blockers. A PR that passes all eight ships. A PR that fails one does not.

---

## Section 1 — Architecture Principles

### The Foundation

PennyWise is a platform, not an application. Every engineering decision is evaluated against this:

> Does this make the platform more capable, more reliable, and more extensible — or does it make it more complex without equivalent value?

### Principles

**P1 — Separation of Concerns**
Business logic lives in services. Persistence logic lives in repositories. Request/response mapping lives in controllers. Logic that belongs in one layer does not migrate to another. A controller that performs calculations is a bug. A repository that contains business rules is a bug.

**P2 — Determinism Before Intelligence**
Financial calculations are deterministic. They do not go through AI models. Tax computations, EMI calculations, corpus projections, Safe-to-Spend balances — these are calculated by typed, tested, auditable engines. AI models explain results. They do not produce them.

**P3 — Explicit Over Implicit**
Code that does what it says is preferable to clever code that requires context to understand. Configuration that is explicit is preferable to configuration by convention that surprises the next reader. The goal is code that a capable engineer who has never seen this codebase can understand in under 5 minutes.

**P4 — Design for Failure**
Every component fails. Design assumes failure, not uptime. Every external dependency has a defined fallback. Every service call has a timeout. Every queue has a dead letter path. The failure path is designed with the same care as the success path.

**P5 — Own Your Domain**
A service owns its data. It does not read another service's database directly. It does not write to another service's database. Cross-service communication is through APIs (synchronous) or events (asynchronous), never through shared storage.

**P6 — Boring is a Virtue**
Financial infrastructure is not the place to evaluate new technology. Proven, well-understood technology with known failure modes is preferred over novel technology with unknown failure modes. When a well-established solution exists, use it. Novel choices require documented justification.

### Anti-Patterns

- God classes (services > 300 lines without clear justification)
- Logic in DTOs or entities
- Controllers making multiple service calls that should be one service call
- Circular dependencies between packages
- Shared database state between services

---

## Section 2 — Coding Standards

### Java / Spring Boot

**Naming**

- Classes: `UpperCamelCase` — `TransactionService`, `GoalRepository`
- Methods: `lowerCamelCase` — `calculateMonthlyContribution()`, `findByUserId()`
- Constants: `SCREAMING_SNAKE_CASE` — `SECTION_80C_ANNUAL_LIMIT = 150_000`
- No abbreviations in public APIs: `amt` → `amount`, `usr` → `user`, `txn` → `transaction`

**Financial Arithmetic**

- Use `BigDecimal` for all monetary values. Never `float` or `double`.
- Always specify `RoundingMode` explicitly. Never rely on defaults.
- Always specify scale. A tax calculation rounded to 2 decimal places at the wrong step produces a different result than one rounded at the final step.
- The constant `ZERO` is `BigDecimal.ZERO`. Not `new BigDecimal(0)`. Not `BigDecimal.valueOf(0)`.

```java
// WRONG
double tax = income * 0.30;

// WRONG
BigDecimal tax = BigDecimal.valueOf(income).multiply(BigDecimal.valueOf(0.30));

// CORRECT
BigDecimal tax = income.multiply(TAX_RATE_30_PERCENT)
                       .setScale(2, RoundingMode.HALF_UP);
```

**Constants**
Every magic number in a financial calculation has a named constant with a source comment.

```java
// WRONG
if (score < 0.80) { triggerAlert(); }

// CORRECT
private static final BigDecimal BUDGET_ALERT_THRESHOLD = new BigDecimal("0.80"); // % of limit
```

**Null Safety**

- No methods return `null` when they can return `Optional<T>`.
- Collections return empty, never null.
- DTOs that carry optional fields use `@Nullable` annotation (not just convention).

**Idempotency**
Any financial write operation (create transaction, update goal, record payment) must be idempotent. Duplicate requests produce the same result, not duplicate records. Idempotency keys are generated by the client, validated by the server.

**Dart / Flutter**

- Prefer `const` constructors wherever possible
- No business logic in widgets
- Repositories own API calls; screens own UI state
- `async`/`await` over raw `Future.then()` chains
- Error states are modeled explicitly, not caught with empty `catch {}`

### Comments

Comments explain _why_, not _what_. Code that requires a comment to explain what it does should be rewritten to explain itself through naming.

```java
// WRONG — describes what the code does (obvious from reading it)
// Multiply monthly contribution by months remaining
BigDecimal total = contribution.multiply(BigDecimal.valueOf(monthsRemaining));

// CORRECT — explains a non-obvious constraint
// RBI AA framework returns balances in paise, not rupees
// divide by 100 before displaying or storing
BigDecimal balanceInRupees = rawBalance.divide(HUNDRED, 2, RoundingMode.HALF_UP);
```

---

## Section 3 — Security Standards

### Classification

Every piece of data is classified before it is stored or transmitted.

```
CLASS 1 — CRITICAL
  Banking credentials, AA consent tokens, auth tokens.
  Never persisted. Session-scoped only.

CLASS 2 — SENSITIVE
  Account balances, transactions, tax data, income figures.
  Encrypted at rest (AES-256-GCM) and in transit (TLS 1.3).
  Field-level encryption in addition to database-level.

CLASS 3 — PERSONAL
  Name, phone, email, preferences.
  Encrypted at rest. Standard access controls.

CLASS 4 — BEHAVIORAL
  Spending patterns, Economic Identity dimensions.
  User-linked. Never sold or shared. Never aggregated commercially.
```

### Authentication

- Passwords hashed with BCrypt, cost factor ≥ 12.
- JWT signed with RS256 (asymmetric). Secret key rotated quarterly.
- Access token TTL: 15 minutes. Refresh token TTL: 30 days.
- Refresh tokens are single-use. Rotation on every use. Old token invalidated immediately.
- OTPs: 6 digits, TTL 5 minutes, max 5 attempts per session, hashed before storage.
- Session invalidation on: password change, suspicious activity, explicit logout, device removal.

### CORS

Allowed origins are explicit. Wildcard `*` with credentials is prohibited.

```java
// PROHIBITED
config.setAllowedOriginPatterns(List.of("*"));

// REQUIRED
config.setAllowedOrigins(List.of(
    "https://app.pennywise.in",
    "https://ca.pennywise.in"
));
```

Development origins (`localhost:*`) are permitted only in development profiles, never in production configuration.

### Secrets

- No secrets in source code. Ever.
- No secrets in `application.yml`, `docker-compose.yml`, or any committed file.
- All secrets injected via environment variables from a secrets manager (HashiCorp Vault, AWS Secrets Manager, or GCP Secret Manager).
- Secrets are rotated on: suspected compromise, employee departure, quarterly for high-risk secrets.
- CI/CD systems use short-lived, scoped credentials. Not long-lived shared keys.

### Input Validation

Every external input is validated at the boundary. Internal calls between services trust the service contract, not user-provided data.

- DTOs annotated with `@Valid` and `@NotNull`/`@Size`/`@Pattern` constraints.
- User-provided strings that reach AI prompts are sanitized before concatenation.
- File uploads are type-validated (magic bytes, not just extension) and size-limited.
- SQL is never constructed by string concatenation. Parameterized queries only.

### Security Headers (HTTP Responses)

Every response includes:

```
Content-Security-Policy: default-src 'self'; script-src 'self'
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: geolocation=(), microphone=(), camera=()
```

### Rate Limiting

Rate limits are applied at the API Gateway, not at individual services.

```
ENDPOINT                      LIMIT               WINDOW
/auth/send-otp                5 requests          1 hour per phone number
/auth/login                   10 requests         15 minutes per IP
/ai/chat                      100 requests        24 hours per user
/affordability/check          50 requests         1 hour per user
/transactions                 500 requests        1 minute per user
All other endpoints           1000 requests       1 minute per user
```

Rate limit responses return `429 Too Many Requests` with `Retry-After` header.

### Prompt Injection Defense

User input that reaches an AI prompt is never concatenated directly. It is passed through an `InputSanitizer` that:

- Removes instruction-like patterns (`ignore previous instructions`, `you are now`, `system:`)
- Truncates to maximum allowed length
- Escapes special formatting characters
- Logs the sanitized input alongside the original for audit

---

## Section 4 — Privacy Standards

Refer to the Privacy & Security Constitution for full principles. Engineering standards:

**Data Minimization**
Before adding a new field to a model, answer: why does PennyWise need this? If the answer is "it might be useful later," the field is not added. Data collected without a current purpose is liability.

**Retention**
Every data type has a defined retention period set at the time of schema creation — not added later. Data past its retention period is deleted by an automated job, not a manual process.

**Logging**
PII is never written to logs. Financial amounts in logs are masked: `₹1,24,500` becomes `₹****`. Account numbers are truncated to last 4 digits. Email addresses are partial: `u***@domain.com`. Phone numbers: `+91 *****67890`.

**Data Access Audit**
Any access to a user's financial data by an internal service, an admin tool, or a support process is logged in the Trust Ledger with: timestamp, accessor identity, data type accessed, purpose.

**Right to Deletion**
The deletion pipeline is tested monthly. When a user requests deletion:

1. Soft-delete the account immediately (stop all processing)
2. Queue for hard deletion after 30-day recovery window
3. Execute: delete all PII, delete all financial records, delete all documents, purge all caches
4. Confirm: automated verification that no PII remains in any store
5. Notify: send confirmation to last known email address

---

## Section 5 — AI Standards

### The Fundamental Rule

> If it is a number that affects a financial decision, it comes from a deterministic engine. The AI explains the number. It does not produce it.

This rule has no exceptions.

### The AI Gateway

Every AI request passes through the AI Gateway. No service calls an LLM directly.

```
User Input
    │
    ▼
INPUT SANITIZER
Removes injection patterns, truncates, escapes
    │
    ▼
INTENT CLASSIFIER
Categorizes: tax / investment / budget / general / out-of-scope
    │
    ▼
POLICY ENGINE
Checks: is this request permissible? Does it require disclaimer?
Is it in the "never decides" zone? (see Constitution)
    │
    ▼
DETERMINISTIC ENGINE ROUTING
Tax query → Tax Engine (numbers first)
Investment query → Investment Engine (numbers first)
Simulation query → Simulation Engine (numbers first)
General query → pass through
    │
    ▼
LLM CALL
Input: deterministic output + user query + system prompt
Output: natural language explanation with evidence references
    │
    ▼
EVIDENCE VALIDATOR
Verifies: does the LLM response reference the engine outputs?
Does it introduce numbers not in the deterministic outputs?
    │
    ▼
CONFIDENCE SCORER
Returns: High / Medium / Low based on data quality
    │
    ▼
USER RESPONSE
```

The LLM never receives raw financial data without deterministic context. It receives deterministic engine outputs and explains them.

### Prompt Governance

- System prompts are versioned. Version number included in every AI audit log entry.
- System prompts are code-reviewed like code. A prompt change is a production change.
- System prompts are stored in version control, not in application configuration.
- Prompts contain: role definition, capability boundaries, prohibited outputs, output format requirements.
- Every system prompt includes: "You are not a registered financial advisor. When providing financial information, note that users should consult qualified professionals for decisions above their personal risk threshold."

### Cost Management

- Every AI call is tagged with: user ID, feature name, model used, input tokens, output tokens, cost estimate.
- Per-user daily spending limit: ₹2 equivalent in API costs. Requests beyond this limit return a graceful fallback, not an error.
- Per-feature budget alerts: if a feature consumes 20% more than its baseline in 24 hours, an alert fires.
- Expensive operations (multi-step simulations, document parsing) are queued asynchronously, not blocking.
- Prompt caching: identical system prompts across users are cached at the provider level where supported.

### Output Validation

AI outputs that contain numbers are cross-validated against deterministic engine outputs before display.

- If the LLM response contains a number that differs from the deterministic engine output by more than 1%, the LLM response is rejected and the deterministic output is shown with a note.
- Responses containing regulatory advice ("you must file by...", "you are required to...") trigger a disclaimer attachment.
- Responses recommending specific financial products are logged separately for compliance review.

### Hallucination Defense

- LLM is never the sole source of truth for any financial fact.
- Factual claims in AI responses are grounded in engine outputs included in the prompt.
- Unknown or uncertain answers use explicit language: "I don't have enough information to answer this accurately" is a valid and required response type.
- AI responses include a confidence label (derived from data quality, not from the LLM's self-assessment).

### Model Routing

Not every query needs the most expensive model.

```
QUERY TYPE                  MODEL TIER       REASON
Simple categorization        Fast/cheap       Structured output task
Conversational chat          Standard         Balance quality/cost
Tax explanation              Standard         Medium complexity
Simulation narration         Standard         Reads from engine outputs
Complex planning             Premium          High stakes, complex context
Document parsing             Specialized OCR  Better accuracy on forms
```

---

## Section 6 — API Standards

### Design

**Resource naming:** plural nouns. `/transactions`, `/goals`, `/budgets`. Never verbs.

**HTTP method semantics:** GET is safe and idempotent. POST creates. PUT replaces completely. PATCH updates partially. DELETE removes. These semantics are not violated for convenience.

**Versioning:** Major version in the URL path. `/api/v1/`, `/api/v2/`. Two versions supported simultaneously. Minimum 12-month deprecation notice before removing any version.

**Response envelope:**

```json
{
  "data": { ... },
  "meta": {
    "request_id": "uuid",
    "timestamp": "2026-07-22T10:32:00+05:30",
    "version": "1.0"
  }
}
```

**Error responses** follow RFC 7807:

```json
{
  "type": "https://errors.pennywise.in/insufficient-funds",
  "title": "Insufficient funds for this operation",
  "status": 422,
  "detail": "The requested amount exceeds your Safe-to-Spend balance.",
  "instance": "/affordability/check"
}
```

Internal stack traces never appear in API responses. Log them internally. Return a request ID the user can reference.

**Monetary amounts:** always in paise (smallest unit), never rupees. Display formatting is the client's responsibility. `"amount": 150000` = ₹1,500.00. This prevents floating-point display bugs and keeps the API unit-consistent.

**Timestamps:** ISO 8601 with timezone. `"created_at": "2026-07-22T10:32:00+05:30"`. Never Unix epoch in user-facing APIs.

**Pagination:** cursor-based, not offset-based, for all collections. Offset pagination produces inconsistent results when data changes between pages. Cursor pagination is consistent.

```json
{
  "data": [...],
  "pagination": {
    "next_cursor": "eyJ0aW1lc3RhbXAiOiAi...",
    "has_more": true,
    "limit": 20
  }
}
```

**Idempotency:** financial write endpoints accept `Idempotency-Key` header. Duplicate requests with the same key return the original response without re-executing.

### Backwards Compatibility

Breaking changes are:

- Removing a field
- Changing a field type
- Changing a field name
- Changing authentication requirements
- Changing error response format
- Removing an endpoint

Non-breaking changes (do not require version increment):

- Adding a new optional field
- Adding a new endpoint
- Adding new enum values (clients must handle unknown values)

When a breaking change is required: create a new version, support both for 12 months, deprecate the old version with `Deprecation` and `Sunset` response headers.

---

## Section 7 — Database Standards

### Schema Design

**All tables have:**

- `id UUID PRIMARY KEY DEFAULT gen_random_uuid()` — never sequential integers for user-facing records
- `created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`
- `updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`
- `deleted_at TIMESTAMPTZ` — soft delete on all tables containing user-generated content

**Financial amounts:** `NUMERIC(19, 4)` for storage. Not `FLOAT`, not `DOUBLE PRECISION`. The precision is not negotiable.

**Enum fields:** stored as `VARCHAR` with `CHECK` constraint, not as database `ENUM` type. Database `ENUM` requires a migration to add values; `VARCHAR` + `CHECK` can be relaxed by changing the constraint only.

**Indexing rules:**

- Every foreign key is indexed
- Every column used in a `WHERE` clause in production queries is indexed
- Composite indexes are ordered: highest-cardinality column first
- Indexes are added in migrations with `CONCURRENTLY` to avoid table locks in production

**Soft deletes:**

- All user-generated data (transactions, goals, budgets, documents, chat messages) has a `deleted_at` column
- All repository queries filter `WHERE deleted_at IS NULL` by default
- Hard delete is only applied to system data and anonymous telemetry
- Financial records are never hard deleted (required for tax audit trail)

### Migrations

- Flyway manages all schema changes. No manual DDL in production.
- Every migration is forward-only. Rollback is a new migration, not undoing the old one.
- Migrations that alter large tables are run with `CONCURRENTLY` for index creation and tested on production-scale data before deployment.
- No migration removes a column without a prior migration that stops writing to it (two-step removal).
- Seed data lives in separate seed migrations (`S` prefix in Flyway), not in application migrations.

### Query Standards

No raw SQL string concatenation. Parameterized queries always.

N+1 queries are blocked at code review. If a service iterates a list and calls the database inside the loop, it is rewritten with a JOIN or batch query.

Query execution plans are reviewed for any query expected to run on tables with > 100,000 rows. `EXPLAIN ANALYZE` output is included in the PR for such queries.

Read-heavy analytics queries use read replicas. They do not run against the primary write replica.

Aggregation queries that are expensive (monthly spending by category, portfolio valuation) are materialized or cached. They are not computed on every request.

### Partitioning Readiness

Tables expected to exceed 10 million rows are designed for partitioning from the start:

- Include the partition key in all query `WHERE` clauses
- Include the partition key in the primary key definition
- Document the expected partitioning strategy (time-range, list, hash) in the schema migration comment

Current candidates: `transactions` (partition by `user_id` + `transaction_date` month), `chat_history` (partition by `user_id`), `documents` (partition by `user_id`).

---

## Section 8 — Testing Standards

### The Testing Pyramid

```
                    E2E TESTS (5%)
                 ┌─────────────────┐
                 │  Critical user  │
                 │  journeys only  │
                 └────────┬────────┘
              INTEGRATION TESTS (25%)
           ┌──────────────────────────┐
           │  All API endpoints       │
           │  All service boundaries  │
           │  All database queries    │
           └───────────┬──────────────┘
          UNIT TESTS (70%)
    ┌──────────────────────────────────────┐
    │  All business logic                  │
    │  All financial calculations (100%)   │
    │  All state machines                  │
    │  All edge cases                      │
    └──────────────────────────────────────┘
```

### Coverage Requirements

- Financial calculation methods: **100% branch coverage**. No exceptions. A missing branch in a tax calculation is a compliance bug.
- Service layer business logic: **90% line coverage minimum**
- Repository layer: **80% line coverage minimum** (integration tests cover the rest)
- Controllers: covered by integration tests, not unit tests

### Financial Calculation Tests

Tax engine tests must cover every slab, every deduction type, and every edge case. When the Finance Ministry changes a slab in the Budget, the failing test is how the team knows what to update.

Test naming for financial calculations:

```java
@Test
void calculateTax_newRegime_incomeAbove15Lakh_applies30PercentSlab() { ... }

@Test
void calculateTax_oldRegime_with80cMaxDeduction_reducesLiabilityCorrectly() { ... }

@Test
void calculateEmi_zeroInterestRate_returnsEqualPrincipalPayments() { ... }
```

### Integration Tests

Use Testcontainers for all integration tests. Tests run against real PostgreSQL and Redis instances, not mocks.

Every API endpoint has at least:

- Happy path test
- Authentication failure test (missing token, expired token)
- Validation failure test (missing required field, invalid format)
- Not-found test (resource belongs to another user)

### Contract Tests

Published API contracts (between mobile app and backend, between backend and partner APIs) are tested with consumer-driven contract tests (Pact or equivalent). A backend change that breaks a contract fails the CI build.

### Performance Tests

Run before every major release:

- Load test: simulate expected peak load for 10 minutes
- Stress test: 2× expected peak until failure
- Soak test: expected load for 2 hours (finds memory leaks)
- Spike test: sudden 10× traffic increase

Acceptance criteria:

- p50 latency < 200ms for all user-facing endpoints
- p95 latency < 500ms
- p99 latency < 2s
- Error rate < 0.1% at expected peak load

### Chaos Tests

Quarterly game days:

- Primary database failure: does failover work? How long?
- Redis failure: do cache misses degrade gracefully?
- LLM API unavailability: do static fallbacks activate?
- AA framework down: do cached balances display correctly?
- 10× traffic spike: does rate limiting activate before service degradation?

Each game day produces a written report within 48 hours.

---

## Section 9 — Performance Standards

### Latency Targets

```
ENDPOINT TYPE                    P50      P95      P99
────────────────────────────────────────────────────────
Safe-to-Spend display            50ms    200ms    500ms
Dashboard load                  100ms    400ms    800ms
Transaction list (paginated)     80ms    300ms    600ms
Tax estimate                    200ms    600ms    1200ms
AI chat response (streaming)    300ms   1000ms   2000ms
Goal projection                 100ms    400ms    800ms
Document upload (initiation)     50ms    200ms    500ms
```

### Caching Strategy

Cache levels and TTLs:

```
DATA TYPE                     CACHE TTL     INVALIDATION TRIGGER
────────────────────────────────────────────────────────────────
Category list                 24 hours      New category created
User profile                  1 hour        Profile updated
Health score                  30 minutes    New transaction, goal change
Monthly budget aggregates     15 minutes    New transaction in period
Tax estimate                  1 hour        New income/deduction
Market data                   5 minutes     External API poll
System categories             7 days        Admin update only
```

Cache keys include the user ID and data version. Cache invalidation is synchronous with the write operation, not eventual.

**Never cache:**

- Account balances (must be real-time from AA)
- Transaction records (authoritative state)
- Auth tokens or session state (security risk)
- Confidence scores derived from live data

### Database Performance

- Connection pool sized to: `(core_count × 2) + effective_spindle_count`
- Read replicas serve all non-transactional reads
- Slow query threshold: queries > 100ms are logged and reviewed
- VACUUM and ANALYZE scheduled during low-traffic windows
- Explain plans reviewed for any query touching > 10,000 rows

### API Response Optimization

- Responses are compressed (gzip) for payloads > 1KB
- Field selection: clients can specify which fields to return (reduces payload size)
- Conditional requests: ETags supported for read-heavy resources
- HTTP/2 enabled for all API endpoints

---

## Section 10 — Observability Standards

### The Three Pillars

Observability is not optional. It is an engineering requirement. A service that cannot be observed is a service that cannot be operated.

**Metrics (quantitative):**
Every service exposes metrics for the four golden signals:

- Latency (request duration, p50/p95/p99)
- Traffic (requests per second, by endpoint)
- Errors (error rate, by type)
- Saturation (CPU, memory, connection pool utilization)

Business metrics alongside technical metrics:

- Transactions processed per minute
- AI calls per minute and average cost
- Safe-to-Spend calculations per minute
- Goal progress updates per minute
- Active users (5-minute window)

**Traces (contextual):**
Every user-facing request is traced end-to-end with OpenTelemetry. A trace ID is generated at the API Gateway and propagated through every service, every database call, every external API call. Log lines include the trace ID. A support request that references an error includes a trace ID that shows exactly what happened.

**Logs (structured):**
All logs are structured JSON. No unstructured strings. Required fields on every log line:

```json
{
  "timestamp": "2026-07-22T10:32:00.123+05:30",
  "level": "INFO",
  "service": "transaction-service",
  "trace_id": "abc123",
  "span_id": "def456",
  "user_id": "u_***xyz",
  "message": "Transaction created successfully",
  "transaction_id": "txn_789",
  "duration_ms": 45
}
```

PII in logs is masked (see Privacy Standards Section 4).

### Alert Philosophy

Alerts fire on user-visible symptoms, not on internal causes.

```
GOOD ALERT: "p99 latency for /transactions exceeded 2s for 5 minutes"
BAD ALERT:  "CPU utilization exceeded 80%"

GOOD ALERT: "Error rate for /ai/chat exceeded 5% in the last 10 minutes"
BAD ALERT:  "Redis connection pool at 90% utilization"
```

Internal resource alerts exist but are routed to infrastructure channels, not to on-call. On-call is paged for user-facing degradation, not for resource utilization.

**Alert fatigue is a bug.** An alert that fires more than once per week without requiring action is tuned or removed.

### Dashboards

Four standard dashboards, maintained by the engineering team:

1. **Service Health** — latency, error rate, throughput per service. The first thing you open when something seems wrong.
2. **Business Health** — transactions per minute, active users, goal completions, AI usage. The first thing a product person opens.
3. **Infrastructure** — database connections, cache hit rate, queue depth, memory/CPU. The first thing you open for capacity planning.
4. **Security** — failed auth attempts, rate limit hits, unusual geographic access, anomalous API patterns.

---

## Section 11 — SRE Standards

### Service Level Objectives

SLOs are the commitments made to users through architecture. They are not aspirational — they are operational targets with consequences.

```
SERVICE                          SLO         ERROR BUDGET
──────────────────────────────────────────────────────────
Authentication                   99.99%      52 minutes/year
Safe-to-Spend display            99.99%      52 minutes/year
Transaction sync                 99.9%       8.7 hours/year
Tax Engine                       99.9%       8.7 hours/year
AI chat                          99.5%       43 hours/year
Document processing              99.0%       87 hours/year
Simulation Engine                99.0%       87 hours/year
```

**Error budget policy:** When a service consumes > 50% of its quarterly error budget, feature development for that service stops until reliability work has been completed. This rule is enforced by the engineering lead, not requested by the SRE team.

### On-Call

- On-call rotation: every engineer is on-call. There is no separate ops team.
- On-call shift: one week primary, one week secondary.
- Primary responds to SEV-1 and SEV-2 alerts within 15 minutes, 24×7.
- Secondary escalation path if primary does not acknowledge within 5 minutes.
- No engineer is on-call for more than 4 consecutive nights.
- On-call compensation: time off equivalent to on-call hours outside business hours.

### Incident Response

```
SEV-1  Data loss, data corruption, authentication failure,
       financial calculation error affecting users.
       Declare within: 5 minutes of detection.
       User notification within: 1 hour.
       Bridge: immediate all-hands.

SEV-2  Core feature unavailable for > 10% of users.
       Declare within: 15 minutes of detection.
       User notification within: 2 hours.
       Bridge: on-call + team lead.

SEV-3  Degraded feature, elevated error rate, isolated failures.
       Declare within: 1 hour.
       No immediate user notification unless data is affected.
       Resolution target: same business day.

SEV-4  Non-critical feature degraded, cosmetic issues.
       Log and schedule.
       Resolution target: next sprint.
```

**Post-mortem:** Every SEV-1 and SEV-2 produces a blameless post-mortem within 48 hours of resolution. Format: timeline, contributing factors, impact, what worked, what didn't, action items with owners and deadlines. Post-mortems are shared with the full engineering team. The goal is learning, not blame.

---

## Section 12 — Deployment Standards

### Environments

```
ENVIRONMENT     PURPOSE                   DATA
─────────────────────────────────────────────────────
local           Individual development    Anonymized test data
development     Team integration          Anonymized test data
staging         Pre-production testing    Production-like volume,
                                          anonymized
production      Live users                Real user data
```

Staging must be architecturally identical to production. A bug that "only appears in production" and cannot be reproduced in staging is a staging configuration problem.

### Deployment Pipeline

```
git push
    │
    ▼
Unit tests (must pass, < 5 minutes)
    │
    ▼
Integration tests (must pass, < 15 minutes)
    │
    ▼
Security scan: SAST, dependency CVE (must pass)
    │
    ▼
Build container image (tagged with commit SHA)
    │
    ▼
Deploy to staging
    │
    ▼
Smoke tests on staging (must pass)
    │
    ▼
Performance regression check (p95 within 10% of baseline)
    │
    ▼
[HUMAN GATE for major releases]
    │
    ▼
Canary deploy: 5% of production traffic
    │
    ▼
Monitor: 15 minutes
Error rate within baseline?  → Proceed to 100%
Error rate elevated?         → Automatic rollback
    │
    ▼
100% deployment
```

No manual steps between commit and canary. Human gate is at canary → full only for major releases.

### Rollback

Every deployment can be rolled back in under 5 minutes by reverting to the previous container image. Rollback does not require a new deployment pipeline run. It is a kubectl rollout undo or equivalent.

Database migrations cannot be rolled back automatically. Schema changes are designed to be forward-compatible: add before remove, never drop in the same migration that changes behavior.

### Feature Flags

Every new feature is deployed behind a feature flag before it is released to users. This decouples deployment from release.

Flags are managed in configuration, not in code. A flag that has been fully rolled out for more than 30 days with no issues is removed from the codebase in the next sprint (flag debt is technical debt).

Flag states: `off`, `internal_only`, `beta_users`, `percentage_rollout_N`, `all_users`, `deprecated`.

---

## Section 13 — Incident Response

### The First 15 Minutes

The most critical phase of any incident is the first 15 minutes. The priority is not diagnosis — it is mitigation.

```
MINUTE 0-2:    Acknowledge alert. Declare severity.
MINUTE 2-5:    Check dashboards. Is the scope expanding or contained?
MINUTE 5-10:   Is there an obvious mitigation? (roll back, disable feature
               flag, scale up, clear cache). If yes: do it now.
MINUTE 10-15:  If no obvious mitigation, open incident bridge.
               Assign: Incident Commander, Communications Lead.
               Notify: team lead.
```

Incident Commander responsibilities:

- Coordinate the response, do not necessarily fix it
- Delegate investigation tasks
- Track what has been tried
- Make the call on mitigations
- Maintain the incident timeline

Communications Lead responsibilities:

- Draft and send user communication
- Update status page
- Communicate to internal stakeholders
- Not responsible for technical investigation

### Communication Templates

**SEV-1 Initial User Notification (within 1 hour):**

> We are aware of an issue affecting [specific feature]. Our team is investigating and working to resolve this as quickly as possible. We will provide an update in [time]. [Any immediate user action required, or: No action is required from you at this time.]

**SEV-1 Resolution:**

> The issue affecting [specific feature] has been resolved as of [time]. [What happened in plain language.] [What data was or was not affected.] [What we are doing to prevent recurrence.] We apologize for the disruption.

These templates are starting points. Plain language always. No legal jargon. No passive voice. No "we apologize for any inconvenience."

### The Post-Mortem

**Format:**

1. Summary (2 sentences)
2. Timeline (minute-by-minute from detection to resolution)
3. Root Cause (the technical fact, not the person)
4. Contributing Factors (what made this worse or harder to detect)
5. Impact (users affected, duration, data affected or not)
6. What Worked (tools, processes, people that helped)
7. What Didn't Work (where the response fell short)
8. Action Items (specific, owned, deadline-bound)

**Action items are not optional.** Every post-mortem produces at least one engineering action item. If the incident was a known risk that had no tracking issue, the action item is to create one.

---

## Section 14 — Disaster Recovery

### Recovery Objectives

```
SERVICE TIER    RTO (Recovery Time)    RPO (Recovery Point)
────────────────────────────────────────────────────────────
Critical        15 minutes             1 minute
High            1 hour                 5 minutes
Standard        4 hours                15 minutes
Background      24 hours               1 hour
```

RTO and RPO are measured, not estimated. Disaster recovery drills validate actual recovery time. The target is not "we believe we can recover in 15 minutes" — it is "we recovered in 14 minutes in the last drill."

### Backup Strategy

- Primary database: continuous WAL archiving + daily snapshot
- Daily snapshots retained for 30 days
- Weekly snapshots retained for 12 months
- Annual snapshots retained for 7 years (tax compliance)
- Backups stored in a different region than production
- Backup restoration tested monthly (automated: restore to test environment, run validation queries)

### DR Scenarios and Runbooks

Each scenario has a written runbook, tested twice per year:

1. **Primary database failure** — failover to read replica, promote to primary
2. **Complete region outage** — failover to secondary region
3. **Data corruption** — point-in-time recovery to last known clean state
4. **Ransomware / security incident** — isolate, restore from clean backup
5. **Third-party API permanent failure** — activate fallback for each critical dependency

Runbooks are stored in a location accessible without the primary production infrastructure (not only in the production environment's documentation system).

---

## Section 15 — Scalability Rules

### The 10× Test

Before finalizing any architectural decision: "What does this look like with 10× our current usage?"

If the answer is "we'd need to redesign it," the design is either wrong or the technical debt is explicitly documented with a migration path.

### Database Scalability

- Every query used in production runs with `EXPLAIN ANALYZE` before the first production deployment
- Tables expected to exceed 5 million rows have a partitioning strategy documented before first data is written
- Read-heavy operations use read replicas
- Write-heavy operations are async where possible

### Application Scalability

- Services are stateless. Session state lives in Redis, not in the application server. Any instance can serve any request.
- Horizontal scaling is the primary scaling strategy. Vertical scaling (bigger servers) is a temporary measure while architectural improvements are made.
- Long-running operations (document processing, simulation runs, bulk exports) are asynchronous jobs, not synchronous request handlers.
- Batch operations use chunked processing. Never load entire tables into memory.

### The Scaling Readiness Checklist

Before a service is considered production-ready for > 100K users:

- [ ] Pagination on all list endpoints
- [ ] Caching for all read-heavy computed data
- [ ] No synchronous external calls in the request path that do not have timeouts
- [ ] No N+1 queries
- [ ] Database indexes confirmed for all production query patterns
- [ ] Load test completed showing SLO compliance at 3× expected peak
- [ ] Circuit breakers on all external dependencies

---

## Section 16 — Cost Optimization

### Cost Awareness as Engineering Discipline

Engineers are responsible for understanding the cost implications of their design choices. This is not an infrastructure team concern — it is a product engineering concern.

**Cost model per user tier:**

```
PHASE          USERS           TARGET INFRA COST/USER/MONTH
────────────────────────────────────────────────────────────
MVP            1,000           < ₹5,000 total (not per user)
Phase 1        10,000          < ₹30/user
Phase 2        100,000         < ₹15/user
Phase 3        1,000,000       < ₹8/user
Phase 4        10,000,000      < ₹5/user
```

Cost per user decreases with scale. If it doesn't, the architecture has a cost design problem.

### AI Cost Management

LLM inference is the most expensive variable cost. Mitigations:

- Prompt caching: reuse cached completion for identical system prompts (OpenAI Prompt Caching API)
- Model routing: use the cheapest model that can correctly handle a given task type
- Response caching: cache AI responses for identical queries (tax questions, generic advice)
- Per-user daily budget: default 5 AI requests/day on free tier, 50 on premium
- Async processing: queue non-urgent AI tasks, process during off-peak to reduce burst cost

### Infrastructure Cost Controls

- Autoscaling: scale down aggressively during off-peak hours (11 PM – 6 AM IST, weekend troughs)
- Reserved instances for baseline load (30% cost reduction vs on-demand)
- Spot/preemptible instances for batch processing (80% cost reduction vs on-demand)
- Data transfer optimization: minimize cross-region data movement; process data where it lives
- Storage tiering: data > 90 days old moves to infrequent-access storage; > 1 year to archive

---

## Section 17 — Engineering Metrics

These metrics are reviewed by the engineering lead weekly and by the full team monthly.

### Code Quality

```
METRIC                          TARGET          ALERT THRESHOLD
────────────────────────────────────────────────────────────────
Test coverage (business logic)  > 90%           < 80%
Financial calc coverage         100%            < 100%
Build success rate              > 98%           < 95%
Average PR review time          < 24 hours      > 48 hours
PR size (lines changed)         < 400           > 800
Time to merge (approved PR)     < 4 hours       > 24 hours
```

### Reliability

```
METRIC                          TARGET          ALERT THRESHOLD
────────────────────────────────────────────────────────────────
Error rate (production)         < 0.1%          > 1%
Mean time to detect (MTTD)      < 5 minutes     > 30 minutes
Mean time to recover (MTTR)     < 1 hour        > 4 hours
Deployment frequency            > 5/week        < 1/week
Change failure rate             < 5%            > 15%
```

### Developer Experience

```
METRIC                          TARGET          ALERT THRESHOLD
────────────────────────────────────────────────────────────────
CI pipeline duration            < 15 minutes    > 30 minutes
Local dev setup time            < 15 minutes    > 30 minutes
Time to first PR (new hire)     < 3 days        > 1 week
On-call incident rate           < 2 SEV-2/month > 5 SEV-2/month
```

---

## Section 18 — Technical Debt Management

### Definition

Technical debt is any engineering shortcut taken with the intention of returning later to do it properly. Debt that is never acknowledged is the most dangerous kind — it accumulates interest invisibly.

### Tracking

Every piece of acknowledged technical debt has a tracking issue with:

- Description of the shortcut taken
- Why it was taken (time constraint, knowledge gap, deliberate MVP decision)
- Impact if not addressed (performance, security, maintainability)
- Estimated effort to resolve
- Priority classification

### Classification

```
PRIORITY    CRITERIA                              RESOLUTION TARGET
──────────────────────────────────────────────────────────────────
Critical    Security vulnerability or data        Next sprint
            integrity risk

High        Will cause production incident at     Within 2 sprints
            > 10K users OR blocks major feature

Medium      Maintainability, test coverage,       Quarterly review
            performance at > 100K users

Low         Code quality, naming, comments,       Next time this
            style                                 code is touched
```

### The 20% Rule

Every sprint allocates 20% of capacity to technical debt reduction. This is not negotiable. Feature pressure does not consume debt reduction capacity. If features are delayed, they are delayed. Debt that is never paid eventually becomes the reason the product cannot ship features at all.

---

## Section 19 — Developer Experience

### Principles

Engineers should spend time solving product problems, not fighting tools. Every hour lost to slow builds, unreliable tests, or difficult local setup is an hour not spent on user value.

### Local Development

- `git clone` → working local environment in < 15 minutes
- All dependencies available via Docker Compose: no manual PostgreSQL, Redis, or Kafka installation
- Seed data scripts: one command to populate a realistic development dataset
- Hot reload in development: code change visible without restart
- Local environment matches production architecture (not a simplified mock)

### Documentation Standards

Every service has a README that answers:

- What does this service do?
- How do I run it locally?
- What are its dependencies?
- How do I run its tests?
- What are the key configuration options?
- Where are the runbooks?

API documentation is generated from code (OpenAPI/Swagger). It is always current. Manually maintained API documentation is not maintained.

Architecture decisions are recorded in Architecture Decision Records (ADRs). An ADR explains: what was decided, what alternatives were considered, and why this option was chosen. ADRs are never deleted — only superseded.

### Code Review Standards

Code review is not gatekeeping. It is knowledge sharing and quality assurance.

Reviewers comment on:

- Correctness: does this do what it claims?
- Completeness: are edge cases handled?
- Security: are the standards from Section 3 met?
- Observability: are the standards from Section 10 met?
- Tests: do the tests cover the claims made by the code?

Reviewers do not block on:

- Style preferences that are not in the coding standards
- "I would have done this differently" without a specific correctness or quality reason
- Architectural changes that are not within the scope of the PR

**Review turnaround target: 24 hours.** A PR that has been waiting for review for more than 24 hours is flagged by the team lead.

---

## Section 20 — Long-Term Evolution Strategy

### The Principle of Continuous Evolution

PennyWise is designed to evolve. No component is permanent. The goal is that each component can be replaced independently without rebuilding the platform.

This requires:

- Stable interfaces between components (APIs and event schemas)
- Single-owner services that can be replaced without coordination
- Data owned by the service that produces it (not shared between services)
- Event history that allows new consumers to replay from the beginning

### The Migration Path

Current state: a Spring Boot monolith. Target state: domain services communicating through events.

The migration follows the Strangler Fig pattern:

1. Identify the domain with the clearest boundary and the most independent scaling need
2. Extract that domain to a new service
3. The monolith routes requests to the new service for that domain
4. The new service is verified for correctness and performance in production
5. The monolith removes its implementation of that domain
6. Repeat for the next domain

No domain is extracted until the previous extraction is proven stable. Premature decomposition creates operational complexity without value.

### Technology Evolution

Technology choices are revisited on a 3-year cycle. A decision made in 2026 is re-evaluated in 2029 against the options available then. The evaluation question is not "should we switch?" but "would we make the same decision today?"

Criteria for technology replacement:

- Current technology has a known, unfixable limitation at the required scale
- Current technology has a security vulnerability with no remediation path
- Replacement offers 10× improvement on a dimension that matters (not 20% improvement)
- Migration cost is less than 3 sprints of the team that owns the component

Technology is never replaced for novelty, trend-following, or resume-driven development.

### The 10-Year Architecture Vision

By year 10, PennyWise architecture is:

- Fully domain-service-separated with event-driven communication
- Multi-region active-active (India primary, one international secondary)
- Financial Digital Twin simulation engine validated by external economists
- Knowledge Graph replacing relational models for the Financial Memory Graph
- AI agents per domain with deterministic engines providing ground truth
- Full API platform enabling CA firms, banks, and payroll providers to build on PennyWise infrastructure
- Zero-knowledge document vault deployed at user device level

The path to this architecture is paved one extraction, one validated migration, and one proven component at a time. The 10-year vision guides decisions. It does not justify shortcuts.

---

## Appendix — The PR Checklist (Printable)

```
┌─────────────────────────────────────────────────────────────────────┐
│                     PENNYWISE PR CHECKLIST                          │
│                                                                     │
│  Before requesting review, confirm each:                            │
│                                                                     │
│  SECURITY                                                           │
│  □ No secrets in code or config                                     │
│  □ User input validated and sanitized                               │
│  □ No CORS, auth, or permission changes without security review     │
│  □ If AI: prompt injection handled                                  │
│                                                                     │
│  CORRECTNESS                                                        │
│  □ Financial amounts use BigDecimal with explicit RoundingMode      │
│  □ Magic numbers have named constants with source comments          │
│  □ Edge cases handled (zero, negative, max values)                  │
│  □ Idempotency key if financial write operation                     │
│                                                                     │
│  OBSERVABILITY                                                      │
│  □ Structured log lines added for significant events                │
│  □ Metrics added for new service behavior                           │
│  □ Trace context propagated through new code paths                  │
│                                                                     │
│  SCALABILITY                                                        │
│  □ No N+1 queries                                                   │
│  □ Pagination on any list that can grow without bound               │
│  □ External calls have timeouts                                     │
│  □ No blocking I/O in hot paths                                     │
│                                                                     │
│  TESTING                                                            │
│  □ Financial calculations: 100% branch coverage                     │
│  □ Business logic: unit tests present                               │
│  □ New endpoints: integration test present                          │
│  □ Edge cases tested explicitly                                     │
│                                                                     │
│  BACKWARDS COMPATIBILITY                                            │
│  □ No fields removed from API responses                             │
│  □ No required fields added to requests without default             │
│  □ No breaking changes to event schemas                             │
│                                                                     │
│  PRIVACY                                                            │
│  □ No PII in logs                                                   │
│  □ New data collection has documented retention period              │
│  □ New data is minimum necessary for the stated purpose             │
│                                                                     │
│  EXPLAINABILITY                                                      │
│  □ AI outputs reference deterministic engine results                │
│  □ Financial recommendations include confidence level               │
│  □ Audit trail entry created for significant user-facing actions    │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

_This document is version 1.0. It is a living document — updated as the platform grows, as new engineering challenges emerge, and as standards evolve._

_What does not change: the commitment to building software that is secure, observable, maintainable, and worthy of the trust users place in it when they share their financial lives with PennyWise._
