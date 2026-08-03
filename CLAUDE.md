# PennyWise AI — Project Context for Claude

## What This Is
A personal finance mobile app (Flutter + Spring Boot) that acts like an AI Chartered Accountant.
Goal: not just expense tracking — **changing financial behavior** through AI analysis, education, and coaching.

Target users: students, salaried professionals, freelancers, families.

---

## Monorepo Structure

```
/
├── mobile/          → Flutter app (iOS + Android)
├── backend/         → Spring Boot REST API
├── database/        → schema.sql (11 tables)
├── docs/architecture/ → ADRs + API contracts
└── docker-compose.yml
```

---

## Tech Stack

| Layer | Choice |
|-------|--------|
| Mobile | Flutter (Dart), go_router, SharedPreferences, Flutter Secure Storage |
| Backend | Spring Boot 3, Java 17, Spring Security, JJWT 0.12.6 |
| Database | PostgreSQL 16 |
| Cache | Redis 7 |
| Charts | fl_chart |
| AI (planned) | OpenAI GPT-4o-mini via LangChain |
| Auth | JWT — fully wired on backend + mobile |
| Push (planned) | Firebase Cloud Messaging |
| SMS parsing | another_telephony (declared, not implemented) |
| OCR | google_mlkit_text_recognition (declared, not implemented) |
| DI (mobile) | get_it — wired via `mobile/lib/core/di/injection.dart` |

---

## Running Locally

```bash
# Start backend + postgres + redis
docker-compose up

# Backend runs at http://localhost:8080/api
# Flutter (iOS simulator or Android emulator)
cd mobile && flutter run
```

API base URL in Flutter: `mobile/lib/core/constants/api_constants.dart`
Default: `http://10.0.2.2:8080/api` (Android emulator) — change to `localhost` for iOS.

---

## Backend API

| Method | Endpoint | Status |
|--------|----------|--------|
| POST | /auth/register | ✅ Done |
| POST | /auth/login | ✅ Done |
| GET | /users/me | ✅ Done |
| PATCH | /users/me | ✅ Done |
| POST | /transactions | ✅ Done |
| GET | /transactions | ✅ Done |
| DELETE | /transactions/{id} | ✅ Done |
| POST | /budgets | ✅ Done |
| GET | /budgets | ✅ Done |
| POST | /goals | ✅ Done |
| GET | /goals | ✅ Done |
| PATCH | /goals/{id}/saved-amount | ✅ Done |
| POST | /affordability/check | ✅ Done — returns AffordabilityResponse (pre-migration) |
| GET | /categories | ✅ Done |
| GET | /decisions/today | ✅ Done — returns **DecisionResponse v2 envelope** |
| POST | /decisions/{id}/lifecycle | ✅ Done — stub (fire-and-forget) |
| GET | /decision-memory | ✅ Done |
| GET | /decision-memory/timeline | ✅ Done |
| GET | /decision-memory/insights | ✅ Done |
| POST | /decision-memory/{id}/review | ✅ Done |
| GET | /health-score | ✅ Done |

**Missing backend endpoints:** `/ai/chat`, `/reports`, `/notifications`, `/investments`

---

## Database Schema (11 tables in database/schema.sql)

**Active (Phase 1):**
- `users` — salary, risk appetite, onboarding status
- `categories` — system defaults + user custom
- `transactions` — amount, merchant, category, direction (DEBIT/CREDIT), source
- `budgets` — per-category monthly limits
- `goals` — target, deadline, monthly contribution, investment suggestion

**Provisioned for future phases:**
- `investment_portfolio`, `assets`, `liabilities` (Phase 3/4)
- `learning_progress`, `achievements`, `savings_rules` (Phase 2)
- `notifications`, `affordability_history`, `chat_history` (Phase 2/3)
- `decision_memory`, `decision_outcome` — ✅ active, wired to DecisionMemoryService

---

## Architecture — Current Layer Status

### Canonical Build Order (agreed 2026-08-03)

