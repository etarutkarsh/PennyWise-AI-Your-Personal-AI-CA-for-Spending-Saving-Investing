# Graph Report - .  (2026-07-26)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 1694 nodes · 2840 edges · 85 communities (77 shown, 8 thin omitted)
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 91 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `99ac4e3f`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- .get
- List
- JwtService
- CurrentUserProvider
- savings_rules_screen.dart
- app_router.dart
- InvestmentPortfolioDto
- net_worth_screen.dart
- ChatService
- investments_screen.dart
- GoalRepository
- learn_screen.dart
- StatelessWidget
- AffordabilityResponse
- quiz_section.dart
- app_services.dart
- add_transaction_sheet.dart
- budget_detail_screen.dart
- dashboard_screen.dart
- leaderboard_screen.dart
- BudgetService.java
- goals_screen.dart
- net_worth_repository.dart
- chat_screen.dart
- ai_service.dart
- budget_screen.dart
- investment_detail_screen.dart
- TransactionRepository
- ApiClient
- notifications_screen.dart
- transactions_screen.dart
- sms_import_screen.dart
- user_prefs_storage.dart
- HealthScoreService
- TransactionDto
- settings_screen.dart
- package:flutter/material.dart
- .build
- reports_screen.dart
- affordability_screen.dart
- api_constants.dart
- State
- savings_detail_screen.dart
- register_screen.dart
- detail_screen_widgets.dart
- Budget
- investment_model.dart
- profile_screen.dart
- app_colors.dart
- ../../core/theme/app_colors.dart
- budget_model.dart
- sms_parser_service.dart
- health_score_repository.dart
- user_repository.dart
- goal_entity.dart
- affordability_result.dart
- Color
- transaction_entity.dart
- String?
- auth_repository.dart
- build
- investment_repository.dart
- token_storage.dart
- dashboard_summary.dart
- api_client.dart
- savings_rule_repository.dart
- goal_repository.dart
- budget_repository.dart
- static const
- category_model.dart
- BaseEntity
- User
- PennywiseApplication
- JpaAuditingConfig.java
- TransactionDirection
- _logout
- build
- BudgetRepository
- CategoryRepository
- _ChatMessage
- GoalRepository
- SavingsRuleRepository
- TransactionRepository
- UserRepository
- com.pennywise:pennywise-backend

## God Nodes (most connected - your core abstractions)
1. `CurrentUserProvider` - 29 edges
2. `ResourceNotFoundException` - 21 edges
3. `TransactionRepository` - 21 edges
4. `User` - 20 edges
5. `Transaction` - 18 edges
6. `ChatService` - 18 edges
7. `UserRepository` - 17 edges
8. `HealthScoreService` - 17 edges
9. `JwtService` - 16 edges
10. `CategoryRepository` - 16 edges

## Surprising Connections (you probably didn't know these)
- `TransactionController` --references--> `TransactionService`  [EXTRACTED]
  backend/src/main/java/com/pennywise/controller/TransactionController.java → backend/src/main/java/com/pennywise/service/TransactionService.java
- `Asset` --inherits--> `BaseEntity`  [EXTRACTED]
  backend/src/main/java/com/pennywise/entity/Asset.java → backend/src/main/java/com/pennywise/entity/BaseEntity.java
- `Budget` --inherits--> `BaseEntity`  [EXTRACTED]
  backend/src/main/java/com/pennywise/entity/Budget.java → backend/src/main/java/com/pennywise/entity/BaseEntity.java
- `Category` --inherits--> `BaseEntity`  [EXTRACTED]
  backend/src/main/java/com/pennywise/entity/Category.java → backend/src/main/java/com/pennywise/entity/BaseEntity.java
- `ChatMessage` --inherits--> `BaseEntity`  [EXTRACTED]
  backend/src/main/java/com/pennywise/entity/ChatMessage.java → backend/src/main/java/com/pennywise/entity/BaseEntity.java

