import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/app_services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../goals/domain/entities/goal_entity.dart';

// ─── Category ─────────────────────────────────────────────────────────────────

enum _BannerCat { mutualFund, rd, creditCard, gold, savings }

extension _BannerCatX on _BannerCat {
  String get label {
    switch (this) {
      case _BannerCat.mutualFund:  return 'Mutual Fund';
      case _BannerCat.rd:          return 'RD / FD';
      case _BannerCat.creditCard:  return 'Credit Card';
      case _BannerCat.gold:        return 'Gold';
      case _BannerCat.savings:     return 'Savings';
    }
  }

  Color get chipColor {
    switch (this) {
      case _BannerCat.mutualFund:  return const Color(0xFF0D9488);
      case _BannerCat.rd:          return const Color(0xFF2563EB);
      case _BannerCat.creditCard:  return const Color(0xFF7C3AED);
      case _BannerCat.gold:        return const Color(0xFFD97706);
      case _BannerCat.savings:     return const Color(0xFF0891B2);
    }
  }
}

// ─── Banner Model ─────────────────────────────────────────────────────────────

class _Banner {
  final String id;
  final String partnerName;
  final String partnerInitials;
  final String offerHeadline;
  final String offerSubline;
  final String bodyLine;
  final String ctaLabel;
  final List<Color> gradientColors;
  final _BannerCat category;
  final List<String> relevantGoalTypes;
  final List<String> relevantInvestmentSuggestions;
  final String defaultGoalLabel;
  final bool isFeatured;

  const _Banner({
    required this.id,
    required this.partnerName,
    required this.partnerInitials,
    required this.offerHeadline,
    required this.offerSubline,
    required this.bodyLine,
    required this.ctaLabel,
    required this.gradientColors,
    required this.category,
    required this.relevantGoalTypes,
    required this.relevantInvestmentSuggestions,
    required this.defaultGoalLabel,
    this.isFeatured = false,
  });
}