| Phase | What | Status |
|-------|------|--------|
| Phase 0 | Flutter domain layer (Decision aggregate, 8 bounded contexts, domain events) | ✅ Complete — commit `36e79f0` |
| Phase 1 | Application layer + DI + Partner Recommendation pipeline | ✅ Complete — commit `b2dd0ec` |
| Phase 2 Sprint 1 | Backend `DecisionResponse` envelope + `FinancialPolicy` + `DecisionResponseMapper` | ✅ Complete — commit `8794b12` |
| Phase 2 Sprint 2 | `AffordabilityEngine` → `DecisionResponse` | ⬜ Next |
| Phase 2 Sprint 3 | Financial Journal → `DecisionResponse` | ⬜ |
| Phase 2 Sprint 4 | Partner Programs → `DecisionResponse` | ⬜ |
| Phase 2 Sprint 5 | Behavioral Engine → `DecisionResponse` | ⬜ |
| Phase 3 | Policy Engine wired into TodayDecisionService + DecisionEngine | ⬜ |
| Phase 4 | Behavioral Engine (pattern detection on real transaction history) | ⬜ |
| Phase 5 | Financial Digital Twin (Bayesian behavioral vector) | ⬜ |
| Phase 6 | Knowledge Graph (PostgreSQL entity graph) | ⬜ |
| Phase 7 | Unified Decision Platform | ⬜ |

### The Canonical Feature Architecture (reference: commit `b2dd0ec`)

Every new feature must follow this 7-layer pattern:

```
Domain (interfaces, value objects, aggregates — no Flutter, no Spring)
    ↓
Infrastructure (concrete implementations — HardcodedRepo, RestRepo)
    ↓
Mapper (infrastructure model → domain entity)
    ↓
Use Case (application layer — orchestrates domain + infrastructure)
    ↓
Dependency Injection (injection.dart — get_it service locator)
    ↓
Screen (calls sl<UseCase>().call(), no business logic)
    ↓
Widget (pure renderer — receives domain objects as constructor params)
```

**10 architectural invariants (all verified at every commit):**
1. Widgets never instantiate repositories directly
2. Widgets depend only on use cases or domain models
3. Infrastructure never imports Flutter
4. Domain only imports `flutter/foundation.dart` (for @immutable)
5. Repository contracts are interfaces in the domain layer
6. Concrete implementations live only in infrastructure
7. Business logic (ranking, scoring, filtering) lives in repositories/use cases, never widgets
8. No hardcoded data lists inside widgets
9. `flutter analyze` passes with zero errors at commit time
10. All DI wiring goes through use cases

### Backend Domain Layer (com.pennywise.domain.decision)

Introduced in Phase 2 Sprint 1. Pure Java records, no Spring/JPA/Lombok.

| Class | Purpose |
|-------|---------|
| `DecisionResponse` | Canonical envelope — every decision endpoint will eventually return this |
| `DecisionData` | Core decision (type, headline, priority, icon, recommendation, goalImpact) |
| `RecommendationData` | actionType, instrument, timeline, confidenceScore |
| `GoalImpactData` | Health score + goal success rate deltas |
| `ExplanationData` | Structured explanation — because[], evidence[], alternatives[], limitations[], confidenceDrivers[] |
| `BehavioralContextData` | Always present. status="uncalibrated" until Behavioral Engine ships. Never omit. |
| `PartnerRecommendation` | Canonical partner shape — programId, matchScore, trustStatement, taxBenefit, rank |
| `TrustData` | Fiduciary proof block — engineVersion, basedOn, missingData, commissionPolicy |
| `DecisionVersioning` | schemaVersion, engineVersion, decisionVersion, behaviorVersion, knowledgeVersion |

### Backend Policy Engine (com.pennywise.policy.FinancialPolicy)

All financial constants live here — not inside engine code. When RBI rules or tax slabs change, update this file only.

Constants: `MIN_EMERGENCY_FUND_MONTHS`, `TARGET_EMERGENCY_FUND_MONTHS`, `MIN_SAVINGS_RATE`, `SAFE_EMI_INCOME_RATIO`, SIP rates by horizon, `SECTION_80C_LIMIT`, `MAX_SIP_INCOME_RATIO`, health score weights, `COMMISSION_POLICY`, `FIDUCIARY_STATEMENT`.

Method: `sipRateForHorizon(int months)` — returns 7%/8%/10%/12% by horizon bucket.

### Backend Mapper Layer (com.pennywise.mapper)

`DecisionResponseMapper` — bridges `TodayDecisionService` (unchanged legacy service) → `DecisionResponse`. The controller is the only change point. Services are untouched.

---

## Flutter App — Feature Status

### Screens — Fully Wired

