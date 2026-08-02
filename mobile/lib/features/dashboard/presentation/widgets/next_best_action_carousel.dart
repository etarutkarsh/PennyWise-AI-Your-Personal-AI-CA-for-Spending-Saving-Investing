import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/app_services.dart';
import '../../../../core/services/storage/user_prefs_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../goals/domain/entities/goal_entity.dart';

// ── Action Model ──────────────────────────────────────────────────────────────

class _NextBestAction {
  final String goalName;
  final String goalEmoji;
  final String action;       // HERO: what the user should do
  final String why;          // 1 sentence explaining the impact
  final int currentPct;
  final int projectedPct;
  final List<String> factors;
  final int confidencePct;
  final String instrument;   // supporting product (shown last)
  final String? partnerName;
  final String? partnerCta;

  const _NextBestAction({
    required this.goalName,
    required this.goalEmoji,
    required this.action,
    required this.why,
    required this.currentPct,
    required this.projectedPct,
    required this.factors,
    required this.confidencePct,
    required this.instrument,
    this.partnerName,
    this.partnerCta,
  });

  int get delta => projectedPct - currentPct;

  String get strengthLabel {
    if (confidencePct >= 85) return 'HIGH';
    if (confidencePct >= 70) return 'MEDIUM';
    return 'LOW';
  }

  Color get strengthColor {
    if (confidencePct >= 85) return AppColors.success;
    if (confidencePct >= 70) return AppColors.warning;
    return AppColors.danger;
  }
}

// ── Action Engine ─────────────────────────────────────────────────────────────

class _ActionEngine {
  static final _fmt =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  static List<_NextBestAction> compute(List<GoalEntity> goals, double salary) {
    if (goals.isEmpty) return _defaults(salary);
    final actions = goals.map((g) => _fromGoal(g, salary)).toList();
    // Off-track goals surface first, then by confidence
    actions.sort((a, b) {
      final aOff = a.currentPct < 70;
      final bOff = b.currentPct < 70;
      if (aOff && !bOff) return -1;
      if (!aOff && bOff) return 1;
      return b.confidencePct.compareTo(a.confidencePct);
    });
    return actions;
  }

