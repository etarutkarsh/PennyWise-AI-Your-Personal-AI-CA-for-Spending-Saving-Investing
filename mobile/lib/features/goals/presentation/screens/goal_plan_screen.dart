import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/app_services.dart';
import '../../../../core/services/storage/user_prefs_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/goal_entity.dart';
import '../../domain/entities/goal_plan_context.dart';

// ─── Goal metadata helpers ────────────────────────────────────────────────────

String _goalEmoji(String type) {
  switch (type.toLowerCase()) {
    case 'house':          return '🏠';
    case 'car':            return '🚗';
    case 'vacation':       return '✈️';
    case 'laptop':         return '💻';
    case 'wedding':        return '💍';
    case 'emergency_fund': return '🛡️';
    case 'retirement':     return '🏖️';
    case 'education':      return '🎓';
    default:               return '⭐';
  }
}

Color _goalColor(String type) {
  switch (type.toLowerCase()) {
    case 'house':          return const Color(0xFF16213E);
    case 'car':            return const Color(0xFF0F9D58);
    case 'vacation':       return const Color(0xFFE65100);
    case 'laptop':         return const Color(0xFF6A1B9A);
    case 'wedding':        return const Color(0xFFC62828);
    case 'emergency_fund': return const Color(0xFF00695C);
    case 'retirement':     return const Color(0xFF1565C0);
    case 'education':      return const Color(0xFF283593);
    default:               return const Color(0xFFF57F17);
  }
}