| Screen | File | What Works |
|--------|------|------------|
| Login | `features/authentication/.../login_screen.dart` | POST /auth/login + JWT save + salary sync from /users/me |
| Register | `features/authentication/.../register_screen.dart` | POST /auth/register + JWT save |
| Splash | `features/authentication/.../splash_screen.dart` | URL token (web), hasSession() check, routes to /dashboard or /login |
| Dashboard | `features/dashboard/.../dashboard_screen.dart` | Health score ring, 4 mission quest cards, Today's Best Decision card, Bank Program Slider, Commitment Intelligence, Behavioral Profile, Quick Actions |
| Transactions | `features/transactions/.../` | GET/POST/PATCH/DELETE, OCR, AI category suggestion |
| Goals | `features/goals/.../` | GET/POST /goals, animated quest cards, GoalPlanScreen with AI plan |
| Budget | `features/budget/.../` | GET/POST /budgets, create/edit/delete, donut chart, swipe-to-delete |
| Affordability | `features/calculator/.../affordability_screen.dart` | POST /affordability/check, salary auto-loads from prefs |
| Profile | `features/profile/.../` | salary, risk appetite, PAN, tax regime → PATCH /users/me |
| Settings | `features/settings/.../` | logout + JWT clear, navigation to sub-screens |
| Salary Detail | `features/dashboard/.../salary_detail_screen.dart` | 50-30-20 breakdown, case study, quiz, XP |
| Savings Detail | `features/dashboard/.../savings_detail_screen.dart` | Emergency fund calculator, Rule of 72, quiz |
| Investment Detail | `features/dashboard/.../investment_detail_screen.dart` | SIP pyramid, portfolio allocation, compounding table, quiz |
| Budget Detail | `features/dashboard/.../budget_detail_screen.dart` | Zero-based budgeting, quiz |
| Financial Journal | `features/decisions/.../financial_journal_screen.dart` | Decision history, timeline, pending reviews |
| Digital Twin | `features/twin/.../digital_twin_screen.dart` | Behavioral parameter visualization (stub data) |
| Commitments | `features/commitments/.../commitments_screen.dart` | Recurring payment detection from transaction history |

### Dashboard Widgets — All Wired

| Widget | File | Data Source |
|--------|------|-------------|
| `TodaysBestDecisionCard` | `widgets/todays_best_decision_card.dart` | GET /decisions/today → DecisionResponse v2 |
| `BankProgramSlider` | `widgets/bank_program_slider.dart` | GetDashboardFeedUseCase → HardcodedPartnerRepository |
| `HeroCarouselSection` | `widgets/hero_carousel_section.dart` | Local salary data |
| `MarketDataSection` | `widgets/market_data_section.dart` | Simulated market indices |
| `FinancialNewsTicker` | `widgets/news_ticker_widget.dart` | Simulated news feed |
| `FinancialOpportunityCarousel` | `widgets/financial_opportunity_carousel.dart` | Local health score |
| `GoalPathwayBanner` | `widgets/goal_pathway_banner.dart` | Local goal data |
| `BehaviorInsightsSection` | `widgets/behavior_insights_section.dart` | Stub behavioral data |
| `NextBestActionCarousel` | `widgets/next_best_action_carousel.dart` | Stub action data |
| `AnimatedStatsSection` | `widgets/animated_stats_section.dart` | Computed from salary |
| `MotivationCardsSection` | `widgets/motivation_cards_section.dart` | Computed from salary |
| `_CommitmentsCard` (inline) | `dashboard_screen.dart` | CommitmentEngine → transaction history |

### Screens — Stubs / Not Built

| Screen | What's Missing |
|--------|----------------|
| AI Chat | Build /ai/chat backend endpoint + wire ChatScreen to OpenAI GPT-4o-mini |
| Learn | Full learning academy — lessons, flashcards, daily content |
| Investments | Portfolio tracking UI + live data |
| Reports | Spending reports + charts (backend endpoint missing) |
| Notifications | AI alerts display (backend endpoint missing) |

---

## Flutter Architecture — Key Files

### Application Layer (`mobile/lib/application/`)
| File | Purpose |
|------|---------|
| `decision/get_dashboard_feed_use_case.dart` | Fetches today's decision + ranked partner programs together |
| `decision/get_today_decision_use_case.dart` | Standalone today's decision fetch |
| `decision/record_decision_lifecycle_use_case.dart` | Records viewed/accepted/executed/reviewed lifecycle state |
| `partner/get_partner_programs_use_case.dart` | Standalone partner program fetch |
| `shared/use_case.dart` | UseCase + NoParamUseCase interfaces |

