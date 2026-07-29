import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class _StatData {
  final String rawValue;
  final double countTo;
  final bool isPercent;
  final bool isOrdinal;
  final String label;
  final String explanation;
  final Color accentColor;
  final IconData icon;

  const _StatData({
    required this.rawValue,
    required this.countTo,
    required this.isPercent,
    required this.isOrdinal,
    required this.label,
    required this.explanation,
    required this.accentColor,
    required this.icon,
  });
}

const _stats = [
  _StatData(
    rawValue: '27',
    countTo: 27,
    isPercent: true,
    isOrdinal: false,
    label: 'of Indians save regularly',
    explanation: "You're in the elite 27% just by saving monthly. Most people spend every rupee they earn.",
    accentColor: AppColors.orange,
    icon: Icons.savings_outlined,
  ),
  _StatData(
    rawValue: '73',
    countTo: 73,
    isPercent: true,
    isOrdinal: false,
    label: 'have no emergency fund',
    explanation: 'One medical bill from crisis. Build 6× your monthly expenses — your financial airbag.',
    accentColor: AppColors.danger,
    icon: Icons.warning_amber_outlined,
  ),
  _StatData(
    rawValue: '80',
    countTo: 80,
    isPercent: true,
    isOrdinal: false,
    label: 'retire without savings',
    explanation: 'Your SIP today is your freedom tomorrow. The best time to start was yesterday.',
    accentColor: AppColors.amber,
    icon: Icons.elderly_outlined,
  ),
  _StatData(
    rawValue: '8th',
    countTo: 8,
    isPercent: false,
    isOrdinal: true,
    label: 'wonder: compound interest',
    explanation: '₹1,000/month at 12% for 30 years grows to ₹35 lakhs. Time is your greatest asset.',
    accentColor: AppColors.success,
    icon: Icons.trending_up_rounded,
  ),
];

class AnimatedStatsSection extends StatefulWidget {
  const AnimatedStatsSection({super.key});

  @override
  State<AnimatedStatsSection> createState() => _AnimatedStatsSectionState();
}

class _AnimatedStatsSectionState extends State<AnimatedStatsSection> {
  bool _started = false;
  Timer? _startTimer;

  @override
  void initState() {
    super.initState();
    _startTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _started = true);
    });
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Financial Reality',
            style: GoogleFonts.dmSans(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Numbers every Indian should know',
            style: GoogleFonts.dmSans(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _StatCard(stat: _stats[0], animate: _started)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(stat: _stats[1], animate: _started)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _StatCard(stat: _stats[2], animate: _started)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(stat: _stats[3], animate: _started)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatefulWidget {
  final _StatData stat;
  final bool animate;

  const _StatCard({required this.stat, required this.animate});

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hovered
                ? widget.stat.accentColor.withValues(alpha: 0.55)
                : AppColors.border,
            width: _hovered ? 1.5 : 1,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: widget.stat.accentColor.withValues(alpha: 0.14),
                    blurRadius: 18,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: widget.stat.accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.stat.icon,
                      color: widget.stat.accentColor, size: 15),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _hovered ? 1.0 : 0.0,
                  child: Icon(
                    Icons.arrow_outward_rounded,
                    color: widget.stat.accentColor,
                    size: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TweenAnimationBuilder<double>(
              tween: Tween(
                  begin: 0, end: widget.animate ? widget.stat.countTo : 0),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeOut,
              builder: (_, value, __) {
                final display = widget.stat.isOrdinal
                    ? '${value.round()}th'
                    : widget.stat.isPercent
                        ? '${value.round()}%'
                        : value.round().toString();
                return Text(
                  display,
                  style: GoogleFonts.manrope(
                    color: widget.stat.accentColor,
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                );
              },
            ),
            const SizedBox(height: 5),
            Text(
              widget.stat.label,
              style: GoogleFonts.dmSans(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.stat.explanation,
              style: GoogleFonts.dmSans(
                color: AppColors.textSecondary,
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