  static _NextBestAction _fromGoal(GoalEntity goal, double salary) {
    final now = DateTime.now();
    final monthsLeft = max(1, _monthsBetween(now, goal.deadline));
    final amountLeft = max(0.0, goal.targetAmount - goal.currentSaved);
    final monthlyNeeded = amountLeft / monthsLeft;
    final monthlyHave = goal.recommendedMonthlyContribution;

    final coverage = monthlyNeeded <= 0
        ? 1.2
        : (monthlyHave / monthlyNeeded).clamp(0.0, 1.2);
    final savedFrac = goal.targetAmount > 0
        ? (goal.currentSaved / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final rawPct = (coverage * 0.70 + savedFrac * 0.30) * 82.0;
    final currentPct = rawPct.round().clamp(5, 93);

    final instrument = _instrument(goal.goalType, monthsLeft);
    final gap = monthlyNeeded - monthlyHave;

    String action;
    String why;
    int projectedPct;
    int confidencePct;

    if (goal.currentSaved >= goal.targetAmount) {
      action = 'Move your surplus toward your next milestone.';
      why = 'This goal is complete. Your discipline is compounding.';
      projectedPct = 100;
      confidencePct = 99;
    } else if (coverage >= 1.05) {
      action =
          'Optimise your $instrument for ${_yieldHint(instrument)} returns.';
      why =
          'You\'re on track — a better rate could reach your goal ${max(1, (monthsLeft * 0.10).round())} months early.';
      projectedPct = min(currentPct + 7, 96);
      confidencePct = 88;
    } else if (gap > 0 && gap <= salary * 0.12) {
      action = 'Increase monthly saving by ${_fmt.format(gap.round())}.';
      final newPct = min(currentPct + 22, 92);
      why =
          'Closes the gap on ${goal.name} and raises success probability from $currentPct% to $newPct%.';
      projectedPct = newPct;
      confidencePct = 85;
    } else {
      final extendMonths = monthlyHave > 0
          ? max(3, (gap / monthlyHave * monthsLeft).round())
          : 12;
      action = 'Extend deadline by $extendMonths months, or increase savings.';
      why = 'Brings ${goal.name} within reach at your current income level.';
      projectedPct = min(currentPct + 18, 85);
      confidencePct = 72;
    }

    return _NextBestAction(
      goalName: goal.name,
      goalEmoji: _emoji(goal.goalType),
      action: action,
      why: why,
      currentPct: currentPct,
      projectedPct: projectedPct,
      factors: _factors(goal, monthsLeft, salary, gap),
      confidencePct: confidencePct,
      instrument: instrument,
      partnerName: _partner(instrument),
      partnerCta: _partnerCta(instrument),
    );
  }

  static List<_NextBestAction> _defaults(double salary) {
    final monthlyExpenses = salary * 0.80;
    final emergencyTarget = monthlyExpenses * 6;
    final sipAmount = (salary * 0.08).round();

    return [
      _NextBestAction(
        goalName: 'Emergency Fund',
        goalEmoji: '🛡️',
        action:
            'Start saving ${_fmt.format((salary * 0.12).round())}/month for emergencies.',
        why:
            'Builds a ${_fmt.format(emergencyTarget.round())} safety net in ~2 years — the single highest-impact financial move you can make.',
        currentPct: 0,
        projectedPct: 62,
        confidencePct: 91,
        factors: [
          'No existing emergency goal detected',
          '6-month target is the financial gold standard',
          'Zero-risk instrument appropriate for this purpose',
        ],
        instrument: 'Recurring Deposit',
        partnerName: 'HDFC Bank',
        partnerCta: 'Open RD',
      ),
      _NextBestAction(
        goalName: 'Long-term Wealth',
        goalEmoji: '📈',
        action: 'Start a SIP of ${_fmt.format(sipAmount)}/month.',
        why:
            'At 12% p.a., ₹$sipAmount/month becomes ${_fmt.format(sipAmount * 240)} in 20 years through compounding.',
        currentPct: 0,
        projectedPct: 58,
        confidencePct: 84,
        factors: [
          'Long horizon supports equity growth',
          'SIP averages out market volatility',
          '8% of salary is a sustainable starting rate',
        ],
        instrument: 'Equity Mutual Fund',
        partnerName: 'Mirae Asset',
        partnerCta: 'Start SIP',
      ),
    ];
  }

  static int _monthsBetween(DateTime from, DateTime to) =>
      (to.year - from.year) * 12 + (to.month - from.month);

  static String _instrument(String goalType, int monthsLeft) {
    if (monthsLeft < 12) return 'Liquid Fund';
    if (monthsLeft < 24) return 'Recurring Deposit';
    if (monthsLeft < 48) {
      if (goalType == 'retirement') return 'PPF';
      return 'Hybrid Mutual Fund';
    }
    if (goalType == 'retirement') return 'Equity Mutual Fund (ELSS)';
    return 'Equity Mutual Fund';
  }

  static String _yieldHint(String instrument) {
    if (instrument.contains('Equity')) return '12–14%';
    if (instrument.contains('Hybrid')) return '9–11%';
    if (instrument.contains('PPF')) return '7.1%';
    if (instrument.contains('RD') || instrument.contains('Recurring')) {
      return '6.5–7.5%';
    }
    return '6–7%';
  }

  static String? _partner(String instrument) {
    if (instrument.contains('ELSS')) return 'Mirae Asset';
    if (instrument.contains('Equity')) return 'Axis Mutual Fund';
    if (instrument.contains('Hybrid')) return 'HDFC MF';
    if (instrument.contains('RD') || instrument.contains('Recurring')) {
      return 'HDFC Bank';
    }
    if (instrument.contains('Liquid')) return 'Parag Parikh';
    if (instrument.contains('PPF')) return 'SBI Bank';
    return null;
  }

  static String? _partnerCta(String instrument) {
    if (instrument.contains('Equity') ||
        instrument.contains('Hybrid') ||
        instrument.contains('Liquid')) {
      return 'Start SIP';
    }
    if (instrument.contains('RD') || instrument.contains('Recurring')) {
      return 'Open RD';
    }
    if (instrument.contains('PPF')) return 'Open PPF Account';
    return null;
  }

  static String _emoji(String goalType) {
    switch (goalType.toLowerCase()) {
      case 'emergency_fund':
        return '🛡️';
      case 'house':
        return '🏠';
      case 'car':
        return '🚗';
      case 'vacation':
        return '✈️';
      case 'education':
        return '🎓';
      case 'retirement':
        return '🌅';
      case 'wedding':
        return '💍';
      case 'laptop':
        return '💻';
      default:
        return '🎯';
    }
  }

  static List<String> _factors(
      GoalEntity goal, int monthsLeft, double salary, double gap) {
    final factors = <String>[];
    final years = monthsLeft / 12;
    if (years >= 5) {
      factors.add('${years.toStringAsFixed(0)}-year horizon supports growth');
    } else if (years >= 2) {
      factors.add('${years.toStringAsFixed(1)}-year medium-term goal');
    } else {
      factors.add('Short timeline — capital safety prioritised');
    }
    if (goal.currentSaved > 0 && goal.targetAmount > 0) {
      final pct = (goal.currentSaved / goal.targetAmount * 100).round();
      factors.add('$pct% already saved — momentum is building');
    }
    if (gap > 0 && gap <= salary * 0.05) {
      factors.add('Small gap — easy to close');
    } else if (gap <= 0) {
      factors.add('Current contributions are sufficient');
    } else {
      factors.add('Matches your risk profile');
    }
    return factors.take(3).toList();
  }
}

// ── Main Carousel Widget ──────────────────────────────────────────────────────

class NextBestActionCarousel extends StatefulWidget {
  const NextBestActionCarousel({super.key});

