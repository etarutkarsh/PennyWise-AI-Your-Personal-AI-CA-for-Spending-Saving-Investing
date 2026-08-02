import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/app_services.dart';
import '../utils/redirect_utils.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/authentication/presentation/screens/onboarding_goal_setup_screen.dart';
import '../../features/authentication/presentation/screens/register_screen.dart';
import '../../features/authentication/presentation/screens/splash_screen.dart';
import '../../features/budget/presentation/screens/budget_screen.dart';
import '../../features/calculator/presentation/screens/affordability_screen.dart';
import '../../features/ai/chat/presentation/screens/chat_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/salary_detail_screen.dart';
import '../../features/dashboard/presentation/screens/savings_detail_screen.dart';
import '../../features/dashboard/presentation/screens/investment_detail_screen.dart';
import '../../features/dashboard/presentation/screens/budget_detail_screen.dart';
import '../../features/goals/presentation/screens/goals_screen.dart';
import '../../features/insights/presentation/screens/insights_screen.dart';
import '../../features/investments/presentation/screens/investments_screen.dart';
import '../../features/learn/presentation/screens/learn_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/transactions/presentation/screens/transactions_screen.dart';
import '../../features/net_worth/presentation/screens/net_worth_screen.dart';
import '../../features/savings_rules/presentation/screens/savings_rules_screen.dart';
import '../../features/leaderboard/presentation/screens/leaderboard_screen.dart';
import '../../features/sms/presentation/screens/sms_import_screen.dart';
import '../../features/documents/presentation/screens/document_vault_screen.dart';
import '../../features/about/presentation/screens/about_screen.dart';
import '../../features/contact/presentation/screens/contact_screen.dart';
import '../../features/decisions/presentation/screens/financial_journal_screen.dart';
import '../../features/twin/presentation/screens/digital_twin_screen.dart';
import 'main_shell.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

const _publicPaths = {'/splash', '/login', '/register', '/onboarding/goal-setup'};

Future<String?> _authRedirect(BuildContext context, GoRouterState state) async {
  final path = state.uri.path;
  if (path == '/') return '/splash';

  try {
    final hasSession = await AppServices.instance.auth.hasSession();

    // Protected route → no valid session → landing page on web, /login on mobile
    if (!_publicPaths.contains(path) && !hasSession) {
      if (redirectToLanding()) return null; // web: hard-navigate, no Flutter route needed
      return '/login';
    }

    // Already authenticated → skip login/register screens
    if ((path == '/login' || path == '/register') && hasSession) return '/dashboard';
  } catch (_) {
    // Auth service failure — redirect unauthenticated routes to login.
    if (!_publicPaths.contains(path)) return '/login';
  }

  return null;
}

/// Central route table. Uses go_router's StatefulShellRoute so the bottom
/// nav (MainShell) preserves each tab's navigation stack independently.
///
/// Detail routes (salary, savings, investment, budget, insights) are defined
/// at the ROOT level with parentNavigatorKey = rootNavigatorKey so they always
/// render above the shell, full-screen. Query params carry all required data.
final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/splash',
  redirect: _authRedirect,
  routes: [
    // ── Auth & onboarding ────────────────────────────────────────────────────
    GoRoute(path: '/splash', builder: (context, state) {
      final at = state.uri.queryParameters['at'];
      final rt = state.uri.queryParameters['rt'];
      return SplashScreen(accessToken: at, refreshToken: rt);
    }),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
    GoRoute(
      path: '/onboarding/goal-setup',
      builder: (context, state) => const OnboardingGoalSetupScreen(),
    ),

    // ── Standalone screens (no shell) ────────────────────────────────────────
    GoRoute(
      path: '/affordability',
      builder: (context, state) {
        final salary = double.tryParse(
              state.uri.queryParameters['salary'] ?? '',
            ) ??
            0.0;
        return AffordabilityScreen(salary: salary);
      },
    ),
    GoRoute(path: '/budgets', builder: (context, state) => const BudgetScreen()),
    GoRoute(path: '/investments', builder: (context, state) => const InvestmentsScreen()),
    GoRoute(path: '/reports', builder: (context, state) => const ReportsScreen()),
    GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
    GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
    GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
    GoRoute(path: '/net-worth', builder: (context, state) => const NetWorthScreen()),
    GoRoute(path: '/savings-rules', builder: (context, state) => const SavingsRulesScreen()),
    GoRoute(path: '/leaderboard', builder: (context, state) => const LeaderboardScreen()),
    GoRoute(path: '/sms-import', builder: (context, state) => const SmsImportScreen()),
    GoRoute(path: '/documents', builder: (context, state) => const DocumentVaultScreen()),
    GoRoute(path: '/about', builder: (context, state) => const AboutScreen()),
    GoRoute(path: '/contact', builder: (context, state) => const ContactScreen()),
    GoRoute(path: '/journal', builder: (context, state) => const FinancialJournalScreen()),
    GoRoute(path: '/twin', builder: (context, state) => const DigitalTwinScreen()),
    GoRoute(
      path: '/insights',
      builder: (context, state) {
        final salary = double.tryParse(
              state.uri.queryParameters['salary'] ?? '',
            ) ??
            0.0;
        return InsightsScreen(salary: salary);
      },
    ),

    // ── Detail screens — parentNavigatorKey forces full-screen above shell ───
    GoRoute(
      path: '/detail/salary',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final salary = double.tryParse(
              state.uri.queryParameters['salary'] ?? '',
            ) ??
            50000.0;
        return SalaryDetailScreen(salary: salary);
      },
    ),
    GoRoute(
      path: '/detail/savings',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final q = state.uri.queryParameters;
        final salary = double.tryParse(q['salary'] ?? '') ?? 50000.0;
        final savings = double.tryParse(q['savings'] ?? '') ?? salary * 0.12;
        return SavingsDetailScreen(salary: salary, savings: savings);
      },
    ),
    GoRoute(
      path: '/detail/investment',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final q = state.uri.queryParameters;
        final salary = double.tryParse(q['salary'] ?? '') ?? 50000.0;
        final investments = double.tryParse(q['investments'] ?? '') ?? salary * 0.08;
        return InvestmentDetailScreen(salary: salary, investments: investments);
      },
    ),
    GoRoute(
      path: '/detail/budget',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final budget = double.tryParse(
              state.uri.queryParameters['budget'] ?? '',
            ) ??
            15000.0;
        return BudgetDetailScreen(remainingBudget: budget);
      },
    ),

    // ── Main tab shell ────────────────────────────────────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/transactions', builder: (context, state) => const TransactionsScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/goals', builder: (context, state) => const GoalsScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/learn', builder: (context, state) => const LearnScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/chat', builder: (context, state) => const ChatScreen()),
        ]),
      ],
    ),
  ],
);
