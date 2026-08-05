import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/services/app_services.dart';
import '../../../../core/services/commitment_intelligence/commitment_engine.dart';
import '../../../../core/services/storage/user_prefs_storage.dart';
import '../../../../domain/commitments/cash_flow_waterfall.dart';
import '../../../../domain/commitments/duplicate_analysis.dart';
import '../../../../domain/commitments/financial_calendar.dart';
import '../../../../domain/commitments/forecast_result.dart';
import '../../../../domain/commitments/goal_impact_result.dart';
import '../../../../domain/commitments/goal_snapshot.dart';
import '../../../../domain/commitments/income_stress_analysis.dart';
import '../../../../domain/commitments/monthly_financial_review.dart';
import '../../../../domain/commitments/recurring_commitments_intelligence.dart';
import '../../../../features/goals/domain/entities/goal_entity.dart';
import '../../../../infrastructure/engines/commitments/recurring_commitments_intelligence_engine.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────

const _bg = Color(0xFF09090B);
const _surface = Color(0xFF18181B);
const _border = Color(0xFF27272A);
const _textPrimary = Colors.white;
const _textSecondary = Color(0xFF9CA3AF);
const _textMuted = Color(0xFF52525B);

const _green = Color(0xFF22C55E);
const _amber = Color(0xFFF59E0B);
const _orange = Color(0xFFF97316);
const _red = Color(0xFFEF4444);
const _indigo = Color(0xFF6366F1);
const _pink = Color(0xFFEC4899);
const _cyan = Color(0xFF06B6D4);

// ─── Type mappings ────────────────────────────────────────────────────────────

const _typeIcons = {
  CommitmentType.emi:          '🏦',
  CommitmentType.subscription: '📺',
  CommitmentType.investment:   '📈',
  CommitmentType.insurance:    '🛡️',
  CommitmentType.utility:      '⚡',
  CommitmentType.rent:         '🏠',
  CommitmentType.education:    '🎓',
  CommitmentType.tax:          '🏛️',
  CommitmentType.savings:      '🪙',
  CommitmentType.membership:   '💪',
  CommitmentType.other:        '📦',
};

const _typeColors = {
  CommitmentType.emi:          Color(0xFFF97316),
  CommitmentType.subscription: Color(0xFFEC4899),
  CommitmentType.investment:   Color(0xFF22C55E),
  CommitmentType.insurance:    Color(0xFFEF4444),
  CommitmentType.utility:      Color(0xFF06B6D4),
  CommitmentType.rent:         Color(0xFFF59E0B),
  CommitmentType.education:    Color(0xFF8B5CF6),
  CommitmentType.tax:          Color(0xFF64748B),
  CommitmentType.savings:      Color(0xFF10B981),
  CommitmentType.membership:   Color(0xFF7C3AED),
  CommitmentType.other:        Color(0xFF6B7280),
};

const _calendarTypeIcons = {
  FinancialCalendarEventType.subscription:        '📺',
  FinancialCalendarEventType.emi:                 '🏦',
  FinancialCalendarEventType.sip:                 '📈',
  FinancialCalendarEventType.insurance:           '🛡️',
  FinancialCalendarEventType.utilityBill:         '⚡',
  FinancialCalendarEventType.tax:                 '🏛️',
  FinancialCalendarEventType.creditCardDue:       '💳',
  FinancialCalendarEventType.investmentMaturity:  '💰',
  FinancialCalendarEventType.salary:              '💵',
  FinancialCalendarEventType.goalMilestone:       '🎯',
  FinancialCalendarEventType.reminder:            '🔔',
};

const _calendarTypeColors = {
  FinancialCalendarEventType.subscription:        Color(0xFFEC4899),
  FinancialCalendarEventType.emi:                 Color(0xFFF97316),
  FinancialCalendarEventType.sip:                 Color(0xFF22C55E),
  FinancialCalendarEventType.insurance:           Color(0xFFEF4444),
  FinancialCalendarEventType.utilityBill:         Color(0xFF06B6D4),
  FinancialCalendarEventType.tax:                 Color(0xFF64748B),
  FinancialCalendarEventType.creditCardDue:       Color(0xFF8B5CF6),
  FinancialCalendarEventType.investmentMaturity:  Color(0xFF22C55E),
  FinancialCalendarEventType.salary:              Color(0xFF10B981),
  FinancialCalendarEventType.goalMilestone:       Color(0xFF7C3AED),
  FinancialCalendarEventType.reminder:            Color(0xFF9CA3AF),
};