## Import Cycles
- None detected.

## Communities (85 total, 8 thin omitted)

### Community 0 - ".get"
Cohesion: 0.05
Nodes (43): DeleteMapping, GetMapping, PostMapping, RequestMapping, RestController, NetWorthController, AssetCreateRequest, Data (+35 more)

### Community 1 - "List"
Cohesion: 0.06
Nodes (43): CategoryController, GetMapping, RequestMapping, RestController, DeleteMapping, GetMapping, PatchMapping, PostMapping (+35 more)

### Community 2 - "JwtService"
Cohesion: 0.06
Nodes (36): Component, HttpServletRequest, JwtAuthFilter, Service, JwtService, Configuration, PasswordEncoder, SecurityConfig (+28 more)

### Community 3 - "CurrentUserProvider"
Cohesion: 0.07
Nodes (29): GetMapping, RequestMapping, RestController, LeaderboardController, GetMapping, PatchMapping, RequestMapping, RestController (+21 more)

### Community 4 - "savings_rules_screen.dart"
Cohesion: 0.05
Nodes (43): ../../../../data/models/savings_rule_model.dart, _AddRuleSheet, _AddRuleSheetState, build, _buildBody, _buildConfig, _buildConfigInputs, _categories (+35 more)

### Community 5 - "app_router.dart"
Cohesion: 0.05
Nodes (41): ../../features/ai/chat/presentation/screens/chat_screen.dart, ../../features/authentication/presentation/screens/login_screen.dart, ../../features/authentication/presentation/screens/onboarding_goal_setup_screen.dart, ../../features/authentication/presentation/screens/register_screen.dart, ../../features/authentication/presentation/screens/splash_screen.dart, ../../features/budget/presentation/screens/budget_screen.dart, ../../features/calculator/presentation/screens/affordability_screen.dart, ../../features/dashboard/presentation/screens/dashboard_screen.dart (+33 more)

### Community 6 - "InvestmentPortfolioDto"
Cohesion: 0.10
Nodes (24): InvestmentPortfolioController, DeleteMapping, GetMapping, PatchMapping, PostMapping, RequestMapping, ResponseEntity, RestController (+16 more)

### Community 7 - "net_worth_screen.dart"
Cohesion: 0.05
Nodes (41): _AddItemSheet, _AddItemSheetState, _AssetAdded, _assetEmoji, _assetLabel, _assetTypes, build, child (+33 more)

### Community 8 - "ChatService"
Cohesion: 0.10
Nodes (25): ChatController, GetMapping, PostMapping, RequestMapping, ResponseEntity, RestController, ChatMessageDto, AllArgsConstructor (+17 more)

### Community 9 - "investments_screen.dart"
Cohesion: 0.05
Nodes (40): ../../../../data/models/investment_model.dart, double totalInvested, totalCurrent, totalReturns,, _AddInvestmentSheet, _AddInvestmentSheetState, build, _buildEmpty, _buildError, _buildList (+32 more)

### Community 10 - "GoalRepository"
Cohesion: 0.10
Nodes (23): GoalController, GetMapping, PatchMapping, PostMapping, RequestMapping, ResponseEntity, RestController, GoalCreateRequest (+15 more)

### Community 11 - "learn_screen.dart"
Cohesion: 0.05
Nodes (39): ../../../dashboard/presentation/screens/budget_detail_screen.dart, ../../../dashboard/presentation/screens/investment_detail_screen.dart, ../../../dashboard/presentation/screens/salary_detail_screen.dart, ../../../dashboard/presentation/screens/savings_detail_screen.dart, _achievements, _badgeMap, _BadgesRow, build (+31 more)

### Community 12 - "StatelessWidget"
Cohesion: 0.07
Nodes (36): _ActionChip, _AiTipCard, _FinancialHealthScoreCard, _QuickActions, _AiKeyBanner, _CategoryBreakdown, color, _computeStats (+28 more)

