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

**Missing backend endpoints:** `/dashboard`, `/ai/chat`, `/users/me`, `/reports`, `/notifications`, `/investments`

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
| Affordability | `features/calculator/presentation/screens/affordability_screen.dart` | Full UI + mock verdict (needs API wiring) |
| Onboarding | `features/authentication/presentation/screens/onboarding_goal_setup_screen.dart` | Saves salary to SharedPreferences |

### Screens That Are Stubs / Need Wiring
| Screen | What's Missing |
|--------|----------------|
| Login | API call to POST /auth/login + JWT storage |
| Register | API call to POST /auth/register |
| Splash | Check TokenStorage for valid session → route to dashboard or login |
| Transactions | Wire to GET/POST /transactions via TransactionsBloc |
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
| Manual transaction entry | ✅ UI scaffold, ❌ not wired |
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

1. **Wire Login/Register to backend** — implement ApiClient calls + save JWT to TokenStorage
2. **Splash screen session check** — read JWT from TokenStorage, route accordingly
3. **Wire Affordability screen** — replace mock with real POST /affordability/check
4. **Wire Transactions screen** — implement TransactionsBloc, GET/POST /transactions
5. **Wire Goals screen** — implement GoalsBloc, GET/POST /goals
6. **Build /users/me endpoint** — so onboarding saves salary to backend too
7. **Build AI chat endpoint** — integrate OpenAI GPT-4o-mini
8. **SMS parsing** — implement another_telephony for auto transaction detection
9. **Financial health score** — calculate dynamically from transactions/savings/goals
10. **Learning screen** — standalone lessons, flashcards, daily content

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
