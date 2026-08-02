import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/app_services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/repositories/health_score_repository.dart';
import '../../../goals/domain/entities/goal_entity.dart';

// ── Data Models ───────────────────────────────────────────────────────────────

class _Method {
  final String name;
  final String pros;
  final String cons;
  final String bestFor;
  const _Method({
    required this.name,
    required this.pros,
    this.cons = '',
    required this.bestFor,
  });
}

class _PartnerOffer {
  final String name;
  const _PartnerOffer(this.name);
}

class _Opportunity {
  final String id;
  final String title;
  final String reason;
  final String strength; // HIGH / MEDIUM / LOW
  final int score;       // 0–100 opportunity score
  final int healthScoreDelta;
  final int goalSuccessDelta;
  final double? gapAmount;
  final double? currentAmount;
  final double? targetAmount;
  final String? freedomDelta;
  final List<Color> gradient;
  final String emoji;
  final List<_Method> methods;
  final List<_PartnerOffer> partners;

  const _Opportunity({
    required this.id,
    required this.title,
    required this.reason,
    required this.strength,
    required this.score,
    required this.healthScoreDelta,
    required this.goalSuccessDelta,
    required this.gradient,
    required this.emoji,
    required this.methods,
    required this.partners,
    this.gapAmount,
    this.currentAmount,
    this.targetAmount,
    this.freedomDelta,
  });
}

// ── Rules Engine ──────────────────────────────────────────────────────────────

