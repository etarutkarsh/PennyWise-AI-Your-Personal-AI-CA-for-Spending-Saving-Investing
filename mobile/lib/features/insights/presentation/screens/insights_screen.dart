import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/app_services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/storage/user_prefs_storage.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  bool _isLoading = true;
  String? _error;
  List<String> _insights = [];
  List<String> _recommendations = [];
  List<String> _predictions = [];
  double _totalDebit = 0;
  double _totalCredit = 0;
  double _salary = 0;
  Map<String, double> _spendingByCategory = {};
  bool _hasAiKey = false;

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
      _salary = await UserPrefsStorage.getSalary();
      _hasAiKey = await AppServices.instance.ai.hasKey();

      final txs = await AppServices.instance.transactions.getAll();
      _computeStats(txs);

      final topCat = _spendingByCategory.isEmpty
          ? 'General'
          : _spendingByCategory.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;

      final results = await Future.wait([
        AppServices.instance.ai.getSpendingInsights(
          totalDebit: _totalDebit,
          totalCredit: _totalCredit,
          salary: _salary,
          spendingByCategory: _spendingByCategory,
        ),
        AppServices.instance.ai.getSavingsRecommendations(
          salary: _salary,
          totalSpent: _totalDebit,
          topCategory: topCat,
        ),
        AppServices.instance.ai.getSpendingPredictions(
          avgSpendingByCategory: _spendingByCategory,
          avgMonthlyTotal: _totalDebit,
        ),
      ]);

      if (mounted) {
        setState(() {
          _insights = results[0];
          _recommendations = results[1];
          _predictions = results[2];
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _computeStats(List<TransactionEntity> txs) {
    _totalDebit = 0;
    _totalCredit = 0;
    _spendingByCategory = {};

    for (final tx in txs) {
      if (tx.direction == 'DEBIT') {
        _totalDebit += tx.amount;
        final cat = tx.categoryName.isEmpty ? 'Uncategorized' : tx.categoryName;
        _spendingByCategory[cat] = (_spendingByCategory[cat] ?? 0) + tx.amount;
      } else {
        _totalCredit += tx.amount;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Insights'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _load,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      if (!_hasAiKey) _AiKeyBanner(),
                      _SpendingSummaryCard(
                        totalDebit: _totalDebit,
                        totalCredit: _totalCredit,
                        salary: _salary,
                        currency: currency,
                      ),
                      const SizedBox(height: 16),
                      _InsightsSection(insights: _insights),
                      const SizedBox(height: 16),
                      _RecommendationsSection(
                          recommendations: _recommendations),
                      if (_predictions.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _PredictionsSection(predictions: _predictions),
                      ],
                      if (_spendingByCategory.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _CategoryBreakdown(
                          spendingByCategory: _spendingByCategory,
                          currency: currency,
                          totalDebit: _totalDebit,
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _AiKeyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.key_rounded, color: AppColors.accent),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Add your OpenAI key in Settings to get personalised AI insights.',
              style: TextStyle(fontSize: 13, color: AppColors.accent),
            ),
          ),
          TextButton(
            onPressed: () => context.push('/settings'),
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }
}

class _SpendingSummaryCard extends StatelessWidget {
  const _SpendingSummaryCard({
    required this.totalDebit,
    required this.totalCredit,
    required this.salary,
    required this.currency,
  });

  final double totalDebit;
  final double totalCredit;
  final double salary;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final savingsRate =
        salary > 0 ? ((salary - totalDebit) / salary * 100).clamp(0, 100) : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This Month',
                style:
                    TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'Total Spent',
                    value: currency.format(totalDebit),
                    color: AppColors.danger,
                    icon: Icons.arrow_upward_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    label: 'Income Received',
                    value: currency.format(totalCredit),
                    color: AppColors.success,
                    icon: Icons.arrow_downward_rounded,
                  ),
                ),
              ],
            ),
            if (salary > 0) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Savings rate',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                  Text('${savingsRate.toStringAsFixed(0)}%',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: savingsRate >= 20
                              ? AppColors.success
                              : AppColors.warning)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: savingsRate / 100,
                  minHeight: 6,
                  backgroundColor: AppColors.background,
                  valueColor: AlwaysStoppedAnimation(
                    savingsRate >= 20
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontSize: 16)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _InsightsSection extends StatelessWidget {
  const _InsightsSection({required this.insights});
  final List<String> insights;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.psychology_outlined, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text('Spending Insights',
                style:
                    TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ],
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: insights
                  .map((insight) => _InsightTile(text: insight))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 6, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _RecommendationsSection extends StatelessWidget {
  const _RecommendationsSection({required this.recommendations});
  final List<String> recommendations;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.lightbulb_outline_rounded,
                color: AppColors.accent, size: 20),
            SizedBox(width: 8),
            Text('Savings Tips',
                style:
                    TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ],
        ),
        const SizedBox(height: 10),
        ...recommendations.asMap().entries.map(
              (e) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor:
                        AppColors.accent.withValues(alpha: 0.12),
                    child: Text('${e.key + 1}',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent)),
                  ),
                  title: Text(e.value,
                      style: const TextStyle(fontSize: 13, height: 1.4)),
                ),
              ),
            ),
      ],
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({
    required this.spendingByCategory,
    required this.currency,
    required this.totalDebit,
  });

  final Map<String, double> spendingByCategory;
  final NumberFormat currency;
  final double totalDebit;

  @override
  Widget build(BuildContext context) {
    final sorted = spendingByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Spending by Category',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: sorted.map((e) {
                final fraction =
                    totalDebit > 0 ? e.value / totalDebit : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.key,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                          Text(
                            '${currency.format(e.value)} (${(fraction * 100).toStringAsFixed(0)}%)',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: fraction.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: AppColors.background,
                          valueColor: const AlwaysStoppedAnimation(
                              AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _PredictionsSection extends StatelessWidget {
  const _PredictionsSection({required this.predictions});
  final List<String> predictions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.schedule_outlined, color: AppColors.secondary, size: 20),
            SizedBox(width: 8),
            Text('Next Month Predictions',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ],
        ),
        const SizedBox(height: 10),
        Card(
          color: AppColors.secondary.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: predictions
                  .map((p) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.arrow_forward_ios_rounded,
                                size: 12, color: AppColors.secondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(p,
                                  style: const TextStyle(fontSize: 13, height: 1.4)),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(error,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
