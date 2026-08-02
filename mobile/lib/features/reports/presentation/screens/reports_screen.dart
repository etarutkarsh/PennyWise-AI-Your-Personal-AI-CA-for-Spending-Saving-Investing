import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/app_services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/repositories/report_repository.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  MonthReport? _monthly;
  List<MonthReport> _trend = [];
  bool _loadingMonthly = true;
  bool _loadingTrend = true;
  String? _error;

  List<String> _insights = [];
  bool _insightsLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTrend();
    _loadMonthly();
  }

  Future<void> _loadTrend() async {
    try {
      final trend = await AppServices.instance.reports.getTrend();
      // trend is newest-first from backend; reverse to chronological for chart
      if (mounted) setState(() { _trend = trend.reversed.toList(); _loadingTrend = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingTrend = false);
    }
  }

  Future<void> _loadMonthly() async {
    setState(() { _loadingMonthly = true; _error = null; _insights = []; });
    try {
      final report = await AppServices.instance.reports.getMonthly(
        year: _selectedMonth.year,
        month: _selectedMonth.month,
      );
      if (mounted) {
        setState(() { _monthly = report; _loadingMonthly = false; });
        _loadInsights(report);
      }
    } catch (e) {
      if (mounted) setState(() { _error = friendlyError(e); _loadingMonthly = false; });
    }
  }

  Future<void> _loadInsights(MonthReport report) async {
    if (report.totalSpend == 0) return;
    setState(() => _insightsLoading = true);
    try {
      final catMap = {for (final c in report.byCategory) c.categoryName: c.amount};
      final ins = await AppServices.instance.ai.getSpendingInsights(
        totalDebit: report.totalSpend,
        totalCredit: report.totalIncome,
        salary: report.totalIncome,
        spendingByCategory: catMap,
      );
      if (mounted) setState(() => _insights = ins);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _insightsLoading = false);
    }
  }

  void _prevMonth() {
    setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1));
    _loadMonthly();
  }

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    if (next.isAfter(DateTime(now.year, now.month))) return;
    setState(() => _selectedMonth = next);
    _loadMonthly();
  }

  bool get _canGoNext {
    final now = DateTime.now();
    return _selectedMonth.isBefore(DateTime(now.year, now.month));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async { await Future.wait([_loadTrend(), _loadMonthly()]); },
          child: CustomScrollView(
            slivers: [
              // ── App bar ───────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Reports',
                              style: GoogleFonts.manrope(
                                fontSize: 26, fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary, letterSpacing: -0.5,
                              )),
                          Text('Your financial story',
                              style: GoogleFonts.dmSans(
                                  fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () async { await Future.wait([_loadTrend(), _loadMonthly()]); },
                        icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Month navigator ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        _NavBtn(icon: Icons.chevron_left_rounded, onTap: _prevMonth),
                        Expanded(
                          child: Center(
                            child: Text(
                              DateFormat('MMMM yyyy').format(_selectedMonth),
                              style: GoogleFonts.manrope(
                                fontSize: 15, fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        _NavBtn(
                          icon: Icons.chevron_right_rounded,
                          onTap: _canGoNext ? _nextMonth : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              if (_loadingMonthly)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(60),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
                )
              else if (_error != null)
                SliverToBoxAdapter(child: _ErrorState(error: _error!, onRetry: _loadMonthly))
              else if (_monthly != null) ...[
                // ── Hero summary card ───────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _HeroCard(report: _monthly!, currency: _currency),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // ── 6-month trend chart ─────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _TrendChart(trend: _trend, loading: _loadingTrend, currency: _currency),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // ── Spending vs income stat row ─────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _StatRow(report: _monthly!, currency: _currency),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // ── Category breakdown ──────────────────────────────────────
                if (_monthly!.byCategory.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _CategoryBreakdown(report: _monthly!, currency: _currency),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // ── AI Insights ─────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _InsightsSection(
                      insights: _insights,
                      loading: _insightsLoading,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 48)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hero Summary Card ─────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.report, required this.currency});
  final MonthReport report;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final saved = report.netSavings;
    final isPositive = saved >= 0;
    final rate = report.savingsRate;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [const Color(0xFF0F9D58), const Color(0xFF005C35)]
              : [const Color(0xFFC62828), const Color(0xFF7B0000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isPositive ? AppColors.primary : AppColors.danger)
                .withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isPositive ? '💚 Saved this month' : '⚠️ Overspent this month',
                style: GoogleFonts.dmSans(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.80),
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${rate.abs().toStringAsFixed(0)}% rate',
                  style: GoogleFonts.dmSans(
                    fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            currency.format(saved.abs()),
            style: GoogleFonts.manrope(
              fontSize: 34, fontWeight: FontWeight.w800,
              color: Colors.white, letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  label: 'Income',
                  value: currency.format(report.totalIncome),
                  icon: Icons.arrow_downward_rounded,
                  color: const Color(0xFF80CBC4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroStat(
                  label: 'Spent',
                  value: currency.format(report.totalSpend),
                  icon: Icons.arrow_upward_rounded,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value,
      required this.icon, required this.color});
  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.dmSans(
                        fontSize: 10, color: Colors.white.withValues(alpha: 0.65))),
                Text(value,
                    style: GoogleFonts.manrope(
                      fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 6-Month Trend Chart ───────────────────────────────────────────────────────

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.trend, required this.loading, required this.currency});
  final List<MonthReport> trend;
  final bool loading;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('6-Month Trend',
                  style: GoogleFonts.manrope(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  )),
              const Spacer(),
              const Row(
                children: [
                  _Legend(color: AppColors.primary, label: 'Spend'),
                  SizedBox(width: 12),
                  _Legend(color: AppColors.success, label: 'Income'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (loading || trend.isEmpty)
            const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2)),
            )
          else
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  maxY: _maxY,
                  minY: 0,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: AppColors.border.withValues(alpha: 0.6),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= trend.length) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(trend[i].monthLabel,
                                style: GoogleFonts.dmSans(
                                    fontSize: 9, color: AppColors.textMuted)),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: trend.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      groupVertically: false,
                      barRods: [
                        BarChartRodData(
                          toY: e.value.totalSpend,
                          color: AppColors.primary,
                          width: 10,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                        BarChartRodData(
                          toY: e.value.totalIncome,
                          color: AppColors.success.withValues(alpha: 0.7),
                          width: 10,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, _, rod, rodIdx) => BarTooltipItem(
                        '${rodIdx == 0 ? "Spend" : "Income"}\n${currency.format(rod.toY)}',
                        GoogleFonts.dmSans(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  double get _maxY {
    if (trend.isEmpty) return 1;
    final vals = trend.expand((r) => [r.totalSpend, r.totalIncome]);
    return (vals.reduce((a, b) => a > b ? a : b) * 1.25).clamp(1.0, double.infinity);
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ── Stat Row ──────────────────────────────────────────────────────────────────

class _StatRow extends StatelessWidget {
  const _StatRow({required this.report, required this.currency});
  final MonthReport report;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final rate = report.savingsRate;
    return Row(
      children: [
        Expanded(child: _StatTile(
          label: 'Transactions',
          value: '${report.byCategory.length} cats',
          icon: Icons.receipt_long_rounded,
          color: AppColors.accent,
        )),
        const SizedBox(width: 10),
        Expanded(child: _StatTile(
          label: 'Savings Rate',
          value: '${rate.toStringAsFixed(0)}%',
          icon: Icons.savings_rounded,
          color: rate >= 20 ? AppColors.success : rate >= 0 ? AppColors.warning : AppColors.danger,
        )),
        const SizedBox(width: 10),
        Expanded(child: _StatTile(
          label: 'Net Flow',
          value: currency.format(report.netSavings),
          icon: report.netSavings >= 0
              ? Icons.trending_up_rounded
              : Icons.trending_down_rounded,
          color: report.netSavings >= 0 ? AppColors.success : AppColors.danger,
        )),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value,
      required this.icon, required this.color});
  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.manrope(
                fontSize: 13, fontWeight: FontWeight.w800, color: color,
              ),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

// ── Category Breakdown ────────────────────────────────────────────────────────

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.report, required this.currency});
  final MonthReport report;
  final NumberFormat currency;

  static const _barColors = [
    AppColors.primary, AppColors.accent, Color(0xFF6A1B9A),
    Color(0xFF00796B), Color(0xFFE65100),
  ];

  @override
  Widget build(BuildContext context) {
    final cats = report.byCategory.take(6).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Where it went',
              style: GoogleFonts.manrope(
                fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
              )),
          const SizedBox(height: 16),
          ...cats.asMap().entries.map((e) {
            final cat = e.value;
            final color = _barColors[e.key % _barColors.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(cat.categoryIcon, style: const TextStyle(fontSize: 15)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(cat.categoryName,
                            style: GoogleFonts.dmSans(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            )),
                      ),
                      Text(
                        '${currency.format(cat.amount)}  ·  ${cat.percentage.toStringAsFixed(0)}%',
                        style: GoogleFonts.dmSans(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (cat.percentage / 100).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceElevated,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── AI Insights ───────────────────────────────────────────────────────────────

class _InsightsSection extends StatelessWidget {
  const _InsightsSection({required this.insights, required this.loading});
  final List<String> insights;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text('AI Insights',
                  style: GoogleFonts.manrope(
                    fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary,
                  )),
              const Spacer(),
              if (loading)
                const SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (insights.isEmpty && !loading)
            Text(
              'Add transactions this month to get personalised AI insights.',
              style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary),
            )
          else
            ...insights.map((insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          width: 5, height: 5,
                          decoration: const BoxDecoration(
                              color: AppColors.primary, shape: BoxShape.circle),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(insight,
                            style: GoogleFonts.dmSans(
                              fontSize: 13, color: AppColors.textSecondary, height: 1.45,
                            )),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _NavBtn extends StatelessWidget {
  const _NavBtn({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(icon,
            color: onTap != null ? AppColors.textPrimary : AppColors.textMuted,
            size: 22),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(error, textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text('Retry', style: GoogleFonts.dmSans(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
