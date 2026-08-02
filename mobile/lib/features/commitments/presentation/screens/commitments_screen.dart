import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/app_services.dart';
import '../../../../core/services/commitment_intelligence/commitment_engine.dart';
import '../../../../core/services/storage/user_prefs_storage.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';

// ─── Display constants ────────────────────────────────────────────────────────

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

const _typeLabels = {
  CommitmentType.emi:          'Loans & EMIs',
  CommitmentType.subscription: 'Subscriptions',
  CommitmentType.investment:   'Investments',
  CommitmentType.insurance:    'Insurance',
  CommitmentType.utility:      'Utilities',
  CommitmentType.rent:         'Rent & Housing',
  CommitmentType.education:    'Education',
  CommitmentType.tax:          'Tax',
  CommitmentType.savings:      'Savings',
  CommitmentType.membership:   'Memberships',
  CommitmentType.other:        'Other',
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

const _periodLabels = {
  RecurrencePeriod.weekly:     'Weekly',
  RecurrencePeriod.biweekly:   'Every 2 weeks',
  RecurrencePeriod.monthly:    'Monthly',
  RecurrencePeriod.quarterly:  'Quarterly',
  RecurrencePeriod.semiannual: 'Every 6 months',
  RecurrencePeriod.annual:     'Annual',
  RecurrencePeriod.irregular:  'Irregular',
};

// Sections: (title, emoji, types that belong here)
const _sections = [
  ('Essential', '🔒', [
    CommitmentType.emi, CommitmentType.rent, CommitmentType.insurance,
    CommitmentType.utility, CommitmentType.tax,
  ]),
  ('Investments & Savings', '📈', [
    CommitmentType.investment, CommitmentType.savings,
  ]),
  ('Lifestyle', '✨', [
    CommitmentType.subscription, CommitmentType.membership,
  ]),
  ('Education', '🎓', [CommitmentType.education]),
  ('Other', '📦', [CommitmentType.other]),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class CommitmentsScreen extends StatefulWidget {
  const CommitmentsScreen({super.key});

  @override
  State<CommitmentsScreen> createState() => _CommitmentsScreenState();
}

class _CommitmentsScreenState extends State<CommitmentsScreen> {
  static const _bg = Color(0xFF09090B);

  bool _loading = true;
  String? _error;
  CommitmentSummary? _summary;

  final _fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  final _compactFmt =
      NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹', decimalDigits: 1);

  final Set<String> _collapsed = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
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

      final summary = CommitmentEngine.analyze(txns.cast(), income);
      if (mounted) setState(() { _summary = summary; _loading = false; });
    } catch (e) {
      if (mounted) setState(() {
        _error = 'Could not load commitments. Check your connection.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, color: Color(0xFF6B7280), size: 48),
              const SizedBox(height: 16),
              Text(_error!, style: _bodyStyle(color: const Color(0xFF9CA3AF))),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                onPressed: _load,
                child: Text('Retry', style: _bodyStyle()),
              ),
            ],
          ),
        ),
      );

  Widget _buildContent() {
    final s = _summary!;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: _bg,
          expandedHeight: 80,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              'Financial Commitments',
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            titlePadding: const EdgeInsets.only(left: 16, bottom: 12),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              tooltip: 'Refresh',
              onPressed: _load,
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
                  style: _bodyStyle(color: const Color(0xFF71717A), fontSize: 12),
                ),
              ),
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 8),
              _HeroCard(summary: s, fmt: _fmt, compactFmt: _compactFmt),
              const SizedBox(height: 16),
              _RatioBar(ratio: s.commitmentRatio),
              const SizedBox(height: 20),
              _UpcomingSection(summary: s, fmt: _fmt),
              const SizedBox(height: 20),
              if (s.insights.isNotEmpty) ...[
                const _SectionTitle('Intelligence'),
                const SizedBox(height: 10),
                ...s.insights.map((i) => _InsightCard(insight: i, fmt: _fmt)),
                const SizedBox(height: 20),
              ],
              if (s.byType.isNotEmpty) ...[
                const _SectionTitle('By obligation'),
                const SizedBox(height: 10),
                _TypeBreakdown(summary: s, fmt: _fmt),
                const SizedBox(height: 20),
              ],
              if (s.all.isEmpty)
                const _EmptyState()
              else ...[
                ..._buildSections(s),
              ],
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildSections(CommitmentSummary s) {
    final widgets = <Widget>[];

    for (final section in _sections) {
      final title = section.$1;
      final emoji = section.$2;
      final types = section.$3;

      final items = s.all.where((c) => types.contains(c.type)).toList();
      if (items.isEmpty) continue;

      items.sort((a, b) => b.avgAmount.compareTo(a.avgAmount));
      final sectionTotal = items.fold<double>(0, (sum, c) => sum + c.monthlyEquivalent);
      final isCollapsed = _collapsed.contains(title);

      widgets.add(_SectionHeader(
        emoji: emoji,
        title: title,
        total: sectionTotal,
        fmt: _fmt,
        itemCount: items.length,
        collapsed: isCollapsed,
        onTap: () => setState(() {
          if (isCollapsed) _collapsed.remove(title);
          else _collapsed.add(title);
        }),
      ));

      if (!isCollapsed) {
        for (final commitment in items) {
          widgets.add(_CommitmentCard(commitment: commitment, fmt: _fmt));
        }
      }
      widgets.add(const SizedBox(height: 12));
    }

    return widgets;
  }

  static TextStyle _bodyStyle({
    Color color = Colors.white,
    double fontSize = 14,
    FontWeight weight = FontWeight.w400,
  }) =>
      GoogleFonts.dmSans(color: color, fontSize: fontSize, fontWeight: weight);
}

