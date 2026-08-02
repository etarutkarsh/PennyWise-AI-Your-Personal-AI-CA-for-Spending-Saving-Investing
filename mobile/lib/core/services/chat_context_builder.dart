import 'package:intl/intl.dart';

import 'app_services.dart';
import '../../data/models/budget_model.dart';
import '../../data/repositories/health_score_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../features/goals/domain/entities/goal_entity.dart';
import '../../features/transactions/domain/entities/transaction_entity.dart';

// ── Result ────────────────────────────────────────────────────────────────────

class ChatContext {
  const ChatContext({
    required this.systemPrompt,
    required this.suggestions,
    required this.statusLabel,
  });

  final String systemPrompt;
  final List<String> suggestions;

  /// Short string shown in the chat header: "Income · Goals · Budget"
  final String statusLabel;

  static const fallback = ChatContext(
    systemPrompt:
        'You are PennyWise AI, a personal finance assistant for Indian users. '
        'Give concise, actionable financial advice. Use ₹ for currency. '
        'Max 3 short paragraphs per reply.',
    suggestions: [
      'How can I save more every month?',
      'Should I invest in mutual funds or FD?',
      'What is the 50-30-20 rule?',
      'How do I build a 6-month emergency fund?',
    ],
    statusLabel: 'Generic mode',
  );
}

// ── Builder ───────────────────────────────────────────────────────────────────

class ChatContextBuilder {
  /// Fetches all data in parallel and returns a fully-loaded [ChatContext].
  /// Never throws — any failed API call is skipped and context is built
  /// from whatever data is available.
  static Future<ChatContext> build() async {
    final now = DateTime.now();

    // Parallel fetch — fail-safe
    final results = await Future.wait([
      AppServices.instance.user.getMe().then<UserModel?>((u) => u).catchError((_) => null),
      AppServices.instance.healthScore.get().then<HealthScoreModel?>((h) => h).catchError((_) => null),
      AppServices.instance.transactions
          .getAll(direction: 'DEBIT')
          .then<List<TransactionEntity>?>((t) => t)
          .catchError((_) => null),
      AppServices.instance.goals.getAll().then<List<GoalEntity>?>((g) => g).catchError((_) => null),
      AppServices.instance.budgets
          .getCurrentPeriod()
          .then<List<BudgetModel>?>((b) => b)
          .catchError((_) => null),
    ]);

    final user       = results[0] as UserModel?;
    final health     = results[1] as HealthScoreModel?;
    final allDebits  = results[2] as List<TransactionEntity>?;
    final goals      = results[3] as List<GoalEntity>?;
    final budgets    = results[4] as List<BudgetModel>?;

    // Current-month debit transactions only
    final txns = allDebits
        ?.where((t) =>
            t.transactionDate.year == now.year &&
            t.transactionDate.month == now.month)
        .toList() ?? [];

    // Spending by category this month
    final Map<String, double> catSpend = {};
    for (final t in txns) {
      catSpend[t.categoryName] = (catSpend[t.categoryName] ?? 0) + t.amount;
    }
    final sortedCats = catSpend.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalSpent = catSpend.values.fold(0.0, (a, b) => a + b);

    final prompt = _buildPrompt(
      now: now,
      user: user,
      health: health,
      sortedCats: sortedCats,
      totalSpent: totalSpent,
      goals: goals ?? [],
      budgets: budgets ?? [],
    );

    final suggestions = _buildSuggestions(
      user: user,
      health: health,
      sortedCats: sortedCats,
      totalSpent: totalSpent,
      goals: goals ?? [],
      budgets: budgets ?? [],
    );

    final parts = <String>[];
    if (user != null) parts.add('Income');
    if (txns.isNotEmpty) parts.add('Transactions');
    if (goals?.isNotEmpty == true) parts.add('Goals');
    if (budgets?.isNotEmpty == true) parts.add('Budget');
    if (health != null) parts.add('Health');

    return ChatContext(
      systemPrompt: prompt,
      suggestions: suggestions,
      statusLabel: parts.isEmpty ? 'Generic mode' : parts.join(' · '),
    );
  }

  // ── System prompt assembly ──────────────────────────────────────────────────

  static String _buildPrompt({
    required DateTime now,
    required UserModel? user,
    required HealthScoreModel? health,
    required List<MapEntry<String, double>> sortedCats,
    required double totalSpent,
    required List<GoalEntity> goals,
    required List<BudgetModel> budgets,
  }) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final monthLabel = DateFormat('MMMM yyyy').format(now);
    final buf = StringBuffer();

    // Identity
    final name = (user?.fullName.isNotEmpty == true) ? user!.fullName : 'the user';
    buf.writeln(
      'You are PennyWise AI — the personal Chartered Accountant for $name. '
      'Always use their actual numbers. Be specific and concise. Max 3 short paragraphs. Use ₹.',
    );
    buf.writeln();

    // User profile
    if (user != null) {
      final income = user.monthlyIncome != null ? fmt.format(user.monthlyIncome) : 'unknown';
      final risk = _riskLabel(user.riskAppetite);
      final tax = user.taxRegime == 'OLD' ? 'Old Regime' : 'New Regime';
      buf.writeln('USER: $name | ${_typeLabel(user.userType)} | Income $income/mo | Risk: $risk | Tax: $tax');
    }

    // Health score
    if (health != null) {
      buf.writeln(
        'HEALTH SCORE: ${health.score}/100 (${health.grade}) — '
        'Savings ${health.savingsScore}/25 | Budget ${health.budgetScore}/25 | '
        'Goals ${health.goalScore}/25 | Activity ${health.activityScore}/15',
      );
    }