### Community 13 - "AffordabilityResponse"
Cohesion: 0.13
Nodes (17): AffordabilityEngine, Component, AffordabilityController, PostMapping, RequestMapping, RestController, AffordabilityRequest, Data (+9 more)

### Community 14 - "quiz_section.dart"
Cohesion: 0.06
Nodes (32): _alreadyCompleted, _answered, build, _buildAlreadyCompletedCard, _buildCompletionCard, _checkIfAlreadyCompleted, _completed, correctIndex (+24 more)

### Community 15 - "app_services.dart"
Cohesion: 0.06
Nodes (31): ai_service.dart, ../../data/repositories/affordability_repository.dart, ../../data/repositories/auth_repository.dart, ../../data/repositories/budget_repository.dart, ../../data/repositories/category_repository.dart, ../../data/repositories/goal_repository.dart, ../../data/repositories/investment_repository.dart, ../../data/repositories/leaderboard_repository.dart (+23 more)

### Community 16 - "add_transaction_sheet.dart"
Cohesion: 0.07
Nodes (28): dart:io, ImageSource, AddTransactionSheet, _AddTransactionSheetState, _amountController, build, _categories, createState (+20 more)

### Community 17 - "budget_detail_screen.dart"
Cohesion: 0.07
Nodes (27): ../../../learn/presentation/widgets/quiz_section.dart, BudgetDetailScreen, _BudgetKillerCard, _budgetQuestions, build, _CategoryRow, color, emoji (+19 more)

### Community 18 - "dashboard_screen.dart"
Cohesion: 0.07
Nodes (26): budget_detail_screen.dart, ../../domain/entities/dashboard_summary.dart, ../../../insights/presentation/screens/insights_screen.dart, investment_detail_screen.dart, createState, _dailyTip, _healthScore, icon (+18 more)

### Community 19 - "leaderboard_screen.dart"
Cohesion: 0.08
Nodes (25): ../../../../data/models/leaderboard_model.dart, LeaderboardEntry? get, displayName, fromJson, grade, isCurrentUser, LeaderboardEntry, rank (+17 more)

### Community 20 - "BudgetService.java"
Cohesion: 0.16
Nodes (16): BudgetController, GetMapping, PostMapping, RequestMapping, ResponseEntity, RestController, BudgetCreateRequest, Data (+8 more)

### Community 21 - "goals_screen.dart"
Cohesion: 0.08
Nodes (25): ../../domain/entities/goal_entity.dart, _amountController, build, _buildBody, _CreateGoalSheet, _CreateGoalSheetState, createState, _deadline (+17 more)

### Community 22 - "net_worth_repository.dart"
Cohesion: 0.08
Nodes (25): asOfDate, AssetModel, assets, assetType, _client, createAsset, createLiability, deleteAsset (+17 more)

### Community 23 - "chat_screen.dart"
Cohesion: 0.08
Nodes (24): _ChatMessage, _checkKey, _controller, createState, dispose, fromUser, _hasKey, initState (+16 more)

### Community 24 - "ai_service.dart"
Cohesion: 0.08
Nodes (23): ../../data/models/category_model.dart, Dio get, AiService, _apiClient, _chat, deleteKey, _dio, getDailyTip (+15 more)

### Community 25 - "budget_screen.dart"
Cohesion: 0.09
Nodes (23): _AddBudgetSheet, _AddBudgetSheetState, budget, _BudgetCard, _budgets, build, _buildBody, _categories (+15 more)

### Community 26 - "investment_detail_screen.dart"
Cohesion: 0.08
Nodes (23): amount, build, color, emoji, examples, InvestmentDetailScreen, _investmentQuestions, investments (+15 more)

### Community 27 - "TransactionRepository"
Cohesion: 0.16
Nodes (10): Entity, Getter, Setter, Table, Transaction, TransactionRepository, Service, Transactional (+2 more)