const _periodLabels = {
  RecurrencePeriod.weekly:     'Weekly',
  RecurrencePeriod.biweekly:   'Every 2 weeks',
  RecurrencePeriod.monthly:    'Monthly',
  RecurrencePeriod.quarterly:  'Quarterly',
  RecurrencePeriod.semiannual: 'Every 6 months',
  RecurrencePeriod.annual:     'Annual',
  RecurrencePeriod.irregular:  'Irregular',
};

const _mechanismLabels = {
  PaymentMechanism.nach:                'NACH',
  PaymentMechanism.ecs:                 'ECS',
  PaymentMechanism.upiAutopay:          'UPI AutoPay',
  PaymentMechanism.standingInstruction: 'Bank SI',
  PaymentMechanism.cardAutopay:         'Card Autopay',
  PaymentMechanism.netbankingAutopay:   'Net Banking',
  PaymentMechanism.manual:              'Manual',
  PaymentMechanism.unknown:             '',
};

Color _gradeColorStr(String g) => switch (g) {
  'A' => _green,
  'B' => const Color(0xFF84CC16),
  'C' => _amber,
  'D' => _orange,
  _   => _red,
};

Color _stressColor(StressAffordability a) => switch (a) {
  StressAffordability.safe       => _green,
  StressAffordability.manageable => _amber,
  StressAffordability.atRisk     => _amber,
  StressAffordability.critical   => _red,
};

// ─── Screen ───────────────────────────────────────────────────────────────────

class CommitmentsScreen extends StatefulWidget {
  const CommitmentsScreen({super.key});

  @override
  State<CommitmentsScreen> createState() => _CommitmentsScreenState();
}

class _CommitmentsScreenState extends State<CommitmentsScreen> {
  bool _loading = true;
  String? _error;

  // Old engine output — drives subscription/mandate card lists
  RecurringCommitmentsReport? _report;
  // New platform engine output — drives all analytical sections
  RecurringCommitmentsIntelligence? _intel;

  final _fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  final _compactFmt =
      NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹', decimalDigits: 1);

