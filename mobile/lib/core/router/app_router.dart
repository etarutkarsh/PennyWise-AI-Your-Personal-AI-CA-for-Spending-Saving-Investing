import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/authentication/presentation/screens/onboarding_goal_setup_screen.dart';
import '../../features/authentication/presentation/screens/register_screen.dart';
import '../../features/authentication/presentation/screens/splash_screen.dart';
import '../../features/budget/presentation/screens/budget_screen.dart';
import '../../features/calculator/presentation/screens/affordability_screen.dart';
import '../../features/ai/chat/presentation/screens/chat_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/goals/presentation/screens/goals_screen.dart';
import '../../features/investments/presentation/screens/investments_screen.dart';
import '../../features/learn/presentation/screens/learn_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/transactions/presentation/screens/transactions_screen.dart';
import '../../features/net_worth/presentation/screens/net_worth_screen.dart';
import 'main_shell.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Central route table. Uses go_router's StatefulShellRoute so the bottom
/// nav (MainShell) preserves each tab's navigation stack independently.
final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
    GoRoute(
      path: '/onboarding/goal-setup',
      builder: (context, state) => const OnboardingGoalSetupScreen(),
    ),
    GoRoute(path: '/affordability', builder: (context, state) => const AffordabilityScreen()),
    GoRoute(path: '/budgets', builder: (context, state) => const BudgetScreen()),
    GoRoute(path: '/investments', builder: (context, state) => const InvestmentsScreen()),
    GoRoute(path: '/reports', builder: (context, state) => const ReportsScreen()),
    GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
    GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
    GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
    GoRoute(path: '/net-worth', builder: (context, state) => const NetWorthScreen()),
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
