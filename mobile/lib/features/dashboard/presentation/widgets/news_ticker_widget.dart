import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

const _headlines = [
  'NIFTY 50 hits new all-time high, crosses 27,000 mark',
  'RBI holds repo rate steady at 6.5% amid global uncertainty',
  'Gold prices surge to ₹78,500 per 10g on safe-haven demand',
  'SEBI introduces new framework for retail bond investments',
  'SIP inflows cross ₹21,000 Cr for the 8th consecutive month',
  'Sensex gains 850 points led by IT and banking stocks',
  "India's forex reserves rise to \$695 billion",
  'Inflation eases to 4.2%, within RBI comfort zone',
];

// Pre-computed constants — never allocated at build/frame time.
final _tickerItems = [..._headlines, ..._headlines];

const _leftFade = BoxDecoration(
  gradient: LinearGradient(
    colors: [AppColors.surface, Color(0x00181818)],
  ),
);

const _rightFade = BoxDecoration(
  gradient: LinearGradient(
    colors: [Color(0x00181818), AppColors.surface],
  ),
);

class FinancialNewsTicker extends StatefulWidget {
  const FinancialNewsTicker({super.key});

  @override
  State<FinancialNewsTicker> createState() => _FinancialNewsTickerState();
}

class _FinancialNewsTickerState extends State<FinancialNewsTicker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const double _speed = 60.0; // px per second
  static const double _approxCharWidth = 8.0;

  late final double _totalWidth;

  @override
  void initState() {
    super.initState();
    _totalWidth = _estimateTotalWidth();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: (_totalWidth / _speed * 1000).round(),
      ),
    )..repeat();
  }

  double _estimateTotalWidth() {
    double total = 0;
    for (final h in _headlines) {
      total += h.length * _approxCharWidth + 80;
    }
    return total;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        height: 36,
        color: AppColors.surface,
        child: Row(
          children: [
            // Static label — never rebuilds
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              color: AppColors.surfaceElevated,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('📰', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 6),
                  Text(
                    'Headlines',
                    style: GoogleFonts.dmSans(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // AnimatedBuilder: only the Transform.translate subtree redraws
            Expanded(
              child: ClipRect(
                child: Stack(
                  children: [
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(
                          -(_controller.value * _totalWidth) % _totalWidth,
                          0,
                        ),
                        child: child,
                      ),
                      // OverflowBox tells Flutter this Row is intentionally
                      // wider than the viewport — suppresses the overflow error.
                      child: OverflowBox(
                        alignment: Alignment.centerLeft,
                        maxWidth: double.infinity,
                        child: Row(
                          children: _tickerItems.map((h) => _TickerItem(text: h)).toList(),
                        ),
                      ),
                    ),
                    // Fade overlays — const, never rebuild
                    const Positioned(
                      left: 0, top: 0, bottom: 0, width: 32,
                      child: DecoratedBox(decoration: _leftFade),
                    ),
                    const Positioned(
                      right: 0, top: 0, bottom: 0, width: 32,
                      child: DecoratedBox(decoration: _rightFade),
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

class _TickerItem extends StatelessWidget {
  final String text;
  const _TickerItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: GoogleFonts.dmSans(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.0,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '•',
            style: GoogleFonts.dmSans(
              color: AppColors.textMuted,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}