List<_Opportunity> _generateOpportunities({
  required HealthScoreModel health,
  required double salary,
  required List<GoalEntity> goals,
}) {
  final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  final ops = <_Opportunity>[];

  final savingsGap = 25 - health.savingsScore;
  final budgetGap = 25 - health.budgetScore;
  final goalGap = 25 - health.goalScore;
  final activityGap = 15 - health.activityScore;

  // ── 1. Emergency Fund ──────────────────────────────────────────────────────
  if (savingsGap >= 6) {
    final currentSaved = salary * 0.12 * 3;
    final targetSaved = salary * 6;
    final gap = max(0.0, targetSaved - currentSaved);
    final monthsToClose = gap > 0 ? (gap / (salary * 0.15)).ceil() : 0;
    ops.add(_Opportunity(
      id: 'emergency_fund',
      title: 'Build Emergency Fund',
      reason: 'Only $monthsToClose more months of disciplined saving reaches full 6-month protection.',
      strength: savingsGap >= 14 ? 'HIGH' : 'MEDIUM',
      score: (90 - health.savingsScore * 2).clamp(30, 95),
      healthScoreDelta: (savingsGap * 0.7).round(),
      goalSuccessDelta: 35,
      currentAmount: currentSaved,
      targetAmount: targetSaved,
      gapAmount: gap,
      freedomDelta: '2039 → 2037',
      gradient: const [Color(0xFF0F9D58), Color(0xFF005F3D)],
      emoji: '🛡️',
      methods: const [
        _Method(
          name: 'Recurring Deposit',
          pros: 'Guaranteed returns, zero market risk',
          bestFor: '12–18 month timeline',
        ),
        _Method(
          name: 'Liquid Mutual Fund',
          pros: 'Flexible, better liquidity than RD',
          bestFor: 'Unknown timeline',
        ),
        _Method(
          name: 'High-Yield Savings Account',
          pros: 'Instant access, FDIC-style protection',
          cons: 'Lower return than other options',
          bestFor: 'Immediate safety net',
        ),
      ],
      partners: const [
        _PartnerOffer('SBI'),
        _PartnerOffer('HDFC'),
        _PartnerOffer('Axis'),
        _PartnerOffer('ICICI'),
      ],
    ));
  }

  // ── 2. Increase Monthly SIP ────────────────────────────────────────────────
  if (goalGap >= 6 || health.goalScore < 15) {
    final currentSIP = salary * 0.08;
    final targetSIP = salary * 0.15;
    final gapSIP = max(0.0, targetSIP - currentSIP);
    ops.add(_Opportunity(
      id: 'increase_sip',
      title: 'Increase Monthly Investment',
      reason: 'You\'re investing ${fmt.format(gapSIP)} less than required to hit wealth targets on schedule.',
      strength: goalGap >= 14 ? 'HIGH' : 'MEDIUM',
      score: (85 - health.goalScore).clamp(30, 90),
      healthScoreDelta: (goalGap * 0.6).round(),
      goalSuccessDelta: 42,
      currentAmount: currentSIP,
      targetAmount: targetSIP,
      gapAmount: gapSIP,
      freedomDelta: '2042 → 2038',
      gradient: const [Color(0xFF1565C0), Color(0xFF0D47A1)],
      emoji: '📈',
      methods: const [
        _Method(
          name: 'Index Fund SIP',
          pros: 'Low cost, market-matched returns',
          bestFor: 'Long term (7+ years)',
        ),
        _Method(
          name: 'ELSS Fund',
          pros: 'Tax benefit under Section 80C',
          bestFor: 'Tax optimization + growth',
        ),
        _Method(
          name: 'PPF',
          pros: 'Guaranteed, completely tax-free',
          cons: '15-year lock-in',
          bestFor: 'Risk-free retirement corpus',
        ),
      ],
      partners: const [
        _PartnerOffer('Zerodha Coin'),
        _PartnerOffer('Groww'),
        _PartnerOffer('Mirae Asset'),
        _PartnerOffer('UTI'),
      ],
    ));
  }

  // ── 3. Reduce Budget Leakage ───────────────────────────────────────────────
  if (budgetGap >= 10) {
    final leaked = salary * 0.12;
    ops.add(_Opportunity(
      id: 'budget_leakage',
      title: 'Plug Budget Leakage',
      reason: '~${fmt.format(leaked)}/month is leaving without building any future value.',
      strength: 'MEDIUM',
      score: (70 - health.budgetScore).clamp(20, 78),
      healthScoreDelta: (budgetGap * 0.5).round(),
      goalSuccessDelta: 18,
      gapAmount: leaked,
      gradient: const [Color(0xFFE65100), Color(0xFFC62828)],
      emoji: '🔒',
      methods: const [
        _Method(
          name: 'Zero-Based Budgeting',
          pros: 'Every rupee has an assigned job',
          bestFor: 'High earners who overspend',
        ),
        _Method(
          name: '50-30-20 Rule',
          pros: 'Simple and automatic to follow',
          bestFor: 'First-time budgeters',
        ),
        _Method(
          name: 'Envelope Method',
          pros: 'Physical discipline, hard limit per category',
          bestFor: 'Impulsive spenders',
        ),
      ],
      partners: const [
        _PartnerOffer('PennyWise Budget'),
        _PartnerOffer('Fi Money'),
        _PartnerOffer('Jupiter'),
      ],
    ));
  }

  // ── 4. Tax Optimisation ────────────────────────────────────────────────────
  if (salary >= 50000) {
    final taxSaving = min(46800.0, salary * 12 * 0.30);
    ops.add(_Opportunity(
      id: 'tax_elss',
      title: 'Save ₹${(taxSaving / 1000).toStringAsFixed(0)}K in Tax',
      reason: 'Investing ₹1.5L in ELSS this year eliminates ${fmt.format(taxSaving)} in tax — legally.',
      strength: 'MEDIUM',
      score: 65,
      healthScoreDelta: 5,
      goalSuccessDelta: 22,
      currentAmount: 0,
      targetAmount: 150000,
      gapAmount: taxSaving,
      gradient: const [Color(0xFF4527A0), Color(0xFF311B92)],
      emoji: '🧮',
      methods: const [
        _Method(
          name: 'ELSS Fund (80C)',
          pros: 'Lowest lock-in (3 yrs), market returns',
          bestFor: 'Young professionals, tax-first investors',
        ),
        _Method(
          name: 'PPF (80C)',
          pros: 'Guaranteed, tax-free maturity',
          cons: '15-year lock-in',
          bestFor: 'Conservative long-term savers',
        ),
        _Method(
          name: 'NPS (80CCD)',
          pros: 'Extra ₹50K deduction beyond 80C limit',
          bestFor: 'Retirement-focused planning',
        ),
      ],
      partners: const [
        _PartnerOffer('Mirae Asset'),
        _PartnerOffer('Quant'),
        _PartnerOffer('Axis'),
        _PartnerOffer('HDFC'),
      ],
    ));
  }

  // ── 5. Automate Savings (low activity) ─────────────────────────────────────
  if (activityGap >= 6) {
    ops.add(_Opportunity(
      id: 'auto_save',
      title: 'Automate Monthly Savings',
      reason: 'Automating on salary day increases savings rate by 40% — removes the willpower dependency.',
      strength: 'MEDIUM',
      score: 60,
      healthScoreDelta: (activityGap * 0.4).round(),
      goalSuccessDelta: 25,
      gradient: const [Color(0xFF00695C), Color(0xFF004D40)],
      emoji: '⚡',
      methods: const [
        _Method(
          name: 'Auto-Debit SIP',
          pros: 'Set once, runs forever — zero effort',
          bestFor: 'Anyone who forgets to invest',
        ),
        _Method(
          name: 'Bank Standing Instruction',
          pros: 'Bank-level reliability, no apps needed',
          bestFor: 'Fixed monthly saving targets',
        ),
        _Method(
          name: 'Round-Up Saving',
          pros: 'Painless micro-savings on every transaction',
          bestFor: 'Low surplus situations',
        ),
      ],
      partners: const [
        _PartnerOffer('Fi Money'),
        _PartnerOffer('Jupiter'),
        _PartnerOffer('NAVI'),
        _PartnerOffer('Jar'),
      ],
    ));
  }

  ops.sort((a, b) => b.score.compareTo(a.score));
  return ops.isNotEmpty ? ops : _fallbackOpportunities();
}

