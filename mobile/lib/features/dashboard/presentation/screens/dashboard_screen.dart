import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/app_services.dart';
import '../../../../core/services/storage/user_prefs_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/repositories/health_score_repository.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../widgets/summary_card.dart';
import '../../../insights/presentation/screens/insights_screen.dart';
import 'budget_detail_screen.dart';
import 'investment_detail_screen.dart';
import 'salary_detail_screen.dart';
import 'savings_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double _salary = 50000;
  bool _loadedSalary = false;
  HealthScoreModel? _healthScore;
  String _dailyTip = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final salary = await UserPrefsStorage.getSalary();
    if (mounted) setState(() => _salary = salary);

    // Load health score and daily tip in parallel
    final results = await Future.wait([
      AppServices.instance.healthScore
          .get()
          .then<HealthScoreModel?>((v) => v)
          .catchError((_) => null),
      AppServices.instance.ai.getDailyTip(),
    ]);

    if (mounted) {
      setState(() {
        _healthScore = results[0] as HealthScoreModel?;
        _dailyTip = results[1] as String;
        _loadedSalary = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final savings = _salary * 0.12;
    final investments = _salary * 0.08;
    final remainingBudget = _salary - savings - investments - (_salary * 0.50);

    final summary = DashboardSummary(
      salary: _salary,
      savings: savings,
      investments: investments,
      remainingBudget: remainingBudget,
      financialHealthScore: _healthScore?.score ??
          DashboardSummary.placeholder.financialHealthScore,
      dailyTip: _dailyTip.isNotEmpty
          ? _dailyTip
          : DashboardSummary.placeholder.dailyTip,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Good morning'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!_loadedSalary)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  SummaryCard(
                    label: 'Salary',
                    amount: currency.format(summary.salary),
                    icon: Icons.account_balance_wallet_outlined,
                    description: 'Your monthly take-home pay',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SalaryDetailScreen(salary: _salary),
                      ),
                    ),
                  ),
                  SummaryCard(
                    label: 'Savings',
                    amount: currency.format(summary.savings),
                    icon: Icons.savings_outlined,
                    description: 'Your safety net & future fund',
                    color: AppColors.success,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SavingsDetailScreen(
                            salary: _salary, savings: summary.savings),
                      ),
                    ),
                  ),
                  SummaryCard(
                    label: 'Investments',
                    amount: currency.format(summary.investments),
                    icon: Icons.trending_up_rounded,
                    description: 'Your wealth-building engine',
                    color: AppColors.secondary,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => InvestmentDetailScreen(
                          salary: _salary,
                          investments: summary.investments,
                        ),
                      ),
                    ),
                  ),
                  SummaryCard(
                    label: 'Remaining Budget',
                    amount: currency.format(summary.remainingBudget),
                    icon: Icons.pie_chart_outline_rounded,
                    description: 'What\'s yours to spend freely',
                    color: AppColors.accent,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BudgetDetailScreen(
                            remainingBudget: summary.remainingBudget),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            _FinancialHealthScoreCard(
              score: summary.financialHealthScore,
              healthScore: _healthScore,
            ),
            const SizedBox(height: 20),
            _QuickActions(
              onAffordabilityTap: () => context.push('/affordability'),
              onGoalsTap: () => context.push('/goals'),
              onInsightsTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const InsightsScreen()),
              ),
              onChatTap: () => context.push('/chat'),
              onNetWorthTap: () => context.push('/net-worth'),
            ),
            const SizedBox(height: 20),
            _AiTipCard(tip: summary.dailyTip),
          ],
        ),
      ),
    );
  }
}

class _FinancialHealthScoreCard extends StatelessWidget {
  const _FinancialHealthScoreCard({
    required this.score,
    required this.healthScore,
  });

  final int score;
  final HealthScoreModel? healthScore;

  Color get _scoreColor {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.primary;
    if (score >= 40) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  height: 56,
                  width: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: score / 100,
                        strokeWidth: 6,
                        backgroundColor: AppColors.background,
                        valueColor: AlwaysStoppedAnimation(_scoreColor),
                      ),
                      Text('$score',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Financial Health',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(width: 8),
                          if (healthScore != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: _scoreColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                healthScore!.grade,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: _scoreColor),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        healthScore?.summary ??
                            'Increase your emergency fund and SIP to boost this score.',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (healthScore != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  _PillarChip(
                      label: 'Savings',
                      score: healthScore!.savingsScore,
                      max: 25),
                  _PillarChip(
                      label: 'Budget',
                      score: healthScore!.budgetScore,
                      max: 25),
                  _PillarChip(
                      label: 'Goals',
                      score: healthScore!.goalScore,
                      max: 25),
                  _PillarChip(
                      label: 'Activity',
                      score: healthScore!.activityScore,
                      max: 15),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PillarChip extends StatelessWidget {
  const _PillarChip(
      {required this.label, required this.score, required this.max});

  final String label;
  final int score;
  final int max;

  @override
  Widget build(BuildContext context) {
    final fraction = max > 0 ? score / max : 0.0;
    final color = fraction >= 0.8
        ? AppColors.success
        : fraction >= 0.5
            ? AppColors.warning
            : AppColors.danger;

    return Expanded(
      child: Column(
        children: [
          Text('$score/$max',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 3),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onAffordabilityTap,
    required this.onGoalsTap,
    required this.onInsightsTap,
    required this.onChatTap,
    required this.onNetWorthTap,
  });

  final VoidCallback onAffordabilityTap;
  final VoidCallback onGoalsTap;
  final VoidCallback onInsightsTap;
  final VoidCallback onChatTap;
  final VoidCallback onNetWorthTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        SizedBox(
          width: (MediaQuery.of(context).size.width - 56) / 2,
          child: _ActionChip(
            label: 'Can I afford?',
            icon: Icons.calculate_outlined,
            onTap: onAffordabilityTap,
          ),
        ),
        SizedBox(
          width: (MediaQuery.of(context).size.width - 56) / 2,
          child: _ActionChip(
            label: 'Goals',
            icon: Icons.flag_outlined,
            onTap: onGoalsTap,
          ),
        ),
        SizedBox(
          width: (MediaQuery.of(context).size.width - 56) / 2,
          child: _ActionChip(
            label: 'AI Insights',
            icon: Icons.psychology_outlined,
            onTap: onInsightsTap,
          ),
        ),
        SizedBox(
          width: (MediaQuery.of(context).size.width - 56) / 2,
          child: _ActionChip(
            label: 'Ask AI',
            icon: Icons.chat_bubble_outline_rounded,
            onTap: onChatTap,
          ),
        ),
        SizedBox(
          width: (MediaQuery.of(context).size.width - 56) / 2,
          child: _ActionChip(
            label: 'Net Worth',
            icon: Icons.account_balance_wallet_rounded,
            onTap: onNetWorthTap,
          ),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip(
      {required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(height: 5),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiTipCard extends StatelessWidget {
  const _AiTipCard({required this.tip});

  final String tip;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.secondary,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.lightbulb_outline_rounded,
                color: AppColors.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(tip,
                  style:
                      const TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
