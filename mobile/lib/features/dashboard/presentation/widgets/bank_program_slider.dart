import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pennywise_ai/domain/partner/partner_assets.dart';
import 'package:pennywise_ai/domain/partner/partner_brand.dart';
import 'package:pennywise_ai/domain/partner/partner_icon_type.dart';
import 'package:pennywise_ai/domain/partner/ranked_partner_program.dart';

import '../../../../core/theme/app_colors.dart';

// ── Local presentation helpers (no business logic, purely display polish) ────

/// Resolves PartnerIconType → Flutter IconData.
/// Lives in presentation — domain stays Flutter-free.
IconData _resolveIcon(PartnerIconType type) {
  switch (type) {
    case PartnerIconType.savings:
      return Icons.savings_outlined;
    case PartnerIconType.trendingUp:
      return Icons.trending_up_rounded;
    case PartnerIconType.gold:
      return Icons.monetization_on_outlined;
    case PartnerIconType.tax:
      return Icons.account_balance_outlined;
    case PartnerIconType.autoSave:
      return Icons.flash_on_rounded;
    case PartnerIconType.creditCard:
      return Icons.credit_card_rounded;
    case PartnerIconType.generic:
      return Icons.bar_chart_rounded;
  }
}

/// Best-effort goal chip label — derived from RankedPartnerProgram
/// matchExplanation which the mapper formats as "Matched to: <goal>".
String _goalChipFromProgram(RankedPartnerProgram p) {
  final ex = p.matchExplanation;
  if (ex.startsWith('Matched to:')) {
    return ex.substring('Matched to:'.length).trim();
  }
  if (ex.isNotEmpty) return ex;
  return 'Your Goals';
}

// ── Main Widget ───────────────────────────────────────────────────────────────

class BankProgramSlider extends StatefulWidget {
  const BankProgramSlider({super.key, required this.programs});

  final List<RankedPartnerProgram> programs;

  @override
  State<BankProgramSlider> createState() => _BankProgramSliderState();
}

class _BankProgramSliderState extends State<BankProgramSlider> {
  final _ctrl = PageController(viewportFraction: 0.86);
  int _page = 0;
  Timer? _timer;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.programs.length <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_dragging || !mounted) return;
      final next = (_page + 1) % widget.programs.length;
      _ctrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final programs = widget.programs;
    if (programs.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section Header ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Programs For Your Goals',
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Matched to what you\'re trying to achieve',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _PillDots(count: programs.length, current: _page),
            ],
          ),
        ),

        // ── Carousel ──────────────────────────────────────────────────────
        SizedBox(
          height: 246,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is ScrollStartNotification) _dragging = true;
              if (n is ScrollEndNotification) {
                _dragging = false;
                _startTimer();
              }
              return false;
            },
            child: PageView.builder(
              controller: _ctrl,
              itemCount: programs.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (ctx, i) {
                final active = i == _page;
                return AnimatedScale(
                  scale: active ? 1.0 : 0.95,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: _ProgramCard(
                    program: programs[i],
                    onLearnMore: () => _openDetail(ctx, programs[i]),
                  ),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ── Goal Filter Tabs ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _GoalTabs(
            programs: programs,
            selected: _page,
            onSelect: (i) {
              _ctrl.animateToPage(
                i,
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutCubic,
              );
            },
          ),
        ),
      ],
    );
  }

  void _openDetail(BuildContext ctx, RankedPartnerProgram p) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProgramDetailSheet(program: p),
    );
  }
}