// ─── Hero Card ────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.summary, required this.fmt, required this.compactFmt});

  final CommitmentSummary summary;
  final NumberFormat fmt;
  final NumberFormat compactFmt;

  @override
  Widget build(BuildContext context) {
    final emiTotal = summary.byType[CommitmentType.emi] ?? 0;
    final investTotal = (summary.byType[CommitmentType.investment] ?? 0) +
        (summary.byType[CommitmentType.savings] ?? 0);
    final subTotal = summary.byType[CommitmentType.subscription] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Committed',
            style: GoogleFonts.manrope(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            fmt.format(summary.totalMonthlyCommitted),
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'of ${fmt.format(summary.monthlyIncome)} income',
            style: GoogleFonts.dmSans(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatChip(label: 'EMIs', value: fmt.format(emiTotal)),
              const SizedBox(width: 8),
              _StatChip(label: 'Investments', value: fmt.format(investTotal)),
              const SizedBox(width: 8),
              _StatChip(label: 'Subscriptions', value: fmt.format(subTotal)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${fmt.format(summary.flexibleIncome)} disposable  ·  Annual drain ${compactFmt.format(summary.annualDrain)}',
            style: GoogleFonts.dmSans(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      );
}

// ─── Ratio Bar ────────────────────────────────────────────────────────────────

class _RatioBar extends StatelessWidget {
  const _RatioBar({required this.ratio});
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final committed = (ratio * 100).round();
    final flexible = 100 - committed;
    final isHealthy = ratio < 0.5;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 28,
            child: Row(
              children: [
                if (ratio > 0)
                  Expanded(
                    flex: committed,
                    child: Container(
                      color: isHealthy ? const Color(0xFF6366F1) : const Color(0xFFF97316),
                      alignment: Alignment.center,
                      child: committed > 10
                          ? Text(
                              '$committed%',
                              style: GoogleFonts.manrope(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : null,
                    ),
                  ),
                if (flexible > 0)
                  Expanded(
                    flex: flexible,
                    child: Container(
                      color: const Color(0xFF27272A),
                      alignment: Alignment.center,
                      child: flexible > 10
                          ? Text(
                              '$flexible%',
                              style: GoogleFonts.dmSans(
                                color: const Color(0xFF9CA3AF),
                                fontSize: 11,
                              ),
                            )
                          : null,
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
              'Committed $committed%',
              style: GoogleFonts.dmSans(
                color: isHealthy ? const Color(0xFF6366F1) : const Color(0xFFF97316),
                fontSize: 12,
              ),
            ),
            Text(
              ratio < 0.5
                  ? 'Healthy'
                  : ratio < 0.7
                      ? 'Watch this'
                      : 'Over-committed',
              style: GoogleFonts.dmSans(
                color: ratio < 0.5
                    ? const Color(0xFF22C55E)
                    : ratio < 0.7
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFEF4444),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Upcoming Section ─────────────────────────────────────────────────────────

class _UpcomingSection extends StatelessWidget {
  const _UpcomingSection({required this.summary, required this.fmt});
  final CommitmentSummary summary;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    final next30 = List<ForecastPayment>.from(summary.next30Days);
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Upcoming'),
        const SizedBox(height: 10),
        if (next30.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF27272A)),
            ),
            child: Row(
              children: [
                const Text('✓', style: TextStyle(fontSize: 20, color: Color(0xFF22C55E))),
                const SizedBox(width: 10),
                Text(
                  'No payments due in the next 30 days',
                  style: GoogleFonts.dmSans(color: const Color(0xFF9CA3AF)),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: next30.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final p = next30[i];
                final days = p.expectedDate.difference(now).inDays;
                return _UpcomingCard(payment: p, daysUntil: days, fmt: fmt);
              },
            ),
          ),
      ],
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.payment, required this.daysUntil, required this.fmt});
  final ForecastPayment payment;
  final int daysUntil;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    final urgent = daysUntil <= 3;
    final dayLabel = daysUntil == 0
        ? 'Today'
        : daysUntil == 1
            ? 'Tomorrow'
            : '${daysUntil}d';
    final color = _typeColors[payment.type] ?? const Color(0xFF6B7280);
    final mechLabel = _mechanismLabels[payment.mechanism] ?? '';

    return Container(
      width: 120,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: urgent
            ? const Color(0xFF78350F).withValues(alpha: 0.4)
            : const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: urgent ? const Color(0xFFF59E0B) : const Color(0xFF27272A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(
                dayLabel,
                style: GoogleFonts.manrope(
                  color: urgent ? const Color(0xFFF59E0B) : const Color(0xFF9CA3AF),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Text(
            payment.merchantName,
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                fmt.format(payment.estimatedAmount),
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (mechLabel.isNotEmpty)
                Text(
                  mechLabel,
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFF71717A),
                    fontSize: 9,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Insights ─────────────────────────────────────────────────────────────────

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight, required this.fmt});
  final CommitmentInsight insight;
  final NumberFormat fmt;

  Color get _stripColor => switch (insight.type) {
        InsightType.waste   => const Color(0xFFEF4444),
        InsightType.warning => const Color(0xFFF59E0B),
        _                   => const Color(0xFF22C55E),
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: _stripColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight.message,
                      style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13),
                    ),
                    if (insight.monthlySaving != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Save ${fmt.format(insight.monthlySaving)}/month',
                          style: GoogleFonts.dmSans(
                            color: const Color(0xFF22C55E),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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

// ─── Type Breakdown ───────────────────────────────────────────────────────────

class _TypeBreakdown extends StatelessWidget {
  const _TypeBreakdown({required this.summary, required this.fmt});
  final CommitmentSummary summary;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    final entries = summary.byType.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 16,
            child: Row(
              children: entries.map((e) {
                final frac = summary.totalMonthlyCommitted > 0
                    ? e.value / summary.totalMonthlyCommitted
                    : 0.0;
                return Expanded(
                  flex: (frac * 1000).round(),
                  child: Container(color: _typeColors[e.key] ?? const Color(0xFF6B7280)),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...entries.map((e) {
          final pct = summary.totalMonthlyCommitted > 0
              ? ((e.value / summary.totalMonthlyCommitted) * 100).round()
              : 0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _typeColors[e.key] ?? const Color(0xFF6B7280),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _typeIcons[e.key] ?? '',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _typeLabels[e.key] ?? '',
                    style: GoogleFonts.dmSans(
                        color: const Color(0xFFD4D4D8), fontSize: 13),
                  ),
                ),
                Text(
                  fmt.format(e.value),
                  style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 36,
                  child: Text(
                    '$pct%',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.dmSans(
                        color: const Color(0xFF71717A), fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.emoji,
    required this.title,
    required this.total,
    required this.fmt,
    required this.itemCount,
    required this.collapsed,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final double total;
  final NumberFormat fmt;
  final int itemCount;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3F3F46)),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '$itemCount item${itemCount != 1 ? "s" : ""}',
                    style: GoogleFonts.dmSans(
                      color: const Color(0xFF71717A),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${fmt.format(total)}/mo',
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              collapsed
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.keyboard_arrow_up_rounded,
              color: const Color(0xFF71717A),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Commitment Card ──────────────────────────────────────────────────────────

class _CommitmentCard extends StatelessWidget {
  const _CommitmentCard({required this.commitment, required this.fmt});
  final DetectedCommitment commitment;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    final color = _typeColors[commitment.type] ?? const Color(0xFF6B7280);
    final icon = _typeIcons[commitment.type] ?? '📦';
    final periodLabel = _periodLabels[commitment.period] ?? '';
    final mechLabel = _mechanismLabels[commitment.mechanism] ?? '';
    final days = commitment.daysUntilNext;

    Color dueChipColor;
    String dueText;
    if (days < 0) {
      dueChipColor = const Color(0xFF6B7280);
      dueText = '${(-days)}d ago';
    } else if (days <= 3) {
      dueChipColor = const Color(0xFFF59E0B);
      dueText = days == 0 ? 'Today' : 'in ${days}d';
    } else if (days <= 10) {
      dueChipColor = const Color(0xFF22C55E);
      dueText = 'in ${days}d';
    } else {
      dueChipColor = const Color(0xFF3F3F46);
      dueText = 'in ${days}d';
    }

    // Risk indicator color
    final riskColor = switch (commitment.riskLevel) {
      RiskLevel.high   => const Color(0xFFEF4444),
      RiskLevel.medium => const Color(0xFFF59E0B),
      RiskLevel.low    => const Color(0xFF22C55E),
    };

    return Container(
      margin: const EdgeInsets.only(left: 8, bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Type icon circle
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(icon, style: const TextStyle(fontSize: 17)),
              ),
              const SizedBox(width: 10),

              // Name + period + mechanism
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      commitment.displayName,
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '$periodLabel · ${fmt.format(commitment.avgAmount)}',
                          style: GoogleFonts.dmSans(
                            color: const Color(0xFF9CA3AF),
                            fontSize: 12,
                          ),
                        ),
                        if (mechLabel.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3F3F46),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              mechLabel,
                              style: GoogleFonts.dmSans(
                                color: const Color(0xFF9CA3AF),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Right column: due chip + confidence
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: dueChipColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      dueText,
                      style: GoogleFonts.dmSans(
                        color: dueChipColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (commitment.confidence < 0.75) ...[
                    const SizedBox(height: 2),
                    Text(
                      '~${(commitment.confidence * 100).round()}% match',
                      style: GoogleFonts.dmSans(
                        color: const Color(0xFF52525B),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          // Bottom row: risk + unused badge + flexibility
          const SizedBox(height: 8),
          Row(
            children: [
              // Risk indicator
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                        color: riskColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    switch (commitment.riskLevel) {
                      RiskLevel.high   => 'HIGH',
                      RiskLevel.medium => 'MEDIUM',
                      RiskLevel.low    => 'LOW',
                    },
                    style: GoogleFonts.dmSans(
                      color: riskColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              // Flexibility badge
              Text(
                switch (commitment.flexibility) {
                  Flexibility.fixed    => 'Fixed',
                  Flexibility.variable => 'Variable',
                  Flexibility.seasonal => 'Seasonal',
                  Flexibility.onDemand => 'On-demand',
                },
                style: GoogleFonts.dmSans(
                  color: const Color(0xFF52525B),
                  fontSize: 10,
                ),
              ),
              const Spacer(),
              if (commitment.likelyUnused)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFF59E0B), size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'Possibly unused',
                        style: GoogleFonts.dmSans(
                          color: const Color(0xFFF59E0B),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: Column(
        children: [
          const Text('🔍', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            'No recurring commitments detected yet',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add at least 2 months of transactions to detect patterns',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
                color: const Color(0xFF71717A), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Section Title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: GoogleFonts.manrope(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      );
}