### Domain Layer (`mobile/lib/domain/`)
| Package | Key Classes |
|---------|-------------|
| `decision/` | `Decision` (aggregate root), `DecisionResponse`, `DecisionFeed`, `Explanation`, `Recommendation`, `TrustMetadata`, `GoalImpact`, `BehavioralContext`, `DecisionAudit` |
| `partner/` | `PartnerProgram`, `RankedPartnerProgram`, `FinancialInstrument`, `PartnerProgramRepository` (interface) |
| `behavioral/` | `BehaviorProfile`, `BehavioralVector`, `FinancialPersonality`, `Habit`, `BehaviorRepository` (interface) |
| `engines/` | `DecisionEngine`, `BehavioralEngine`, `ExplainabilityEngine`, `KnowledgeGraphEngine`, `PartnerMatchingEngine`, `SimulationEngine` (all interfaces) |
| `events/` | `DomainEvents` — `DecisionGenerated`, `DecisionAccepted`, `DecisionExecuted`, `DecisionObserved`, `DecisionReviewed`, `DecisionLearned`, `TwinUpdated` |
| `finance/` | `FinancialState`, `FinancialPolicy` |
| `value_objects/` | `Money`, `Currency`, `RiskLevel`, `TimeHorizon`, `Ids` (DecisionId, UserId, GoalId, etc.) |

### Infrastructure Layer (`mobile/lib/infrastructure/`)
| File | Purpose |
|------|---------|
| `repositories/rest_decision_repository.dart` | Calls GET /decisions/today → maps via DecisionMapper |
| `repositories/hardcoded_partner_repository.dart` | 6 curated programs (HDFC RD, Nippon SIP, Jar Gold, Axis ELSS, Fi Smart Deposit, ICICI Amazon CC) |
| `mappers/decision_mapper.dart` | TodayDecisionModel → Flutter DecisionResponse domain object |
| `mappers/partner_mapper.dart` | PartnerOptionModel / PartnerRecommendation → RankedPartnerProgram |

### Data Models (`mobile/lib/features/decisions/data/models/`)
`today_decision_model.dart` — parses **both** backend formats:
- v1 flat (`{ decisionId, headline, reasons, partnerOptions }`) — backward compat
- v2 nested (`{ decision: {...}, explanation: {...}, partnerPrograms: [...] }`) — current

---

## Backend Architecture — Key Packages

| Package | Purpose |
|---------|---------|
| `domain.decision` | Canonical domain records — `DecisionResponse` and all nested types (no Spring/JPA) |
| `policy` | `FinancialPolicy` — all financial constants, SIP rate lookup, fiduciary statement |
| `mapper` | `DecisionResponseMapper` — `TodayDecisionResponse` → `DecisionResponse` |
| `engine.decision` | `DecisionEngine`, `RiskEngine`, `TradeoffEngine`, `ExplainabilityEngine`, `GoalImpactEngine` |
| `engine.memory` | `DecisionMemoryEngine`, `DecisionRecorder`, `DecisionOutcomeEngine` |
| `engine.behavioral` | Behavioral pattern detection (scaffolded) |
| `service` | `TodayDecisionService`, `AffordabilityService`, `DecisionMemoryService`, `HealthScoreService` |
| `controller` | REST controllers — `TodayDecisionController` now returns `DecisionResponse` |
| `dto.decision` | `TodayDecisionResponse`, `DecisionImpact`, `RecommendedAction`, `PartnerOption` — legacy, kept for backward compat |

---

## Key Local Storage
`mobile/lib/core/services/storage/user_prefs_storage.dart`

- `user_salary` → double
- `user_achievements` → List<String>
- `quiz_total_score` → int (XP points)
- `completed_quizzes` → List<String>

JWT tokens: `mobile/lib/core/services/storage/token_storage.dart` (Flutter Secure Storage)

---

## Achievement IDs
- `onboarding_complete`
- `salary_quiz_done` → 💰 Salary Scholar
- `savings_quiz_done` → 🏦 Savings Expert
- `investment_quiz_done` → 📈 Investment Pro
- `budget_quiz_done` → 🎯 Budget Boss

---