// ── Program Card ──────────────────────────────────────────────────────────────

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({required this.program, required this.onLearnMore});
  final RankedPartnerProgram program;
  final VoidCallback onLearnMore;

  @override
  Widget build(BuildContext context) {
    final pp = program.program;
    final bankColor = Color(pp.brand.primaryColorHex);
    return GestureDetector(
      onTap: onLearnMore,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: bankColor.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Visual image area ────────────────────────────────────────
            _ProgramImageArea(program: program),

            // ── Card body ────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Goal context chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.30),
                        ),
                      ),
                      child: Text(
                        '🎯  ${_goalChipFromProgram(program)}',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 7),

                    // Product name
                    Text(
                      '${pp.partnerName} · ${pp.productName}',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 3),

                    // Product benefit tagline — what this product actually does for you
                    Text(
                      pp.tagline.isNotEmpty ? pp.tagline : program.trustStatement,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

                    // CTA row
                    Row(
                      children: [
                        Expanded(
                          child: _CTAButton(
                            label: program.ctaLabel,
                            isPrimary: false,
                            color: bankColor,
                            onTap: onLearnMore,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _CTAButton(
                          label: 'Learn',
                          isPrimary: true,
                          color: bankColor,
                          onTap: onLearnMore,
                        ),
                      ],
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

// ── Partner Logo Widget ───────────────────────────────────────────────────────
// Renders a partner logo using the PartnerAssets contract:
//   1. If a bundled image path is available → Image.asset() (Sprint 2 step 2)
//   2. If a network URL override is loaded   → Image.network() (Sprint 4)
//   3. Fallback: styled short-name text treatment (always available)
// Theme-aware: prefers darkLogoAssetPath in dark mode.

class _PartnerLogoWidget extends StatelessWidget {
  const _PartnerLogoWidget({required this.brand});
  final PartnerBrand brand;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final assets = brand.assets;
    final logoPath = brightness == Brightness.dark
        ? (assets.darkLogoAssetPath ?? assets.logoAssetPath)
        : (assets.lightLogoAssetPath ?? assets.logoAssetPath);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: logoPath != null
          ? Image.asset(
              logoPath,
              height: 28,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _FallbackBrandText(brand: brand),
            )
          : _FallbackBrandText(brand: brand),
    );
  }
}

/// Text treatment used when no logo image is available.
/// Uses brand.shortName so the label is always intentional, not auto-derived.
class _FallbackBrandText extends StatelessWidget {
  const _FallbackBrandText({required this.brand});
  final PartnerBrand brand;

  @override
  Widget build(BuildContext context) {
    return Text(
      brand.shortName,
      style: GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        letterSpacing: 0.6,
        height: 1.1,
      ),
    );
  }
}

// ── Visual Image Area ─────────────────────────────────────────────────────────

class _ProgramImageArea extends StatelessWidget {
  const _ProgramImageArea({required this.program});
  final RankedPartnerProgram program;

  @override
  Widget build(BuildContext context) {
    final pp = program.program;
    final bankColor = Color(pp.brand.primaryColorHex);
    final bankColorDark = Color(pp.brand.darkColorHex);
    final icon = _resolveIcon(pp.brand.assets.fallbackIcon);
    return Container(
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bankColor, bankColorDark],
        ),
      ),
      child: Stack(
        children: [
          // Large decorative circle (top-right)
          Positioned(
            right: -28,
            top: -28,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          // Small circle (bottom-left)
          Positioned(
            left: -18,
            bottom: -22,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                // Partner logo block — resolves via PartnerAssets contract
                _PartnerLogoWidget(brand: pp.brand),

                const Spacer(),

                // Key metric (the headline number)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      pp.keyMetric,
                      style: GoogleFonts.manrope(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      pp.keyMetricLabel,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.70),
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 12),

                // Product icon in circle (replaces emoji — renders crisply on all Android versions)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Center(
                    child: Icon(icon, color: Colors.white, size: 22),
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

// ── CTA Button ────────────────────────────────────────────────────────────────

class _CTAButton extends StatelessWidget {
  const _CTAButton({
    required this.label,
    required this.isPrimary,
    required this.color,
    required this.onTap,
  });
  final String label;
  final bool isPrimary;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isPrimary ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: isPrimary
              ? null
              : Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isPrimary ? Colors.white : color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ── Goal Filter Tabs ──────────────────────────────────────────────────────────

class _GoalTabs extends StatelessWidget {
  const _GoalTabs({
    required this.programs,
    required this.selected,
    required this.onSelect,
  });
  final List<RankedPartnerProgram> programs;
  final int selected;
  final void Function(int) onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(programs.length, (i) {
          final p = programs[i];
          final pp = p.program;
          final active = i == selected;
          final bankColor = Color(pp.brand.primaryColorHex);
          final icon = _resolveIcon(pp.brand.assets.fallbackIcon);
          final shortLabel = pp.brand.shortName;
          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: active
                    ? bankColor.withValues(alpha: 0.10)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active
                      ? bankColor.withValues(alpha: 0.40)
                      : AppColors.border,
                  width: active ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: active ? 13 : 12,
                    color: active ? bankColor : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    shortLabel,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight:
                          active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? bankColor : AppColors.textSecondary,
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

// ── Dot Indicators ────────────────────────────────────────────────────────────

class _PillDots extends StatelessWidget {
  const _PillDots({required this.count, required this.current});
  final int count, current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(left: 4),
          width: active ? 16 : 5,
          height: 5,
          decoration: BoxDecoration(
            color: active
                ? AppColors.secondary
                : AppColors.secondary.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

// ── Detail Bottom Sheet ───────────────────────────────────────────────────────

class _ProgramDetailSheet extends StatelessWidget {
  const _ProgramDetailSheet({required this.program});
  final RankedPartnerProgram program;

  @override
  Widget build(BuildContext context) {
    final pp = program.program;
    final bankColor = Color(pp.brand.primaryColorHex);
    final bankColorDark = Color(pp.brand.darkColorHex);
    final icon = _resolveIcon(pp.brand.assets.fallbackIcon);
    return DraggableScrollableSheet(
      initialChildSize: 0.80,
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
              // Detail header image
              const SizedBox(height: 4),
              Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [bankColor, bankColorDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 14),
                  child: Row(
                    children: [
                      Icon(icon, color: Colors.white, size: 38),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              pp.partnerName,
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.65),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              pp.productName,
                              style: GoogleFonts.manrope(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            pp.keyMetric,
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                          ),
                          Text(
                            pp.keyMetricLabel,
                            style: GoogleFonts.dmSans(
                              fontSize: 9,
                              color: Colors.white.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
                  children: [
                    // Goal context
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.20),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text('🎯', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Matched to: ${_goalChipFromProgram(program)}',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accent,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  program.matchExplanation,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 1. What you get
                    _DetailSection(
                      label: 'WHAT YOU GET',
                      accentColor: bankColor,
                      child: Text(
                        '${pp.productName} from ${pp.partnerName}. '
                        'Highlight: ${pp.keyMetric} — ${pp.keyMetricLabel.toLowerCase()}.',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          height: 1.65,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 2. Quick facts (derived from the domain entity)
                    _DetailSection(
                      label: 'QUICK FACTS',
                      accentColor: bankColor,
                      child: Column(
                        children: [
                          _FactRow(
                            text:
                                'Minimum amount: ₹${pp.minAmount.amount.toStringAsFixed(0)}',
                            color: bankColor,
                          ),
                          _FactRow(
                            text: 'Instrument: ${pp.instrument.label}',
                            color: bankColor,
                          ),
                          _FactRow(
                            text: 'Risk level: ${pp.riskLevel.label}',
                            color: bankColor,
                          ),
                          if (pp.taxBenefit)
                            _FactRow(
                              text: 'Qualifies for tax benefit (80C)',
                              color: bankColor,
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // CTA (Explain → Compare → Apply hierarchy)
                    _CTASection(program: program),
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

class _DetailSection extends StatelessWidget {
  const _DetailSection({
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

class _FactRow extends StatelessWidget {
  const _FactRow({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CTASection extends StatelessWidget {
  const _CTASection({required this.program});
  final RankedPartnerProgram program;

  @override
  Widget build(BuildContext context) {
    final pp = program.program;
    final bankColor = Color(pp.brand.primaryColorHex);
    final bankColorDark = Color(pp.brand.darkColorHex);
    return Column(
      children: [
        // Primary CTA
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [bankColor, bankColorDark],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  program.ctaLabel,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Secondary CTA
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: bankColor.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: bankColor.withValues(alpha: 0.22),
                ),
              ),
              child: Center(
                child: Text(
                  'Not right now',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Trust note (comes from the domain entity, not hardcoded)
        Text(
          program.trustStatement,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            color: AppColors.textMuted,
            height: 1.5,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
