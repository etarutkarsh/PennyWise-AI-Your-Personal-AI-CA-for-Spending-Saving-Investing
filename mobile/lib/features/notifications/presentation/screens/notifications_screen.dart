import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/app_services.dart';
import '../../../../core/services/storage/user_prefs_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/budget_model.dart';
import '../../../../data/repositories/health_score_repository.dart';
import '../../../../features/goals/domain/entities/goal_entity.dart';

enum _AlertType { danger, warning, info, success }

class _Alert {
  const _Alert({
    required this.title,
    required this.body,
    required this.icon,
    required this.type,
  });
  final String title;
  final String body;
  final String icon;
  final _AlertType type;
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<_Alert> _alerts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        AppServices.instance.budgets.getCurrentPeriod().catchError((_) => <BudgetModel>[]),
        AppServices.instance.goals.getAll().catchError((_) => <GoalEntity>[]),
        AppServices.instance.healthScore.get().then<HealthScoreModel?>((v) => v).catchError((_) => null),
        UserPrefsStorage.getSalary(),
      ]);

      final budgets = results[0] as List<BudgetModel>;
      final goals = results[1] as List<GoalEntity>;
      final health = results[2] as HealthScoreModel?;
      final salary = results[3] as double;

      if (mounted) {
        setState(() => _alerts = _buildAlerts(budgets, goals, health, salary));
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not load insights. Check your connection.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<_Alert> _buildAlerts(
    List<BudgetModel> budgets,
    List<GoalEntity> goals,
    HealthScoreModel? health,
    double salary,
  ) {
    final alerts = <_Alert>[];
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final now = DateTime.now();

    // ── Budget alerts ──────────────────────────────────────────────────────────
    for (final b in budgets) {
      if (b.overBudget) {
        final over = b.spent - b.monthlyLimit;
        alerts.add(_Alert(
          title: '${b.categoryIcon} ${b.categoryName} over budget',
          body: 'You have spent ${currency.format(over)} more than your '
              '${currency.format(b.monthlyLimit)} limit this month.',
          icon: '🚨',
          type: _AlertType.danger,
        ));
      } else if (b.progressFraction >= 0.85) {
        alerts.add(_Alert(
          title: '${b.categoryIcon} ${b.categoryName} almost full',
          body: 'You have used ${(b.progressFraction * 100).toStringAsFixed(0)}% of your '
              '${currency.format(b.monthlyLimit)} budget. Only ${currency.format(b.remainingAmount)} left.',
          icon: '⚠️',
          type: _AlertType.warning,
        ));
      }
    }

    // ── Goal alerts ────────────────────────────────────────────────────────────
    for (final g in goals) {
      final daysLeft = g.deadline.difference(now).inDays;
      if (daysLeft <= 30 && daysLeft >= 0 && g.progressPercent < 100) {
        alerts.add(_Alert(
          title: '${g.name} deadline approaching',
          body: 'Only $daysLeft days until your "${g.name}" goal deadline. '
              'You are ${g.progressPercent.toStringAsFixed(0)}% of the way there.',
          icon: '🎯',
          type: daysLeft <= 7 ? _AlertType.danger : _AlertType.warning,
        ));
      } else if (g.progressPercent >= 100) {
        alerts.add(_Alert(
          title: '${g.name} goal reached!',
          body: 'Congratulations! You have fully funded your "${g.name}" goal. '
              'Consider starting a new goal.',
          icon: '🏆',
          type: _AlertType.success,
        ));
      } else if (g.recommendedMonthlyContribution > 0 && salary > 0) {
        final pct = (g.recommendedMonthlyContribution / salary * 100);
        if (pct > 30) {
          alerts.add(_Alert(
            title: 'Aggressive saving needed for ${g.name}',
            body: 'To meet your "${g.name}" goal you need to save '
                '${currency.format(g.recommendedMonthlyContribution)}/month '
                '(${pct.toStringAsFixed(0)}% of income). Consider extending the deadline.',
            icon: '📊',
            type: _AlertType.warning,
          ));
        }
      }
    }

    // ── Health score alerts ────────────────────────────────────────────────────
    if (health != null) {
      if (health.score < 40) {
        alerts.add(_Alert(
          title: 'Financial health needs attention',
          body: health.summary,
          icon: '❤️',
          type: _AlertType.danger,
        ));
      } else if (health.score >= 80) {
        alerts.add(_Alert(
          title: 'Excellent financial health!',
          body: health.summary,
          icon: '💪',
          type: _AlertType.success,
        ));
      }

      if (health.budgetScore == 0) {
        alerts.add(_Alert(
          title: 'No budgets set',
          body: 'Set monthly spending limits per category to stay on track and improve your health score.',
          icon: '📋',
          type: _AlertType.info,
        ));
      }
      if (health.goalScore <= 3) {
        alerts.add(_Alert(
          title: 'Start saving for a goal',
          body: 'Users with active goals save 40% more on average. Set your first goal in the Goals tab.',
          icon: '🚀',
          type: _AlertType.info,
        ));
      }
    }

    // ── Savings rate tip ──────────────────────────────────────────────────────
    if (salary > 0 && budgets.isNotEmpty) {
      final totalSpent = budgets.fold(0.0, (s, b) => s + b.spent);
      final savingsRate = (salary - totalSpent) / salary;
      if (savingsRate < 0.1 && savingsRate >= 0) {
        alerts.add(_Alert(
          title: 'Low savings rate this month',
          body: 'You are saving less than 10% of your income. '
              'Try reducing discretionary spending to hit the 20% target.',
          icon: '💡',
          type: _AlertType.warning,
        ));
      }
    }

    // ── No alerts fallback ────────────────────────────────────────────────────
    if (alerts.isEmpty) {
      alerts.add(const _Alert(
        title: 'All clear!',
        body: 'No alerts right now. Keep tracking your spending and you\'ll stay on top of your finances.',
        icon: '✅',
        type: _AlertType.success,
      ));
    }

    // Danger first, then warning, then info, then success
    alerts.sort((a, b) => a.type.index.compareTo(b.type.index));
    return alerts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights & Alerts'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _load,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _buildList(),
      ),
    );
  }

  Widget _buildError() => ListView(children: [
        const SizedBox(height: 100),
        const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textSecondary),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: ElevatedButton(onPressed: _load, child: const Text('Retry')),
        ),
      ]);

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _alerts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _AlertCard(alert: _alerts[i]),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});
  final _Alert alert;

  static const _colors = {
    _AlertType.danger: AppColors.danger,
    _AlertType.warning: AppColors.warning,
    _AlertType.info: AppColors.accent,
    _AlertType.success: AppColors.success,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[alert.type]!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(alert.icon, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alert.title,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: color)),
                  const SizedBox(height: 4),
                  Text(alert.body,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
