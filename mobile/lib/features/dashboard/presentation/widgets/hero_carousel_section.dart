import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

// ─── Data ─────────────────────────────────────────────────────────────────────

class _SlideData {
  final List<Color> gradientColors;
  final String headline;
  final String subline;
  final String ctaLabel;

  const _SlideData({
    required this.gradientColors,
    required this.headline,
    required this.subline,
    required this.ctaLabel,
  });
}

const _slides = [
  _SlideData(
    gradientColors: [Color(0xFF1E3A8A), Color(0xFF4338CA), Color(0xFF5B21B6)],
    headline: 'Save ₹100 today.\nFuture You will\nthank you.',
    subline: 'Small daily habits build life-changing wealth.',
    ctaLabel: 'See my plan',
  ),
  _SlideData(
    gradientColors: [Color(0xFF065F46), Color(0xFF0E7490), Color(0xFF0C4A6E)],
    headline: 'Compound interest:\nthe 8th wonder\nof the world.',
    subline: '₹5,000/month at 12% p.a. becomes ₹1.76 Cr in 30 years.',
    ctaLabel: 'Calculate mine',
  ),
  _SlideData(
    gradientColors: [Color(0xFF4C1D95), Color(0xFF7C3AED), Color(0xFF6D28D9)],
    headline: 'Your emergency\nfund is your\nfreedom.',
    subline: '6 months of salary means 6 months of choices.',
    ctaLabel: 'Build mine',
  ),
  _SlideData(
    gradientColors: [Color(0xFF7C2D12), Color(0xFFB45309), Color(0xFF92400E)],
    headline: 'Only 27% of\nIndians regularly\nsave money.',
    subline: "You're already here. That puts you ahead of 73%.",
    ctaLabel: 'Stay ahead',
  ),
];

// ─── Hero Carousel Section ────────────────────────────────────────────────────

class HeroCarouselSection extends StatefulWidget {
  final double salary;
  const HeroCarouselSection({super.key, required this.salary});

  @override
  State<HeroCarouselSection> createState() => _HeroCarouselSectionState();
}

