import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

// ── Data Model ────────────────────────────────────────────────────────────────

enum _SparklineStyle { rising, stepped, curve, jagged, flat }

class _Instrument {
  final String id;
  final String emoji;
  final String name;
  final String tagline;
  final String goalTag;
  final String benefit;
  final List<Color> gradient;
  final _SparklineStyle sparkline;
  final String whatIsThis;
  final String whyItFits;
  final List<String> howToStart;
  final List<String> partners;

  const _Instrument({
    required this.id,
    required this.emoji,
    required this.name,
    required this.tagline,
    required this.goalTag,
    required this.benefit,
    required this.gradient,
    required this.sparkline,
    required this.whatIsThis,
    required this.whyItFits,
    required this.howToStart,
    required this.partners,
  });
}

const _instruments = [
  _Instrument(
    id: 'sip',
    emoji: '📈',
    name: 'Mutual Fund SIP',
    tagline: 'Grow wealth on autopilot',
    goalTag: 'Long-term goals',
    benefit: '₹5,000/mo → ₹1.75 Cr in 20 yrs',
    gradient: [Color(0xFF1565C0), Color(0xFF0D47A1)],
    sparkline: _SparklineStyle.rising,
    whatIsThis:
        'A Systematic Investment Plan (SIP) invests a fixed amount every month into a mutual fund. The fund buys stocks or bonds on your behalf — you earn market returns without picking stocks yourself.',
    whyItFits:
        'Your long-term wealth goals need compounding to work. Starting early with a small amount consistently beats waiting to invest a large sum later.',
    howToStart: [
      'Choose between Index Fund (low cost) or ELSS (tax benefit)',
      'Set amount: even ₹500/month counts',
      'Enable auto-debit on salary date — removes willpower dependency',
      'Review annually, increase SIP by 10% each year',
    ],
    partners: ['Zerodha Coin', 'Groww', 'Paytm Money', 'Mirae Asset'],
  ),
  _Instrument(
    id: 'rd',
    emoji: '🏦',
    name: 'Recurring Deposit',
    tagline: 'Safe, guaranteed, zero stress',
    goalTag: 'Emergency fund',
    benefit: '₹7.1% p.a. guaranteed returns',
    gradient: [Color(0xFF00695C), Color(0xFF004D40)],
    sparkline: _SparklineStyle.stepped,
    whatIsThis:
        'A Recurring Deposit lets you deposit a fixed amount every month at a guaranteed interest rate. The bank locks your money safely — no market risk, no surprises.',
    whyItFits:
        'Your emergency fund should never be in a volatile instrument. RDs give you guaranteed growth while keeping the money accessible when you truly need it.',
    howToStart: [
      'Open an RD with your existing bank — takes 5 minutes',
      'Match the amount to your monthly savings target',
      'Set tenure to 12–18 months for your emergency fund goal',
      'Roll over or withdraw at maturity based on your need',
    ],
    partners: ['SBI', 'HDFC Bank', 'ICICI Bank', 'Axis Bank'],
  ),
  _Instrument(
    id: 'gold',
    emoji: '🥇',
    name: 'Digital Gold',
    tagline: 'Inflation protection, zero locker fees',
    goalTag: 'Wealth preservation',
    benefit: 'Beats inflation over 10+ years',
    gradient: [Color(0xFFD97706), Color(0xFFB45309)],
    sparkline: _SparklineStyle.curve,
    whatIsThis:
        'Digital Gold lets you buy 99.9% pure gold in any amount — even ₹1 — stored securely in a vault on your behalf. No physical risk, no locker needed.',
    whyItFits:
        'Gold holds its value against inflation and rupee depreciation over the long run. A 5–10% gold allocation in your portfolio provides a natural hedge when equities fall.',
    howToStart: [
      'Start with ₹500 — you get actual grams of gold',
      'Invest every month alongside your SIP (not instead of it)',
      'Hold for 5+ years for the inflation hedge to work',
      'You can take physical delivery or sell anytime',
    ],
    partners: ['Jar', 'PhonePe Gold', 'Google Pay Gold', 'Augmont'],
  ),
  _Instrument(
    id: 'credit',
    emoji: '💳',
    name: 'Smart Credit Card',
    tagline: 'Earn 2–5% back on every spend',
    goalTag: 'Spend smarter',
    benefit: 'Up to ₹18,000 saved/year in rewards',
    gradient: [Color(0xFF6D28D9), Color(0xFF4C1D95)],
    sparkline: _SparklineStyle.jagged,
    whatIsThis:
        'A rewards credit card gives you 2–5% cashback or points on every purchase you were already making — groceries, fuel, online shopping, dining.',
    whyItFits:
        'You spend money anyway. A credit card captures value on that spending and redirects it toward your goals — only if you pay the full balance every month.',
    howToStart: [
      'Choose a card based on where you spend most (Amazon, Swiggy, fuel)',
      'Never carry a balance — pay in full before due date, every month',
      'Treat the credit limit as a cash-flow tool, not extra money',
      'Redeem cashback into your savings goal monthly',
    ],
    partners: ['HDFC Millennia', 'SBI SimplyClick', 'Axis Flipkart', 'ICICI Amazon'],
  ),
  _Instrument(
    id: 'habits',
    emoji: '🎯',
    name: 'Saving Habits',
    tagline: 'The system that makes wealth automatic',
    goalTag: 'Daily discipline',
    benefit: 'Saves 40% more than willpower alone',
    gradient: [Color(0xFF0F9D58), Color(0xFF065F46)],
    sparkline: _SparklineStyle.flat,
    whatIsThis:
        'Saving habits are automated financial rules: pay-yourself-first transfers on salary day, round-up savings on every transaction, and spending rules that prevent leakage.',
    whyItFits:
        'Willpower is unreliable. Automating savings on the day salary arrives — before you have a chance to spend it — consistently outperforms manual saving by 40%.',
    howToStart: [
      'Set up an auto-transfer to savings on your salary credit date',
      'Use round-up saving: every ₹47 purchase saves ₹3 automatically',
      'Create a "no spend" window 3 days after salary to lock in savings',
      'Review your automation monthly and increase by ₹500 each quarter',
    ],
    partners: ['Fi Money', 'Jupiter', 'NAVI', 'Jar'],
  ),
];

