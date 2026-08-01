import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/app_services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../goals/domain/entities/goal_entity.dart';

// ─── Category ─────────────────────────────────────────────────────────────────

enum _Category {
  all,
  mutualFund,
  gold,
  recurringDeposit,
  creditCard,
  savings,
}

extension _CategoryX on _Category {
  String get label {
    switch (this) {
      case _Category.all:
        return 'All';
      case _Category.mutualFund:
        return 'Mutual Fund';
      case _Category.gold:
        return 'Gold';
      case _Category.recurringDeposit:
        return 'RD / FD';
      case _Category.creditCard:
        return 'Credit Card';
      case _Category.savings:
        return 'Savings';
    }
  }

  Color get color {
    switch (this) {
      case _Category.all:
        return AppColors.primary;
      case _Category.mutualFund:
        return const Color(0xFF0F9D58);
      case _Category.gold:
        return const Color(0xFFF2A104);
      case _Category.recurringDeposit:
        return const Color(0xFF16213E);
      case _Category.creditCard:
        return const Color(0xFF7C3AED);
      case _Category.savings:
        return const Color(0xFF0EA5E9);
    }
  }

  IconData get icon {
    switch (this) {
      case _Category.all:
        return Icons.apps_rounded;
      case _Category.mutualFund:
        return Icons.trending_up_rounded;
      case _Category.gold:
        return Icons.star_rounded;
      case _Category.recurringDeposit:
        return Icons.account_balance_rounded;
      case _Category.creditCard:
        return Icons.credit_card_rounded;
      case _Category.savings:
        return Icons.savings_rounded;
    }
  }
}

// ─── Model ────────────────────────────────────────────────────────────────────

class _Product {
  final String id;
  final _Category category;
  final String partnerName;
  final String partnerInitials;
  final String productName;
  final String keyMetric;
  final String keyMetricLabel;
  final String defaultMatchedGoal;
  // Backend investmentSuggestion values this product is relevant for
  final List<String> relevantInvestmentSuggestions;
  // Backend goalType values this product is relevant for
  final List<String> relevantGoalTypes;
  final String ctaLabel;
  final bool isFeatured;

  const _Product({
    required this.id,
    required this.category,
    required this.partnerName,
    required this.partnerInitials,
    required this.productName,
    required this.keyMetric,
    required this.keyMetricLabel,
    required this.defaultMatchedGoal,
    required this.relevantInvestmentSuggestions,
    required this.relevantGoalTypes,
    required this.ctaLabel,
    this.isFeatured = false,
  });
}