const _kBanners = [
  _Banner(
    id: 'mf_elss',
    partnerName: 'Mirae Asset',
    partnerInitials: 'MA',
    offerHeadline: '18.4% p.a.',
    offerSubline: '3-Year Returns',
    bodyLine: 'Save tax under 80C & grow wealth with ELSS.',
    ctaLabel: 'Start SIP',
    gradientColors: [Color(0xFF064E3B), Color(0xFF065F46), Color(0xFF0D9488)],
    category: _BannerCat.mutualFund,
    relevantGoalTypes: ['retirement', 'education', 'house', 'custom'],
    relevantInvestmentSuggestions: ['equity', 'hybrid_fund', 'mixed'],
    defaultGoalLabel: 'Tax Savings',
    isFeatured: true,
  ),
  _Banner(
    id: 'rd_hdfc',
    partnerName: 'HDFC Bank',
    partnerInitials: 'HDFC',
    offerHeadline: '7.1% p.a.',
    offerSubline: 'Guaranteed Returns',
    bodyLine: 'Recurring deposit — no market risk, full safety.',
    ctaLabel: 'Open RD',
    gradientColors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8), Color(0xFF3B82F6)],
    category: _BannerCat.rd,
    relevantGoalTypes: ['emergency_fund', 'vacation', 'laptop', 'car'],
    relevantInvestmentSuggestions: ['rd', 'fd', 'debt'],
    defaultGoalLabel: 'Emergency Fund',
    isFeatured: true,
  ),
  _Banner(
    id: 'cc_millennia',
    partnerName: 'HDFC Bank',
    partnerInitials: 'HDFC',
    offerHeadline: '5% cashback',
    offerSubline: 'On Online Spends',
    bodyLine: 'Every purchase builds rewards. Turn spend into savings.',
    ctaLabel: 'Apply Now',
    gradientColors: [Color(0xFF4C1D95), Color(0xFF6D28D9), Color(0xFF7C3AED)],
    category: _BannerCat.creditCard,
    relevantGoalTypes: ['vacation', 'laptop', 'custom'],
    relevantInvestmentSuggestions: ['liquid_fund'],
    defaultGoalLabel: 'Smart Spending',
  ),
  _Banner(
    id: 'gold_sgb',
    partnerName: 'Sovereign Bond',
    partnerInitials: 'SGB',
    offerHeadline: '2.5% + Gold',
    offerSubline: 'Interest + Price Gain',
    bodyLine: 'Government-backed gold. No storage cost. 8-year tenure.',
    ctaLabel: 'Invest Now',
    gradientColors: [Color(0xFF78350F), Color(0xFFB45309), Color(0xFFD97706)],
    category: _BannerCat.gold,
    relevantGoalTypes: ['retirement', 'wedding', 'house', 'custom'],
    relevantInvestmentSuggestions: ['equity', 'mixed'],
    defaultGoalLabel: 'Wealth Building',
  ),
  _Banner(
    id: 'sav_jupiter',
    partnerName: 'Jupiter Money',
    partnerInitials: 'JUP',
    offerHeadline: '3.5% p.a.',
    offerSubline: 'Savings Interest',
    bodyLine: 'Your idle cash earns every day. Zero balance account.',
    ctaLabel: 'Open Account',
    gradientColors: [Color(0xFF164E63), Color(0xFF0E7490), Color(0xFF0891B2)],
    category: _BannerCat.savings,
    relevantGoalTypes: ['emergency_fund', 'vacation', 'laptop', 'car'],
    relevantInvestmentSuggestions: ['liquid_fund', 'rd'],
    defaultGoalLabel: 'Daily Savings',
  ),
  _Banner(
    id: 'mf_axis',
    partnerName: 'Axis Mutual Fund',
    partnerInitials: 'AXIS',
    offerHeadline: '14.2% p.a.',
    offerSubline: '5-Year Returns',
    bodyLine: 'Large-cap stability with consistent long-term growth.',
    ctaLabel: 'Start SIP',
    gradientColors: [Color(0xFF312E81), Color(0xFF4338CA), Color(0xFF6366F1)],
    category: _BannerCat.mutualFund,
    relevantGoalTypes: ['retirement', 'house', 'education', 'wedding'],
    relevantInvestmentSuggestions: ['equity', 'hybrid_fund'],
    defaultGoalLabel: 'Retirement',
  ),
  _Banner(
    id: 'gold_jar',
    partnerName: 'Jar',
    partnerInitials: 'JAR',
    offerHeadline: '₹10/day',
    offerSubline: 'Min. Gold Investment',
    bodyLine: 'Accumulate 24K digital gold daily. Start tiny, grow big.',
    ctaLabel: 'Start Saving',
    gradientColors: [Color(0xFF92400E), Color(0xFFB45309), Color(0xFFD97706)],
    category: _BannerCat.gold,
    relevantGoalTypes: ['custom', 'wedding', 'vacation'],
    relevantInvestmentSuggestions: ['mixed', 'equity'],
    defaultGoalLabel: 'Gold Savings',
  ),
  _Banner(
    id: 'fd_sbi',
    partnerName: 'SBI Bank',
    partnerInitials: 'SBI',
    offerHeadline: '7.0% p.a.',
    offerSubline: 'Fixed Deposit Rate',
    bodyLine: "India's most trusted bank. Book FD in under 2 minutes.",
    ctaLabel: 'Book FD',
    gradientColors: [Color(0xFF1E3A5F), Color(0xFF1E4D8C), Color(0xFF1D6FAF)],
    category: _BannerCat.rd,
    relevantGoalTypes: ['emergency_fund', 'car', 'laptop', 'vacation'],
    relevantInvestmentSuggestions: ['fd', 'debt', 'rd'],
    defaultGoalLabel: 'Short-term Goal',
  ),
];

// ─── Main Widget ──────────────────────────────────────────────────────────────

class GoalPromoBanner extends StatefulWidget {
  const GoalPromoBanner({super.key});

  @override
  State<GoalPromoBanner> createState() => _GoalPromoBannerState();
}

