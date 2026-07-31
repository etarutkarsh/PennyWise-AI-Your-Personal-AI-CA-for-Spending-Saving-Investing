import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/app_services.dart';
import '../../../../core/services/storage/user_prefs_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/budget_model.dart';
import '../../../../data/repositories/health_score_repository.dart';
import '../../../../data/repositories/notifications_repository.dart';
import '../../../../features/goals/domain/entities/goal_entity.dart';

enum _AlertType { danger, warning, info, success }

class _Alert {
  const _Alert({
    required this.id,
    required this.title,
    required this.body,
    required this.icon,
    required this.type,
    this.read = false,
  });
  final String? id;
  final String title;
  final String body;
  final String icon;
  final _AlertType type;
  final bool read;

  _Alert copyWith({bool? read}) => _Alert(
        id: id,
        title: title,
        body: body,
        icon: icon,
        type: type,
        read: read ?? this.read,
      );
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
  bool _fromBackend = false;

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
      // Try backend first — it generates smart notifications from
      // actual budget/goal state server-side.
      final items = await AppServices.instance.notifications.getAll();
      if (mounted) {
        setState(() {
          _fromBackend = true;
          _alerts = _mapBackendItems(items);
          _isLoading = false;
        });
      }
    } catch (_) {
      // Fall back to client-side alert generation.
      await _loadClientSide();
    }
  }

  Future<void> _loadClientSide() async {
    try {
      final results = await Future.wait([
        AppServices.instance.budgets.getCurrentPeriod().catchError((_) => <BudgetModel>[]),
        AppServices.instance.goals.getAll().catchError((_) => <GoalEntity>[]),
        AppServices.instance.healthScore.get().then<HealthScoreModel?>((v) => v).catchError((_) => null),
        UserPrefsStorage.getSalary(),
      ]);

      final budgets = results[0] as List<BudgetModel>;
      final goals   = results[1] as List<GoalEntity>;
      final health  = results[2] as HealthScoreModel?;
      final salary  = results[3] as double;

      if (mounted) {
        setState(() {
          _fromBackend = false;
          _alerts = _buildLocalAlerts(budgets, goals, health, salary);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load insights. Check your connection.';
          _isLoading = false;
        });
      }
    }
  }

  List<_Alert> _mapBackendItems(List<NotificationItem> items) {
    final mapped = items.map((n) {
      final (icon, type) = switch (n.type) {
        'budget_exceeded' => ('🚨', _AlertType.danger),
        'overspend'       => ('⚠️', _AlertType.warning),
        'goal_behind'     => ('🎯', _AlertType.warning),
        'sip_suggestion'  => ('📈', _AlertType.info),
        'savings_tip'     => ('💡', _AlertType.info),
        _                 => ('🔔', _AlertType.info),
      };
      return _Alert(
        id: n.id,
        title: n.title,
        body: n.body,
        icon: icon,
        type: type,
        read: n.read,
      );
    }).toList();

    if (mapped.isEmpty) {
      return const [
        _Alert(
          id: null,
          title: 'All clear!',
          body: 'No alerts right now. Keep tracking your spending and you\'ll stay on top of your finances.',
          icon: '✅',
          type: _AlertType.success,
        ),
      ];
    }

    mapped.sort((a, b) => a.type.index.compareTo(b.type.index));
    return mapped;
  }

  Future<void> _markRead(String id, int index) async {
    if (_alerts[index].read) return;
    setState(() {
      _alerts = [..._alerts]..[index] = _alerts[index].copyWith(read: true);
    });
    AppServices.instance.notifications.markRead(id).catchError((_) {});
  }

  Future<void> _markAllRead() async {
    setState(() {
      _alerts = _alerts.map((a) => a.copyWith(read: true)).toList();
    });
    AppServices.instance.notifications.markAllRead().catchError((_) {});
  }

  // ── Fallback client-side alert generation ──────────────────────────────────

  List<_Alert> _buildLocalAlerts(
    List<BudgetModel> budgets,
    List<GoalEntity> goals,
    HealthScoreModel? health,
    double salary,
  ) {
    final alerts = <_Alert>[];
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final now = DateTime.now();

    for (final b in budgets) {
      if (b.overBudget) {
        final over = b.spent - b.monthlyLimit;
        alerts.add(_Alert(
          id: null,
          title: '${b.categoryIcon} ${b.categoryName} over budget',
          body: 'You have spent ${currency.format(over)} more than your '
              '${currency.format(b.monthlyLimit)} limit this month.',
          icon: '🚨',
          type: _AlertType.danger,
        ));
      } else if (b.progressFraction >= 0.85) {
        alerts.add(_Alert(
          id: null,
          title: '${b.categoryIcon} ${b.categoryName} almost full',
          body: 'You have used ${(b.progressFraction * 100).toStringAsFixed(0)}% of your '
              '${currency.format(b.monthlyLimit)} budget. Only ${currency.format(b.remainingAmount)} left.',
          icon: '⚠️',
          type: _AlertType.warning,
        ));
      }
    }

    for (final g in goals) {
      final daysLeft = g.deadline.difference(now).inDays;
      if (daysLeft <= 30 && daysLeft >= 0 && g.progressPercent < 100) {
        alerts.add(_Alert(
          id: null,
          title: '${g.name} deadline approaching',
          body: 'Only $daysLeft days until your "${g.name}" goal deadline. '
              'You are ${g.progressPercent.toStringAsFixed(0)}% of the way there.',
          icon: '🎯',
          type: daysLeft <= 7 ? _AlertType.danger : _AlertType.warning,
        ));
      } else if (g.progressPercent >= 100) {
        alerts.add(_Alert(
          id: null,
          title: '${g.name} goal reached!',
          body: 'Congratulations! You have fully funded your "${g.name}" goal.',
          icon: '🏆',
          type: _AlertType.success,
        ));
      } else if (g.recommendedMonthlyContribution > 0 && salary > 0) {
        final pct = (g.recommendedMonthlyContribution / salary * 100);
        if (pct > 30) {
          alerts.add(_Alert(
            id: null,
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

    if (health != null) {
      if (health.score < 40) {
        alerts.add(_Alert(id: null, title: 'Financial health needs attention', body: health.summary, icon: '❤️', type: _AlertType.danger));
      } else if (health.score >= 80) {
        alerts.add(_Alert(id: null, title: 'Excellent financial health!', body: health.summary, icon: '💪', type: _AlertType.success));
      }
      if (health.budgetScore == 0) {
        alerts.add(const _Alert(id: null, title: 'No budgets set', body: 'Set monthly spending limits per category to stay on track.', icon: '📋', type: _AlertType.info));
      }
      if (health.goalScore <= 3) {
        alerts.add(const _Alert(id: null, title: 'Start saving for a goal', body: 'Users with active goals save 40% more on average.', icon: '🚀', type: _AlertType.info));
      }
    }

    if (salary > 0 && budgets.isNotEmpty) {
      final totalSpent = budgets.fold(0.0, (s, b) => s + b.spent);
      final savingsRate = (salary - totalSpent) / salary;
      if (savingsRate < 0.1 && savingsRate >= 0) {
        alerts.add(const _Alert(id: null, title: 'Low savings rate this month', body: 'You are saving less than 10% of your income. Try reducing discretionary spending.', icon: '💡', type: _AlertType.warning));
      }
    }

    if (alerts.isEmpty) {
      alerts.add(const _Alert(id: null, title: 'All clear!', body: 'No alerts right now. Keep tracking your spending!', icon: '✅', type: _AlertType.success));
    }

    alerts.sort((a, b) => a.type.index.compareTo(b.type.index));
    return alerts;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  bool get _hasUnread => _alerts.any((a) => !a.read && a.id != null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights & Alerts'),
        actions: [
          if (_fromBackend && _hasUnread)
            TextButton(
              onPressed: _markAllRead,
              child: Text('Mark all read',
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: AppColors.primary)),
            ),
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
      itemBuilder: (_, i) => _AlertCard(
        alert: _alerts[i],
        onTap: _alerts[i].id != null && !_alerts[i].read
            ? () => _markRead(_alerts[i].id!, i)
            : null,
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert, this.onTap});
  final _Alert alert;
  final VoidCallback? onTap;

  static const _colors = {
    _AlertType.danger:  AppColors.danger,
    _AlertType.warning: AppColors.warning,
    _AlertType.info:    AppColors.accent,
    _AlertType.success: AppColors.success,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[alert.type]!;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: alert.read ? 0.55 : 1.0,
        child: Card(
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(alert.title,
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: color)),
                          ),
                          if (!alert.read && alert.id != null)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
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
        ),
      ),
    );
  }
}
