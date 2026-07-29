import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/app_services.dart';
import '../../../../core/services/dashboard_cache.dart';
import '../../../../core/services/storage/user_prefs_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/repositories/health_score_repository.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../widgets/hero_carousel_section.dart';
import '../widgets/market_data_section.dart';
import '../widgets/news_ticker_widget.dart';
import '../widgets/animated_stats_section.dart';
import '../widgets/motivation_cards_section.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  double _salary = 50000;
  bool _loadedSalary = false;
  HealthScoreModel? _healthScore;
  String _dailyTip = '';
  late AnimationController _animController;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _progressAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _load();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    final salary = await UserPrefsStorage.getSalary();
    if (!mounted) return;
    setState(() => _salary = salary);

    // Fire-and-forget: sync salary to backend if not set yet.
    if (salary > 0) {
      AppServices.instance.user.getMe().then((user) {
        if ((user.monthlyIncome ?? 0) <= 0) {
          AppServices.instance.user.updateMe(monthlyIncome: salary);
        }
      }).catchError((_) {});
    }

    // Serve cached data instantly; skip network on warm sessions.
    if (!forceRefresh && !DashboardCache.isStale) {
      if (mounted) {
        setState(() {
          _healthScore = DashboardCache.healthScore;
          _dailyTip = DashboardCache.dailyTip;
          _loadedSalary = true;
        });
        _animController.forward();
      }
      return;
    }

    final results = await Future.wait([
      AppServices.instance.healthScore
          .get()
          .then<HealthScoreModel?>((v) => v)
          .catchError((_) => null),
      AppServices.instance.ai.getDailyTip(),
    ]);

    if (mounted) {
      DashboardCache.set(results[0] as HealthScoreModel?, results[1] as String);
      setState(() {
        _healthScore = DashboardCache.healthScore;
        _dailyTip = DashboardCache.dailyTip;
        _loadedSalary = true;
      });
      _animController.forward();
    }
  }

  int get _level {
    final s = _healthScore?.score ?? DashboardSummary.placeholder.financialHealthScore;
    return (s / 20).floor() + 1;
  }

  int get _xpCurrent {
    final s = _healthScore?.score ?? DashboardSummary.placeholder.financialHealthScore;
    return (s % 20) * 120;
  }

  int get _xpMax => 2400;

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final savings = _salary * 0.12;
    final investments = _salary * 0.08;
    final remainingBudget = _salary - savings - investments - (_salary * 0.50);
    final tip = _dailyTip.isNotEmpty
        ? _dailyTip
        : DashboardSummary.placeholder.dailyTip;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.orange,
        backgroundColor: AppColors.surface,
        onRefresh: () => _load(forceRefresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                onNotificationsTap: () => context.push('/notifications'),
                onSettingsTap: () => context.push('/settings'),
              ),
              RepaintBoundary(child: HeroCarouselSection(salary: _salary)),
              const SizedBox(height: 20),
              const RepaintBoundary(child: MarketDataSection()),
              const SizedBox(height: 4),
              const RepaintBoundary(child: FinancialNewsTicker()),
              const SizedBox(height: 20),
              const AnimatedStatsSection(),
              const SizedBox(height: 20),
              MotivationCardsSection(salary: _salary, savings: savings),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LevelCard(
                      level: _level,
                      xpCurrent: _xpCurrent,
                      xpMax: _xpMax,
                      progressAnim: _progressAnim,
                      healthScore: _healthScore,
                    ),
                    const SizedBox(height: 28),
                    if (!_loadedSalary)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: CircularProgressIndicator(
                              color: AppColors.orange),
                        ),
                      )
                    else ...[
                      _SectionLabel(
                        label: '4 missions today',
                        badge: 'earn 850 XP',
                      ),
                      const SizedBox(height: 12),
                      _QuestCard(
                        letter: 'S',
                        letterColor: const Color(0xFF0F9D58),
                        letterBg: AppColors.questGreen,
                        title: 'Monthly Salary',
                        subtitle: currency.format(_salary),
                        xp: '+120 XP',
                        onTap: () => context.push(
                          '/detail/salary?salary=${_salary.toStringAsFixed(2)}',
                        ),
                      ),
                      _QuestCard(
                        letter: 'G',
                        letterColor: const Color(0xFF1565C0),
                        letterBg: AppColors.questBlue,
                        title: 'Savings Goal',
                        subtitle: '${currency.format(savings)} this month',
                        xp: '+90 XP',
                        onTap: () => context.push(
                          '/detail/savings?salary=${_salary.toStringAsFixed(2)}&savings=${savings.toStringAsFixed(2)}',
                        ),
                      ),
                      _QuestCard(
                        letter: 'I',
                        letterColor: const Color(0xFF6A1B9A),
                        letterBg: AppColors.questPurple,
                        title: 'Investments',
                        subtitle: '${currency.format(investments)} in SIP',
                        xp: '+80 XP',
                        onTap: () => context.push(
                          '/detail/investment?salary=${_salary.toStringAsFixed(2)}&investments=${investments.toStringAsFixed(2)}',
                        ),
                      ),
                      _QuestCard(
                        letter: 'B',
                        letterColor: const Color(0xFFE65100),
                        letterBg: AppColors.questPeach,
                        title: 'Budget Left',
                        subtitle:
                            '${currency.format(remainingBudget)} remaining',
                        xp: '+60 XP',
                        onTap: () => context.push(
                          '/detail/budget?budget=${remainingBudget.toStringAsFixed(2)}',
                        ),
                      ),
                      const SizedBox(height: 28),
                      _SectionLabel(label: 'Quick Actions'),
                      const SizedBox(height: 12),
                      _QuickActions(
                        onAffordabilityTap: () =>
                            context.push('/affordability'),
                        onGoalsTap: () => context.push('/goals'),
                        onInsightsTap: () => context.push('/insights'),
                        onChatTap: () => context.push('/chat'),
                        onNetWorthTap: () => context.push('/net-worth'),
                      ),
                      const SizedBox(height: 28),
                      _InsightCard(tip: tip),
                    ],
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.onNotificationsTap,
    required this.onSettingsTap,
  });
  final VoidCallback onNotificationsTap, onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good morning',
                style: GoogleFonts.dmSans(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'PennyWise AI',
                style: GoogleFonts.dmSans(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '×3',
                  style: GoogleFonts.dmSans(
                    color: AppColors.orange,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onNotificationsTap,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.notifications_none_rounded,
                  color: AppColors.textPrimary, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Level Card ───────────────────────────────────────────────────────────────

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.xpCurrent,
    required this.xpMax,
    required this.progressAnim,
    required this.healthScore,
  });
  final int level, xpCurrent, xpMax;
  final Animation<double> progressAnim;
  final HealthScoreModel? healthScore;

  String get _levelTitle {
    if (level >= 8) return 'Money Master';
    if (level >= 6) return 'Wealth Builder';
    if (level >= 4) return 'Financial Pro';
    if (level >= 2) return 'Saver';
    return 'Beginner';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'LEVEL $level',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _levelTitle,
                style: GoogleFonts.dmSans(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '$xpCurrent / $xpMax',
                style: GoogleFonts.dmSans(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: progressAnim,
            builder: (_, __) {
              final frac = (xpCurrent / xpMax) * progressAnim.value;
              return Stack(
                children: [
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: frac.clamp(0.0, 1.0),
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          if (healthScore != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                _PillarBadge(
                    label: 'Savings',
                    score: healthScore!.savingsScore,
                    max: 25),
                const SizedBox(width: 6),
                _PillarBadge(
                    label: 'Budget',
                    score: healthScore!.budgetScore,
                    max: 25),
                const SizedBox(width: 6),
                _PillarBadge(
                    label: 'Goals',
                    score: healthScore!.goalScore,
                    max: 25),
                const SizedBox(width: 6),
                _PillarBadge(
                    label: 'Activity',
                    score: healthScore!.activityScore,
                    max: 15),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PillarBadge extends StatelessWidget {
  const _PillarBadge(
      {required this.label, required this.score, required this.max});
  final String label;
  final int score;
  final int max;

  @override
  Widget build(BuildContext context) {
    final frac = max > 0 ? score / max : 0.0;
    final c = frac >= 0.8
        ? AppColors.success
        : frac >= 0.5
            ? AppColors.warning
            : AppColors.danger;
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$score/$max',
              style: TextStyle(
                  color: c,
                  fontSize: 11,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.badge});
  final String label;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              badge!,
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Quest Card ───────────────────────────────────────────────────────────────

class _QuestCard extends StatefulWidget {
  const _QuestCard({
    required this.letter,
    required this.letterColor,
    required this.letterBg,
    required this.title,
    required this.subtitle,
    required this.xp,
    required this.onTap,
  });

  final String letter, title, subtitle, xp;
  final Color letterColor, letterBg;
  final VoidCallback onTap;

  @override
  State<_QuestCard> createState() => _QuestCardState();
}

class _QuestCardState extends State<_QuestCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.surfaceElevated : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hovered
                  ? widget.letterColor.withValues(alpha: 0.4)
                  : AppColors.border,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: widget.letterColor.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: widget.letterBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    widget.letter,
                    style: GoogleFonts.dmSans(
                      color: widget.letterColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.dmSans(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: GoogleFonts.dmSans(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.xp,
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: _hovered ? AppColors.textSecondary : AppColors.textMuted,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Quick Actions ────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onAffordabilityTap,
    required this.onGoalsTap,
    required this.onInsightsTap,
    required this.onChatTap,
    required this.onNetWorthTap,
  });

  final VoidCallback onAffordabilityTap,
      onGoalsTap,
      onInsightsTap,
      onChatTap,
      onNetWorthTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                label: 'Can I Afford?',
                description: 'Smart purchase check',
                icon: Icons.calculate_outlined,
                color: AppColors.orange,
                onTap: onAffordabilityTap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionCard(
                label: 'My Goals',
                description: 'Track your dreams',
                icon: Icons.flag_outlined,
                color: const Color(0xFF1565C0),
                onTap: onGoalsTap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                label: 'AI Insights',
                description: 'Spending analysis',
                icon: Icons.psychology_outlined,
                color: AppColors.success,
                onTap: onInsightsTap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionCard(
                label: 'Ask AI',
                description: 'Financial advisor',
                icon: Icons.chat_bubble_outline_rounded,
                color: const Color(0xFF6A1B9A),
                onTap: onChatTap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ActionCard(
          label: 'Net Worth',
          description: 'Assets minus liabilities — your real financial score',
          icon: Icons.account_balance_outlined,
          color: AppColors.amber,
          onTap: onNetWorthTap,
          fullWidth: true,
        ),
      ],
    );
  }
}

class _ActionCard extends StatefulWidget {
  const _ActionCard({
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
    this.fullWidth = false,
  });

  final String label, description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool fullWidth;

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hovered
                  ? widget.color.withValues(alpha: 0.5)
                  : AppColors.border,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.10),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: widget.fullWidth
              ? Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(widget.icon, color: widget.color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.label,
                            style: GoogleFonts.dmSans(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.description,
                            style: GoogleFonts.dmSans(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: _hovered
                          ? AppColors.textSecondary
                          : AppColors.textMuted,
                      size: 18,
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(widget.icon, color: widget.color, size: 20),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.label,
                      style: GoogleFonts.dmSans(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.description,
                      style: GoogleFonts.dmSans(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─── Insight Card (Playfair Display italic hero) ──────────────────────────────

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.tip});
  final String tip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.questPeach,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '💡  AI INSIGHT',
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFF5C3A00),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            tip,
            style: GoogleFonts.playfairDisplay(
              color: const Color(0xFF1A0A00),
              fontSize: 20,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Tap to learn more',
                style: GoogleFonts.dmSans(
                  color: const Color(0xFF5C3A00),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_rounded,
                  color: Color(0xFF5C3A00), size: 14),
            ],
          ),
        ],
      ),
    );
  }
}
