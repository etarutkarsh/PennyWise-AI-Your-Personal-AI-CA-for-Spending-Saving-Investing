import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class _StatData {
  final String rawValue;
  final double countTo;
  final bool isPercent;
  final bool isOrdinal;
  final String description;
  final Color accentColor;
  final IconData icon;

  const _StatData({
    required this.rawValue,
    required this.countTo,
    required this.isPercent,
    required this.isOrdinal,
    required this.description,
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
    description: 'of Indians regularly save money',
    accentColor: AppColors.orange,
    icon: Icons.savings_outlined,
  ),
  _StatData(
    rawValue: '73',
    countTo: 73,
    isPercent: true,
    isOrdinal: false,
    description: 'have no emergency fund',
    accentColor: AppColors.danger,
    icon: Icons.warning_amber_outlined,
  ),
  _StatData(
    rawValue: '80',
    countTo: 80,
    isPercent: true,
    isOrdinal: false,
    description: 'retire without adequate savings',
    accentColor: AppColors.amber,
    icon: Icons.elderly_outlined,
  ),
  _StatData(
    rawValue: '8th',
    countTo: 8,
    isPercent: false,
    isOrdinal: true,
    description: 'wonder: compound interest',
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
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: _stats.map((s) {
              return _StatCard(stat: s, animate: _started);
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final _StatData stat;
  final bool animate;

  const _StatCard({required this.stat, required this.animate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: stat.accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(stat.icon, color: stat.accentColor, size: 16),
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: animate ? stat.countTo : 0),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOut,
            builder: (_, value, __) {
              final display = stat.isOrdinal
                  ? '${value.round()}th'
                  : stat.isPercent
                      ? '${value.round()}%'
                      : value.round().toString();
              return Text(
                display,
                style: GoogleFonts.manrope(
                  color: stat.accentColor,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              stat.description,
              style: GoogleFonts.dmSans(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
