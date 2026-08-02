import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/app_services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../goals/domain/entities/goal_entity.dart';

// ── Product Catalogue ─────────────────────────────────────────────────────────

class _Product {
  final String id;
  final String category;        // display label
  final String title;
  final String tagline;         // the single compelling stat
  final String benefit;         // one-sentence why it matters
  final String ctaLabel;        // explain-first: "Explore", "Compare", "See How"
  final List<Color> gradient;
  final IconData icon;
  final String? partner;        // bank/provider — shown last, subdued
  final List<String> goalTypes; // which goal types this card serves

  const _Product({
    required this.id,
    required this.category,
    required this.title,
    required this.tagline,
    required this.benefit,
    required this.ctaLabel,
    required this.gradient,
    required this.icon,
    this.partner,
    this.goalTypes = const [],
  });
}

const _catalogue = [
  _Product(
    id: 'sip_mf',
    category: 'MUTUAL FUNDS',
    title: 'Start a Monthly SIP',
    tagline: '₹500/mo → ₹14.8 L in 15 yrs',
    benefit: 'Compounding at 12% p.a. turns small habits into serious wealth.',
    ctaLabel: 'Explore SIPs',
    gradient: [Color(0xFF0F9D58), Color(0xFF00796B)],
    icon: Icons.trending_up_rounded,
    partner: 'via Zerodha Coin · Groww',
    goalTypes: ['INVESTMENT', 'WEALTH', 'RETIREMENT', 'EDUCATION'],
  ),
  _Product(
    id: 'rd_savings',
    category: 'RECURRING DEPOSIT',
    title: 'Lock in 7.5% p.a.',
    tagline: '₹3,000/mo → guaranteed growth',
    benefit: 'No market risk, fixed returns, auto-deducted every month.',
    ctaLabel: 'See RD Rates',
    gradient: [Color(0xFF1565C0), Color(0xFF0288D1)],
    icon: Icons.account_balance_rounded,
    partner: 'via SBI · HDFC · ICICI',
    goalTypes: ['EMERGENCY_FUND', 'SAVINGS', 'SHORT_TERM'],
  ),
  _Product(
    id: 'digital_gold',
    category: 'DIGITAL GOLD',
    title: 'Buy Gold from ₹10',
    tagline: 'Inflation hedge, 0 storage cost',
    benefit: 'Gold has outpaced inflation by 8% per year over 20 years.',
    ctaLabel: 'Learn About Gold',
    gradient: [Color(0xFFF57F17), Color(0xFFE65100)],
    icon: Icons.circle_rounded,
    partner: 'via MMTC-PAMP · SafeGold',
    goalTypes: ['WEALTH', 'INVESTMENT', 'LONG_TERM'],
  ),
  _Product(
    id: 'elss_tax',
    category: 'TAX SAVER (ELSS)',
    title: 'Save ₹46,800 in Tax',
    tagline: 'U/s 80C: invest ₹1.5 L, save big',
    benefit: 'Lowest lock-in (3 yrs) among 80C options, market-linked returns.',
    ctaLabel: 'Explore ELSS',
    gradient: [Color(0xFF4527A0), Color(0xFF6A1B9A)],
    icon: Icons.receipt_long_rounded,
    partner: 'via Mirae · Axis · Quant',
    goalTypes: ['TAX_SAVING', 'INVESTMENT', 'RETIREMENT'],
  ),
  _Product(
    id: 'cashback_card',
    category: 'CREDIT CARD',
    title: 'Earn While You Spend',
    tagline: '5% cashback on top categories',
    benefit: 'Turn every essential spend into rewards — zero annual fee options exist.',
    ctaLabel: 'Compare Cards',
    gradient: [Color(0xFF283593), Color(0xFF512DA8)],
    icon: Icons.credit_card_rounded,
    partner: 'via HDFC · Axis · IDFC',
    goalTypes: ['BUDGET', 'SHORT_TERM', 'TRAVEL'],
  ),
  _Product(
    id: 'auto_save_habit',
    category: 'SAVINGS HABIT',
    title: 'Auto-Save on Salary Day',
    tagline: 'Pay yourself first — before spending',
    benefit: 'Automating savings on day 1 increases savings rate by 40% on average.',
    ctaLabel: 'See How It Works',
    gradient: [Color(0xFF00695C), Color(0xFF004D40)],
    icon: Icons.auto_mode_rounded,
    partner: 'via Fi Money · Jupiter · NAVI',
    goalTypes: ['EMERGENCY_FUND', 'SAVINGS', 'BUDGET'],
  ),
];

List<_Product> _sortForGoals(List<GoalEntity> goals) {
  if (goals.isEmpty) return _catalogue;

  final activeTypes = goals
      .where((g) => g.currentSaved < g.targetAmount)
      .map((g) => g.goalType.toUpperCase())
      .toSet();

  final scored = _catalogue.map((p) {
    final overlap = p.goalTypes.where(activeTypes.contains).length;
    return (product: p, score: overlap);
  }).toList()
    ..sort((a, b) => b.score.compareTo(a.score));

  return scored.map((e) => e.product).toList();
}

// ── Main Widget ───────────────────────────────────────────────────────────────

class PartnerProductCarousel extends StatefulWidget {
  const PartnerProductCarousel({super.key});

  @override
  State<PartnerProductCarousel> createState() => _PartnerProductCarouselState();
}

class _PartnerProductCarouselState extends State<PartnerProductCarousel> {
  final _ctrl = PageController(viewportFraction: 0.88);
  int _page = 0;
  Timer? _timer;
  bool _userScrolling = false;
  List<_Product> _products = _catalogue;

  @override
  void initState() {
    super.initState();
    _loadGoals();
    _startTimer();
  }

  Future<void> _loadGoals() async {
    try {
      final goals = await AppServices.instance.goals.getAll();
      if (mounted) {
        setState(() => _products = _sortForGoals(goals));
      }
    } catch (_) {
      // keep default catalogue order
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_userScrolling || !mounted) return;
      final next = (_page + 1) % _products.length;
      _ctrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 480),
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
        // ── Section header ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Recommendations',
                      style: GoogleFonts.manrope(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            '🎯 Goal-Matched',
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Products that help you reach your goals',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Page indicator
              _DotIndicator(count: _products.length, current: _page),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Carousel ─────────────────────────────────────────────────
        SizedBox(
          height: 172,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is ScrollStartNotification) {
                _userScrolling = true;
              } else if (n is ScrollEndNotification) {
                _userScrolling = false;
                _startTimer();
              }
              return false;
            },
            child: PageView.builder(
              controller: _ctrl,
              itemCount: _products.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) {
                return AnimatedScale(
                  scale: i == _page ? 1.0 : 0.95,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: _ProductCard(product: _products[i]),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ── Product Card ──────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});
  final _Product product;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: product.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: product.gradient.first.withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorative circle
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -30,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category badge + icon row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.category,
                        style: GoogleFonts.dmSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.90),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        product.icon,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Title
                Text(
                  product.title,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                    height: 1.15,
                  ),
                ),

                const SizedBox(height: 4),

                // Tagline (the compelling stat)
                Text(
                  product.tagline,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.3,
                  ),
                ),

                const Spacer(),

                // Bottom row: CTA + partner
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // CTA button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        product.ctaLabel,
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: product.gradient.first,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Partner attribution — shown last, subdued
                    if (product.partner != null)
                      Text(
                        product.partner!,
                        style: GoogleFonts.dmSans(
                          fontSize: 9,
                          color: Colors.white.withValues(alpha: 0.55),
                          height: 1.3,
                        ),
                        textAlign: TextAlign.right,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