### Community 28 - "ApiClient"
Cohesion: 0.09
Nodes (20): ../../core/services/network/api_client.dart, ../../features/calculator/domain/entities/affordability_result.dart, ../../features/transactions/domain/entities/transaction_entity.dart, ApiClient, AffordabilityRepository, check, _client, CategoryRepository (+12 more)

### Community 29 - "notifications_screen.dart"
Cohesion: 0.09
Nodes (22): ../../../../data/models/budget_model.dart, ../../data/repositories/health_score_repository.dart, _Alert, _AlertCard, _alerts, _AlertType, body, build (+14 more)

### Community 30 - "transactions_screen.dart"
Cohesion: 0.10
Nodes (21): add_transaction_sheet.dart, ../../domain/entities/transaction_entity.dart, build, _buildBody, createState, currency, _delete, _EmptyState (+13 more)

### Community 31 - "sms_import_screen.dart"
Cohesion: 0.10
Nodes (21): ../../../../core/services/sms_parser_service.dart, build, createState, dispose, _examples, label, onAddTransaction, _openAddSheet (+13 more)

### Community 32 - "user_prefs_storage.dart"
Cohesion: 0.09
Nodes (21): addAchievement, addQuizScore, _checkLevelAchievements, _dateKey, getAchievements, getCompletedQuizzes, getSalary, getStreak (+13 more)

### Community 33 - "HealthScoreService"
Cohesion: 0.18
Nodes (11): HealthScoreController, GetMapping, RequestMapping, ResponseEntity, RestController, HealthScoreResponse, AllArgsConstructor, Builder (+3 more)

### Community 34 - "TransactionDto"
Cohesion: 0.14
Nodes (14): DeleteMapping, GetMapping, PostMapping, RequestMapping, ResponseEntity, RestController, TransactionController, Data (+6 more)

### Community 35 - "settings_screen.dart"
Cohesion: 0.10
Nodes (20): _AiKeySheet, _AiKeySheetState, _checkAiKey, _controller, createState, _delete, dispose, _hasAiKey (+12 more)

### Community 36 - "package:flutter/material.dart"
Cohesion: 0.11
Nodes (17): app_colors.dart, core/router/app_router.dart, core/services/app_services.dart, ../../core/services/storage/user_prefs_storage.dart, core/theme/app_theme.dart, AppTheme, build, createState (+9 more)

### Community 37 - ".build"
Cohesion: 0.28
Nodes (12): ErrorResponse, AllArgsConstructor, Data, GlobalExceptionHandler, HttpServletRequest, ResponseEntity, BadCredentialsException, ExceptionHandler (+4 more)

### Community 38 - "reports_screen.dart"
Cohesion: 0.11
Nodes (18): build, _buildContent, _categorySpend, color, createState, _error, initState, _isLoading (+10 more)

### Community 39 - "affordability_screen.dart"
Cohesion: 0.11
Nodes (17): ../../domain/entities/affordability_result.dart, build, _check, color, createState, dispose, _error, _formKey (+9 more)

### Community 40 - "api_constants.dart"
Cohesion: 0.11
Nodes (17): accessTokenKey, affordability, ApiConstants, auth, budgets, categories, chat, chatHistory (+9 more)

### Community 41 - "State"
Cohesion: 0.16
Nodes (18): ChatScreen, _ChatScreenState, OnboardingGoalSetupScreen, _OnboardingGoalSetupScreenState, SplashScreen, _SplashScreenState, BudgetScreen, _BudgetScreenState (+10 more)

### Community 42 - "savings_detail_screen.dart"
Cohesion: 0.12
Nodes (16): amount, build, color, _FundGoalRow, icon, label, rate, _Rule72Row (+8 more)

### Community 43 - "register_screen.dart"
Cohesion: 0.13
Nodes (15): FormState, build, createState, dispose, _emailController, _formKey, _isLoading, _nameController (+7 more)