const _allProducts = [
  _Product(
    id: 'mf_001',
    category: _Category.mutualFund,
    partnerName: 'Mirae Asset',
    partnerInitials: 'MA',
    productName: 'Mirae ELSS Tax Saver',
    keyMetric: '18.4% p.a.',
    keyMetricLabel: '3Y Returns',
    defaultMatchedGoal: 'Tax Savings',
    relevantInvestmentSuggestions: ['equity', 'hybrid_fund', 'mixed'],
    relevantGoalTypes: ['retirement', 'education', 'custom', 'house'],
    ctaLabel: 'Start SIP',
    isFeatured: true,
  ),
  _Product(
    id: 'rd_001',
    category: _Category.recurringDeposit,
    partnerName: 'HDFC Bank',
    partnerInitials: 'HDFC',
    productName: 'HDFC Recurring Deposit',
    keyMetric: '7.1% p.a.',
    keyMetricLabel: 'Interest Rate',
    defaultMatchedGoal: 'Emergency Fund',
    relevantInvestmentSuggestions: ['rd', 'fd', 'debt'],
    relevantGoalTypes: ['emergency_fund', 'vacation', 'laptop', 'car'],
    ctaLabel: 'Open RD',
    isFeatured: true,
  ),
  _Product(
    id: 'gold_001',
    category: _Category.gold,
    partnerName: 'Sovereign Bond',
    partnerInitials: 'SGB',
    productName: 'SGB 2026 Series II',
    keyMetric: '2.5% + gold',
    keyMetricLabel: 'Interest + Price Gain',
    defaultMatchedGoal: 'Wealth Building',
    relevantInvestmentSuggestions: ['equity', 'mixed'],
    relevantGoalTypes: ['retirement', 'house', 'wedding', 'custom'],
    ctaLabel: 'Invest Now',
  ),
  _Product(
    id: 'cc_001',
    category: _Category.creditCard,
    partnerName: 'HDFC Bank',
    partnerInitials: 'HDFC',
    productName: 'HDFC Millennia Card',
    keyMetric: '5% cashback',
    keyMetricLabel: 'On Online Spends',
    defaultMatchedGoal: 'Smart Spending',
    relevantInvestmentSuggestions: ['liquid_fund'],
    relevantGoalTypes: ['vacation', 'laptop', 'custom'],
    ctaLabel: 'Apply Now',
  ),
  _Product(
    id: 'sav_001',
    category: _Category.savings,
    partnerName: 'Jupiter Money',
    partnerInitials: 'JUP',
    productName: 'Jupiter Savings Account',
    keyMetric: '3.5% p.a.',
    keyMetricLabel: 'Savings Interest',
    defaultMatchedGoal: 'Daily Savings',
    relevantInvestmentSuggestions: ['liquid_fund', 'rd'],
    relevantGoalTypes: ['emergency_fund', 'vacation', 'laptop', 'car'],
    ctaLabel: 'Open Account',
  ),
  _Product(
    id: 'mf_002',
    category: _Category.mutualFund,
    partnerName: 'Axis Mutual Fund',
    partnerInitials: 'AXIS',
    productName: 'Axis Bluechip Fund',
    keyMetric: '14.2% p.a.',
    keyMetricLabel: '5Y Returns',
    defaultMatchedGoal: 'Retirement',
    relevantInvestmentSuggestions: ['equity', 'hybrid_fund'],
    relevantGoalTypes: ['retirement', 'house', 'education', 'wedding'],
    ctaLabel: 'Start SIP',
  ),
  _Product(
    id: 'gold_002',
    category: _Category.gold,
    partnerName: 'Jar App',
    partnerInitials: 'JAR',
    productName: 'Digital Gold — Daily Save',
    keyMetric: '₹10/day',
    keyMetricLabel: 'Min. Investment',
    defaultMatchedGoal: 'Savings Habit',
    relevantInvestmentSuggestions: ['mixed', 'equity'],
    relevantGoalTypes: ['custom', 'wedding', 'vacation'],
    ctaLabel: 'Start Saving',
  ),
  _Product(
    id: 'rd_002',
    category: _Category.recurringDeposit,
    partnerName: 'SBI Bank',
    partnerInitials: 'SBI',
    productName: 'SBI Fixed Deposit',
    keyMetric: '7.0% p.a.',
    keyMetricLabel: 'Interest Rate',
    defaultMatchedGoal: 'Short-term Goal',
    relevantInvestmentSuggestions: ['fd', 'debt', 'rd'],
    relevantGoalTypes: ['emergency_fund', 'car', 'laptop', 'vacation'],
    ctaLabel: 'Book FD',
  ),
];

// ─── Main Widget ──────────────────────────────────────────────────────────────

class ProductRecommendationCarousel extends StatefulWidget {
  const ProductRecommendationCarousel({super.key});

  @override
  State<ProductRecommendationCarousel> createState() =>
      _ProductRecommendationCarouselState();
}

