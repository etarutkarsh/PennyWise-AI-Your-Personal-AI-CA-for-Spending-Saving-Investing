import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';

class MotivationCardsSection extends StatelessWidget {
  final double salary;
  final double savings;

  const MotivationCardsSection({
    super.key,
    required this.salary,
    required this.savings,
  });

  double _projectedWealth(double monthlySavings, double annualRate, int years) {
    if (monthlySavings <= 0) return 0;
    final r = annualRate / 12;
    final n = years * 12;
    return monthlySavings * (pow(1 + r, n) - 1) / r;
  }

  String _formatCompact(double value) {
    if (value >= 10000000) {
      return '₹${(value / 10000000).toStringAsFixed(2)} Cr';
    } else if (value >= 100000) {
      return '₹${(value / 100000).toStringAsFixed(1)} L';
    }
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
        .format(value);
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
        locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final projected = _projectedWealth(savings, 0.10, 20);

    final cards = [
      _CardData(
        emoji: '💰',
        tag: 'THIS MONTH',
        value: currency.format(savings),
        headline: 'Saved',
        encourage:
            'Your financial armor is growing. This single habit separates those who retire free from those who retire broke.',
        accent: AppColors.success,
        accentBg: AppColors.success.withValues(alpha: 0.10),
      ),
      _CardData(
        emoji: '🏆',
        tag: 'PEER RANKING',
        value: 'Top 28%',
        headline: 'Of earners your age',
        encourage:
            '72% of people earning like you save less. Keep this pace 3 more years and you hit the top 10%.',
        accent: const Color(0xFF4FC3F7),
        accentBg: const Color(0xFF4FC3F7).withValues(alpha: 0.10),
      ),
      _CardData(
        emoji: '🔥',
        tag: 'CONSISTENCY',
        value: '18 Days',
        headline: 'Savings streak',
        encourage:
            'You haven\'t missed a day in 18 days. Habits compound faster than money — don\'t break the chain now.',
        accent: AppColors.orange,
        accentBg: AppColors.orange.withValues(alpha: 0.10),
      ),
      _CardData(
        emoji: '📈',
        tag: 'IN 20 YEARS',
        value: _formatCompact(projected),
        headline: 'Projected wealth',
        encourage:
            'At this savings rate you\'ll retire with ${_formatCompact(projected)}. That\'s your freedom number — guard it.',
        accent: AppColors.amber,
        accentBg: AppColors.amber.withValues(alpha: 0.10),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Your Momentum',
                style: GoogleFonts.dmSans(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'LIVE',
                  style: GoogleFonts.dmSans(
                    color: AppColors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _MotivationCard(data: cards[0])),
                const SizedBox(width: 12),
                Expanded(child: _MotivationCard(data: cards[1])),
              ],
            ),
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _MotivationCard(data: cards[2])),
                const SizedBox(width: 12),
                Expanded(child: _MotivationCard(data: cards[3])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardData {
  final String emoji;
  final String tag;
  final String value;
  final String headline;
  final String encourage;
  final Color accent;
  final Color accentBg;

  const _CardData({
    required this.emoji,
    required this.tag,
    required this.value,
    required this.headline,
    required this.encourage,
    required this.accent,
    required this.accentBg,
  });
}

class _MotivationCard extends StatefulWidget {
  final _CardData data;
  const _MotivationCard({required this.data});

  @override
  State<_MotivationCard> createState() => _MotivationCardState();
}

class _MotivationCardState extends State<_MotivationCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.surfaceElevated : AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _hovered
                ? d.accent.withValues(alpha: 0.5)
                : AppColors.border,
            width: _hovered ? 1.5 : 1.0,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: d.accent.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tag + emoji badge row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: d.accentBg,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    d.emoji,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    d.tag,
                    style: GoogleFonts.dmSans(
                      color: d.accent,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Big value
            Text(
              d.value,
              style: GoogleFonts.manrope(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 3),

            // Headline (what the value means)
            Text(
              d.headline,
              style: GoogleFonts.dmSans(
                color: d.accent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 12),

            // Divider
            Container(height: 1, color: AppColors.border),

            const SizedBox(height: 12),

            // Encouragement copy
            Text(
              d.encourage,
              style: GoogleFonts.dmSans(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