## App Colors (`mobile/lib/core/theme/app_colors.dart`)
- `AppColors.primary` = `#0F9D58` (savings green)
- `AppColors.secondary` = `#16213E` (trust navy)
- `AppColors.accent` = `#F2A104` (insight amber)
- `AppColors.success` = `#2ECC71`
- `AppColors.danger` = `#E74C3C`
- `AppColors.warning` = `#F39C12`
- `AppColors.background` = `#F7F9FC`

---

## Navigation (go_router)
Router file: `mobile/lib/core/router/app_router.dart`

Main tab shell (`/dashboard`, `/transactions`, `/goals`, `/learn`, `/chat`) uses `StatefulShellRoute`.
Detail screens pushed via `Navigator.of(context).push(MaterialPageRoute(...))`.

---

## PRD Phase Progress

### Phase 1 — MVP
| Item | Status |
|------|--------|
| Authentication UI | ✅ login + register + JWT + salary sync |
| SMS auto-parsing | ❌ 0% — another_telephony declared, background listener not implemented |
| Manual transaction entry | ✅ create/edit/delete + OCR + AI category |
| Budget tracking | ✅ create/edit/delete, donut chart, progress bars |
| Dashboard | ✅ Local salary data + backend health score + Today's Best Decision + Bank Program Slider |
| Goals | ✅ GET/POST, animated cards, GoalPlanScreen, AI plan |
| Affordability checker | ✅ POST /affordability/check, salary auto-loads |
| Reports | ❌ 0% — backend endpoint missing |

### Phase 2
| Item | Status |
|------|--------|
| AI categorization | ❌ 0% |
| AI spending insights | ❌ 0% |
| Learning academy | ⚠️ Quiz system in detail screens; no standalone lesson/flashcard screen |
| Notifications | ❌ 0% |
| Financial health score (dynamic) | ⚠️ Backend HealthScoreService calculates from transactions/goals; UI shows it |
| Today's Best Decision | ✅ Rule-based v1 (4 rules); returns DecisionResponse v2 envelope |
| Decision Memory | ✅ Backend: record + timeline + review + insights; Flutter: Financial Journal screen |
| Savings recommendations | ❌ 0% — no proactive nudge system yet |

### Phase 3
| Item | Status |
|------|--------|
| Investment recommendations | ⚠️ Educational content in detail screens; no live portfolio |
| Portfolio tracking | ❌ 0% |
| AI chat assistant | ⚠️ UI only; no LLM backend endpoint |
| Receipt OCR | ⚠️ ML Kit declared; not wired end-to-end |
| Gamification | ⚠️ XP + achievements working; levels/leaderboard missing |
| Spending predictions | ❌ 0% |
| Commitment Intelligence | ✅ CommitmentEngine detects recurring patterns from transaction history |
| Digital Twin (stub) | ✅ Screen exists with behavioral parameter visualizations; no real data |
| Financial Journal | ✅ Decision history, timeline, pending reviews |

### Phase 4+
Everything else: ❌ 0% (Behavioral Engine, Knowledge Graph, Life Event Intelligence, Account Aggregator)

---

## Next Steps — Priority Order

### Immediate (Phase 2 continuation)
1. **Phase 2 Sprint 2** — Affordability → `DecisionResponse`: update `AffordabilityService` and `AffordabilityController` to return `DecisionResponse` via `DecisionResponseMapper`. Wire `FinancialPolicy` constants into `DecisionEngine`.
2. **Wire FinancialPolicy into TodayDecisionService** — replace hardcoded constants (3, 6, 0.15, etc.) with `FinancialPolicy.*` references.
3. **Step-Up SIP formula** — replace `targetMonthly = outstanding / monthsToGoal` in `TodayDecisionService.buildStartSipDecision()` with proper SIP formula using `FinancialPolicy.sipRateForHorizon()`.

### Data Foundation (unlocks all intelligence engines)
4. **RBI Account Aggregator** (Setu SDK) — 12 months bank history in one API call
5. **Android SMS background listener** — `another_telephony` real-time detection + NACH/ECS/UPI AutoPay rail detection
6. **Financial Knowledge Graph** — PostgreSQL entity graph: Person → Income → Goals → Transactions → Merchants → Subscriptions

### Intelligence (requires data foundation)
7. **True Financial Health Engine** — 10-dimensional score (liquidity, debt quality, savings consistency, goal funding, insurance, diversification, behavioral consistency, income stability, anxiety, tax efficiency)
8. **Decision Engine v2** — multi-axis pipeline: Goal → Cash Flow → Liquidity → Behavior → Health → Opportunity Cost → Tax → Risk → Recommendation
9. **Close the Decision Memory Loop** — full AAR lifecycle (Recommend → Accept → Execute → Observe → Outcome → Lesson → Twin Update)
10. **Behavioral Engine** — pattern detection from transaction history; update behavioral vector θ