// ── Sparkline Painter ─────────────────────────────────────────────────────────

class _SparklinePainter extends CustomPainter {
  final _SparklineStyle style;
  final double progress;

  const _SparklinePainter({required this.style, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final w = size.width;
    final h = size.height;

    switch (style) {
      case _SparklineStyle.rising:
        path.moveTo(0, h * 0.75);
        path.cubicTo(w * 0.2, h * 0.65, w * 0.4, h * 0.45, w * 0.6, h * 0.35);
        path.cubicTo(w * 0.75, h * 0.28, w * 0.85, h * 0.15, w, h * 0.08);
        break;
      case _SparklineStyle.stepped:
        path.moveTo(0, h * 0.80);
        path.lineTo(w * 0.20, h * 0.80);
        path.lineTo(w * 0.20, h * 0.65);
        path.lineTo(w * 0.42, h * 0.65);
        path.lineTo(w * 0.42, h * 0.50);
        path.lineTo(w * 0.65, h * 0.50);
        path.lineTo(w * 0.65, h * 0.33);
        path.lineTo(w, h * 0.33);
        break;
      case _SparklineStyle.curve:
        path.moveTo(0, h * 0.60);
        for (int i = 0; i <= 60; i++) {
          final x = w * i / 60;
          final noise = sin(i * 0.35) * h * 0.06;
          final trend = h * 0.60 - (h * 0.40 * i / 60);
          path.lineTo(x, trend + noise);
        }
        break;
      case _SparklineStyle.jagged:
        final pts = [0.78, 0.62, 0.70, 0.55, 0.64, 0.45, 0.58, 0.40, 0.52, 0.28];
        for (int i = 0; i < pts.length; i++) {
          final x = w * i / (pts.length - 1);
          if (i == 0) {
            path.moveTo(x, h * pts[i]);
          } else {
            path.lineTo(x, h * pts[i]);
          }
        }
        break;
      case _SparklineStyle.flat:
        path.moveTo(0, h * 0.60);
        path.lineTo(w * 0.15, h * 0.60);
        path.lineTo(w * 0.22, h * 0.50);
        path.lineTo(w * 0.36, h * 0.50);
        path.lineTo(w * 0.36, h * 0.38);
        path.lineTo(w * 0.52, h * 0.38);
        path.lineTo(w * 0.52, h * 0.28);
        path.lineTo(w * 0.68, h * 0.28);
        path.lineTo(w * 0.68, h * 0.18);
        path.lineTo(w, h * 0.18);
        break;
    }

    // Clip to progress
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w * progress.clamp(0.0, 1.0), h));
    canvas.drawPath(path, paint);
    canvas.restore();

