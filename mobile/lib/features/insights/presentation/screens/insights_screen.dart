import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/app_services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/storage/user_prefs_storage.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key, this.salary = 0.0});
  final double salary;

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
    // Use navigated salary immediately; fall back to local storage in _load.
    if (widget.salary > 0) _salary = widget.salary;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      if (_salary <= 0) _salary = await UserPrefsStorage.getSalary();
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Custom header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textPrimary, size: 16),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Insights',
                        style: GoogleFonts.dmSans(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Powered by your spending data',
                        style: GoogleFonts.dmSans(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (!_isLoading)
                    GestureDetector(
                      onTap: _load,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.refresh_rounded,
                            color: AppColors.textSecondary, size: 18),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.orange))
                  : _error != null
                      ? _ErrorView(error: _error!, onRetry: _load)
                      : RefreshIndicator(
                          color: AppColors.orange,
                          backgroundColor: AppColors.surface,
                          onRefresh: _load,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                            children: [
                              if (!_hasAiKey) _AiKeyBanner(onReload: _load),
                              _SpendingSummaryCard(
                                totalDebit: _totalDebit,
                                totalCredit: _totalCredit,
                                salary: _salary,
                                currency: currency,
                              ),
                              const SizedBox(height: 20),
                              _InsightsSection(insights: _insights),
                              const SizedBox(height: 20),
                              _RecommendationsSection(
                                  recommendations: _recommendations),
                              if (_predictions.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                _PredictionsSection(predictions: _predictions),
                              ],
                              if (_spendingByCategory.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                _CategoryBreakdown(
                                  spendingByCategory: _spendingByCategory,
                                  currency: currency,
                                  totalDebit: _totalDebit,
                                ),
                              ],
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(
      {required this.title, required this.icon, required this.color});
  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.dmSans(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

Widget _darkCard({required Widget child, EdgeInsets? padding}) {
  return Container(
    width: double.infinity,
    padding: padding ?? const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
    ),
    child: child,
  );
}

// ─── AI Key Banner ────────────────────────────────────────────────────────────

class _AiKeyBanner extends StatelessWidget {
  const _AiKeyBanner({required this.onReload});
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.key_rounded, color: AppColors.amber, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Add your OpenAI key in Settings to unlock personalised AI insights.',
              style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppColors.amber,
                  height: 1.4),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              await context.push('/settings');
              onReload();
            },
            child: Text(
              'Settings →',
              style: GoogleFonts.dmSans(
                color: AppColors.amber,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Spending Summary ─────────────────────────────────────────────────────────

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
        salary > 0 ? ((salary - totalDebit) / salary * 100).clamp(0.0, 100.0) : 0.0;
    final rateColor = savingsRate >= 20 ? AppColors.success : AppColors.warning;

    return _darkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Month',
            style: GoogleFonts.dmSans(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
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
                  label: 'Income In',
                  value: currency.format(totalCredit),
                  color: AppColors.success,
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
            ],
          ),
          if (salary > 0) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Savings rate',
                  style: GoogleFonts.dmSans(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: rateColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${savingsRate.toStringAsFixed(0)}%',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w700,
                      color: rateColor,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: savingsRate / 100,
                minHeight: 7,
                backgroundColor: AppColors.surfaceElevated,
                valueColor: AlwaysStoppedAnimation(rateColor),
              ),
            ),
          ],
        ],
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  color: color.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w800,
              color: color,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Insights Section ─────────────────────────────────────────────────────────

class _InsightsSection extends StatelessWidget {
  const _InsightsSection({required this.insights});
  final List<String> insights;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Spending Insights',
          icon: Icons.psychology_outlined,
          color: AppColors.success,
        ),
        const SizedBox(height: 12),
        _darkCard(
          padding: const EdgeInsets.all(6),
          child: Column(
            children: insights.asMap().entries.map((e) {
              return _InsightTile(text: e.value, index: e.key);
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({required this.text, required this.index});
  final String text;
  final int index;

  static const _dotColors = [
    AppColors.success,
    AppColors.orange,
    AppColors.amber,
    AppColors.primary,
    AppColors.danger,
  ];

  @override
  Widget build(BuildContext context) {
    final color = _dotColors[index % _dotColors.length];
    return Container(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.dmSans(
                color: AppColors.textPrimary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Recommendations ─────────────────────────────────────────────────────────

class _RecommendationsSection extends StatelessWidget {
  const _RecommendationsSection({required this.recommendations});
  final List<String> recommendations;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Savings Tips',
          icon: Icons.lightbulb_outline_rounded,
          color: AppColors.amber,
        ),
        const SizedBox(height: 12),
        ...recommendations.asMap().entries.map(
          (e) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${e.key + 1}',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.amber,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    e.value,
                    style: GoogleFonts.dmSans(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Predictions ─────────────────────────────────────────────────────────────

class _PredictionsSection extends StatelessWidget {
  const _PredictionsSection({required this.predictions});
  final List<String> predictions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Next Month Forecast',
          icon: Icons.schedule_outlined,
          color: AppColors.questBlue,
        ),
        const SizedBox(height: 12),
        _darkCard(
          child: Column(
            children: predictions.asMap().entries.map(
              (e) => Padding(
                padding: EdgeInsets.only(bottom: e.key < predictions.length - 1 ? 14 : 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.arrow_forward_rounded,
                        size: 14, color: AppColors.questBlue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        e.value,
                        style: GoogleFonts.dmSans(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).toList(),
          ),
        ),
      ],
    );
  }
}

// ─── Category Breakdown ───────────────────────────────────────────────────────

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({
    required this.spendingByCategory,
    required this.currency,
    required this.totalDebit,
  });

  final Map<String, double> spendingByCategory;
  final NumberFormat currency;
  final double totalDebit;

  static const _barColors = [
    AppColors.orange,
    AppColors.success,
    AppColors.amber,
    AppColors.danger,
    AppColors.questBlue,
    Color(0xFF6A1B9A),
  ];

  @override
  Widget build(BuildContext context) {
    final sorted = spendingByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Spending by Category',
          icon: Icons.pie_chart_outline_rounded,
          color: AppColors.orange,
        ),
        const SizedBox(height: 12),
        _darkCard(
          child: Column(
            children: sorted.asMap().entries.map((entry) {
              final i = entry.key;
              final e = entry.value;
              final fraction = totalDebit > 0 ? e.value / totalDebit : 0.0;
              final color = _barColors[i % _barColors.length];
              return Padding(
                padding: EdgeInsets.only(bottom: i < sorted.length - 1 ? 16 : 0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                  color: color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              e.key,
                              style: GoogleFonts.dmSans(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${currency.format(e.value)}  ·  ${(fraction * 100).toStringAsFixed(0)}%',
                          style: GoogleFonts.dmSans(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fraction.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: AppColors.surfaceElevated,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  size: 28, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onRetry,
              child: Text('Retry', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