---

## Financial Data Pipeline — North Star

### The 11-Layer Ingestion Stack
| # | Layer | Status |
|---|-------|--------|
| 1 | RBI Account Aggregator (Setu SDK) | ❌ Not started |
| 2 | SMS Intelligence Engine | ⚠️ Basic parser; no background listener |
| 3 | Email Intelligence | ❌ Not started |
| 4 | Calendar Prediction Engine | ❌ Not started |
| 5 | Subscription Intelligence | ❌ Not started |
| 6 | Merchant Intelligence Graph | ❌ Not started |
| 7 | One-Tap Confirmation | ❌ Not started |
| 8 | AI Transaction Intelligence | ❌ Not started |
| 9 | OCR (google_mlkit declared) | ⚠️ Declared; not wired |
| 10 | Voice Entry | ❌ Not started |
| 11 | Manual Entry | ✅ Done (3-step stepper) |

---

## Known Issues / Debt
- `withOpacity()` deprecated Flutter 3.44 — should use `.withValues(alpha: x)` (~37 lint infos, no errors)
- `flutter_bloc` imported in pubspec but unused — state management is StatefulWidget local state
- Dashboard health score: backend `HealthScoreService` calculates dynamically, but pillars (savings, budget, goals, activity) are rule-based offsets, not computed from real multi-dimensional model
- `AffordabilityController` still returns `AffordabilityResponse` (pre-migration) — Phase 2 Sprint 2 will migrate to `DecisionResponse`
- `HardcodedPartnerRepository` — partner data is static; Phase 4 will replace with live backend `/partners` endpoint
- `TodayDecisionService` still has hardcoded constants (3, 6, 0.15, 0.40) — Phase 2 Sprint 3 will wire `FinancialPolicy`
- `DecisionLifecycleEvent` POST `/decisions/{id}/lifecycle` is a stub — Decision Memory Engine loop not closed

---

# gstack

gstack is installed globally at `~/.claude/skills/gstack`. Use these slash commands:

| Command | Role | Use When |
|---------|------|----------|
| `/office-hours` | YC Office Hours | Challenge product assumptions before building |
| `/spec` | Spec Author | Turn vague intent into a precise, executable spec |
| `/plan-ceo-review` | CEO / Founder | Expand scope, find the 10-star product |
| `/plan-eng-review` | Eng Manager | Lock in architecture, data flow, edge cases |
| `/plan-design-review` | Senior Designer | Rate and fix the design plan |
| `/autoplan` | Review Pipeline | One command: CEO → design → eng review |
| `/review` | Staff Engineer | Find bugs that pass CI but blow up in prod |
| `/investigate` | Debugger | Systematic root-cause debugging |
| `/design-review` | Designer | Live visual audit + fix loop |
| `/design-shotgun` | Design Explorer | Generate multiple design variants to compare |
| `/qa` | QA Lead | Test app in real browser, fix bugs, re-verify |
| `/cso` | Chief Security Officer | OWASP Top 10 + STRIDE security audit |
| `/ship` | Release Engineer | Sync, test, push, open PR in one command |
| `/health` | Code Quality | Type check, lint, tests, dead code score |
| `/document-release` | Technical Writer | Update stale docs after shipping |
| `/careful` | Safety Guardrails | Warn before destructive commands |
| `/diagram` | Diagram Maker | English in → mermaid + excalidraw + SVG out |

**Recommended workflow for PennyWise features:**
1. `/office-hours` — challenge the feature assumption
2. `/autoplan` — get a reviewed plan (CEO + design + eng)
3. Build with Claude Code
4. `/review` — catch production bugs
5. `/cso` — security audit before shipping
6. `/ship` — push + PR

---

# frontend-design skill

Installed at `~/.claude/skills/frontend-design`. Invoked automatically when building or redesigning UI screens.

**App design tokens (from `app_colors.dart`):**
- Primary: `#0F9D58` (savings green)
- Secondary: `#16213E` (trust navy)
- Accent: `#F2A104` (insight amber)
- Background: `#F7F9FC`

Use `/frontend-design` when: building new screens, redesigning existing ones, or needing aesthetic direction on Flutter widgets.
