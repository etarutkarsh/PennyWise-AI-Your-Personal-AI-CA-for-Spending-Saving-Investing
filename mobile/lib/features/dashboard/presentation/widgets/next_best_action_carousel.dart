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
  final String goalType;
  final String action;           // HERO: what the user should do
  final List<String> whyToday;  // 2-3 contextual trigger bullets
  final int currentPct;
  final int projectedPct;
  final List<String> factors;
  final int confidencePct;
  final int healthScoreDelta;    // estimated health score improvement
  final int freedomRunwayMonths; // estimated additional months of financial runway
  final String instrument;       // supporting product (shown last, subdued)
  final String? partnerName;

  const _NextBestAction({
    required this.goalName,
    required this.goalEmoji,
    required this.goalType,
    required this.action,
    required this.whyToday,
    required this.currentPct,
    required this.projectedPct,
    required this.factors,
    required this.confidencePct,
    required this.healthScoreDelta,
    required this.freedomRunwayMonths,
    required this.instrument,
    this.partnerName,
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

  bool get isEfGoal => goalType.toLowerCase() == 'emergency_fund';
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
    List<String> whyToday;
    int projectedPct;
    int confidencePct;

    if (goal.currentSaved >= goal.targetAmount) {
      action = 'Move your surplus toward your next milestone.';
      whyToday = [
        'This goal is complete — momentum is your biggest asset now.',
        'Idle surplus loses value to inflation every month.',
      ];
      projectedPct = 100;
      confidencePct = 99;
    } else if (coverage >= 1.05) {
      action = 'Optimise your $instrument for ${_yieldHint(instrument)} returns.';
      whyToday = [
        'You\'re on track — better rate could reach goal ${max(1, (monthsLeft * 0.10).round())} months early.',
        'Market conditions favour switching to a higher-yield option.',
      ];
      projectedPct = min(currentPct + 7, 96);
      confidencePct = 88;
    } else if (gap > 0 && gap <= salary * 0.12) {
      action = 'Increase monthly saving by ${_fmt.format(gap.round())}.';
      final newPct = min(currentPct + 22, 92);
      whyToday = [
        'Small gap — closeable with ${_fmt.format(gap.round())} more per month.',
        'Raises success probability from $currentPct% to $newPct% immediately.',
        'Your current income level supports this increase.',
      ];
      projectedPct = newPct;
      confidencePct = 85;
    } else {
      final extendMonths = monthlyHave > 0
          ? max(3, (gap / monthlyHave * monthsLeft).round())
          : 12;
      action = 'Extend deadline by $extendMonths months, or increase savings.';
      whyToday = [
        'Current contributions won\'t reach the target by ${_month(goal.deadline)}.',
        'Extending deadline or increasing savings are both viable paths.',
      ];
      projectedPct = min(currentPct + 18, 85);
      confidencePct = 72;
    }

    final healthDelta = _healthDelta(confidencePct, currentPct, projectedPct);
    final runwayDelta = _runwayDelta(projectedPct - currentPct, goal.goalType);

    return _NextBestAction(
      goalName: goal.name,
      goalEmoji: _emoji(goal.goalType),
      goalType: goal.goalType,
      action: action,
      whyToday: whyToday,
      currentPct: currentPct,
      projectedPct: projectedPct,
      factors: _factors(goal, monthsLeft, salary, gap),
      confidencePct: confidencePct,
      healthScoreDelta: healthDelta,
      freedomRunwayMonths: runwayDelta,
      instrument: instrument,
      partnerName: _partner(instrument),
    );
  }

  static List<_NextBestAction> _defaults(double salary) {
    final monthlyExpenses = salary * 0.80;
    final efTarget = monthlyExpenses * 6;
    final sipAmount = (salary * 0.08).round();

    return [
      _NextBestAction(
        goalName: 'Emergency Fund',
        goalEmoji: '🛡️',
        goalType: 'emergency_fund',
        action: 'Start saving ${_fmt.format((salary * 0.12).round())}/month for emergencies.',
        whyToday: [
          'No emergency fund detected — your highest financial risk right now.',
          'Six months of expenses (${_fmt.format(efTarget.round())}) is the gold standard. You\'re at zero.',
          'One unexpected event could destabilise your entire financial plan.',
        ],
        currentPct: 0,
        projectedPct: 62,
        confidencePct: 91,
        healthScoreDelta: 9,
        freedomRunwayMonths: 8,
        factors: [
          'No existing emergency goal detected',
          '6-month target is the financial gold standard',
          'Zero-risk instrument appropriate for this purpose',
        ],
        instrument: 'Recurring Deposit',
        partnerName: 'HDFC Bank',
      ),
      _NextBestAction(
        goalName: 'Long-term Wealth',
        goalEmoji: '📈',
        goalType: 'investment',
        action: 'Start a SIP of ${_fmt.format(sipAmount)}/month.',
        whyToday: [
          'No investment goal detected — time in market beats timing the market.',
          'At 12% p.a., ₹$sipAmount/month becomes ${_fmt.format(sipAmount * 240)} in 20 years.',
          '8% of salary is the minimum recommended starting rate.',
        ],
        currentPct: 0,
        projectedPct: 58,
        confidencePct: 84,
        healthScoreDelta: 6,
        freedomRunwayMonths: 5,
        factors: [
          'Long horizon supports equity growth',
          'SIP averages out market volatility',
          '8% of salary is a sustainable starting rate',
        ],
        instrument: 'Equity Mutual Fund',
        partnerName: 'Mirae Asset',
      ),
    ];
  }

  static int _healthDelta(int confidencePct, int currentPct, int projectedPct) {
    final goalDelta = projectedPct - currentPct;
    if (confidencePct >= 85) return (goalDelta * 0.38).round().clamp(5, 12);
    if (confidencePct >= 70) return (goalDelta * 0.25).round().clamp(3, 8);
    return (goalDelta * 0.15).round().clamp(1, 4);
  }

  static int _runwayDelta(int goalDelta, String goalType) {
    if (goalType.toLowerCase() == 'emergency_fund') {
      return (goalDelta * 0.25).round().clamp(1, 12);
    }
    return (goalDelta * 0.15).round().clamp(1, 8);
  }

  static int _monthsBetween(DateTime from, DateTime to) =>
      (to.year - from.year) * 12 + (to.month - from.month);

  static String _month(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month]} ${dt.year}';
  }

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
    if (instrument.contains('RD') || instrument.contains('Recurring')) return '6.5–7.5%';
    return '6–7%';
  }

  static String? _partner(String instrument) {
    if (instrument.contains('ELSS')) return 'Mirae Asset';
    if (instrument.contains('Equity')) return 'Axis Mutual Fund';
    if (instrument.contains('Hybrid')) return 'HDFC MF';
    if (instrument.contains('RD') || instrument.contains('Recurring')) return 'HDFC Bank';
    if (instrument.contains('Liquid')) return 'Parag Parikh';
    if (instrument.contains('PPF')) return 'SBI Bank';
    return null;
  }

  static String _emoji(String goalType) {
    switch (goalType.toLowerCase()) {
      case 'emergency_fund': return '🛡️';
      case 'house':          return '🏠';
      case 'car':            return '🚗';
      case 'vacation':       return '✈️';
      case 'education':      return '🎓';
      case 'retirement':     return '🌅';
      case 'wedding':        return '💍';
      case 'laptop':         return '💻';
      default:               return '🎯';
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
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                  style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textMuted),
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
            height: 390,
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
            // ── 1. Eyebrow: goal context + strength ─────────────────────
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

            const SizedBox(height: 10),

            // ── 2. HERO: the recommended action ─────────────────────────
            Text(
              action.action,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.45,
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 12),

            // ── 3. Why today? ────────────────────────────────────────────
            Text(
              'WHY TODAY?',
              style: GoogleFonts.dmSans(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            ...action.whyToday.take(2).map(
              (bullet) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
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
                        bullet,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 12),

            // ── 4. Decision Impact ───────────────────────────────────────
            Text(
              'DECISION IMPACT',
              style: GoogleFonts.dmSans(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _ImpactChip(
                  icon: Icons.favorite_rounded,
                  label: 'Health',
                  value: '+${action.healthScoreDelta}',
                  color: AppColors.success,
                ),
                const SizedBox(width: 6),
                _ImpactChip(
                  icon: Icons.flag_rounded,
                  label: 'Goal',
                  value: '${action.currentPct}→${action.projectedPct}%',
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                _ImpactChip(
                  icon: Icons.shield_rounded,
                  label: action.isEfGoal ? 'EF' : 'Risk',
                  value: action.isEfGoal
                      ? '+${action.freedomRunwayMonths}mo'
                      : 'Lower',
                  color: AppColors.accent,
                ),
                const SizedBox(width: 6),
                _ImpactChip(
                  icon: Icons.timelapse_rounded,
                  label: 'Runway',
                  value: '+${action.freedomRunwayMonths}mo',
                  color: AppColors.textSecondary,
                ),
              ],
            ),

            const Spacer(),

            // ── 5. Product row (supporting, subdued) ────────────────────
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
                    Expanded(
                      child: Text(
                        '${action.instrument} · ${action.partnerName}',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── 6. CTA row ───────────────────────────────────────────────
            Row(
              children: [
                _TextCta(label: 'Explain', onTap: () => _showExplain(context)),
                const SizedBox(width: 8),
                _TextCta(label: 'Compare', onTap: () {}),
                const Spacer(),
                GestureDetector(
                  onTap: () {},
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View Options',
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
              'Why this action, why today?',
              style: GoogleFonts.manrope(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...action.whyToday.map(
              (bullet) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        bullet,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Supporting factors:',
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
                          color: AppColors.textSecondary,
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
                      'Strength: ${action.strengthLabel} · Confidence: ${action.confidencePct}%',
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
              const SizedBox(height: 16),
              Text(
                'Suggested instrument: ${action.instrument} via ${action.partnerName}',
                style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Impact Chip ───────────────────────────────────────────────────────────────

class _ImpactChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ImpactChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1.1,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 9,
                color: AppColors.textMuted,
                height: 1.2,
              ),
            ),
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
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
          height: 390,
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
                        color: shimmer, borderRadius: BorderRadius.circular(6))),
                const SizedBox(width: 8),
                Container(
                    width: 120,
                    height: 10,
                    decoration: BoxDecoration(
                        color: shimmer, borderRadius: BorderRadius.circular(5))),
              ]),
              const SizedBox(height: 14),
              Container(
                  width: double.infinity,
                  height: 18,
                  decoration: BoxDecoration(
                      color: shimmer, borderRadius: BorderRadius.circular(6))),
              const SizedBox(height: 8),
              Container(
                  width: 220,
                  height: 18,
                  decoration: BoxDecoration(
                      color: shimmer, borderRadius: BorderRadius.circular(6))),
              const SizedBox(height: 16),
              Container(
                  width: 80,
                  height: 9,
                  decoration: BoxDecoration(
                      color: shimmer, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 8),
              Container(
                  width: double.infinity,
                  height: 11,
                  decoration: BoxDecoration(
                      color: shimmer, borderRadius: BorderRadius.circular(5))),
              const SizedBox(height: 6),
              Container(
                  width: 260,
                  height: 11,
                  decoration: BoxDecoration(
                      color: shimmer, borderRadius: BorderRadius.circular(5))),
              const SizedBox(height: 20),
              Row(children: List.generate(4, (i) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                  height: 52,
                  decoration: BoxDecoration(
                      color: shimmer, borderRadius: BorderRadius.circular(10)),
                ),
              ))),
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
