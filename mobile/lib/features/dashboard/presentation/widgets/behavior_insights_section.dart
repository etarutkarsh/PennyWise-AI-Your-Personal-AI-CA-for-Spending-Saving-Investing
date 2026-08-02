import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/app_services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/repositories/behavior_repository.dart';

class BehaviorInsightsSection extends StatefulWidget {
  const BehaviorInsightsSection({super.key});

  @override
  State<BehaviorInsightsSection> createState() => _BehaviorInsightsSectionState();
}

class _BehaviorInsightsSectionState extends State<BehaviorInsightsSection> {
  BehaviorProfile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await AppServices.instance.behavior.getProfile();
      if (mounted) setState(() { _profile = profile; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _SkeletonSection();
    if (_profile == null) return const SizedBox.shrink();

    final p = _profile!;

    // If no meaningful data yet, show a teaser card
    if (!p.hasEnoughData) return _TeaserCard(profile: p);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Behavioral Profile',
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
                          '🧠 AI CA',
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'How you consistently behave',
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
            // Confidence badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _confidenceColor(p.dataConfidence).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _confidenceColor(p.dataConfidence).withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                '${p.dataConfidence} confidence',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _confidenceColor(p.dataConfidence),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ── Primary behavior label ────────────────────────────────────
        if (p.primaryBehavior != null && p.primaryBehavior!.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.psychology_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.primaryBehavior!,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      if (p.secondaryBehavior != null && p.secondaryBehavior!.isNotEmpty)
                        Text(
                          'Also: ${p.secondaryBehavior}',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: AppColors.primary.withValues(alpha: 0.7),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 12),

        // ── Trait grades grid ─────────────────────────────────────────
        _TraitsGrid(profile: p),

        const SizedBox(height: 14),

        // ── Insights ─────────────────────────────────────────────────
        if (p.insights.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BEHAVIOR THIS MONTH',
                  style: GoogleFonts.dmSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 10),
                ...p.insights.take(3).map(
                  (insight) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            insight,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // ── Stats footer ──────────────────────────────────────────────
        const SizedBox(height: 10),
        Text(
          'Based on ${p.eventsAnalyzed} events · ${p.decisionsAnalyzed} decisions · ${p.monthsOfData} months',
          style: GoogleFonts.dmSans(
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Color _confidenceColor(String confidence) {
    switch (confidence) {
      case 'HIGH':   return AppColors.success;
      case 'MEDIUM': return AppColors.warning;
      default:       return AppColors.textMuted;
    }
  }
}

// ── Trait Grades Grid ─────────────────────────────────────────────────────────

class _TraitsGrid extends StatelessWidget {
  const _TraitsGrid({required this.profile});
  final BehaviorProfile profile;

  @override
  Widget build(BuildContext context) {
    final traits = [
      ('Discipline',   profile.discipline,        Icons.military_tech_rounded),
      ('Impulse Ctrl', profile.impulseControl,     Icons.electric_bolt_rounded),
      ('Goal Focus',   profile.goalCommitment,     Icons.flag_rounded),
      ('Savings',      profile.savingsConsistency, Icons.savings_rounded),
    ];

    return Row(
      children: traits.map((t) {
        final label = t.$1;
        final grade = t.$2;
        final icon  = t.$3;
        final color = _gradeColor(grade);
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: label == 'Savings' ? 0 : 8),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.18)),
            ),
            child: Column(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(height: 6),
                Text(
                  grade ?? '–',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 9,
                    color: AppColors.textMuted,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _gradeColor(String? grade) {
    if (grade == null) return AppColors.textMuted;
    if (grade.startsWith('A')) return AppColors.success;
    if (grade.startsWith('B')) return AppColors.primary;
    if (grade.startsWith('C')) return AppColors.warning;
    return AppColors.danger;
  }
}

// ── Teaser Card (not enough data yet) ────────────────────────────────────────

class _TeaserCard extends StatelessWidget {
  const _TeaserCard({required this.profile});
  final BehaviorProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.psychology_rounded,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Building your behavioral profile…',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'PennyWise needs a few more decisions to learn how you behave.',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _SkeletonSection extends StatelessWidget {
  const _SkeletonSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
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
            width: 160,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(4, (i) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            )),
          ),
        ],
      ),
    );
  }
}
