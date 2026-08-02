import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

// ── Data Model ────────────────────────────────────────────────────────────────

enum _GoalType { emergencyFund, longTermWealth, savingsHabit, taxSaving, goldHedge, spendSmart }

class _BankProgram {
  final String id;
  final String bankName;
  final String bankInitials;
  final Color bankColor;
  final Color bankColorDark;
  final String productName;
  final String productEmoji;
  final String keyMetric;       // "7.1% p.a." or "₹1.75 Cr in 20 yrs"
  final String keyMetricLabel;  // "Guaranteed return" or "SIP projection"
  final String tagline;
  final String goalChip;        // "Emergency Fund" / "Long-term Wealth"
  final _GoalType goalType;
  final String whatYouGet;
  final String howItHelps;
  final List<String> quickFacts;
  final String ctaLabel;

  const _BankProgram({
    required this.id,
    required this.bankName,
    required this.bankInitials,
    required this.bankColor,
    required this.bankColorDark,
    required this.productName,
    required this.productEmoji,
    required this.keyMetric,
    required this.keyMetricLabel,
    required this.tagline,
    required this.goalChip,
    required this.goalType,
    required this.whatYouGet,
    required this.howItHelps,
    required this.quickFacts,
    required this.ctaLabel,
  });
}

const _programs = <_BankProgram>[
  _BankProgram(
    id: 'hdfc_rd',
    bankName: 'HDFC Bank',
    bankInitials: 'HDFC',
    bankColor: Color(0xFF004C8F),
    bankColorDark: Color(0xFF002D57),
    productName: 'Recurring Deposit',
    productEmoji: '🏦',
    keyMetric: '7.1% p.a.',
    keyMetricLabel: 'Guaranteed return',
    tagline: 'Safe, predictable savings — zero market risk',
    goalChip: 'Emergency Fund',
    goalType: _GoalType.emergencyFund,
    whatYouGet: 'A fixed monthly deposit for 12–24 months at 7.1% guaranteed interest. Mature into cash you can access the day your emergency hits.',
    howItHelps: 'Your emergency fund should never fluctuate. An RD locks in growth while keeping the money accessible — ideal for building your 6-month buffer.',
    quickFacts: [
      'Open in 5 min via HDFC netbanking',
      'Min ₹500/month',
      'Premature withdrawal allowed',
      'TDS applies above ₹40,000/year',
    ],
    ctaLabel: 'Compare RD Rates',
  ),
  _BankProgram(
    id: 'nippon_sip',
    bankName: 'Nippon India MF',
    bankInitials: 'NI',
    bankColor: Color(0xFFE63012),
    bankColorDark: Color(0xFFAF1C08),
    productName: 'Nifty 50 Index SIP',
    productEmoji: '📈',
    keyMetric: '₹5K → ₹1.75 Cr',
    keyMetricLabel: '20-year SIP projection',
    tagline: 'Own all of India\'s top 50 companies for ₹100/day',
    goalChip: 'Long-term Wealth',
    goalType: _GoalType.longTermWealth,
    whatYouGet: 'A monthly SIP into Nippon India Nifty 50 Index Fund — one of India\'s lowest-cost index funds tracking the NSE Nifty 50. Mirrors the entire Indian large-cap market.',
    howItHelps: 'Index funds outperform 85% of actively managed funds over 10+ years. You capture Indian market growth without paying a fund manager to guess.',
    quickFacts: [
      'Expense ratio: 0.20% (lowest tier)',
      'Start from ₹100/month',
      'Auto-debit on salary date',
      '0% entry load, 1% exit load < 1 yr',
    ],
    ctaLabel: 'Start SIP',
  ),
  _BankProgram(
    id: 'jar_gold',
    bankName: 'Jar · Digital Gold',
    bankInitials: 'JAR',
    bankColor: Color(0xFFB45309),
    bankColorDark: Color(0xFF7C3A00),
    productName: 'Digital Gold SIP',
    productEmoji: '🥇',
    keyMetric: '12.4% CAGR',
    keyMetricLabel: '10-year gold return',
    tagline: 'Inflation hedge that never rusts or needs a locker',
    goalChip: 'Wealth Preservation',
    goalType: _GoalType.goldHedge,
    whatYouGet: '99.9% pure 24K gold stored in Brink\'s vaults. Buy as little as ₹1. Sell anytime, take delivery, or convert to jewellery.',
    howItHelps: 'Gold has beaten Indian inflation for 30+ years. A 5–10% gold allocation stabilises your portfolio when equity markets fall. Jar rounds up every UPI transaction to save automatically.',
    quickFacts: [
      'Backed by MMTC-PAMP certified gold',
      'Round-up saving on every transaction',
      'Free delivery above 1g',
      'No GST on selling',
    ],
    ctaLabel: 'See Gold Price',
  ),
  _BankProgram(
    id: 'axis_elss',
    bankName: 'Axis Mutual Fund',
    bankInitials: 'AXIS',
    bankColor: Color(0xFF8B0000),
    bankColorDark: Color(0xFF5C0000),
    productName: 'ELSS Tax Saver Fund',
    productEmoji: '🧮',
    keyMetric: '₹46,800 saved',
    keyMetricLabel: 'Max annual tax saving',
    tagline: 'Invest ₹1.5L, save ₹46,800 tax — every year',
    goalChip: 'Tax Saving',
    goalType: _GoalType.taxSaving,
    whatYouGet: 'An Equity-Linked Savings Scheme (ELSS) that qualifies for ₹1.5L deduction under Section 80C. Shortest lock-in (3 years) among all 80C options, with equity-linked growth.',
    howItHelps: 'ELSS gives you the same tax benefit as PPF but with equity returns — historically 12–15% over 10 years. You pay less tax and build more wealth simultaneously.',
    quickFacts: [
      '3-year lock-in (shortest in 80C)',
      'Can redeem in parts after lock-in',
      'Both lump-sum and SIP allowed',
      'LTCG tax at 10% above ₹1L gains',
    ],
    ctaLabel: 'Check 80C Limit',
  ),
  _BankProgram(
    id: 'fi_auto_save',
    bankName: 'Fi Money',
    bankInitials: 'Fi',
    bankColor: Color(0xFF0D9488),
    bankColorDark: Color(0xFF0A7570),
    productName: 'Smart Deposit (Auto-Save)',
    productEmoji: '⚡',
    keyMetric: '6.5% p.a.',
    keyMetricLabel: 'On auto-saved balance',
    tagline: 'Savings happen automatically — no willpower needed',
    goalChip: 'Daily Discipline',
    goalType: _GoalType.savingsHabit,
    whatYouGet: 'Fi\'s Smart Deposit auto-moves money to a 6.5% FD the moment your salary hits. Round-up savings on every spend. Withdraw anytime with 1-day notice.',
    howItHelps: 'Automating savings on salary day — before you have a chance to spend — increases your savings rate by 40% compared to saving "what\'s left at month end".',
    quickFacts: [
      'Zero penalty for early withdrawal',
      'Round-up saving on every spend',
      'Monthly interest credited',
      'FDIC-equivalent DICGC insured',
    ],
    ctaLabel: 'Open Fi Account',
  ),
  _BankProgram(
    id: 'icici_amazon_cc',
    bankName: 'ICICI Bank',
    bankInitials: 'ICICI',
    bankColor: Color(0xFFB44F00),
    bankColorDark: Color(0xFF7A3500),
    productName: 'Amazon Pay Credit Card',
    productEmoji: '💳',
    keyMetric: 'Up to 5%',
    keyMetricLabel: 'Cashback on every spend',
    tagline: 'Earn ₹12,000–18,000/year on money you\'d spend anyway',
    goalChip: 'Spend Smarter',
    goalType: _GoalType.spendSmart,
    whatYouGet: '5% cashback on Amazon + 2% on Prime purchases + 1% everywhere else. No annual fee for Prime members. Cashback credited as Amazon Pay balance.',
    howItHelps: 'A zero-fee cashback card captures value on existing spending and redirects it toward your goals — only if you pay in full every month.',
    quickFacts: [
      'Zero annual fee (lifetime free for Prime)',
      'Cashback in 3 days, auto-applied',
      'No forex markup on international spend',
      'Never carry a balance — always pay in full',
    ],
    ctaLabel: 'Check Eligibility',
  ),
];