### Community 44 - "detail_screen_widgets.dart"
Cohesion: 0.12
Nodes (15): build, child, color, DetailCaseStudyCard, DetailFactChip, DetailInfoCard, DetailSectionHeader, fact (+7 more)

### Community 45 - "Budget"
Cohesion: 0.22
Nodes (8): Budget, Entity, Getter, Setter, Table, BudgetRepository, Service, YearMonth

### Community 46 - "investment_model.dart"
Cohesion: 0.14
Nodes (13): bool get, currentValue, fromJson, id, instrumentType, investedAmount, InvestmentModel, isPositive (+5 more)

### Community 47 - "profile_screen.dart"
Cohesion: 0.15
Nodes (13): ../../data/repositories/user_repository.dart, UserModel, build, createState, _editRiskAppetite, _editSalary, _error, initState (+5 more)

### Community 48 - "app_colors.dart"
Cohesion: 0.14
Nodes (13): accent, AppColors, background, danger, primary, primaryDark, secondary, success (+5 more)

### Community 49 - "../../core/theme/app_colors.dart"
Cohesion: 0.15
Nodes (11): ../../core/theme/app_colors.dart, IconData, build, _checkSession, createState, initState, build, description (+3 more)

### Community 50 - "budget_model.dart"
Cohesion: 0.15
Nodes (12): double get, BudgetModel, categoryIcon, categoryName, fromJson, id, monthlyLimit, overBudget (+4 more)

### Community 51 - "sms_parser_service.dart"
Cohesion: 0.15
Nodes (12): accountLast4, amount, direction, _extractAccount, _extractAmount, _extractMerchant, isBankSms, merchant (+4 more)

### Community 52 - "health_score_repository.dart"
Cohesion: 0.15
Nodes (12): activityScore, _api, budgetScore, fromJson, goalScore, grade, HealthScoreModel, HealthScoreRepository (+4 more)

### Community 53 - "user_repository.dart"
Cohesion: 0.15
Nodes (12): _client, email, fromJson, fullName, getMe, id, monthlyIncome, phoneNumber (+4 more)

### Community 54 - "goal_entity.dart"
Cohesion: 0.15
Nodes (12): currentSaved, deadline, fromJson, GoalEntity, goalType, id, investmentSuggestion, name (+4 more)

### Community 55 - "affordability_result.dart"
Cohesion: 0.17
Nodes (11): double?, int?, AffordabilityResult, expectedPurchaseDate, fromJson, investmentSuggestion, _parseDateNullable, reason (+3 more)

### Community 56 - "Color"
Cohesion: 0.18
Nodes (10): Color, amount, build, color, description, icon, label, onTap (+2 more)

### Community 57 - "transaction_entity.dart"
Cohesion: 0.18
Nodes (10): DateTime, amount, categoryName, direction, fromJson, id, merchant, source (+2 more)

### Community 58 - "String?"
Cohesion: 0.18
Nodes (10): active, categoryId, categoryName, config, copyWith, fromJson, id, SavingsRuleModel (+2 more)

### Community 59 - "auth_repository.dart"
Cohesion: 0.20
Nodes (9): ../../core/services/storage/token_storage.dart, TokenStorage, AuthRepository, _client, hasSession, login, logout, register (+1 more)

### Community 60 - "build"
Cohesion: 0.20
Nodes (10): MaterialPageRoute, build, build, build, Route /affordability, Route /chat, Route /goals, Route /net-worth (+2 more)

### Community 61 - "investment_repository.dart"
Cohesion: 0.22
Nodes (8): ../../core/constants/api_constants.dart, _api, create, delete, getAll, InvestmentRepository, updateCurrentValue, ../models/investment_model.dart

### Community 62 - "token_storage.dart"
Cohesion: 0.22
Nodes (8): FlutterSecureStorage, Future, accessToken, clear, refreshToken, saveTokens, _storage, package:flutter_secure_storage/flutter_secure_storage.dart