  @override
  State<NextBestActionCarousel> createState() => _NextBestActionCarouselState();
}

class _NextBestActionCarouselState extends State<NextBestActionCarousel> {
  final _pageController = PageController(viewportFraction: 0.92);
  int _page = 0;
  List<_NextBestAction> _actions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final salary = await UserPrefsStorage.getSalary();
      final goals = await AppServices.instance.goals.getAll();
      if (mounted) {
        setState(() {
          _actions = _ActionEngine.compute(goals, salary);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next Best Action',
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            '🤖 AI CA',
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Behaviour over products',
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
              if (!_loading && _actions.isNotEmpty)
                Text(
                  '${_page + 1} / ${_actions.length}',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Cards ───────────────────────────────────────────────────────
        if (_loading)
          _SkeletonCard()
        else if (_actions.isEmpty)
          _EmptyState()
        else
          SizedBox(
            height: 340,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _actions.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => _ActionCard(action: _actions[i]),
            ),
          ),

        // ── Dots ────────────────────────────────────────────────────────
        if (!_loading && _actions.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_actions.length, (i) {
              final active = i == _page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.border,
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

// ── Action Card ───────────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final _NextBestAction action;
  const _ActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Eyebrow: goal context + strength ────────────────────────
            Row(
              children: [
                Text(action.goalEmoji, style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    action.goalName.toUpperCase(),
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 0.8,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _StrengthBadge(
                  label: action.strengthLabel,
                  color: action.strengthColor,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── HERO: the action ────────────────────────────────────────
            Text(
              action.action,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.45,
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 6),

            // ── Why ─────────────────────────────────────────────────────
            Text(
              action.why,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 14),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 12),

            // ── Expected outcome: before → after ────────────────────────
            Row(
              children: [
                Expanded(
                  child: _OutcomeBox(
                    label: 'Now',
                    pct: action.currentPct,
                    isProjected: false,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ),
                Expanded(
                  child: _OutcomeBox(
                    label: 'With action',
                    pct: action.projectedPct,
                    isProjected: true,
                    delta: action.delta,
                  ),
                ),
              ],
            ),

            const Spacer(),

            // ── Product row (supporting, subdued) ───────────────────────
            if (action.partnerName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.account_balance_outlined,
                      size: 12,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${action.instrument} via ${action.partnerName}',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

            // ── CTA row ─────────────────────────────────────────────────
            Row(
              children: [
                _TextCta(
                  label: 'Explain',
                  onTap: () => _showExplain(context),
                ),
                const SizedBox(width: 8),
                _TextCta(
                  label: 'Compare',
                  onTap: () {},
                ),
                const Spacer(),
                if (action.partnerCta != null)
                  GestureDetector(
                    onTap: () {},
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          action.partnerCta!,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 10,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showExplain(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Why this action?',
              style: GoogleFonts.manrope(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              action.why,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Based on your data:',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            ...action.factors.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        f,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome_outlined,
                    size: 16,
                    color: action.strengthColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Strength: ${action.strengthLabel} — based on your income, goal progress, and spending patterns.',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (action.partnerName != null) ...[
              const SizedBox(height: 20),
              Text(
                'Suggested instrument: ${action.instrument} via ${action.partnerName}',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Strength Badge ────────────────────────────────────────────────────────────

class _StrengthBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StrengthBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Outcome Box ───────────────────────────────────────────────────────────────

class _OutcomeBox extends StatelessWidget {
  final String label;
  final int pct;
  final bool isProjected;
  final int? delta;

  const _OutcomeBox({
    required this.label,
    required this.pct,
    required this.isProjected,
    this.delta,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isProjected ? AppColors.success : AppColors.textSecondary;
    final bgColor = isProjected
        ? AppColors.success.withValues(alpha: 0.08)
        : AppColors.surfaceElevated;
    final borderColor = isProjected
        ? AppColors.success.withValues(alpha: 0.25)
        : AppColors.border;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              color: isProjected
                  ? AppColors.success.withValues(alpha: 0.7)
                  : AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$pct%',
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1.0,
                ),
              ),
              if (isProjected && delta != null && delta! > 0) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    '+$delta%',
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Text CTA ──────────────────────────────────────────────────────────────────

class _TextCta extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TextCta({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _SkeletonCard extends StatefulWidget {
  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final shimmer = Color.lerp(
          AppColors.surfaceElevated,
          AppColors.border,
          _anim.value,
        )!;
        return Container(
          height: 340,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                        color: shimmer,
                        borderRadius: BorderRadius.circular(6))),
                const SizedBox(width: 8),
                Container(
                    width: 120,
                    height: 10,
                    decoration: BoxDecoration(
                        color: shimmer,
                        borderRadius: BorderRadius.circular(5))),
              ]),
              const SizedBox(height: 16),
              Container(
                  width: double.infinity,
                  height: 18,
                  decoration: BoxDecoration(
                      color: shimmer,
                      borderRadius: BorderRadius.circular(6))),
              const SizedBox(height: 8),
              Container(
                  width: 200,
                  height: 18,
                  decoration: BoxDecoration(
                      color: shimmer,
                      borderRadius: BorderRadius.circular(6))),
              const SizedBox(height: 8),
              Container(
                  width: 240,
                  height: 12,
                  decoration: BoxDecoration(
                      color: shimmer,
                      borderRadius: BorderRadius.circular(5))),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: Container(
                      height: 72,
                      decoration: BoxDecoration(
                          color: shimmer,
                          borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Container(
                      height: 72,
                      decoration: BoxDecoration(
                          color: shimmer,
                          borderRadius: BorderRadius.circular(12))),
                ),
              ]),
            ],
          ),
        );
      },
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome_rounded,
                color: AppColors.textMuted, size: 28),
            const SizedBox(height: 8),
            Text(
              'Add goals to unlock personalised next actions',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