String _investmentLabel(String suggestion) {
  switch (suggestion.toLowerCase()) {
    case 'liquid_fund':  return 'Liquid Fund';
    case 'rd':           return 'Recurring Deposit';
    case 'hybrid_fund':  return 'Hybrid Mutual Fund';
    case 'equity':       return 'Equity SIP';
    case 'debt':         return 'Debt Fund';
    case 'fd':           return 'Fixed Deposit';
    case 'mixed':        return 'Mixed Portfolio';
    default:             return suggestion;
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

enum _PlanTab { save, invest, loan }

class GoalPlanScreen extends StatefulWidget {
  final GoalEntity goal;
  const GoalPlanScreen({super.key, required this.goal});

  @override
  State<GoalPlanScreen> createState() => _GoalPlanScreenState();
}

class _GoalPlanScreenState extends State<GoalPlanScreen> {
  _PlanTab _tab = _PlanTab.save;
  double _salary = 0;
  bool _loadingAi = false;
  String? _aiPlan;
  late GoalPlanContext _ctx;

  final _fmt = NumberFormat('#,##,###', 'en_IN');
  final _dateFmt = DateFormat('d MMM yyyy');

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final salary = await UserPrefsStorage.getSalary();
    if (!mounted) return;
    setState(() {
      _salary = salary;
      _ctx = GoalPlanContext(goal: widget.goal, monthlySalary: salary);
      if (!_ctx.loanApplicable && _tab == _PlanTab.loan) {
        _tab = _PlanTab.save;
      }
    });
  }

  Future<void> _fetchAiPlan() async {
    if (_loadingAi || _aiPlan != null) return;
    setState(() => _loadingAi = true);
    try {
      final result = await AppServices.instance.ai
          .sendMessage(_ctx.toAiPrompt());
      if (mounted) setState(() => _aiPlan = result);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not reach AI. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingAi = false);
    }
  }

  Color get _accent => _goalColor(widget.goal.goalType);

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;
    final pct = goal.targetAmount > 0
        ? (goal.currentSaved / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Gradient AppBar ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: _accent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _GoalHeader(
                goal: goal,
                accent: _accent,
                pct: pct,
                fmt: _fmt,
                dateFmt: _dateFmt,
                monthsRemaining: _salary > 0 ? _ctx.monthsRemaining : null,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: _salary == 0
                ? const SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),

                      // ── Feasibility Banner ─────────────────────────────
                      _FeasibilityBanner(ctx: _ctx, accent: _accent),
                      const SizedBox(height: 24),

                      // ── Plan Tabs ──────────────────────────────────────
                      _PlanTabBar(
                        selected: _tab,
                        accent: _accent,
                        showLoan: _ctx.loanApplicable,
                        onSelect: (t) => setState(() => _tab = t),
                      ),
                      const SizedBox(height: 20),

                      // ── Tab Content ────────────────────────────────────
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: KeyedSubtree(
                          key: ValueKey(_tab),
                          child: _tabContent(),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Monthly Breakdown ──────────────────────────────
                      _MonthlyBreakdown(ctx: _ctx, accent: _accent, fmt: _fmt),
                      const SizedBox(height: 28),

                      // ── AI CA Plan ─────────────────────────────────────
                      _AiPlanSection(
                        loading: _loadingAi,
                        plan: _aiPlan,
                        accent: _accent,
                        onTap: _fetchAiPlan,
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tabContent() {
    switch (_tab) {
      case _PlanTab.save:
        return _SavePlanSection(ctx: _ctx, accent: _accent, fmt: _fmt);
      case _PlanTab.invest:
        return _InvestPlanSection(ctx: _ctx, accent: _accent, fmt: _fmt);
      case _PlanTab.loan:
        return _LoanSection(ctx: _ctx, accent: _accent, fmt: _fmt);
    }
  }
}

// ─── Goal Header ──────────────────────────────────────────────────────────────

class _GoalHeader extends StatelessWidget {
  final GoalEntity goal;
  final Color accent;
  final double pct;
  final NumberFormat fmt;
  final DateFormat dateFmt;
  final int? monthsRemaining;

  const _GoalHeader({
    required this.goal,
    required this.accent,
    required this.pct,
    required this.fmt,
    required this.dateFmt,
    required this.monthsRemaining,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, Color.lerp(accent, Colors.black, 0.35)!],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              Text(
                _goalEmoji(goal.goalType),
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  goal.name,
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '₹${fmt.format(goal.currentSaved)}',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                ' / ₹${fmt.format(goal.targetAmount)}',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              Text(
                '${(pct * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 12, color: Colors.white.withValues(alpha: 0.7)),
              const SizedBox(width: 4),
              Text(
                dateFmt.format(goal.deadline),
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              if (monthsRemaining != null) ...[
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$monthsRemaining months left',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Feasibility Banner ───────────────────────────────────────────────────────

class _FeasibilityBanner extends StatelessWidget {
  final GoalPlanContext ctx;
  final Color accent;
  const _FeasibilityBanner({required this.ctx, required this.accent});

  Color get _color {
    switch (ctx.feasibility) {
      case Feasibility.easy:    return const Color(0xFF0F9D58);
      case Feasibility.doable:  return const Color(0xFF0EA5E9);
      case Feasibility.stretch: return const Color(0xFFF2A104);
      case Feasibility.tough:   return const Color(0xFFE74C3C);
    }
  }

  IconData get _icon {
    switch (ctx.feasibility) {
      case Feasibility.easy:    return Icons.check_circle_rounded;
      case Feasibility.doable:  return Icons.thumb_up_rounded;
      case Feasibility.stretch: return Icons.warning_amber_rounded;
      case Feasibility.tough:   return Icons.error_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(_icon, color: _color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Feasibility: ${ctx.feasibility.label}',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ctx.feasibility.description,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Plan Tab Bar ─────────────────────────────────────────────────────────────

class _PlanTabBar extends StatelessWidget {
  final _PlanTab selected;
  final Color accent;
  final bool showLoan;
  final ValueChanged<_PlanTab> onSelect;

  const _PlanTabBar({
    required this.selected,
    required this.accent,
    required this.showLoan,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (_PlanTab.save, '💰', 'Save'),
      (_PlanTab.invest, '📈', 'Invest'),
      if (showLoan) (_PlanTab.loan, '🏦', 'Loan'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: tabs.map((entry) {
          final (tab, emoji, label) = entry;
          final isActive = selected == tab;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isActive ? accent : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isActive ? accent : AppColors.border,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isActive ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Save Plan Section ────────────────────────────────────────────────────────

class _SavePlanSection extends StatelessWidget {
  final GoalPlanContext ctx;
  final Color accent;
  final NumberFormat fmt;
  const _SavePlanSection(
      {required this.ctx, required this.accent, required this.fmt});

  static const _tips = [
    ('🍱', 'Cook at home 3×/week', 'Save ₹3,000–5,000/month on food delivery'),
    ('📺', 'Audit subscriptions', 'Cancel unused OTT/apps — save ₹1,500–3,000/month'),
    ('🛵', 'Use public transport 2×/week', 'Save ₹1,000–2,500/month on fuel & cabs'),
    ('☕', 'Skip café coffees', 'Brew at home — save ₹800–2,000/month'),
    ('🛍️', 'Apply 48-hour rule on purchases', 'Reduces impulse buys by up to 30%'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
              title: 'Savings Plan',
              subtitle: 'How to save your way to this goal',
              accent: accent),
          const SizedBox(height: 16),

          // Monthly target card
          _InfoCard(
            accent: accent,
            child: Row(
              children: [
                Expanded(
                  child: _StatColumn(
                    label: 'Monthly Target',
                    value: '₹${fmt.format(ctx.neededMonthly)}',
                    accent: accent,
                  ),
                ),
                Container(width: 1, height: 48, color: AppColors.border),
                Expanded(
                  child: _StatColumn(
                    label: 'Time Remaining',
                    value: '${ctx.monthsRemaining} months',
                    accent: accent,
                  ),
                ),
                Container(width: 1, height: 48, color: AppColors.border),
                Expanded(
                  child: _StatColumn(
                    label: 'Still Needed',
                    value: '₹${fmt.format(ctx.remainingAmount)}',
                    accent: accent,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Text(
            'Top expense cuts to free up budget',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ..._tips.map((t) => _ExpenseTipRow(
              emoji: t.$1, title: t.$2, subtitle: t.$3, accent: accent)),
        ],
      ),
    );
  }
}

// ─── Invest Plan Section ──────────────────────────────────────────────────────

class _InvestPlanSection extends StatelessWidget {
  final GoalPlanContext ctx;
  final Color accent;
  final NumberFormat fmt;
  const _InvestPlanSection(
      {required this.ctx, required this.accent, required this.fmt});

  List<_InvestOption> get _options {
    switch (ctx.goal.investmentSuggestion.toLowerCase()) {
      case 'equity':
        return [
          _InvestOption('📈', 'Equity SIP', '12–15% p.a.', 'Best for >36 month goals'),
          _InvestOption('🌐', 'Index Fund', '11–13% p.a.', 'Low-cost, diversified'),
        ];
      case 'hybrid_fund':
        return [
          _InvestOption('⚖️', 'Hybrid Fund SIP', '10–12% p.a.', 'Balanced risk + return'),
          _InvestOption('📊', 'Balanced Advantage', '9–11% p.a.', 'Auto-rebalances'),
        ];
      case 'rd':
        return [
          _InvestOption('🏦', 'Recurring Deposit', '6.5–7.5% p.a.', 'Safe, guaranteed returns'),
          _InvestOption('💡', 'Liquid Fund', '6–7% p.a.', 'Better than savings account'),
        ];
      case 'fd':
        return [
          _InvestOption('🔒', 'Fixed Deposit', '6.5–7.5% p.a.', 'Capital protected'),
          _InvestOption('🏦', 'Post Office TD', '7.5% p.a.', 'Government backed'),
        ];
      default:
        return [
          _InvestOption('💰', 'Liquid Fund', '6–7% p.a.', 'Park surplus here'),
          _InvestOption('🏦', 'RD / FD', '6.5–7.5% p.a.', 'Low risk, steady growth'),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final sipAmount = (ctx.neededMonthly * 0.6).clamp(500, double.infinity);
    final projected = sipAmount * ctx.monthsRemaining * 1.12;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
              title: 'Investment Plan',
              subtitle: _investmentLabel(ctx.goal.investmentSuggestion),
              accent: accent),
          const SizedBox(height: 16),

          _InfoCard(
            accent: accent,
            child: Row(
              children: [
                Expanded(
                  child: _StatColumn(
                    label: 'Suggested SIP',
                    value: '₹${fmt.format(sipAmount.roundToDouble())}',
                    accent: accent,
                  ),
                ),
                Container(width: 1, height: 48, color: AppColors.border),
                Expanded(
                  child: _StatColumn(
                    label: 'Projected Corpus',
                    value: '₹${fmt.format(projected.roundToDouble())}',
                    accent: accent,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Text(
            'Recommended instruments',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ..._options.map((o) => _InvestOptionRow(option: o, accent: accent)),
        ],
      ),
    );
  }
}

// ─── Loan Section ─────────────────────────────────────────────────────────────

class _LoanSection extends StatelessWidget {
  final GoalPlanContext ctx;
  final Color accent;
  final NumberFormat fmt;
  const _LoanSection(
      {required this.ctx, required this.accent, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final emi = ctx.estimatedLoanEmi;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
              title: ctx.loanType,
              subtitle: 'Borrow the gap, repay over time',
              accent: accent),
          const SizedBox(height: 16),

          _InfoCard(
            accent: accent,
            child: Row(
              children: [
                Expanded(
                  child: _StatColumn(
                    label: 'Loan Amount',
                    value: '₹${fmt.format(ctx.remainingAmount)}',
                    accent: accent,
                  ),
                ),
                Container(width: 1, height: 48, color: AppColors.border),
                Expanded(
                  child: _StatColumn(
                    label: 'Est. EMI @ 9%',
                    value: '₹${fmt.format(emi.roundToDouble())}',
                    accent: accent,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _ProConList(
            pros: [
              'Get your goal NOW without waiting',
              'Interest may be tax-deductible (home/education)',
              'Build credit history with on-time EMIs',
            ],
            cons: [
              'Total cost is higher due to interest',
              'EMI reduces monthly cash flow',
              'Loan approval depends on CIBIL score',
            ],
            accent: accent,
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.amber.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Consider saving 20–30% first, then taking a smaller loan to reduce EMI and total interest paid.',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Monthly Breakdown ────────────────────────────────────────────────────────

class _MonthlyBreakdown extends StatelessWidget {
  final GoalPlanContext ctx;
  final Color accent;
  final NumberFormat fmt;
  const _MonthlyBreakdown(
      {required this.ctx, required this.accent, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Monthly Income', '₹${fmt.format(ctx.monthlySalary)}', accent),
      ('Estimated Surplus (30%)', '₹${fmt.format(ctx.estimatedSurplus)}', AppColors.success),
      ('Monthly Needed for Goal', '₹${fmt.format(ctx.neededMonthly)}', AppColors.danger),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
              title: 'Monthly Breakdown',
              subtitle: 'Where your money fits in',
              accent: accent),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: rows.asMap().entries.map((e) {
                final i = e.key;
                final (label, value, color) = e.value;
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: i < rows.length - 1
                        ? Border(
                            bottom:
                                BorderSide(color: AppColors.border))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(label,
                            style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: AppColors.textSecondary)),
                      ),
                      Text(value,
                          style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: color)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AI CA Plan Section ───────────────────────────────────────────────────────

class _AiPlanSection extends StatelessWidget {
  final bool loading;
  final String? plan;
  final Color accent;
  final VoidCallback onTap;

  const _AiPlanSection({
    required this.loading,
    required this.plan,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
              title: 'AI CA Plan',
              subtitle: 'Personalised plan generated for you',
              accent: accent),
          const SizedBox(height: 14),
          if (plan != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Text(
                plan!,
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: AppColors.textPrimary, height: 1.6),
              ),
            )
          else
            GestureDetector(
              onTap: loading ? null : onTap,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent, Color.lerp(accent, Colors.black, 0.2)!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Text('🤖', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Get my personalised plan',
                            style: GoogleFonts.manrope(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'AI CA will generate savings milestones, investment picks, and expense cuts specific to your goal.',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.arrow_forward_ios_rounded,
                            color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Shared Small Widgets ─────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accent;
  const _SectionHeader(
      {required this.title, required this.subtitle, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            Text(subtitle,
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Color accent;
  final Widget child;
  const _InfoCard({required this.accent, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: child,
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  const _StatColumn(
      {required this.label, required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.manrope(
                fontSize: 15, fontWeight: FontWeight.w800, color: accent)),
        const SizedBox(height: 3),
        Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 10, color: AppColors.textSecondary),
            textAlign: TextAlign.center),
      ],
    );
  }
}

class _ExpenseTipRow extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color accent;
  const _ExpenseTipRow(
      {required this.emoji,
      required this.title,
      required this.subtitle,
      required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                Text(subtitle,
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              size: 18, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _InvestOption {
  final String emoji;
  final String name;
  final String returns;
  final String note;
  const _InvestOption(this.emoji, this.name, this.returns, this.note);
}

class _InvestOptionRow extends StatelessWidget {
  final _InvestOption option;
  final Color accent;
  const _InvestOptionRow({required this.option, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Text(option.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(option.name,
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                Text(option.note,
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(option.returns,
              style: GoogleFonts.manrope(
                  fontSize: 13, fontWeight: FontWeight.w700, color: accent)),
        ],
      ),
    );
  }
}

class _ProConList extends StatelessWidget {
  final List<String> pros;
  final List<String> cons;
  final Color accent;
  const _ProConList(
      {required this.pros, required this.cons, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _ProConColumn(label: '✅ Pros', items: pros, color: AppColors.success)),
        const SizedBox(width: 12),
        Expanded(child: _ProConColumn(label: '⚠️ Cons', items: cons, color: AppColors.danger)),
      ],
    );
  }
}

class _ProConColumn extends StatelessWidget {
  final String label;
  final List<String> items;
  final Color color;
  const _ProConColumn(
      {required this.label, required this.items, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.manrope(
                  fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• $item',
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: AppColors.textPrimary, height: 1.4)),
              )),
        ],
      ),
    );
  }
}
