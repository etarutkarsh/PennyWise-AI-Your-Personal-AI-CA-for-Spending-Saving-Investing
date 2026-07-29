import 'dart:math';
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

    if (salary > 0) {
      AppServices.instance.user.getMe().then((user) {
        if ((user.monthlyIncome ?? 0) <= 0) {
          AppServices.instance.user.updateMe(monthlyIncome: salary);
        }
      }).catchError((_) {});
    }

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

  String get _levelTitle {
    if (_level >= 8) return 'Money Master';
    if (_level >= 6) return 'Wealth Builder';
    if (_level >= 4) return 'Financial Pro';
    if (_level >= 2) return 'Saver';
    return 'Beginner';
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final savings = _salary * 0.12;
    final investments = _salary * 0.08;
    final remainingBudget = _salary - savings - investments - (_salary * 0.50);
    final tip = _dailyTip.isNotEmpty ? _dailyTip : DashboardSummary.placeholder.dailyTip;
    final score = _healthScore?.score ?? DashboardSummary.placeholder.financialHealthScore;

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
              // Premium AI Coach Hero
              _AICoachHero(
                salary: _salary,
                savings: savings,
                healthScore: score,
                levelTitle: _levelTitle,
                level: _level,
                onNotificationsTap: () => context.push('/notifications'),
                onSettingsTap: () => context.push('/settings'),
              ),
              const SizedBox(height: 28),
              RepaintBoundary(child: HeroCarouselSection(salary: _salary)),
              const SizedBox(height: 24),
              const RepaintBoundary(child: MarketDataSection()),
              const SizedBox(height: 4),
              const RepaintBoundary(child: FinancialNewsTicker()),
              const SizedBox(height: 24),
              const AnimatedStatsSection(),
              const SizedBox(height: 24),
              MotivationCardsSection(salary: _salary, savings: savings),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_loadedSalary)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: CircularProgressIndicator(color: AppColors.orange),
                        ),
                      )
                    else ...[
                      // Progress Card
                      _ProgressCard(
                        level: _level,
                        levelTitle: _levelTitle,
                        xpCurrent: _xpCurrent,
                        xpMax: _xpMax,
                        progressAnim: _progressAnim,
                        healthScore: _healthScore,
                        score: score,
                      ),
                      const SizedBox(height: 32),

                      // Missions
                      _SectionHeader(
                        title: 'Your 4 Missions',
                        subtitle: 'Complete all to earn 350 XP today',
                        badge: '350 XP',
                      ),
                      const SizedBox(height: 14),
                      _QuestCard(
                        emoji: '💰',
                        gradient: AppColors.salaryGradient,
                        title: 'Monthly Salary',
                        value: currency.format(_salary),
                        description: 'Your income is your foundation. Every rupee managed well compounds into wealth.',
                        xp: '+120 XP',
                        onTap: () => context
                            .push('/detail/salary?salary=${_salary.toStringAsFixed(2)}')
                            .then((_) { if (mounted) _load(); }),
                      ),
                      _QuestCard(
                        emoji: '🏦',
                        gradient: AppColors.savingsGradient,
                        title: 'Savings Goal',
                        value: '${currency.format(savings)}/month',
                        description: 'Saving ${(savings / _salary * 100).toStringAsFixed(0)}% of income puts you ahead of 72% of your peers.',
                        xp: '+90 XP',
                        onTap: () => context
                            .push('/detail/savings?salary=${_salary.toStringAsFixed(2)}&savings=${savings.toStringAsFixed(2)}')
                            .then((_) { if (mounted) _load(); }),
                      ),
                      _QuestCard(
                        emoji: '📈',
                        gradient: AppColors.investGradient,
                        title: 'Investment Engine',
                        value: '${currency.format(investments)}/month in SIP',
                        description: 'Your future wealth machine. At 12% p.a., this becomes ${_formatFuture(investments)} in 20 years.',
                        xp: '+80 XP',
                        onTap: () => context
                            .push('/detail/investment?salary=${_salary.toStringAsFixed(2)}&investments=${investments.toStringAsFixed(2)}')
                            .then((_) { if (mounted) _load(); }),
                      ),
                      _QuestCard(
                        emoji: '🎯',
                        gradient: AppColors.budgetGradient,
                        title: 'Budget Remaining',
                        value: currency.format(remainingBudget),
                        description: 'Your discretionary buffer. Spend mindfully — every unspent rupee is a future asset.',
                        xp: '+60 XP',
                        onTap: () => context
                            .push('/detail/budget?budget=${remainingBudget.toStringAsFixed(2)}')
                            .then((_) { if (mounted) _load(); }),
                      ),

                      const SizedBox(height: 32),

                      // Quick Actions
                      _SectionHeader(
                        title: 'Explore',
                        subtitle: 'Tools to accelerate your financial growth',
                      ),
                      const SizedBox(height: 14),
                      _QuickActions(
                        onAffordabilityTap: () => context
                            .push('/affordability?salary=${_salary.toStringAsFixed(2)}')
                            .then((_) { if (mounted) _load(); }),
                        onGoalsTap: () => context
                            .push('/goals')
                            .then((_) { if (mounted) _load(); }),
                        onInsightsTap: () => context
                            .push('/insights?salary=${_salary.toStringAsFixed(2)}')
                            .then((_) { if (mounted) _load(); }),
                        onChatTap: () => context
                            .push('/chat')
                            .then((_) { if (mounted) _load(); }),
                        onNetWorthTap: () => context
                            .push('/net-worth')
                            .then((_) { if (mounted) _load(); }),
                      ),

                      const SizedBox(height: 28),
                      _AIInsightCard(tip: tip),
                    ],
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatFuture(double monthly) {
    final fv = monthly * (pow(1 + 0.01, 240) - 1) / 0.01;
    if (fv >= 10000000) return '₹${(fv / 10000000).toStringAsFixed(1)} Cr';
    if (fv >= 100000)   return '₹${(fv / 100000).toStringAsFixed(0)} L';
    return '₹${fv.toStringAsFixed(0)}';
  }
}