// ── Main Widget ───────────────────────────────────────────────────────────────

class BankProgramSlider extends StatefulWidget {
  const BankProgramSlider({super.key});

  @override
  State<BankProgramSlider> createState() => _BankProgramSliderState();
}

class _BankProgramSliderState extends State<BankProgramSlider> {
  final _ctrl = PageController(viewportFraction: 0.86);
  int _page = 0;
  Timer? _timer;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_dragging || !mounted) return;
      final next = (_page + 1) % _programs.length;
      _ctrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section Header ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Programs For Your Goals',
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Matched to what you\'re trying to achieve',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _PillDots(count: _programs.length, current: _page),
            ],
          ),
        ),

        // ── Carousel ──────────────────────────────────────────────────────
        SizedBox(
          height: 246,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is ScrollStartNotification) _dragging = true;
              if (n is ScrollEndNotification) {
                _dragging = false;
                _startTimer();
              }
              return false;
            },
            child: PageView.builder(
              controller: _ctrl,
              itemCount: _programs.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (ctx, i) {
                final active = i == _page;
                return AnimatedScale(
                  scale: active ? 1.0 : 0.95,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: _ProgramCard(
                    program: _programs[i],
                    onLearnMore: () => _openDetail(ctx, _programs[i]),
                  ),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ── Goal Filter Tabs ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _GoalTabs(
            programs: _programs,
            selected: _page,
            onSelect: (i) {
              _ctrl.animateToPage(
                i,
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutCubic,
              );
            },
          ),
        ),
      ],
    );
  }

  void _openDetail(BuildContext ctx, _BankProgram p) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProgramDetailSheet(program: p),
    );
  }
}