  final Set<CommitmentCategory> _collapsedCategories = {};
  bool _mandatesCollapsed = false;
  bool _subscriptionsCollapsed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        AppServices.instance.transactions.getAll().catchError((_) => <TransactionEntity>[]),
        UserPrefsStorage.getSalary(),
      ]);

      final txns = results[0] as List<dynamic>;
      final salary = results[1] as double;

      double income = salary;
      try {
        final user = await AppServices.instance.user.getMe();
        if ((user.monthlyIncome ?? 0) > 0) income = user.monthlyIncome!;
      } catch (_) {}

      List<GoalSnapshot> goalSnapshots = const [];
      try {
        final goals = await AppServices.instance.goals.getAll();
        goalSnapshots = goals.map(_goalToSnapshot).toList();
      } catch (_) {}

      final summary = CommitmentEngine.analyze(txns.cast(), income);
      final report = RecurringCommitmentsEngine.fromSummary(summary);
      final intel = sl<RecurringCommitmentsIntelligenceEngine>().analyze(
        summary,
        goals: goalSnapshots,
      );

      if (mounted) {
        setState(() {
          _report = report;
          _intel = intel;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load commitments. Check your connection.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _indigo))
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final r = _report!;
    final intel = _intel!;
    final stressResult = intel.stressAnalysis.twentyPercentDrop;

    return CustomScrollView(
      slivers: [
        _AppBar(onRefresh: _load),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 12),

              // ── Hero ──────────────────────────────────────────────────────
              _HeroCard(intel: intel, fmt: _fmt, compactFmt: _compactFmt),
              const SizedBox(height: 16),

              // ── 6-month Forecast ─────────────────────────────────────────
              if (intel.forecast.monthlyForecasts.isNotEmpty) ...[
                _ForecastStrip(forecast: intel.forecast, compactFmt: _compactFmt),
                const SizedBox(height: 16),
              ],

              // ── Commitment Insights (replaces old Health Score Card) ──────
              _CommitmentInsightsCard(intel: intel),
              const SizedBox(height: 16),

              // ── Cash Flow Waterfall ───────────────────────────────────────
              if (intel.monthlyIncome > 0) ...[
                _CashFlowCard(cashFlow: intel.cashFlow, fmt: _fmt),
                const SizedBox(height: 16),
              ],

              // ── Stress Alert ──────────────────────────────────────────────
              if (stressResult != null &&
                  (stressResult.affordability == StressAffordability.atRisk ||
                   stressResult.affordability == StressAffordability.critical)) ...[
                _StressAlert(stressResult: stressResult, fmt: _fmt),
                const SizedBox(height: 16),
              ],

              // ── Renewal Alerts ────────────────────────────────────────────
              if (intel.forecast.renewalTimeline.isNotEmpty) ...[
                _RenewalAlerts(renewals: intel.forecast.renewalTimeline, fmt: _fmt),
                const SizedBox(height: 16),
              ],

              // ── Duplicate Alerts ──────────────────────────────────────────
              if (intel.duplicateAnalysis.hasDuplicates) ...[
                ...intel.duplicateAnalysis.groups.map((g) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DuplicateAlert(group: g, fmt: _fmt),
                )),
              ],

              // ── Upcoming Payments (from calendar) ─────────────────────────
              if (intel.calendar.next30Days.isNotEmpty) ...[
                _UpcomingSection(events: intel.calendar.next30Days, fmt: _fmt),
                const SizedBox(height: 20),
              ],

              // ── Section 1: Subscriptions ───────────────────────────────────
              _SectionHeader(
                emoji: '📺',
                title: 'Subscriptions',
                subtitle: '${r.subscriptions.length} services · ${_fmt.format(r.subscriptionMonthly)}/mo',
                collapsed: _subscriptionsCollapsed,
                onTap: () => setState(
                  () => _subscriptionsCollapsed = !_subscriptionsCollapsed,
                ),
              ),
              if (!_subscriptionsCollapsed) ...[
                if (r.subscriptions.isEmpty)
                  const _EmptySection(
                    message: 'No subscriptions detected from transaction history.',
                  )
                else
                  ...r.subscriptions.map(
                    (c) => _SubscriptionCard(
                      commitment: c,
                      fmt: _fmt,
                      goalImpact: intel.goalImpacts[c.merchantKey],
                    ),
                  ),
              ],
              const SizedBox(height: 20),

              // ── Section 2: AutoPay & Bank Mandates ─────────────────────────
              _SectionHeader(
                emoji: '🏛️',
                title: 'AutoPay & Bank Mandates',
                subtitle: '${r.mandates.length} mandates · ${_fmt.format(r.mandateMonthly)}/mo',
                collapsed: _mandatesCollapsed,
                onTap: () =>
                    setState(() => _mandatesCollapsed = !_mandatesCollapsed),
              ),
              if (!_mandatesCollapsed) ...[
                if (r.mandates.isEmpty)
                  const _EmptySection(
                    message: 'No bank mandates or AutoPay detected.',
                  )
                else ...[
                  _buildMandateCategory(
                    r, CommitmentCategory.critical,
                    '🔒 Critical', 'EMIs, rent, insurance, tax',
                  ),
                  _buildMandateCategory(
                    r, CommitmentCategory.investment,
                    '📈 Investment', 'SIP, RD, NPS, savings',
                  ),
                  _buildMandateCategory(
                    r, CommitmentCategory.lifestyle,
                    '✨ Lifestyle', 'Utilities, education, memberships',
                  ),
                  _buildMandateCategory(
                    r, CommitmentCategory.optional,
                    '📦 Optional', 'Other recurring payments',
                  ),
                ],
              ],
              const SizedBox(height: 20),

              // ── Monthly Intelligence Report ───────────────────────────────
              _MonthlyReportCard(review: intel.monthlyReview, fmt: _fmt),
              const SizedBox(height: 20),

              // ── Intelligence: AI Recommendations ──────────────────────────
              if (intel.monthlyReview.aiRecommendations.isNotEmpty ||
                  intel.monthlyReview.savingsOpportunities.isNotEmpty ||
                  intel.monthlyReview.riskAlerts.isNotEmpty) ...[
                const _SectionTitle('Intelligence'),
                const SizedBox(height: 10),
                ...intel.monthlyReview.riskAlerts.map(
                  (msg) => _SimpleInsightCard(message: msg, type: _InsightKind.warning),
                ),
                ...intel.monthlyReview.savingsOpportunities.map(
                  (msg) => _SimpleInsightCard(message: msg, type: _InsightKind.saving),
                ),
                ...intel.monthlyReview.aiRecommendations.map(
                  (msg) => _SimpleInsightCard(message: msg, type: _InsightKind.tip),
                ),
              ],

              const SizedBox(height: 40),
            ]),
          ),
        ),
      ],
    );
  }

  static GoalSnapshot _goalToSnapshot(GoalEntity g) => GoalSnapshot(
        id: g.id,
        name: g.name,
        goalType: g.goalType,
        targetAmount: g.targetAmount,
        currentSaved: g.currentSaved,
        monthlyContribution: g.recommendedMonthlyContribution,
        deadline: g.deadline,
      );

  Widget _buildMandateCategory(
    RecurringCommitmentsReport r,
    CommitmentCategory cat,
    String label,
    String subtitle,
  ) {
    final items = r.mandatesByCategory[cat] ?? [];
    if (items.isEmpty) return const SizedBox.shrink();
    final total = items.fold<double>(0, (s, c) => s + c.monthlyEquivalent);
    final isCollapsed = _collapsedCategories.contains(cat);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => setState(() {
            if (isCollapsed) {
              _collapsedCategories.remove(cat);
            } else {
              _collapsedCategories.add(cat);
            }
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                Text(label, style: _label(fontSize: 13)),
                const SizedBox(width: 6),
                Text(
                  subtitle,
                  style: _body(color: _textMuted, fontSize: 11),
                ),
                const Spacer(),
                Text(_fmt.format(total),
                    style: _label(fontSize: 13, color: _textSecondary)),
                const SizedBox(width: 6),
                Icon(
                  isCollapsed
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_up_rounded,
                  color: _textMuted,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        if (!isCollapsed)
          ...items.map((c) => _MandateCard(commitment: c, fmt: _fmt)),
      ],
    );
  }
}