class _GoalPromoBannerState extends State<GoalPromoBanner> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoTimer;
  Timer? _resumeTimer;
  bool _isPaused = false;
  List<GoalEntity> _goals = [];
  _BannerCat? _selectedCat;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
    _startAuto();
    _loadGoals();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _resumeTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAuto() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_isPaused && mounted) {
        final list = _filtered;
        if (list.length > 1) {
          final next = (_currentPage + 1) % list.length;
          _pageController.animateToPage(
            next,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
          );
        }
      }
    });
  }

  void _pause() {
    _isPaused = true;
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) _isPaused = false;
    });
  }

  Future<void> _loadGoals() async {
    try {
      final goals = await AppServices.instance.goals.getAll();
      if (mounted) setState(() => _goals = goals);
    } catch (_) {}
  }

  List<_Banner> get _filtered {
    final base = _selectedCat == null
        ? List<_Banner>.from(_kBanners)
        : _kBanners.where((b) => b.category == _selectedCat).toList();

    if (_goals.isEmpty) return base;

    final matched = base.where(_isGoalMatched).toList();
    final unmatched = base.where((b) => !_isGoalMatched(b)).toList();
    return [...matched, ...unmatched];
  }

  String _goalLabel(_Banner b) {
    for (final g in _goals) {
      if (b.relevantInvestmentSuggestions
          .contains(g.investmentSuggestion.toLowerCase())) {
        return g.name;
      }
    }
    for (final g in _goals) {
      if (b.relevantGoalTypes.contains(g.goalType.toLowerCase())) {
        return g.name;
      }
    }
    return b.defaultGoalLabel;
  }

  bool _isGoalMatched(_Banner b) => _goalLabel(b) != b.defaultGoalLabel;

  void _selectCat(_BannerCat? cat) {
    setState(() {
      _selectedCat = cat;
      _currentPage = 0;
    });
    _pageController.jumpToPage(0);
  }

  @override
  Widget build(BuildContext context) {
    final banners = _filtered;
    final cats = [null, ..._BannerCat.values];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ─────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Made for your goals',
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
                        Text(
                          'Curated by your AI CA',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (_goals.isNotEmpty) ...[
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
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Category chips ─────────────────────────────────────────────────
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: cats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final cat = cats[i];
              final isActive = _selectedCat == cat;
              final label = cat?.label ?? 'All';
              final color = cat?.chipColor ?? AppColors.primary;
              return GestureDetector(
                onTap: () => _selectCat(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? color : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? color : AppColors.border,
                    ),
                  ),
                  child: Text(
                    label,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 14),

        // ── Banner slides ───────────────────────────────────────────────────
        GestureDetector(
          onPanDown: (_) => _pause(),
          child: SizedBox(
            height: 190,
            child: PageView.builder(
              controller: _pageController,
              itemCount: banners.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (context, i) => _BannerSlide(
                banner: banners[i],
                goalLabel: _goalLabel(banners[i]),
                isGoalMatched: _isGoalMatched(banners[i]),
                pageController: _pageController,
                index: i,
              ),
            ),
          ),
        ),

        // ── Dots ───────────────────────────────────────────────────────────
        if (banners.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(banners.length, (i) {
              final isActive = i == _currentPage;
              final dotColor = banners[i % banners.length].gradientColors.last;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 18 : 6,
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

// ─── Banner Slide ─────────────────────────────────────────────────────────────

class _BannerSlide extends StatelessWidget {
  final _Banner banner;
  final String goalLabel;
  final bool isGoalMatched;
  final PageController pageController;
  final int index;

  const _BannerSlide({
    required this.banner,
    required this.goalLabel,
    required this.isGoalMatched,
    required this.pageController,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pageController,
      builder: (_, child) {
        double scale = 1.0;
        final page = pageController.hasClients ? pageController.page : null;
        if (page != null) {
          final offset = (page - index).abs();
          scale = (1.0 - offset * 0.05).clamp(0.93, 1.0);
        }
        return Transform.scale(scale: scale, child: child);
      },
      child: GestureDetector(
        onTap: () {},
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 7),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: banner.gradientColors,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: banner.gradientColors.last.withValues(alpha: 0.30),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              // Category-specific background illustration
              Positioned.fill(
                child: CustomPaint(
                  painter: _PatternPainter(banner.category),
                ),
              ),
              // Ambient glow top-right
              Positioned(
                right: -24,
                top: -24,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Partner row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.22)),
                          ),
                          child: Text(
                            banner.partnerInitials,
                            style: GoogleFonts.manrope(
                              color: Colors.white,
                              fontSize: banner.partnerInitials.length > 3
                                  ? 9
                                  : 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          banner.partnerName,
                          style: GoogleFonts.dmSans(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        if (banner.isFeatured)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '⭐ Top Pick',
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Offer headline
                    Text(
                      banner.offerHeadline,
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      banner.offerSubline,
                      style: GoogleFonts.dmSans(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      banner.bodyLine,
                      style: GoogleFonts.dmSans(
                        color: Colors.white.withValues(alpha: 0.60),
                        fontSize: 11,
                        height: 1.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

                    // Footer: goal pill + CTA
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(
                                  alpha: isGoalMatched ? 0.20 : 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(
                                    alpha: isGoalMatched ? 0.40 : 0.18),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isGoalMatched
                                      ? Icons.flag_rounded
                                      : Icons.flag_outlined,
                                  color: Colors.white.withValues(
                                      alpha: isGoalMatched ? 1.0 : 0.60),
                                  size: 11,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    goalLabel,
                                    style: GoogleFonts.dmSans(
                                      color: Colors.white.withValues(
                                          alpha:
                                              isGoalMatched ? 1.0 : 0.70),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 9),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              banner.ctaLabel,
                              style: GoogleFonts.dmSans(
                                color: banner.gradientColors.first,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
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
      ),
    );
  }
}

// ─── Pattern Painter ──────────────────────────────────────────────────────────
// Each category gets a distinct background decoration that reads clearly
// at a glance, reinforcing the product category without distracting from the copy.

class _PatternPainter extends CustomPainter {
  final _BannerCat category;
  _PatternPainter(this.category);

  @override
  void paint(Canvas canvas, Size size) {
    switch (category) {
      case _BannerCat.mutualFund:
        _drawBars(canvas, size);
        break;
      case _BannerCat.rd:
        _drawRings(canvas, size);
        break;
      case _BannerCat.creditCard:
        _drawGrid(canvas, size);
        break;
      case _BannerCat.gold:
        _drawHoneycomb(canvas, size);
        break;
      case _BannerCat.savings:
        _drawWaves(canvas, size);
        break;
    }
  }

  // Rising bar chart — wealth growth
  void _drawBars(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;

    const barCount = 9;
    final barW = size.width * 0.038;
    final startX = size.width * 0.50;
    final heights = [0.28, 0.45, 0.38, 0.60, 0.52, 0.72, 0.62, 0.85, 0.78];

    for (int i = 0; i < barCount; i++) {
      final x = startX + i * (barW + size.width * 0.022);
      final barH = size.height * heights[i];
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - barH - 6, barW, barH),
          const Radius.circular(3),
        ),
        paint,
      );
    }
    // Trend line over bars
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path();
    for (int i = 0; i < barCount; i++) {
      final x = startX + i * (barW + size.width * 0.022) + barW / 2;
      final y = size.height - size.height * heights[i] - 6;
      if (i == 0) { path.moveTo(x, y); } else { path.lineTo(x, y); }
    }
    canvas.drawPath(path, linePaint);
  }

  // Concentric rings — stability / FD safety
  void _drawRings(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.07);
    final center = Offset(size.width * 0.78, size.height * 0.50);
    for (final r in [18.0, 36.0, 54.0, 72.0, 90.0, 108.0]) {
      canvas.drawCircle(center, r, paint);
    }
  }

  // Fine grid — precision / credit card structure
  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Colors.white.withValues(alpha: 0.05);
    const step = 20.0;
    final startX = size.width * 0.42;
    for (double x = startX; x <= size.width + step; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(startX, y), Offset(size.width, y), paint);
    }
  }

  // Honeycomb — gold's natural association
  void _drawHoneycomb(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.08);
    const r = 17.0;
    const dxStep = r * 1.732;
    const dyStep = r * 1.5;
    final startX = size.width * 0.44;
    for (double row = 0; row * dyStep < size.height + r; row++) {
      final xOffset = (row % 2 == 0) ? 0.0 : dxStep / 2;
      for (double col = 0; startX + col * dxStep + xOffset < size.width + r; col++) {
        final cx = startX + col * dxStep + xOffset;
        final cy = row * dyStep;
        _hex(canvas, Offset(cx, cy), r, paint);
      }
    }
  }

  void _hex(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final a = pi / 180 * (60.0 * i - 30);
      final x = center.dx + r * cos(a);
      final y = center.dy + r * sin(a);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  // Sine waves — liquid savings, flow of money
  void _drawWaves(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeCap = StrokeCap.round;

    const waveCount = 4;
    final startX = size.width * 0.40;
    for (int w = 0; w < waveCount; w++) {
      final path = Path();
      final yBase = size.height * (0.2 + w * 0.22);
      final amplitude = 8.0 + w * 2;
      path.moveTo(startX, yBase);
      for (double x = startX; x <= size.width + 4; x += 2) {
        final normalized = (x - startX) / (size.width - startX);
        final y = yBase + sin(normalized * pi * 2.5) * amplitude;
        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_PatternPainter old) => old.category != category;
}
