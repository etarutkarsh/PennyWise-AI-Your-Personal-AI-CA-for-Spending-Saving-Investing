import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/storage/user_prefs_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../widgets/summary_card.dart';
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

  @override
  void initState() {
    super.initState();
    _loadSalary();
  }

  Future<void> _loadSalary() async {
    final saved = await UserPrefsStorage.getSalary();
    if (mounted) {
      setState(() {
        _salary = saved;
        _loadedSalary = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    // Derive savings and investments from salary using 50-30-20 rule
    final savings = _salary * 0.12;
    final investments = _salary * 0.08;
    final remainingBudget = _salary - savings - investments - (_salary * 0.50);

    // Build summary with real salary
    final summary = DashboardSummary(
      salary: _salary,
      savings: savings,
      investments: investments,
      remainingBudget: remainingBudget,
      financialHealthScore: DashboardSummary.placeholder.financialHealthScore,
      dailyTip: DashboardSummary.placeholder.dailyTip,
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
        onRefresh: _loadSalary,
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
                        builder: (_) => SavingsDetailScreen(salary: _salary, savings: summary.savings),
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
                        builder: (_) => BudgetDetailScreen(remainingBudget: summary.remainingBudget),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            _FinancialHealthScoreCard(score: summary.financialHealthScore),
            const SizedBox(height: 20),
            _QuickActions(
              onAffordabilityTap: () => context.push('/affordability'),
              onGoalsTap: () => context.push('/goals'),
              onChatTap: () => context.push('/chat'),
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
  const _FinancialHealthScoreCard({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
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
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                  Text('$score', style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Financial Health Score', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text(
                    'Increase your emergency fund and SIP to boost this score.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onAffordabilityTap,
    required this.onGoalsTap,
    required this.onChatTap,
  });

  final VoidCallback onAffordabilityTap;
  final VoidCallback onGoalsTap;
  final VoidCallback onChatTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionChip(
            label: 'Can I afford this?',
            icon: Icons.calculate_outlined,
            onTap: onAffordabilityTap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionChip(label: 'Goals', icon: Icons.flag_outlined, onTap: onGoalsTap),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionChip(label: 'Ask AI', icon: Icons.chat_bubble_outline_rounded, onTap: onChatTap),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.label, required this.icon, required this.onTap});

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
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: 6),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
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
            const Icon(Icons.lightbulb_outline_rounded, color: AppColors.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(tip, style: const TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