List<_Opportunity> _fallbackOpportunities() => const [
  _Opportunity(
    id: 'start_investing',
    title: 'Start Your Investment Journey',
    reason: 'Starting with ₹500/month today beats waiting until you earn more.',
    strength: 'HIGH',
    score: 80,
    healthScoreDelta: 12,
    goalSuccessDelta: 30,
    gradient: [Color(0xFF0F9D58), Color(0xFF005F3D)],
    emoji: '🚀',
    methods: [
      _Method(name: 'Index Fund SIP', pros: 'Low cost, proven over decades', bestFor: 'Beginners'),
      _Method(name: 'Recurring Deposit', pros: 'Safe, guaranteed return', bestFor: 'Risk-averse starters'),
    ],
    partners: [
      _PartnerOffer('Groww'),
      _PartnerOffer('Zerodha'),
      _PartnerOffer('Paytm Money'),
    ],
  ),
];

// ── Main Widget ───────────────────────────────────────────────────────────────

class FinancialOpportunityCarousel extends StatefulWidget {
  const FinancialOpportunityCarousel({
    super.key,
    required this.salary,
    this.healthScore,
  });

  final double salary;
  final HealthScoreModel? healthScore;

  @override
  State<FinancialOpportunityCarousel> createState() =>
      _FinancialOpportunityCarouselState();
}

class _FinancialOpportunityCarouselState
    extends State<FinancialOpportunityCarousel> {
  final _ctrl = PageController(viewportFraction: 0.88);
  int _page = 0;
  Timer? _timer;
  bool _userScrolling = false;
  List<_Opportunity> _opps = _fallbackOpportunities();

  @override
  void initState() {
    super.initState();
    _build();
    _startTimer();
  }

  @override
  void didUpdateWidget(FinancialOpportunityCarousel old) {
    super.didUpdateWidget(old);
    if (old.healthScore != widget.healthScore || old.salary != widget.salary) {
      _build();
    }
  }

  Future<void> _build() async {
    final health = widget.healthScore;
    if (health == null) return;
    try {
      final goals = await AppServices.instance.goals.getAll();
      if (!mounted) return;
      setState(() {
        _opps = _generateOpportunities(
          health: health,
          salary: widget.salary,
          goals: goals,
        );
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _opps = _generateOpportunities(
            health: health,
            salary: widget.salary,
            goals: const [],
          );
        });
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_userScrolling || !mounted || _opps.isEmpty) return;
      final next = (_page + 1) % _opps.length;
      _ctrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Financial Opportunities',
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Ranked by impact on your financial future',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _DotIndicator(count: _opps.length, current: _page),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Carousel
        SizedBox(
          height: 220,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is ScrollStartNotification) _userScrolling = true;
              if (n is ScrollEndNotification) {
                _userScrolling = false;
                _startTimer();
              }
              return false;
            },
            child: PageView.builder(
              controller: _ctrl,
              itemCount: _opps.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) => AnimatedScale(
                scale: i == _page ? 1.0 : 0.95,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: _OpportunityCard(
                  opp: _opps[i],
                  onTap: () => _openDetail(context, _opps[i]),
                ),
              ),
            ),
          ),
        ),

        // Opportunity Score Leaderboard
        if (_opps.length > 1) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _OpportunityRanking(opps: _opps),
          ),
        ],
      ],
    );
  }

  void _openDetail(BuildContext context, _Opportunity opp) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OpportunityDetailSheet(opp: opp, salary: widget.salary),
    );
  }
}