    // Glow dot at tip
    if (progress > 0.9) {
      final metric = path.computeMetrics().first;
      final tangent = metric.getTangentForOffset(metric.length * progress.clamp(0.0, 1.0));
      if (tangent != null) {
        canvas.drawCircle(
          tangent.position,
          3.5,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.35)
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.style != style || old.progress != progress;
}

// ── Main Widget ───────────────────────────────────────────────────────────────

class GoalPathwayBanner extends StatefulWidget {
  const GoalPathwayBanner({super.key});

  @override
  State<GoalPathwayBanner> createState() => _GoalPathwayBannerState();
}

class _GoalPathwayBannerState extends State<GoalPathwayBanner>
    with SingleTickerProviderStateMixin {
  final _ctrl = PageController(viewportFraction: 0.82);
  int _page = 0;
  Timer? _timer;
  bool _userScrolling = false;
  late AnimationController _lineAnim;

  @override
  void initState() {
    super.initState();
    _lineAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    _lineAnim.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (_userScrolling || !mounted) return;
      final next = (_page + 1) % _instruments.length;
      _ctrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 540),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _onPageChanged(int i) {
    setState(() => _page = i);
    _lineAnim.reset();
    _lineAnim.forward();
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
                      'Achieve Your Goals Faster',
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Financial instruments matched to your goals',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _DotRow(count: _instruments.length, current: _page),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Carousel
        SizedBox(
          height: 178,
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
              itemCount: _instruments.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (ctx, i) => AnimatedScale(
                scale: i == _page ? 1.0 : 0.94,
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                child: AnimatedBuilder(
                  animation: _lineAnim,
                  builder: (_, __) => _PathwayCard(
                    instrument: _instruments[i],
                    sparklineProgress: i == _page ? _lineAnim.value : 1.0,
                    onTap: () => _openDetail(ctx, _instruments[i]),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Quick instrument tabs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _InstrumentTabs(
            instruments: _instruments,
            selected: _page,
            onSelect: (i) {
              _ctrl.animateToPage(
                i,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
              );
            },
          ),
        ),
      ],
    );
  }

  void _openDetail(BuildContext ctx, _Instrument instrument) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PathwayDetailSheet(instrument: instrument),
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _PathwayCard extends StatelessWidget {
  const _PathwayCard({
    required this.instrument,
    required this.sparklineProgress,
    required this.onTap,
  });
  final _Instrument instrument;
  final double sparklineProgress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: instrument.gradient,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: instrument.gradient.first.withValues(alpha: 0.30),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // Decorative circle blobs
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              left: -25,
              bottom: -45,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),

            // Sparkline in bottom half
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 100,
              child: CustomPaint(
                painter: _SparklinePainter(
                  style: instrument.sparkline,
                  progress: sparklineProgress,
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: goal tag + emoji
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22)),
                        ),
                        child: Text(
                          instrument.goalTag.toUpperCase(),
                          style: GoogleFonts.dmSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.9),
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        instrument.emoji,
                        style: const TextStyle(fontSize: 26),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Name
                  Text(
                    instrument.name,
                    style: GoogleFonts.manrope(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                      height: 1.1,
                    ),
                  ),

                  const SizedBox(height: 3),

                  // Tagline
                  Text(
                    instrument.tagline,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.65),
                      height: 1.3,
                    ),
                  ),