// ─── AI Coach Hero ─────────────────────────────────────────────────────────────

class _AICoachHero extends StatefulWidget {
  const _AICoachHero({
    required this.salary,
    required this.savings,
    required this.healthScore,
    required this.levelTitle,
    required this.level,
    required this.onNotificationsTap,
    required this.onSettingsTap,
  });
  final double salary, savings;
  final int healthScore, level;
  final String levelTitle;
  final VoidCallback onNotificationsTap, onSettingsTap;

  @override
  State<_AICoachHero> createState() => _AICoachHeroState();
}

class _AICoachHeroState extends State<_AICoachHero>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 12))
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
    final topPad = MediaQuery.of(context).padding.top;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final t = _anim.value;
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(const Color(0xFF1E3A8A), const Color(0xFF1D4ED8), t * 0.4)!,
                Color.lerp(const Color(0xFF3730A3), const Color(0xFF4338CA), t * 0.3)!,
                Color.lerp(const Color(0xFF5B21B6), const Color(0xFF6D28D9), t * 0.2)!,
              ],
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              // Ambient blobs
              Positioned(
                right: -50,
                top: -40,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.03 + t * 0.03),
                  ),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -60,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF06B6D4).withValues(alpha: 0.06 + t * 0.04),
                  ),
                ),
              ),
              Positioned(
                right: 80,
                bottom: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.08 + t * 0.04),
                  ),
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.fromLTRB(22, topPad + 20, 22, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: greeting + icons
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 5),
                      Text(
                        '18-day streak',
                        style: GoogleFonts.dmSans(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _GlassIconBtn(icon: Icons.notifications_none_rounded, onTap: widget.onNotificationsTap),
                const SizedBox(width: 8),
                _GlassIconBtn(icon: Icons.settings_outlined, onTap: widget.onSettingsTap),
              ],
            ),

            const SizedBox(height: 20),

            // Main content row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: headline + message + mini stats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good morning 👋',
                        style: GoogleFonts.dmSans(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your money is\nworking smarter.',
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          height: 1.12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.savings > 0
                            ? 'You saved ${currency.format(widget.savings)} this month — you\'re ahead of 72% of your peers.'
                            : 'Set a savings goal and your AI coach will guide you every step.',
                        style: GoogleFonts.dmSans(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Mini stats pills
                      Row(
                        children: [
                          _HeroPill(label: 'Income', value: currency.format(widget.salary)),
                          const SizedBox(width: 8),
                          _HeroPill(label: widget.levelTitle, value: 'Lv ${widget.level}'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Right: Health score ring
                _HealthRing(score: widget.healthScore),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassIconBtn extends StatelessWidget {
  const _GlassIconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 18),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthRing extends StatelessWidget {
  const _HealthRing({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    final color = score >= 70
        ? AppColors.success
        : score >= 40
            ? AppColors.warning
            : AppColors.danger;

    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(80, 80),
            painter: _RingPainter(
              progress: score / 100.0,
              color: color,
              bgColor: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
              Text(
                'Health',
                style: GoogleFonts.dmSans(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.bgColor,
  });
  final double progress;
  final Color color, bgColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 10) / 2;
    final paint = Paint()
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Background ring
    canvas.drawCircle(center, radius, paint..color = bgColor);

    // Progress arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * progress.clamp(0.0, 1.0),
      false,
      paint..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle, this.badge});
  final String title;
  final String? subtitle, badge;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: GoogleFonts.manrope(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.orange.withValues(alpha: 0.3)),
                ),
                child: Text(
                  badge!,
                  style: GoogleFonts.dmSans(
                    color: AppColors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(
            subtitle!,
            style: GoogleFonts.dmSans(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Progress Card ────────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.level,
    required this.levelTitle,
    required this.xpCurrent,
    required this.xpMax,
    required this.progressAnim,
    required this.healthScore,
    required this.score,
  });
  final int level, xpCurrent, xpMax, score;
  final String levelTitle;
  final Animation<double> progressAnim;
  final HealthScoreModel? healthScore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Level badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1D4ED8), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'LEVEL $level',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                levelTitle,
                style: GoogleFonts.manrope(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '$xpCurrent / $xpMax XP',
                style: GoogleFonts.dmSans(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // XP progress bar
          AnimatedBuilder(
            animation: progressAnim,
            builder: (_, __) {
              final frac = (xpCurrent / xpMax) * progressAnim.value;
              return Stack(
                children: [
                  Container(
                    height: 7,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: frac.clamp(0.0, 1.0),
                    child: Container(
                      height: 7,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          if (healthScore != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _PillarBadge(label: 'Savings', score: healthScore!.savingsScore, max: 25),
                const SizedBox(width: 8),
                _PillarBadge(label: 'Budget',  score: healthScore!.budgetScore,  max: 25),
                const SizedBox(width: 8),
                _PillarBadge(label: 'Goals',   score: healthScore!.goalScore,    max: 25),
                const SizedBox(width: 8),
                _PillarBadge(label: 'Activity', score: healthScore!.activityScore, max: 15),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PillarBadge extends StatelessWidget {
  const _PillarBadge({required this.label, required this.score, required this.max});
  final String label;
  final int score, max;

  @override
  Widget build(BuildContext context) {
    final frac = max > 0 ? score / max : 0.0;
    final c = frac >= 0.8 ? AppColors.success : frac >= 0.5 ? AppColors.warning : AppColors.danger;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.withValues(alpha: 0.18)),
        ),
        child: Column(
          children: [
            Text(
              '$score/$max',
              style: GoogleFonts.manrope(color: c, fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quest Card ───────────────────────────────────────────────────────────────

class _QuestCard extends StatefulWidget {
  const _QuestCard({
    required this.emoji,
    required this.gradient,
    required this.title,
    required this.value,
    required this.description,
    required this.xp,
    required this.onTap,
  });
  final String emoji, title, value, description, xp;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  State<_QuestCard> createState() => _QuestCardState();
}

class _QuestCardState extends State<_QuestCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.gradient.first;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.surfaceElevated : AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _hovered ? accentColor.withValues(alpha: 0.45) : AppColors.border,
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: _hovered
                ? [BoxShadow(color: accentColor.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 6))]
                : null,
          ),
          child: Row(
            children: [
              // Gradient accent strip
              Container(
                width: 5,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: widget.gradient,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(22),
                    bottomLeft: Radius.circular(22),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Emoji badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.gradient.first.withValues(alpha: 0.2),
                      widget.gradient.last.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Center(
                  child: Text(widget.emoji, style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 14),
              // Text
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: GoogleFonts.manrope(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.value,
                        style: GoogleFonts.manrope(
                          color: accentColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.description,
                        style: GoogleFonts.dmSans(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          height: 1.45,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // XP + chevron
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: widget.gradient),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      widget.xp,
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: _hovered ? AppColors.textSecondary : AppColors.textMuted,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(width: 14),
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
  final VoidCallback onAffordabilityTap, onGoalsTap, onInsightsTap, onChatTap, onNetWorthTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.calculate_outlined,
                  label: 'Can I Afford It?',
                  description: 'Smart purchase analysis against your income',
                  gradient: const [Color(0xFFF4722B), Color(0xFFFF8C42)],
                  onTap: onAffordabilityTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  icon: Icons.flag_rounded,
                  label: 'My Goals',
                  description: 'Track every dream with a savings plan',
                  gradient: const [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
                  onTap: onGoalsTap,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.psychology_outlined,
                  label: 'AI Insights',
                  description: 'Spending patterns & savings opportunities',
                  gradient: const [Color(0xFF059669), Color(0xFF22C55E)],
                  onTap: onInsightsTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Ask AI',
                  description: 'Your 24/7 financial coach',
                  gradient: const [Color(0xFF6D28D9), Color(0xFF8B5CF6)],
                  onTap: onChatTap,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Net Worth — full width hero card
        _NetWorthCard(onTap: onNetWorthTap),
      ],
    );
  }
}

class _ActionCard extends StatefulWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.gradient,
    required this.onTap,
  });
  final IconData icon;
  final String label, description;
  final List<Color> gradient;
  final VoidCallback onTap;

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
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.surfaceElevated : AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _hovered
                  ? widget.gradient.first.withValues(alpha: 0.5)
                  : AppColors.border,
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: _hovered
                ? [BoxShadow(color: widget.gradient.first.withValues(alpha: 0.12), blurRadius: 18, offset: const Offset(0, 5))]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gradient icon badge
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: widget.gradient),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(widget.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 14),
              Text(
                widget.label,
                style: GoogleFonts.manrope(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.description,
                style: GoogleFonts.dmSans(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NetWorthCard extends StatefulWidget {
  const _NetWorthCard({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_NetWorthCard> createState() => _NetWorthCardState();
}

class _NetWorthCardState extends State<_NetWorthCard> {
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _hovered
                  ? [const Color(0xFF1A1F2E), const Color(0xFF1E2535)]
                  : [AppColors.surface, AppColors.surface],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _hovered
                  ? AppColors.amber.withValues(alpha: 0.45)
                  : AppColors.border,
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: _hovered
                ? [BoxShadow(color: AppColors.amber.withValues(alpha: 0.10), blurRadius: 20, offset: const Offset(0, 6))]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD97706), Color(0xFFFFB830)],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.account_balance_outlined, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Net Worth',
                      style: GoogleFonts.manrope(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Assets minus liabilities — your real financial score',
                      style: GoogleFonts.dmSans(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.arrow_forward_rounded,
                color: _hovered ? AppColors.amber : AppColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── AI Insight Card ──────────────────────────────────────────────────────────

class _AIInsightCard extends StatelessWidget {
  const _AIInsightCard({required this.tip});
  final String tip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1200), Color(0xFF2A1E00)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: AppColors.amber, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                'Your AI Coach',
                style: GoogleFonts.dmSans(
                  color: AppColors.amber,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '"$tip"',
            style: GoogleFonts.playfairDisplay(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Powered by PennyWise AI',
                style: GoogleFonts.dmSans(
                  color: AppColors.amber.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_rounded, color: AppColors.amber, size: 14),
            ],
          ),
        ],
      ),
    );
  }
}