### Community 63 - "dashboard_summary.dart"
Cohesion: 0.22
Nodes (8): dailyTip, DashboardSummary, financialHealthScore, investments, placeholder, remainingBudget, salary, savings

### Community 64 - "api_client.dart"
Cohesion: 0.25
Nodes (7): ../constants/api_constants.dart, Dio, dio, _tokenStorage, package:dio/dio.dart, package:pretty_dio_logger/pretty_dio_logger.dart, storage/token_storage.dart

### Community 65 - "savings_rule_repository.dart"
Cohesion: 0.25
Nodes (7): _client, create, delete, getAll, SavingsRuleRepository, toggleActive, ../models/savings_rule_model.dart

### Community 66 - "goal_repository.dart"
Cohesion: 0.29
Nodes (6): ../../features/goals/domain/entities/goal_entity.dart, _client, create, getAll, GoalRepository, updateSavedAmount

### Community 67 - "budget_repository.dart"
Cohesion: 0.33
Nodes (5): BudgetRepository, _client, create, getCurrentPeriod, ../models/budget_model.dart

### Community 68 - "static const"
Cohesion: 0.29
Nodes (6): build, MainShell, navigationShell, _tabs, StatefulNavigationShell, static const

### Community 69 - "category_model.dart"
Cohesion: 0.29
Nodes (6): CategoryModel, fromJson, icon, id, name, type

### Community 70 - "BaseEntity"
Cohesion: 0.60
Nodes (5): BaseEntity, Getter, Setter, EntityListeners, MappedSuperclass

### Community 71 - "User"
Cohesion: 0.60
Nodes (5): Entity, Getter, Setter, Table, User

### Community 72 - "PennywiseApplication"
Cohesion: 0.53
Nodes (4): PennywiseApplication, EnableAsync, EnableScheduling, SpringBootApplication

### Community 73 - "JpaAuditingConfig.java"
Cohesion: 0.83
Nodes (3): Configuration, JpaAuditingConfig, EnableJpaAuditing

### Community 74 - "TransactionDirection"
Cohesion: 0.67
Nodes (3): TransactionDirection, CREDIT, DEBIT

### Community 75 - "_logout"
Cohesion: 0.67
Nodes (3): _logout, _logout, Route /login

### Community 76 - "build"
Cohesion: 0.67
Nodes (3): build, Route /profile, Route /savings-rules

## Knowledge Gaps
- **746 isolated node(s):** `com.pennywise:pennywise-backend`, `DEBIT`, `CREDIT`, `ApiConstants`, `auth` (+741 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **8 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `UserRepository` connect `CurrentUserProvider` to `.get`, `JwtService`, `User`?**
  _High betweenness centrality (0.051) - this node is a cross-community bridge._
- **Why does `ApiClient` connect `ApiClient` to `api_client.dart`, `savings_rule_repository.dart`, `goal_repository.dart`, `budget_repository.dart`, `app_services.dart`, `health_score_repository.dart`, `user_repository.dart`, `net_worth_repository.dart`, `ai_service.dart`, `auth_repository.dart`, `investment_repository.dart`?**
  _High betweenness centrality (0.044) - this node is a cross-community bridge._
- **Why does `BudgetModel` connect `budget_model.dart` to `budget_screen.dart`?**
  _High betweenness centrality (0.036) - this node is a cross-community bridge._
- **What connects `com.pennywise:pennywise-backend`, `DEBIT`, `CREDIT` to the rest of the system?**
  _746 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `.get` be split into smaller, more focused modules?**
  _Cohesion score 0.05009009009009009 - nodes in this community are weakly interconnected._
- **Should `List` be split into smaller, more focused modules?**
  _Cohesion score 0.05829420970266041 - nodes in this community are weakly interconnected._
- **Should `JwtService` be split into smaller, more focused modules?**
  _Cohesion score 0.05583972719522592 - nodes in this community are weakly interconnected._