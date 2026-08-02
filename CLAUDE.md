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
└── docker-compose.yml
```

---

## Tech Stack

| Layer | Choice |
|-------|--------|
| Mobile | Flutter (Dart), go_router, flutter_bloc (declared, not wired yet), SharedPreferences |
| Backend | Spring Boot 3, Java 17, Spring Security, JJWT 0.12.6 |
| Database | PostgreSQL 16 |
| Cache | Redis 7 |
| Charts | fl_chart |
| AI (planned) | OpenAI GPT-4o-mini via LangChain |
| Auth (planned) | Firebase Auth or JWT (JWT currently wired on backend) |
| Push (planned) | Firebase Cloud Messaging |
| SMS parsing | another_telephony (declared, not implemented) |
| OCR | google_mlkit_text_recognition (declared, not implemented) |

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

## Backend API (All Implemented & Working)

| Method | Endpoint | Status |
|--------|----------|--------|
| POST | /auth/register | ✅ Done |
| POST | /auth/login | ✅ Done |
| POST | /transactions | ✅ Done |
| GET | /transactions | ✅ Done |
| DELETE | /transactions/{id} | ✅ Done |
| POST | /budgets | ✅ Done |
| GET | /budgets | ✅ Done |
| POST | /goals | ✅ Done |
| GET | /goals | ✅ Done |
| PATCH | /goals/{id}/saved-amount | ✅ Done |
| POST | /affordability/check | ✅ Done |
| GET | /categories | ✅ Done |

**Missing backend endpoints:** `/dashboard`, `/ai/chat`, `/reports`, `/notifications`, `/investments`
**Confirmed present:** `/users/me` (GET + PATCH, UserController fully implemented)

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

---

## Flutter App — Feature Status

### Screens with Real Implementation
| Screen | File | What Works |
|--------|------|------------|
| Dashboard | `features/dashboard/presentation/screens/dashboard_screen.dart` | Loads salary from SharedPreferences, calculates savings/investments/budget using 50-30-20 rule, 4 clickable summary cards |
| Salary Detail | `features/dashboard/presentation/screens/salary_detail_screen.dart` | 50-30-20 breakdown, case study, 5-question quiz, XP + achievement |
| Savings Detail | `features/dashboard/presentation/screens/savings_detail_screen.dart` | Emergency fund calculator, Rule of 72, 5 tips, quiz |
| Investment Detail | `features/dashboard/presentation/screens/investment_detail_screen.dart` | Pyramid, portfolio allocation, SIP compounding table, quiz |
| Budget Detail | `features/dashboard/presentation/screens/budget_detail_screen.dart` | Zero-based budgeting, budget killers, 30-day challenge, quiz |
| Affordability | `features/calculator/presentation/screens/affordability_screen.dart` | Full UI + real POST /affordability/check + salary auto-loads from prefs |
| Onboarding | `features/authentication/presentation/screens/onboarding_goal_setup_screen.dart` | Saves salary to SharedPreferences |

### Screens That Are Stubs / Need Wiring
| Screen | What's Missing |
|--------|----------------|
| Login | ✅ Fully wired — POST /auth/login + JWT save + salary sync from /users/me |
| Register | ✅ Fully wired — POST /auth/register + JWT save |
| Splash | ✅ Fully wired — reads URL tokens (web), hasSession() check, routes to /dashboard or /login |
| Transactions | ✅ Fully wired — GET/POST/PATCH/DELETE, OCR, AI category suggestion |
| Goals | Wire to GET/POST /goals via GoalsBloc |
| Budget | Complete UI + wire to GET/POST /budgets |
| AI Chat | Build /ai/chat backend endpoint + wire ChatScreen |
| Learn | Full learning academy with lessons, flashcards |
| Investments | Portfolio tracking UI |
| Reports | Spending reports + charts |
| Notifications | AI alerts display |
| Profile | Edit salary, risk appetite, PATCH /users/me |
| Settings | Logout (clear JWT), permissions |

---

## Key Local Storage
`mobile/lib/core/services/storage/user_prefs_storage.dart`

Stores via SharedPreferences:
- `user_salary` → double (set on onboarding)
- `user_achievements` → List<String> (badge IDs earned)
- `quiz_total_score` → int (XP points)
- `completed_quizzes` → List<String> (quiz IDs completed)

JWT tokens: `mobile/lib/core/services/storage/token_storage.dart` (Flutter Secure Storage, declared but not yet used by login screen)

---

## Achievement IDs (currently in use)
- `onboarding_complete` — finished onboarding
- `salary_quiz_done` → 💰 Salary Scholar
- `savings_quiz_done` → 🏦 Savings Expert
- `investment_quiz_done` → 📈 Investment Pro
- `budget_quiz_done` → 🎯 Budget Boss

---

## Shared UI Widgets (reusable)
- `mobile/lib/features/dashboard/presentation/widgets/detail_screen_widgets.dart`
  → `DetailSectionHeader`, `DetailInfoCard`, `DetailCaseStudyCard`, `DetailFactChip`, `showAchievementSnackbar()`
- `mobile/lib/features/learn/presentation/widgets/quiz_section.dart`
  → `QuizSection`, `QuizQuestion` — self-contained quiz widget with XP + achievement hooks

---

## App Colors (mobile/lib/core/theme/app_colors.dart)
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
Detail screens pushed via `Navigator.of(context).push(MaterialPageRoute(...))` — NOT go_router routes.

---

## PRD Phase Progress

### Phase 1 — MVP
| Item | Status |
|------|--------|
| Authentication UI | ✅ UI done, ❌ not wired to backend |
| SMS auto-parsing | ❌ 0% |
| Manual transaction entry | ✅ Fully wired — create/edit/delete + OCR + AI category |
| Budget tracking | ❌ Placeholder only |
| Dashboard | ✅ Local data, ❌ no backend sync |
| Goals | ✅ UI scaffold, ❌ not wired |
| Affordability checker | ✅ UI done, ✅ backend done, ❌ not wired together |
| Reports | ❌ 0% |

### Phase 2
| Item | Status |
|------|--------|
| AI categorization | ❌ 0% |
| AI spending insights | ❌ 0% |
| Learning academy | ✅ Quiz system built in card detail screens, ❌ no standalone learn screen |
| Notifications | ❌ 0% |
| Financial health score (dynamic) | ❌ Hardcoded 82 |
| Savings recommendations | ❌ 0% |

### Phase 3
| Item | Status |
|------|--------|
| Investment recommendations | ✅ Educational content (detail screen), ❌ no live portfolio |
| Portfolio tracking | ❌ 0% |
| AI chat assistant | ✅ UI only, ❌ no LLM backend |
| Receipt OCR | ❌ 0% (ML Kit declared) |
| Full gamification (levels, leaderboard) | ✅ Basic XP + achievements, ❌ levels/leaderboard missing |
| Spending predictions | ❌ 0% |

### Phase 4
Everything in Phase 4: ❌ 0%

---

## Biggest Next Steps (Priority Order)

1. ~~Wire Login/Register to backend~~ ✅ Done — login + register + JWT save + salary sync
2. ~~Splash screen session check~~ ✅ Done — hasSession() check, URL token support for web
3. ~~Wire Affordability screen~~ ✅ Done — real POST /affordability/check, salary auto-loads from prefs
4. ~~Wire Transactions screen~~ ✅ Done
5. **Wire Goals screen** — implement GoalsBloc, GET/POST /goals
6. **Build /users/me endpoint** — so onboarding saves salary to backend too
7. **Build AI chat endpoint** — integrate OpenAI GPT-4o-mini
8. **SMS background listener** — implement `another_telephony` real-time detection + upgrade parser for NACH/ECS/UPI AutoPay rails
9. **Financial health score** — calculate dynamically from transactions/savings/goals
10. **Learning screen** — standalone lessons, flashcards, daily content
11. **Merchant Intelligence** — map raw merchant names/VPAs → brand + category + impulse score
12. **Subscription Intelligence** — detect forgotten/duplicate/price-increased subscriptions
13. **CommitmentEngine auto-pending** — pre-create expected transactions before they debit

---

## Financial Data Pipeline — North Star Architecture

**Core philosophy:** The user should almost never have to enter a transaction manually. Every debit/credit should be detected, classified, and confirmed with a single tap — or zero taps for high-confidence recurring items.

### The 11-Layer Ingestion Stack (priority order)

| # | Layer | What It Captures | Status |
|---|-------|-----------------|--------|
| 1 | **RBI Account Aggregator** | Complete bank history: salary, UPI, NACH, EMIs, credit cards (12–24 months) | ❌ Coming soon (Setu SDK) |
| 2 | **SMS Intelligence Engine** | Amount, direction, merchant, UPI VPA, balance, payment rail, recurring probability, confidence score | ⚠️ Basic parser done; needs NACH/ECS/UPI AutoPay rail detection + background listener |
| 3 | **Email Intelligence** | Invoices, refund confirmations, subscription renewals, EMI schedules, tax documents | ❌ Not started |
| 4 | **Calendar Prediction Engine** | Predict recurring debits before they happen (salary, EMI, rent, subscriptions) | ❌ Not started |
| 5 | **Subscription Intelligence** | Forgotten subs, duplicates, price increases, inactive, family plans, free-trial-to-paid traps | ❌ Not started |
| 6 | **Merchant Intelligence Graph** | Map "AMZ PAY INDIA PVT LTD" → Amazon, impulse score, refund frequency, cashback eligibility | ❌ Not started |
| 7 | **One-Tap Confirmation** | For 80–90% confidence detections — show card, single tap to confirm. Never a form. | ❌ Not started |
| 8 | **AI Transaction Intelligence** | "ABC PVT LTD" → "Office Lunch" — corrections become training signals for this user | ❌ Not started |
| 9 | **OCR** | Capture receipts (GST, merchant, items, amount) from camera — google_mlkit declared | ⚠️ ML Kit declared; not wired |
| 10 | **Voice Entry** | "I paid Rahul ₹500 cash" → structured transaction. Natural language, no form. | ❌ Not started |
| 11 | **Manual Entry** | Escape hatch only. Must feel like failure if user reaches here. | ✅ Done (3-step stepper) |

### Financial Identity Graph (target state)

```
User → Salary → Bank Accounts → Transactions → Merchants → Goals
     ↓                                               ↓
  Behavior ← Decision History ← Investments ← Subscriptions
     ↓
  Digital Twin (AI model of user's financial life)
```

Every node in this graph should be populated passively. PennyWise builds the graph from signals, not from forms.

### Passive Data Collection Philosophy

Infer recurring patterns without asking:
- Gym SMS every 5th of the month (₹1,200) → auto-create Health subscription commitment
- Zomato 3×/week avg ₹340 → suggest Food budget alert threshold
- Salary credit last Friday of month → lock in salary detection + next-month prediction
- No manual tagging of "this is my salary" — detect from amount + CREDIT rail + recurrence

### Additional Capabilities (roadmap)

- **WhatsApp integration** — "Paid Rahul ₹200 on Swiggy" messages → transactions
- **Family financial graph** — split expenses, shared goals, household budget
- **Predictive missing transaction detection** — "You usually pay electricity around the 12th — not detected yet. Paid?"
- **Unified commitments calendar** — all upcoming debits visible 30 days ahead (salary in, EMI out, rent out, SIP debit)

### Recommended Implementation Order

```
Phase A (foundations — do first):
  1. RBI Account Aggregator (Setu SDK) — unlocks 12 months of history instantly
  2. Android SMS background listener (another_telephony) — real-time detection
  3. PDF/CSV statement import — iOS users + any bank AA doesn't cover yet

Phase B (intelligence layer):
  4. Email Intelligence — catch subscriptions that banks see as generic "RAZORPAY" charges
  5. Merchant Intelligence Graph — enrich raw merchant strings across all sources
  6. Commitment + Subscription Engine — identify recurring patterns, pre-create pending txns

Phase C (AI layer):
  7. Prediction Engine — forecast upcoming debits from calendar + recurrence models
  8. OCR + Voice Entry — last-mile capture for cash and offline transactions

Phase D (autonomous):
  9. Behavioral Engine + Digital Twin — model user habits, trigger proactive coaching
```

### Key Files (ingestion layer)

| File | Purpose |
|------|---------|
| `mobile/lib/core/services/ingestion/ingestion_source.dart` | Enum, status, abstract base for all ingestion sources |
| `mobile/lib/features/sms/presentation/screens/sms_import_screen.dart` | SMS one-time bulk import (manual trigger) |
| `mobile/lib/features/commitments/` | CommitmentEngine — detects recurring patterns |
| `mobile/lib/features/documents/` | Document vault (PDF/CSV future home) |
| `mobile/lib/features/transactions/presentation/screens/add_transaction_sheet.dart` | Manual entry + OCR + AI category suggestion |

---

## Backend AI Engine
`backend/src/main/java/com/pennywise/ai/AffordabilityEngine.java`

Rule-based (not ML) affordability logic:
- Rule 1: Monthly surplus ≤ 0 → DONT_BUY
- Rule 2: Emergency fund post-purchase < 6× monthly expenses → WAIT_AND_SAVE
- Rule 3: Otherwise → SAFE_TO_BUY

OpenAI config ready in `application.yml` (env var: OPENAI_API_KEY, model: gpt-4o-mini)

---

## Known Issues / Debt
- `withOpacity()` deprecated Flutter 3.44 — should use `.withValues(alpha: x)` (56 lint warnings, no errors)
- flutter_bloc imported in pubspec but unused — state management is all StatefulWidget local state for now
- Dashboard salary derivation is local only — backend User entity has `monthlyIncome` field but it's never POSTed from mobile
- Affordability screen uses hardcoded emergency fund value — Phase 3 will use real investment portfolio data

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

This skill acts as the design lead — makes deliberate, opinionated choices about palette, typography, and layout specific to PennyWise (finance app, trust + clarity as core values). It grounds every design in the subject's real world rather than generic templates.

**App design tokens (from `app_colors.dart`):**
- Primary: `#0F9D58` (savings green)
- Secondary: `#16213E` (trust navy)
- Accent: `#F2A104` (insight amber)
- Background: `#F7F9FC`

Use `/frontend-design` when: building new screens, redesigning existing ones, or needing aesthetic direction on Flutter widgets.