    buf.writeln();

    // This month's finances
    buf.writeln('$monthLabel FINANCES:');
    if (user?.monthlyIncome != null) {
      final pct = user!.monthlyIncome! > 0
          ? (totalSpent / user.monthlyIncome! * 100).toStringAsFixed(1)
          : '—';
      buf.writeln('• Spent: ${fmt.format(totalSpent)} ($pct% of income)');
    } else if (totalSpent > 0) {
      buf.writeln('• Spent: ${fmt.format(totalSpent)}');
    }

    if (sortedCats.isNotEmpty) {
      final top = sortedCats.take(4).map((e) => '${e.key} ${fmt.format(e.value)}').join(' · ');
      buf.writeln('• Top categories: $top');
    }

    // Budget alerts
    final alerts = budgets.where((b) => b.progressFraction > 0.85).toList()
      ..sort((a, b) => b.progressFraction.compareTo(a.progressFraction));
    if (alerts.isNotEmpty) {
      final alertStr = alerts
          .take(3)
          .map((b) => b.overBudget
              ? '${b.categoryName} over by ${fmt.format(b.spent - b.monthlyLimit)}'
              : '${b.categoryName} at ${(b.progressFraction * 100).toStringAsFixed(0)}%')
          .join(', ');
      buf.writeln('• Budget alerts: $alertStr');
    }

    // Goals
    if (goals.isNotEmpty) {
      buf.writeln();
      buf.writeln('ACTIVE GOALS (${goals.length}):');
      for (final g in goals.take(5)) {
        final pct = g.progressPercent.toStringAsFixed(0);
        final months = _monthsUntil(g.deadline, now);
        final contrib = g.recommendedMonthlyContribution > 0
            ? ' — save ${fmt.format(g.recommendedMonthlyContribution)}/mo'
            : '';
        buf.writeln('• ${g.name}: ${fmt.format(g.currentSaved)} of ${fmt.format(g.targetAmount)} ($pct%)$contrib | $months months left');
      }
    }

    buf.writeln();
    buf.writeln('Today: ${DateFormat('d MMMM yyyy').format(now)}');

    return buf.toString().trim();
  }

  // ── Contextual suggestions ─────────────────────────────────────────────────

  static List<String> _buildSuggestions({
    required UserModel? user,
    required HealthScoreModel? health,
    required List<MapEntry<String, double>> sortedCats,
    required double totalSpent,
    required List<GoalEntity> goals,
    required List<BudgetModel> budgets,
  }) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final suggestions = <String>[];

    // 1. Over-budget categories
    final overBudget = budgets.where((b) => b.overBudget).toList();
    if (overBudget.isNotEmpty) {
      suggestions.add('Why is my ${overBudget.first.categoryName} over budget?');
    }

    // 2. Near-limit categories (85–99%)
    final nearLimit = budgets
        .where((b) => !b.overBudget && b.progressFraction >= 0.85)
        .toList();
    if (nearLimit.isNotEmpty) {
      suggestions.add('How do I keep my ${nearLimit.first.categoryName} under the limit?');
    }

    // 3. Struggling goals (< 25% progress)
    final strugglingGoal = goals
        .where((g) => g.progressPercent < 25 && g.recommendedMonthlyContribution > 0)
        .toList();
    if (strugglingGoal.isNotEmpty) {
      suggestions.add('How can I hit my ${strugglingGoal.first.name} goal faster?');
    }

    // 4. Surplus suggestion
    if (user?.monthlyIncome != null && totalSpent > 0) {
      final surplus = user!.monthlyIncome! - totalSpent;
      if (surplus > user.monthlyIncome! * 0.25) {
        suggestions.add('I have ${fmt.format(surplus)} left — where should I invest it?');
      }
    }

    // 5. Low health score
    if (health != null && health.score < 60) {
      suggestions.add('My financial health score is ${health.score} — how do I improve it?');
    } else if (health != null && health.budgetScore < 15) {
      suggestions.add('What\'s dragging down my budget score?');
    }

    // 6. Top spending category insight
    if (sortedCats.isNotEmpty && suggestions.length < 4) {
      suggestions.add('Is my ${sortedCats.first.key} spending too high?');
    }

    // 7. Generic fallbacks to always have 4
    const fallbacks = [
      'Am I saving enough for retirement?',
      'Should I increase my SIP amount?',
      'How do I reduce my tax liability?',
      'What\'s the best way to grow my emergency fund?',
    ];
    for (final f in fallbacks) {
      if (suggestions.length >= 4) { break; }
      if (!suggestions.contains(f)) suggestions.add(f);
    }

    return suggestions.take(4).toList();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _riskLabel(String? r) {
    return switch (r?.toLowerCase()) {
      'low'    => 'Low (FDs, bonds)',
      'medium' => 'Medium (mutual funds)',
      'high'   => 'High (equity)',
      _        => 'Not set',
    };
  }

  static String _typeLabel(String type) {
    return switch (type.toUpperCase()) {
      'SALARIED_EMPLOYEE' => 'Salaried',
      'FREELANCER'        => 'Freelancer',
      'STUDENT'           => 'Student',
      'BUSINESS_OWNER'    => 'Business Owner',
      _                   => type.isNotEmpty ? type : 'Individual',
    };
  }

  static int _monthsUntil(DateTime deadline, DateTime now) {
    return ((deadline.year - now.year) * 12 + deadline.month - now.month)
        .clamp(0, 999);
  }
}