class _ProductRecommendationCarouselState
    extends State<ProductRecommendationCarousel> {
  _Category _selected = _Category.all;
  late final PageController _pageController;
  int _currentPage = 0;

  List<GoalEntity> _goals = [];
  bool _goalsLoading = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.82);
    _loadGoals();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadGoals() async {
    try {
      final goals = await AppServices.instance.goals.getAll();
      if (mounted) setState(() {
        _goals = goals;
        _goalsLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _goalsLoading = false);
    }
  }

  // Returns the user's real goal name if this product matches one of their
  // goals, otherwise falls back to the product's default label.
  String _resolveGoalName(_Product product) {
    for (final goal in _goals) {
      if (product.relevantInvestmentSuggestions
          .contains(goal.investmentSuggestion.toLowerCase())) {
        return goal.name;
      }
    }
    for (final goal in _goals) {
      if (product.relevantGoalTypes.contains(goal.goalType.toLowerCase())) {
        return goal.name;
      }
    }
    return product.defaultMatchedGoal;
  }

  bool _isMatchedToRealGoal(_Product product) =>
      _resolveGoalName(product) != product.defaultMatchedGoal;

  List<_Product> get _filteredAndSorted {
    final base = _selected == _Category.all
        ? _allProducts
        : _allProducts.where((p) => p.category == _selected).toList();

    if (_goals.isEmpty) return base;

    // Matched products float to the top
    final matched = base.where(_isMatchedToRealGoal).toList();
    final unmatched = base.where((p) => !_isMatchedToRealGoal(p)).toList();
    return [...matched, ...unmatched];
  }

  void _onCategoryTap(_Category cat) {
    setState(() {
      _selected = cat;
      _currentPage = 0;
    });
    _pageController.jumpToPage(0);
  }

  @override
  Widget build(BuildContext context) {
    final products = _filteredAndSorted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recommended for your goals',
                      style: GoogleFonts.manrope(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'Curated by your AI CA',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (!_goalsLoading && _goals.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${_goals.length} goal${_goals.length == 1 ? '' : 's'} matched',
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'See all',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Category Chips ───────────────────────────────────────────────────
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _Category.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final cat = _Category.values[i];
              final isActive = _selected == cat;
              return GestureDetector(
                onTap: () => _onCategoryTap(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? cat.color : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? cat.color : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        cat.icon,
                        size: 13,
                        color: isActive
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        cat.label,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // ── Cards ─────────────────────────────────────────────────────────
        if (_goalsLoading)
          _SkeletonCards()
        else if (products.isEmpty)
          _EmptyState(category: _selected)
        else
          SizedBox(
            height: 210,
            child: PageView.builder(
              controller: _pageController,
              itemCount: products.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (context, index) {
                final product = products[index];
                return _RecommendationCard(
                  product: product,
                  resolvedGoalName: _resolveGoalName(product),
                  isRealGoalMatch: _isMatchedToRealGoal(product),
                  pageController: _pageController,
                  index: index,
                );
              },
            ),
          ),

        // ── Dots ──────────────────────────────────────────────────────────
        if (!_goalsLoading && products.length > 1) ...[
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(products.length, (i) {
              final isActive = i == _currentPage;
              final dotColor = _selected == _Category.all
                  ? AppColors.primary
                  : _selected.color;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive
                      ? dotColor
                      : dotColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

// ─── Recommendation Card ──────────────────────────────────────────────────────

class _RecommendationCard extends StatelessWidget {
  final _Product product;
  final String resolvedGoalName;
  final bool isRealGoalMatch;
  final PageController pageController;
  final int index;

  const _RecommendationCard({
    required this.product,
    required this.resolvedGoalName,
    required this.isRealGoalMatch,
    required this.pageController,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final accent = product.category.color;

    return AnimatedBuilder(
      animation: pageController,
      builder: (_, child) {
        double scale = 1.0;
        if (pageController.hasClients && pageController.page != null) {
          final offset = (pageController.page! - index).abs();
          scale = (1.0 - offset * 0.04).clamp(0.94, 1.0);
        }
        return Transform.scale(scale: scale, child: child);
      },
      child: GestureDetector(
        onTap: () {},
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border(
              left: BorderSide(color: accent, width: 4),
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Partner row ──────────────────────────────────────────
                Row(
                  children: [
                    _PartnerAvatar(
                      initials: product.partnerInitials,
                      color: accent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.partnerName,
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            product.productName,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (product.isFeatured)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.amber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Top Pick',
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.amber,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Key metric ───────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(product.category.icon, color: accent, size: 18),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.keyMetric,
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: accent,
                            ),
                          ),
                          Text(
                            product.keyMetricLabel,
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // ── Footer: goal match + CTA ─────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            isRealGoalMatch
                                ? Icons.flag_rounded
                                : Icons.flag_outlined,
                            size: 13,
                            color: isRealGoalMatch
                                ? accent
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              resolvedGoalName,
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: isRealGoalMatch
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isRealGoalMatch
                                    ? accent
                                    : AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          product.ctaLabel,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Partner Avatar ───────────────────────────────────────────────────────────

class _PartnerAvatar extends StatelessWidget {
  final String initials;
  final Color color;

  const _PartnerAvatar({required this.initials, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      alignment: Alignment.center,
      child: Text(
        initials.length > 4 ? initials.substring(0, 4) : initials,
        style: GoogleFonts.manrope(
          fontSize: initials.length > 3 ? 9 : 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

// ─── Skeleton Loading ─────────────────────────────────────────────────────────

class _SkeletonCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => Container(
          width: MediaQuery.of(context).size.width * 0.72,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border(
              left: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.5), width: 4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Shimmer(width: 40, height: 40, radius: 12),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Shimmer(width: 80, height: 10, radius: 5),
                      const SizedBox(height: 6),
                      _Shimmer(width: 130, height: 14, radius: 5),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _Shimmer(width: double.infinity, height: 56, radius: 12),
              const Spacer(),
              Row(
                children: [
                  _Shimmer(width: 90, height: 12, radius: 5),
                  const Spacer(),
                  _Shimmer(width: 70, height: 32, radius: 10),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Shimmer extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  const _Shimmer(
      {required this.width, required this.height, required this.radius});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(
            const Color(0xFFEEEEEE),
            const Color(0xFFF8F8F8),
            _anim.value,
          ),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final _Category category;
  const _EmptyState({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(category.icon, color: AppColors.textSecondary, size: 28),
            const SizedBox(height: 8),
            Text(
              'No ${category.label} recommendations yet',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