// ── Program Card ──────────────────────────────────────────────────────────────

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({required this.program, required this.onLearnMore});
  final _BankProgram program;
  final VoidCallback onLearnMore;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onLearnMore,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: program.bankColor.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Visual image area ────────────────────────────────────────
            _ProgramImageArea(program: program),

            // ── Card body ────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Goal context chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.30),
                        ),
                      ),
                      child: Text(
                        '🎯  ${program.goalChip}',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 7),

                    // Product name
                    Text(
                      '${program.bankName} · ${program.productName}',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 3),

                    // Tagline
                    Text(
                      program.tagline,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

                    // CTA row
                    Row(
                      children: [
                        Expanded(
                          child: _CTAButton(
                            label: program.ctaLabel,
                            isPrimary: false,
                            color: program.bankColor,
                            onTap: onLearnMore,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _CTAButton(
                          label: 'Learn',
                          isPrimary: true,
                          color: program.bankColor,
                          onTap: onLearnMore,
                        ),
                      ],
                    ),
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

// ── Visual Image Area ─────────────────────────────────────────────────────────

class _ProgramImageArea extends StatelessWidget {
  const _ProgramImageArea({required this.program});
  final _BankProgram program;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [program.bankColor, program.bankColorDark],
        ),
      ),
      child: Stack(
        children: [
          // Large decorative circle (top-right)
          Positioned(
            right: -28,
            top: -28,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          // Small circle (bottom-left)
          Positioned(
            left: -18,
            bottom: -22,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                // Bank logo block
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Text(
                    program.bankInitials,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                const Spacer(),

                // Key metric (the headline number)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      program.keyMetric,
                      style: GoogleFonts.manrope(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      program.keyMetricLabel,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.70),
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 12),

                // Product emoji in circle
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      program.productEmoji,
                      style: const TextStyle(fontSize: 22),
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

// ── CTA Button ────────────────────────────────────────────────────────────────

class _CTAButton extends StatelessWidget {
  const _CTAButton({
    required this.label,
    required this.isPrimary,
    required this.color,
    required this.onTap,
  });
  final String label;
  final bool isPrimary;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isPrimary ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: isPrimary
              ? null
              : Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isPrimary ? Colors.white : color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ── Goal Filter Tabs ──────────────────────────────────────────────────────────

class _GoalTabs extends StatelessWidget {
  const _GoalTabs({
    required this.programs,
    required this.selected,
    required this.onSelect,
  });
  final List<_BankProgram> programs;
  final int selected;
  final void Function(int) onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(programs.length, (i) {
          final p = programs[i];
          final active = i == selected;
          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: active
                    ? p.bankColor.withValues(alpha: 0.10)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active
                      ? p.bankColor.withValues(alpha: 0.40)
                      : AppColors.border,
                  width: active ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(p.productEmoji,
                      style: TextStyle(fontSize: active ? 13 : 12)),
                  const SizedBox(width: 6),
                  Text(
                    p.bankInitials,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight:
                          active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? p.bankColor : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Dot Indicators ────────────────────────────────────────────────────────────

class _PillDots extends StatelessWidget {
  const _PillDots({required this.count, required this.current});
  final int count, current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(left: 4),
          width: active ? 16 : 5,
          height: 5,
          decoration: BoxDecoration(
            color: active
                ? AppColors.secondary
                : AppColors.secondary.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

// ── Detail Bottom Sheet ───────────────────────────────────────────────────────

class _ProgramDetailSheet extends StatelessWidget {
  const _ProgramDetailSheet({required this.program});
  final _BankProgram program;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.80,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
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
              // Detail header image
              const SizedBox(height: 4),
              Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [program.bankColor, program.bankColorDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 14),
                  child: Row(
                    children: [
                      Text(
                        program.productEmoji,
                        style: const TextStyle(fontSize: 38),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              program.bankName,
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.65),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              program.productName,
                              style: GoogleFonts.manrope(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            program.keyMetric,
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                          ),
                          Text(
                            program.keyMetricLabel,
                            style: GoogleFonts.dmSans(
                              fontSize: 9,
                              color: Colors.white.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
                  children: [
                    // Goal context
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.20),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text('🎯', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Matched to: ${program.goalChip}',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accent,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  program.howItHelps,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 1. What you get
                    _DetailSection(
                      label: 'WHAT YOU GET',
                      accentColor: program.bankColor,
                      child: Text(
                        program.whatYouGet,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          height: 1.65,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 2. Quick facts
                    _DetailSection(
                      label: 'QUICK FACTS',
                      accentColor: program.bankColor,
                      child: Column(
                        children: program.quickFacts
                            .map((f) => _FactRow(
                                  text: f,
                                  color: program.bankColor,
                                ))
                            .toList(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // CTA (Explain → Compare → Apply hierarchy)
                    _CTASection(program: program),
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

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.label,
    required this.accentColor,
    required this.child,
  });
  final String label;
  final Color accentColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 12,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
        const SizedBox(height: 2),
        const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CTASection extends StatelessWidget {
  const _CTASection({required this.program});
  final _BankProgram program;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Primary CTA
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [program.bankColor, program.bankColorDark],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  program.ctaLabel,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Secondary CTA
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: program.bankColor.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: program.bankColor.withValues(alpha: 0.22),
                ),
              ),
              child: Center(
                child: Text(
                  'Not right now',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Trust note
        Text(
          'PennyWise earns nothing from this. We show this because it matched your goals — not because of a partnership.',
          style: GoogleFonts.dmSans(
            fontSize: 11,
            color: AppColors.textMuted,
            height: 1.5,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