// ─── App Bar ─────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  const _AppBar({required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: _bg,
      expandedHeight: 88,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Recurring Commitments',
          style: GoogleFonts.manrope(
            color: _textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 12),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: onRefresh,
          tooltip: 'Refresh',
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(20),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              'All recurring obligations, one place',
              style: _body(color: _textMuted, fontSize: 12),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Hero Card ────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.intel,
    required this.fmt,
    required this.compactFmt,
  });

  final RecurringCommitmentsIntelligence intel;
  final NumberFormat fmt;
  final NumberFormat compactFmt;

  @override
  Widget build(BuildContext context) {
    final committedPct = intel.monthlyIncome > 0
        ? ((intel.totalMonthlyCommitted / intel.monthlyIncome) * 100).round().clamp(0, 100)
        : 0;
    final gradeColor = _gradeColorStr(intel.healthGrade);
    final ratio = intel.monthlyIncome > 0
        ? (intel.totalMonthlyCommitted / intel.monthlyIncome).clamp(0.0, 1.0)
        : 0.0;
    final flexibleIncome = intel.monthlyIncome - intel.totalMonthlyCommitted;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Committed',
                      style: GoogleFonts.manrope(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fmt.format(intel.totalMonthlyCommitted),
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      intel.monthlyIncome > 0
                          ? 'of ${fmt.format(intel.monthlyIncome)} income · $committedPct% committed'
                          : 'Set salary to see commitment ratio',
                      style: GoogleFonts.dmSans(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: gradeColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: gradeColor, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  intel.healthGrade,
                  style: GoogleFonts.manrope(
                    color: gradeColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MiniChip(
                label: 'Subscriptions',
                value: compactFmt.format(intel.subscriptionMonthly),
                color: _pink,
              ),
              const SizedBox(width: 8),
              _MiniChip(
                label: 'Mandates',
                value: compactFmt.format(intel.mandateMonthly),
                color: _indigo,
              ),
              const SizedBox(width: 8),
              _MiniChip(
                label: 'Disposable',
                value: compactFmt.format(flexibleIncome.abs()),
                color: flexibleIncome >= 0 ? _green : _red,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _CommitmentBar(ratio: ratio),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.manrope(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      );
}

class _CommitmentBar extends StatelessWidget {
  const _CommitmentBar({required this.ratio});
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final committed = (ratio * 100).round().clamp(0, 100);
    final free = 100 - committed;
    final color = ratio < 0.50 ? _indigo : ratio < 0.65 ? _amber : _red;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                Expanded(
                  flex: committed.clamp(1, 100),
                  child: Container(color: color),
                ),
                Expanded(
                  flex: free.clamp(1, 100),
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$committed% committed',
              style: GoogleFonts.dmSans(color: color, fontSize: 11),
            ),
            Text(
              ratio < 0.50
                  ? 'Healthy'
                  : ratio < 0.65
                      ? 'Watch this'
                      : 'Over-committed',
              style: GoogleFonts.dmSans(color: color, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Forecast Strip ───────────────────────────────────────────────────────────

class _ForecastStrip extends StatelessWidget {
  const _ForecastStrip({required this.forecast, required this.compactFmt});
  final ForecastResult forecast;
  final NumberFormat compactFmt;

  @override
  Widget build(BuildContext context) {
    final forecasts = forecast.monthlyForecasts;
    final peak = forecast.peakMonth;
    final maxAmount = forecasts.isEmpty ? 1.0 : forecasts
        .map((f) => f.expectedTotal)
        .reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _SectionTitle('6-Month Forecast'),
            Text(
              'Annual: ${compactFmt.format(forecast.annualProjection)}',
              style: _body(color: _textMuted, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: forecasts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final f = forecasts[i];
              final isPeak = f.month == peak.month && f.year == peak.year;
              final barFraction = maxAmount > 0
                  ? (f.expectedTotal / maxAmount).clamp(0.0, 1.0)
                  : 0.0;
              final barHeight = 8.0 + barFraction * 48;
              final color = isPeak
                  ? _red
                  : f.isSpike
                      ? _amber
                      : _indigo;

              return Container(
                width: 68,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isPeak
                        ? _red.withValues(alpha: 0.5)
                        : f.isSpike
                            ? _amber.withValues(alpha: 0.4)
                            : _border,
                    width: isPeak ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isPeak)
                      Text('Peak', style: _body(color: _red, fontSize: 9)),
                    const SizedBox(height: 2),
                    Container(
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      f.label.split(' ').first,
                      style: _body(color: _textSecondary, fontSize: 11),
                    ),
                    Text(
                      compactFmt.format(f.expectedTotal),
                      style: _body(color: color, fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Commitment Insights Card ─────────────────────────────────────────────────

class _CommitmentInsightsCard extends StatelessWidget {
  const _CommitmentInsightsCard({required this.intel});
  final RecurringCommitmentsIntelligence intel;

  @override
  Widget build(BuildContext context) {
    final gradeColor = _gradeColorStr(intel.healthGrade);
    final score = intel.healthScore;

    // Derived scores (0–100)
    final ratioScore = intel.monthlyIncome > 0
        ? ((1 - (intel.totalMonthlyCommitted / intel.monthlyIncome).clamp(0.0, 1.0)) * 100)
        : 50.0;
    final investScore = intel.monthlyIncome > 0
        ? ((intel.cashFlow.investmentCommitments / intel.monthlyIncome) * 100 * 5).clamp(0.0, 100.0)
        : 0.0;
    final surplusScore = intel.monthlyIncome > 0
        ? ((intel.cashFlow.surplus / intel.monthlyIncome) * 200).clamp(0.0, 100.0)
        : 50.0;
    final unused = intel.monthlyReview.unusedSubscriptionCount;
    final efficiencyScore = unused == 0
        ? 100.0
        : (100.0 - unused * 20.0).clamp(0.0, 100.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: gradeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Commitment Health · Grade ${intel.healthGrade}',
                  style: GoogleFonts.manrope(
                    color: gradeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${score.toInt()}/100',
                style: GoogleFonts.manrope(
                  color: gradeColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ScoreBar(label: 'Income Headroom', score: ratioScore),
          const SizedBox(height: 6),
          _ScoreBar(label: 'Investment Rate', score: investScore),
          const SizedBox(height: 6),
          _ScoreBar(label: 'Surplus Buffer', score: surplusScore),
          const SizedBox(height: 6),
          _ScoreBar(label: 'Subscription Efficiency', score: efficiencyScore),
          if (intel.monthlyReview.changeSummary != null) ...[
            const SizedBox(height: 10),
            Text(
              intel.monthlyReview.changeSummary!,
              style: _body(color: _textMuted, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.label, required this.score});
  final String label;
  final double score;

  @override
  Widget build(BuildContext context) {
    final fraction = (score / 100).clamp(0.0, 1.0);
    final color = fraction >= 0.8
        ? _green
        : fraction >= 0.5
            ? _amber
            : _red;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: _body(color: _textSecondary, fontSize: 11)),
            Text(
              '${score.toInt()}/100',
              style: _body(color: color, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 6,
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: _border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Cash Flow Waterfall ──────────────────────────────────────────────────────

class _CashFlowCard extends StatelessWidget {
  const _CashFlowCard({required this.cashFlow, required this.fmt});
  final CashFlowWaterfall cashFlow;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    final cf = cashFlow;
    final surplusColor = cf.surplus >= 0 ? _green : _red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Cash Flow',
            style: GoogleFonts.manrope(
              color: _textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _FlowRow(label: '💵 Monthly Income', amount: cf.monthlyIncome, fmt: fmt, color: _green, isDeduction: false),
          if (cf.criticalCommitments > 0)
            _FlowRow(label: '🔒 Critical (EMI, rent)', amount: cf.criticalCommitments, fmt: fmt, color: _orange, isDeduction: true),
          if (cf.investmentCommitments > 0)
            _FlowRow(label: '📈 Investments (SIP, RD)', amount: cf.investmentCommitments, fmt: fmt, color: _green, isDeduction: true),
          if (cf.lifestyleCommitments > 0)
            _FlowRow(label: '✨ Lifestyle', amount: cf.lifestyleCommitments, fmt: fmt, color: _amber, isDeduction: true),
          if (cf.subscriptionCommitments > 0)
            _FlowRow(label: '📺 Subscriptions', amount: cf.subscriptionCommitments, fmt: fmt, color: _pink, isDeduction: true),
          const Divider(color: _border, height: 16),
          _FlowRow(
            label: cf.surplus >= 0 ? '= Available' : '= Shortfall',
            amount: cf.surplus.abs(),
            fmt: fmt,
            color: surplusColor,
            isDeduction: false,
            isBold: true,
          ),
          if (cf.suggestedEmergencyContribution > 0) ...[
            const SizedBox(height: 6),
            Text(
              'Suggested emergency reserve: ${fmt.format(cf.suggestedEmergencyContribution)}/mo',
              style: _body(color: _textMuted, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

class _FlowRow extends StatelessWidget {
  const _FlowRow({
    required this.label,
    required this.amount,
    required this.fmt,
    required this.color,
    required this.isDeduction,
    this.isBold = false,
  });

  final String label;
  final double amount;
  final NumberFormat fmt;
  final Color color;
  final bool isDeduction;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          if (isDeduction) const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: _body(
                color: isBold ? _textPrimary : _textSecondary,
                fontSize: 12,
                weight: isBold ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            '${isDeduction ? '−' : ''} ${fmt.format(amount)}',
            style: GoogleFonts.manrope(
              color: color,
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stress Alert ─────────────────────────────────────────────────────────────

class _StressAlert extends StatelessWidget {
  const _StressAlert({required this.stressResult, required this.fmt});
  final StressScenarioResult stressResult;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    final s = stressResult;
    final color = _stressColor(s.affordability);
    final icon = s.affordability == StressAffordability.critical
        ? Icons.dangerous_rounded
        : Icons.warning_amber_rounded;
    final shortfall = s.surplusOrShortfall < 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '20% income drop: ${s.assessmentLabel}',
                  style: _label(color: color, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'If income drops to ${fmt.format(s.reducedIncome)}/mo — '
                  '${shortfall ? 'shortfall: ${fmt.format(s.surplusOrShortfall.abs())}' : 'surplus: ${fmt.format(s.surplusOrShortfall)}'}.',
                  style: _body(color: _textSecondary, fontSize: 12),
                ),
                if (s.recommendations.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    s.recommendations.first,
                    style: _body(color: _textMuted, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Renewal Alerts ───────────────────────────────────────────────────────────

class _RenewalAlerts extends StatelessWidget {
  const _RenewalAlerts({required this.renewals, required this.fmt});
  final List<RenewalAlert> renewals;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Upcoming Renewals'),
        const SizedBox(height: 10),
        ...renewals.take(4).map((r) {
          final color = r.isUrgent ? _red : _amber;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              r.merchantName,
                              style: _label(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (r.isUrgent)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _red.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Urgent',
                                style: _body(color: _red, fontSize: 10),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${r.recurrencePeriod} · in ${r.daysUntil} days',
                        style: _body(color: _textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Text(
                  fmt.format(r.amount),
                  style: _label(color: color, fontSize: 14),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ─── Duplicate Alert ─────────────────────────────────────────────────────────

class _DuplicateAlert extends StatelessWidget {
  const _DuplicateAlert({required this.group, required this.fmt});
  final DuplicateGroup group;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _amber.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.copy_rounded, color: _amber, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Duplicate ${group.category}',
                  style: _label(color: _amber, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  group.insight,
                  style: _body(color: _textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  group.consolidationSuggestion,
                  style: _body(color: _textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            fmt.format(group.totalMonthly),
            style: _label(color: _amber, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Upcoming Payments Section ────────────────────────────────────────────────

class _UpcomingSection extends StatelessWidget {
  const _UpcomingSection({required this.events, required this.fmt});
  final List<FinancialCalendarEvent> events;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Coming up — next 30 days'),
        const SizedBox(height: 10),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final e = events[i];
              final daysAway = e.date.difference(now).inDays;
              final color = _calendarTypeColors[e.type] ?? _indigo;
              final icon = _calendarTypeIcons[e.type] ?? '📦';

              return Container(
                width: 110,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(
                      e.title,
                      style: _body(fontSize: 11, color: _textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fmt.format(e.amount),
                      style: _label(color: color, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      daysAway == 0
                          ? 'Today'
                          : daysAway == 1
                              ? 'Tomorrow'
                              : 'in $daysAway days',
                      style: _body(color: _textMuted, fontSize: 10),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.collapsed,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      color: _textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: _body(color: _textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(
              collapsed
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.keyboard_arrow_up_rounded,
              color: _textMuted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Subscription Card ────────────────────────────────────────────────────────

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.commitment,
    required this.fmt,
    this.goalImpact,
  });
  final DetectedCommitment commitment;
  final NumberFormat fmt;
  final GoalImpactResult? goalImpact;

  Future<void> _openManagePage(BuildContext context) async {
    final url = RecurringCommitmentsEngine.deepLinkFor(commitment);
    if (url == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No manage link available for this service.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!context.mounted) return;
      await Clipboard.setData(ClipboardData(text: url));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Link copied: $url'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = commitment;
    final color = _typeColors[c.type] ?? _pink;
    final periodLabel = _periodLabels[c.period] ?? '';
    final mechLabel = _mechanismLabels[c.mechanism] ?? '';
    final hasManageLink = RecurringCommitmentsEngine.deepLinkFor(c) != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              _typeIcons[c.type] ?? '📦',
              style: const TextStyle(fontSize: 20),
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
                      child: Text(
                        c.displayName,
                        style: _label(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (c.likelyUnused)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Likely unused',
                          style: _body(color: _amber, fontSize: 10),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      '${fmt.format(c.avgAmount)} · $periodLabel',
                      style: _body(color: _textSecondary, fontSize: 12),
                    ),
                    if (mechLabel.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: _border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          mechLabel,
                          style: _body(color: _textMuted, fontSize: 10),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _openManagePage(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: hasManageLink
                    ? _indigo.withValues(alpha: 0.15)
                    : _border,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: hasManageLink
                      ? _indigo.withValues(alpha: 0.4)
                      : _textMuted.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'Manage',
                style: _body(
                  color: hasManageLink ? _indigo : _textMuted,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
        ),
        if (goalImpact != null && goalImpact!.hasImpact)
          _GoalImpactBadge(impact: goalImpact!),
      ],
    );
  }
}

// ─── Goal Impact Badge ────────────────────────────────────────────────────────

class _GoalImpactBadge extends StatelessWidget {
  const _GoalImpactBadge({required this.impact});
  final GoalImpactResult impact;

  @override
  Widget build(BuildContext context) {
    final primary = impact.primaryImpact!;
    final isPositive = primary.isPositive;
    final color = isPositive ? _green : _cyan;
    final icon = isPositive ? '📈' : '🎯';

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              impact.primaryInsight,
              style: _body(color: color, fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mandate Card ─────────────────────────────────────────────────────────────

class _MandateCard extends StatelessWidget {
  const _MandateCard({required this.commitment, required this.fmt});
  final DetectedCommitment commitment;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    final c = commitment;
    final color = _typeColors[c.type] ?? _indigo;
    final periodLabel = _periodLabels[c.period] ?? '';
    final mechLabel = _mechanismLabels[c.mechanism] ?? '';

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              _typeIcons[c.type] ?? '📦',
              style: const TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.displayName,
                  style: _label(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      '${fmt.format(c.avgAmount)} · $periodLabel',
                      style: _body(color: _textSecondary, fontSize: 12),
                    ),
                    if (mechLabel.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: _border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          mechLabel,
                          style: _body(color: _textMuted, fontSize: 10),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fmt.format(c.monthlyEquivalent),
                style: _label(color: color, fontSize: 14),
              ),
              Text(
                '/month',
                style: _body(color: _textMuted, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Monthly Report Card ──────────────────────────────────────────────────────

class _MonthlyReportCard extends StatelessWidget {
  const _MonthlyReportCard({required this.review, required this.fmt});
  final MonthlyFinancialReview review;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📋', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Monthly Intelligence · ${review.monthLabel}',
                  style: GoogleFonts.manrope(
                    color: _textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _gradeColorStr(review.healthGrade).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Grade ${review.healthGrade}',
                  style: _body(
                    color: _gradeColorStr(review.healthGrade),
                    fontSize: 11,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ReviewRow(
            label: 'Annual projection',
            value: fmt.format(review.totalAnnualCommitted),
            color: _textSecondary,
          ),
          _ReviewRow(
            label: 'Investment commitments',
            value: '${fmt.format(review.investmentCommitments)}/mo',
            color: _green,
          ),
          if (review.potentialMonthlySavings > 0)
            _ReviewRow(
              label: 'Potential savings',
              value: '${fmt.format(review.potentialMonthlySavings)}/mo',
              color: _green,
            ),
          if (review.upcomingRenewalCount > 0)
            _ReviewRow(
              label: 'Upcoming renewals',
              value: '${review.upcomingRenewalCount} this month',
              color: _amber,
            ),
          if (review.nextMonthForecast > 0 &&
              review.nextMonthForecast != review.totalMonthlyCommitted) ...[
            const SizedBox(height: 4),
            Text(
              'Next month forecast: ${fmt.format(review.nextMonthForecast)}',
              style: _body(color: _textMuted, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: _body(color: _textSecondary, fontSize: 12)),
            Text(value, style: _body(color: color, fontSize: 12, weight: FontWeight.w500)),
          ],
        ),
      );
}

// ─── Simple Insight Card ──────────────────────────────────────────────────────

enum _InsightKind { warning, saving, tip }

class _SimpleInsightCard extends StatelessWidget {
  const _SimpleInsightCard({required this.message, required this.type});
  final String message;
  final _InsightKind type;

  Color get _color => switch (type) {
    _InsightKind.warning => _amber,
    _InsightKind.saving  => _green,
    _InsightKind.tip     => _cyan,
  };

  IconData get _icon => switch (type) {
    _InsightKind.warning => Icons.warning_amber_rounded,
    _InsightKind.saving  => Icons.savings_outlined,
    _InsightKind.tip     => Icons.lightbulb_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: _body(color: _textPrimary, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        child: Text(message, style: _body(color: _textMuted, fontSize: 13)),
      );
}

// ─── Error View ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, color: _textMuted, size: 48),
              const SizedBox(height: 16),
              Text(message, style: _body(color: _textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _indigo),
                onPressed: onRetry,
                child: Text('Retry', style: _body()),
              ),
            ],
          ),
        ),
      );
}

// ─── Section Title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.manrope(
          color: _textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      );
}

// ─── Text style helpers ───────────────────────────────────────────────────────

TextStyle _body({
  Color color = _textPrimary,
  double fontSize = 14,
  FontWeight weight = FontWeight.w400,
}) =>
    GoogleFonts.dmSans(color: color, fontSize: fontSize, fontWeight: weight);

TextStyle _label({
  Color color = _textPrimary,
  double fontSize = 14,
}) =>
    GoogleFonts.manrope(color: color, fontSize: fontSize, fontWeight: FontWeight.w600);