                  const Spacer(),

                  // Bottom: benefit pill + arrow
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            instrument.benefit,
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(10),
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

// ── Instrument Quick Tabs ─────────────────────────────────────────────────────

class _InstrumentTabs extends StatelessWidget {
  const _InstrumentTabs({
    required this.instruments,
    required this.selected,
    required this.onSelect,
  });
  final List<_Instrument> instruments;
  final int selected;
  final void Function(int) onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(instruments.length, (i) {
          final inst = instruments[i];
          final active = i == selected;
          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: active
                    ? inst.gradient.first.withValues(alpha: 0.12)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active
                      ? inst.gradient.first.withValues(alpha: 0.45)
                      : AppColors.border,
                  width: active ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(inst.emoji,
                      style: TextStyle(fontSize: active ? 14 : 13)),
                  const SizedBox(width: 6),
                  Text(
                    inst.name.split(' ').first,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight:
                          active ? FontWeight.w700 : FontWeight.w500,
                      color: active
                          ? inst.gradient.first
                          : AppColors.textSecondary,
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

// ── Detail Bottom Sheet ───────────────────────────────────────────────────────

class _PathwayDetailSheet extends StatelessWidget {
  const _PathwayDetailSheet({required this.instrument});
  final _Instrument instrument;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
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
              const SizedBox(height: 4),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 40),
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: instrument.gradient,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Text(
                            instrument.emoji,
                            style: const TextStyle(fontSize: 40),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  instrument.name,
                                  style: GoogleFonts.manrope(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  instrument.tagline,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color:
                                        Colors.white.withValues(alpha: 0.70),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ── 1. What is this ───────────────────────────────────
                    _Section(
                      label: 'WHAT IS THIS',
                      accentColor: instrument.gradient.first,
                      child: Text(
                        instrument.whatIsThis,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          height: 1.65,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ── 2. Why it fits ────────────────────────────────────
                    _Section(
                      label: 'WHY IT FITS YOUR GOALS',
                      accentColor: instrument.gradient.first,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: instrument.gradient.first
                              .withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: instrument.gradient.first
                                .withValues(alpha: 0.18),
                          ),
                        ),
                        child: Text(
                          instrument.whyItFits,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                            height: 1.65,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ── 3. How to start ───────────────────────────────────
                    _Section(
                      label: 'HOW TO START',
                      accentColor: instrument.gradient.first,
                      child: Column(
                        children: [
                          for (int i = 0;
                              i < instrument.howToStart.length;
                              i++) ...[
                            _StepRow(
                              step: i + 1,
                              text: instrument.howToStart[i],
                              accentColor: instrument.gradient.first,
                            ),
                            if (i < instrument.howToStart.length - 1)
                              const SizedBox(height: 10),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ── 4. Available through (partners — last, subdued) ───
                    _Section(
                      label: 'AVAILABLE THROUGH',
                      accentColor: AppColors.textMuted,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: instrument.partners
                            .map((p) => _PartnerChip(name: p))
                            .toList(),
                      ),
                    ),
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

// ── Supporting Widgets ────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({
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

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.text,
    required this.accentColor,
  });
  final int step;
  final String text;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: accentColor.withValues(alpha: 0.25)),
          ),
          child: Center(
            child: Text(
              '$step',
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: accentColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              text,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.55,
              ),
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

class _DotRow extends StatelessWidget {
  const _DotRow({required this.count, required this.current});
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
                : AppColors.primary.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
