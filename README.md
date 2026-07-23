# PennyWise AI

Monorepo skeleton for **PennyWise AI** - a personal finance app that acts like an AI Chartered Accountant. Generated from the PRD (v1.0) as a Phase 1 (MVP) starting point.

```
pennywise-ai/
├── backend/    Spring Boot 3 / Java 17 REST API
├── mobile/     Flutter app (iOS + Android)
├── database/   Canonical PostgreSQL schema reference (schema.sql)
└── docs/       Reserved for design docs, ADRs, API specs
```

## What's implemented right now

This is a scaffold, not a finished product. The following is real, working logic - not just empty folders:

**Backend** (`backend/`)
- JWT auth (register/login) with BCrypt password hashing and Spring Security
- Transactions: manual entry, list, delete (`TransactionController`)
- Categories: 20 seeded system categories (Food, Transport, Rent, etc.)
- Budgets: per-category monthly limits with spend tracking
- Goals: create/list, with a Goal AI that computes the monthly contribution needed to
  hit a deadline and suggests an investment vehicle based on time horizon
  (`GoalService.applyRecommendation`)
- **Affordability Checker** (Feature 4, the PRD's flagship feature): a rule-based,
  explainable decision engine (`ai/AffordabilityEngine.java`) that checks whether a
  purchase would breach the recommended emergency-fund floor or exceed monthly
  surplus, and returns SAFE_TO_BUY / WAIT_AND_SAVE / DONT_BUY with a plain-English
  reason - with unit tests (`AffordabilityEngineTest`)
- Full PostgreSQL schema via Flyway (`db/migration/V1__init.sql`, `V2__seed_default_categories.sql`),
  covering every table in PRD Section 13 (Phase 1 tables are live; Phase 2-4 tables
  like `investment_portfolio`, `assets`, `liabilities` are provisioned but unused so far)

**Mobile** (`mobile/`)
- Flutter project with the feature-based folder structure from the PRD
  (`core/`, `shared/`, `features/{authentication,dashboard,transactions,goals,budget,
  investments,learn,calculator,reports,notifications,profile,ai,chat,settings}`)
- Working navigation: splash → login/register → onboarding → bottom-nav shell
  (Dashboard, Transactions, Goals, Learn, Ask AI) via `go_router`
- Dashboard screen matching PRD Section 8 (salary/savings/investments/budget cards,
  financial health score, quick actions, AI tip)
- Affordability Checker screen wired to the shape of `POST /affordability/check`
  (currently using mock data - see TODOs)
- Manual transaction entry sheet, goals list with progress bars, basic chat UI
- Placeholder screens for Phase 2/3 features (Budget UI, Investments, Learn, Reports,
  Notifications) so routing is complete even before those are built out

## What's explicitly NOT done yet

- No SMS/notification auto-parsing (Feature 1) - only manual transaction entry
- No real LLM wiring for the AI chat / accountant features - the OpenAI config key
  exists in `application.yml` but nothing calls it yet
- No investment portfolio, assets/liabilities tracking (entities + tables exist,
  services/controllers don't)
- Mobile screens use mock/placeholder data - the `ApiClient`/`TokenStorage` classes
  exist but repositories aren't wired to blocs yet
- No CI, no Docker Compose for local Postgres/Redis

## Running the backend

Requires **JDK 17+**, Maven, PostgreSQL, and Redis running locally (see
`backend/src/main/resources/application.yml` for connection defaults - override via
`DB_USERNAME`, `DB_PASSWORD`, `REDIS_HOST`, `JWT_SECRET`, `OPENAI_API_KEY` env vars).

```bash
cd backend
createdb pennywise          # or point DATASOURCE_URL elsewhere
mvn spring-boot:run
```

Flyway runs the migrations automatically on startup. Health check: `GET /api/actuator/health`.

## Running the mobile app

Requires **Flutter 3.22+**.

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api   # Android emulator
```

(`10.0.2.2` is the Android emulator's alias for the host machine's `localhost`; use
your machine's LAN IP for a physical device, or `localhost` for iOS simulator.)

## Suggested next steps

1. Wire the Flutter repositories (`features/*/data/repositories`) to the real
   `ApiClient` and replace the mock data in `DashboardScreen`, `AffordabilityScreen`,
   `TransactionsScreen`, and `GoalsScreen`.
2. Add SMS parsing on Android (Feature 1) using the `another_telephony` package
   already declared in `pubspec.yaml`.
3. Stand up Docker Compose for local Postgres + Redis so `mvn spring-boot:run` works
   out of the box.
4. Start Phase 2: AI categorization, spending insights, financial health score
   calculation, notifications.

See the original PRD's Section 17 (Roadmap) for the full phased plan.