// ── Opportunity Card (carousel item) ─────────────────────────────────────────

class _OpportunityCard extends StatelessWidget {
  const _OpportunityCard({required this.opp, required this.onTap});
  final _Opportunity opp;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strengthColor = opp.strength == 'HIGH'
        ? const Color(0xFFFF6B6B)
        : opp.strength == 'MEDIUM'
            ? const Color(0xFFFFA726)
            : const Color(0xFF66BB6A);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: opp.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: opp.gradient.first.withValues(alpha: 0.32),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // Decorative blobs
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              left: -20,
              bottom: -40,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top: strength pill + emoji
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: strengthColor.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: strengthColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: strengthColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${opp.strength} IMPACT',
                              style: GoogleFonts.dmSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: strengthColor,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(opp.emoji, style: const TextStyle(fontSize: 24)),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Title
                  Text(
                    opp.title,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                      height: 1.15,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Reason
                  Text(
                    opp.reason,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.72),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const Spacer(),

                  // Impact pills row
                  Row(
                    children: [
                      _ImpactPill(
                        label: 'Health Score',
                        value: '+${opp.healthScoreDelta} pts',
                      ),
                      const SizedBox(width: 8),
                      _ImpactPill(
                        label: 'Goal Success',
                        value: '+${opp.goalSuccessDelta}%',
                      ),
                      const Spacer(),
                      // "Open" chevron
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ],
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

class _ImpactPill extends StatelessWidget {
  const _ImpactPill({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 8,
              color: Colors.white.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Opportunity Score Ranking ─────────────────────────────────────────────────

class _OpportunityRanking extends StatelessWidget {
  const _OpportunityRanking({required this.opps});
  final List<_Opportunity> opps;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Opportunity Score',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < opps.length; i++) ...[
            _RankingRow(opp: opps[i], rank: i + 1),
            if (i < opps.length - 1)
              Divider(
                height: 14,
                thickness: 1,
                color: AppColors.border.withValues(alpha: 0.5),
              ),
          ],
        ],
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({required this.opp, required this.rank});
  final _Opportunity opp;
  final int rank;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Rank badge
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: opp.gradient),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              '$rank',
              style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Title
        Expanded(
          child: Text(
            '${opp.emoji}  ${opp.title}',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        // Score bar + number
        SizedBox(
          width: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 48,
                height: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: opp.score / 100,
                    backgroundColor: AppColors.surfaceElevated,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(opp.gradient.first),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                '${opp.score}',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: opp.gradient.first,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Detail Bottom Sheet ───────────────────────────────────────────────────────

class _OpportunityDetailSheet extends StatelessWidget {
  const _OpportunityDetailSheet({required this.opp, required this.salary});
  final _Opportunity opp;
  final double salary;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final strengthColor = opp.strength == 'HIGH'
        ? const Color(0xFFFF6B6B)
        : opp.strength == 'MEDIUM'
            ? const Color(0xFFFFA726)
            : const Color(0xFF66BB6A);

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.94,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 4),

              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
                  children: [
                    // ── Header ────────────────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          opp.emoji,
                          style: const TextStyle(fontSize: 36),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color:
                                      strengthColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: strengthColor.withValues(
                                          alpha: 0.3)),
                                ),
                                child: Text(
                                  '${opp.strength} IMPACT',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: strengthColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                opp.title,
                                style: GoogleFonts.manrope(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.4,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Why Now ───────────────────────────────────────────
                    _SheetSection(
                      label: 'WHY NOW',
                      child: Text(
                        opp.reason,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          height: 1.6,
                        ),
                      ),
                    ),

                    // ── Current / Target / Gap ────────────────────────────
                    if (opp.currentAmount != null || opp.gapAmount != null) ...[
                      const SizedBox(height: 18),
                      _SheetSection(
                        label: 'YOUR POSITION',
                        child: _PositionRow(
                          current: opp.currentAmount != null
                              ? fmt.format(opp.currentAmount)
                              : null,
                          target: opp.targetAmount != null
                              ? fmt.format(opp.targetAmount)
                              : null,
                          gap: opp.gapAmount != null
                              ? fmt.format(opp.gapAmount)
                              : null,
                          gradient: opp.gradient,
                        ),
                      ),
                    ],

                    // ── If Completed ──────────────────────────────────────
                    const SizedBox(height: 18),
                    _SheetSection(
                      label: 'IF YOU DO THIS',
                      child: Column(
                        children: [
                          _ImpactRow(
                            label: 'Health Score',
                            value: '+${opp.healthScoreDelta} pts',
                            color: AppColors.success,
                          ),
                          const SizedBox(height: 8),
                          _ImpactRow(
                            label: 'Goal Success Rate',
                            value: '+${opp.goalSuccessDelta}%',
                            color: AppColors.primary,
                          ),
                          if (opp.freedomDelta != null) ...[
                            const SizedBox(height: 8),
                            _ImpactRow(
                              label: 'Freedom Date',
                              value: opp.freedomDelta!,
                              color: AppColors.amber,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // ── Recommended Methods ───────────────────────────────
                    const SizedBox(height: 20),
                    _SheetSection(
                      label: 'RECOMMENDED METHODS',
                      child: Column(
                        children: opp.methods
                            .map((m) => _MethodCard(method: m))
                            .toList(),
                      ),
                    ),

                    // ── Partner Options (last, subdued) ───────────────────
                    if (opp.partners.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _SheetSection(
                        label: 'AVAILABLE THROUGH',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: opp.partners
                              .map((p) => _PartnerChip(name: p.name))
                              .toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SheetSection extends StatelessWidget {
  const _SheetSection({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        child,
        const SizedBox(height: 2),
        const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}

class _PositionRow extends StatelessWidget {
  const _PositionRow({
    required this.current,
    required this.target,
    required this.gap,
    required this.gradient,
  });
  final String? current, target, gap;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (current != null) _PositionCell(label: 'Current', value: current!, gradient: gradient),
        if (current != null && target != null) const SizedBox(width: 10),
        if (target != null) _PositionCell(label: 'Target', value: target!, gradient: gradient),
        if (gap != null) ...[
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: gradient.first.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: gradient.first.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gap',
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    gap!,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: gradient.first,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PositionCell extends StatelessWidget {
  const _PositionCell({required this.label, required this.value, required this.gradient});
  final String label, value;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImpactRow extends StatelessWidget {
  const _ImpactRow({required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({required this.method});
  final _Method method;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            method.name,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          if (method.pros.isNotEmpty)
            _MethodDetail(icon: Icons.check_circle_outline_rounded, text: method.pros, color: AppColors.success),
          if (method.cons.isNotEmpty) ...[
            const SizedBox(height: 3),
            _MethodDetail(icon: Icons.info_outline_rounded, text: method.cons, color: AppColors.warning),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'Best for: ',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                method.bestFor,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MethodDetail extends StatelessWidget {
  const _MethodDetail({required this.icon, required this.text, required this.color});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _PartnerChip extends StatelessWidget {
  const _PartnerChip({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        name,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ── Dot Indicator ─────────────────────────────────────────────────────────────

class _DotIndicator extends StatelessWidget {
  const _DotIndicator({required this.count, required this.current});
  final int count, current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(left: 4),
          width: active ? 16 : 5,
          height: 5,
          decoration: BoxDecoration(
            color: active
                ? AppColors.orange
                : AppColors.orange.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
