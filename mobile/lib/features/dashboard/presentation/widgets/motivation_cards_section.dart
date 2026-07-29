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

  // Future value of annuity: FV = PMT × ((1+r)^n - 1) / r
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
        value: currency.format(savings),
        subtext: 'Keep it up! 🎯',
        label: 'Savings this month',
      ),
      _CardData(
        emoji: '🏆',
        value: '72%',
        subtext: 'of users save less than you',
        label: 'Ahead of peers',
      ),
      _CardData(
        emoji: '🔥',
        value: '18 days',
        subtext: 'Daily savings streak',
        label: 'Current streak',
      ),
      _CardData(
        emoji: '📈',
        value: _formatCompact(projected),
        subtext: 'in 20 years at current pace',
        label: 'Projected wealth',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Momentum',
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
            childAspectRatio: 1.3,
            children: cards.map((c) => _MotivationCard(data: c)).toList(),
          ),
        ],
      ),
    );
  }
}

class _CardData {
  final String emoji;
  final String value;
  final String subtext;
  final String label;

  const _CardData({
    required this.emoji,
    required this.value,
    required this.subtext,
    required this.label,
  });
}

class _MotivationCard extends StatelessWidget {
  final _CardData data;
  const _MotivationCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              data.emoji,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data.value,
            style: GoogleFonts.manrope(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              data.subtext,
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