class _HeroCarouselSectionState extends State<HeroCarouselSection>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoSlideTimer;
  Timer? _resumeTimer;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _startAutoSlide();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _resumeTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!_isPaused && mounted) {
        final next = (_currentPage + 1) % _slides.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onInteraction() {
    _isPaused = true;
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _isPaused = false);
    });
  }

  void _goTo(int index) {
    _onInteraction();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
    );
  }

  void _prev() {
    final prev = (_currentPage - 1 + _slides.length) % _slides.length;
    _goTo(prev);
  }

  void _next() {
    final next = (_currentPage + 1) % _slides.length;
    _goTo(next);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final slideHeight = (screenWidth * 0.55).clamp(240.0, 440.0);
    final showArrows = screenWidth > 600;

    return GestureDetector(
      onPanDown: (_) => _onInteraction(),
      child: Column(
        children: [
          Stack(
            children: [
              SizedBox(
                height: slideHeight,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (i) {
                    if (mounted) setState(() => _currentPage = i);
                  },
                  itemBuilder: (context, index) {
                    return _AnimatedSlide(
                      pageController: _pageController,
                      index: index,
                      slide: _slides[index],
                      slideHeight: slideHeight,
                    );
                  },
                ),
              ),
              if (showArrows) ...[
                Positioned(
                  left: 12,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _ArrowButton(
                      icon: Icons.chevron_left_rounded,
                      onTap: _prev,
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _ArrowButton(
                      icon: Icons.chevron_right_rounded,
                      onTap: _next,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_slides.length, (i) {
              final isActive = i == _currentPage;
              return GestureDetector(
                onTap: () => _goTo(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.orange
                        : Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─── Arrow Button ─────────────────────────────────────────────────────────────

class _ArrowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ArrowButton({required this.icon, required this.onTap});

  @override
  State<_ArrowButton> createState() => _ArrowButtonState();
}

class _ArrowButtonState extends State<_ArrowButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedOpacity(
        opacity: _hovered ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(widget.icon,
                color: AppColors.textPrimary, size: 22),
          ),
        ),
      ),
    );
  }
}

// ─── Animated Slide (opacity + translate driven by PageController) ────────────
// Uses AnimatedBuilder so only this node redraws on every scroll pixel,
// not the entire carousel state.

class _AnimatedSlide extends StatelessWidget {
  final PageController pageController;
  final int index;
  final _SlideData slide;
  final double slideHeight;

  const _AnimatedSlide({
    required this.pageController,
    required this.index,
    required this.slide,
    required this.slideHeight,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pageController,
      builder: (_, child) {
        final page = pageController.hasClients
            ? (pageController.page ?? index.toDouble())
            : index.toDouble();
        final offset = page - index;
        final opacity = (1.0 - offset.abs()).clamp(0.0, 1.0);
        final translateX = offset * 40.0;
        return Transform.translate(
          offset: Offset(translateX, 0),
          child: Opacity(opacity: opacity, child: child),
        );
      },
      child: _HeroSlide(slide: slide, height: slideHeight),
    );
  }
}

// ─── Hero Slide ───────────────────────────────────────────────────────────────

class _HeroSlide extends StatefulWidget {
  final _SlideData slide;
  final double height;

  const _HeroSlide({required this.slide, required this.height});

  @override
  State<_HeroSlide> createState() => _HeroSlideState();
}

class _HeroSlideState extends State<_HeroSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _gradientController;
  late Animation<double> _gradientAnim;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _gradientAnim = CurvedAnimation(
      parent: _gradientController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _gradientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;
    final headlineFontSize = isWide ? 36.0 : 28.0;

    return AnimatedBuilder(
      animation: _gradientAnim,
      builder: (context, child) {
        final t = _gradientAnim.value;
        final colors = widget.slide.gradientColors;
        final shiftedColors = [
          Color.lerp(colors[0], colors[1], t * 0.3)!,
          Color.lerp(colors[1], colors[2], t * 0.3)!,
          Color.lerp(colors[2], colors[0], t * 0.3)!,
        ];

        return Container(
          height: widget.height,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: shiftedColors,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              // Blob circles
              Positioned.fill(
                child: CustomPaint(
                  painter: _BlobPainter(animValue: t),
                ),
              ),
              // Chart decoration on right
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: widget.height * 0.55,
                child: const CustomPaint(
                  painter: _ChartDecoPainter(),
                ),
              ),
              // Glassmorphism content card
              Positioned(
                left: 16,
                top: 20,
                bottom: 20,
                right: widget.height * 0.40,
                child: _GlassCard(
                  headline: widget.slide.headline,
                  subline: widget.slide.subline,
                  ctaLabel: widget.slide.ctaLabel,
                  headlineFontSize: headlineFontSize,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Glass Card ───────────────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final String headline;
  final String subline;
  final String ctaLabel;
  final double headlineFontSize;

  const _GlassCard({
    required this.headline,
    required this.subline,
    required this.ctaLabel,
    required this.headlineFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              headline,
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontSize: headlineFontSize,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subline,
              style: GoogleFonts.dmSans(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Flexible(
                  child: GestureDetector(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        ctaLabel,
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: GestureDetector(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'Learn more',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Blob Painter ─────────────────────────────────────────────────────────────

class _BlobPainter extends CustomPainter {
  final double animValue;
  _BlobPainter({required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);

    // Blob 1 — top right
    final offset1 = Offset(
      size.width * (0.7 + animValue * 0.1),
      size.height * (0.1 + animValue * 0.15),
    );
    canvas.drawCircle(offset1, size.width * 0.35, paint);

    // Blob 2 — bottom left
    final offset2 = Offset(
      size.width * (0.1 - animValue * 0.05),
      size.height * (0.75 + animValue * 0.1),
    );
    canvas.drawCircle(offset2, size.width * 0.28, paint);
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.animValue != animValue;
}

// ─── Chart Deco Painter ───────────────────────────────────────────────────────

class _ChartDecoPainter extends CustomPainter {
  const _ChartDecoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Upward line chart path
    final points = [
      Offset(size.width * 0.05, size.height * 0.75),
      Offset(size.width * 0.20, size.height * 0.60),
      Offset(size.width * 0.35, size.height * 0.65),
      Offset(size.width * 0.50, size.height * 0.45),
      Offset(size.width * 0.65, size.height * 0.35),
      Offset(size.width * 0.80, size.height * 0.20),
      Offset(size.width * 0.95, size.height * 0.10),
    ];

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final cp1 = Offset(
        (points[i - 1].dx + points[i].dx) / 2,
        points[i - 1].dy,
      );
      final cp2 = Offset(
        (points[i - 1].dx + points[i].dx) / 2,
        points[i].dy,
      );
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);

    // Fill under chart
    final fillPath = Path.from(path);
    fillPath.lineTo(points.last.dx, size.height * 0.9);
    fillPath.lineTo(points.first.dx, size.height * 0.9);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.10),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Dots at each data point
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    for (final pt in points) {
      canvas.drawCircle(pt, 4, dotPaint);
    }

    // Highlight last dot
    canvas.drawCircle(
      points.last,
      6,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_ChartDecoPainter old) => false;
}
