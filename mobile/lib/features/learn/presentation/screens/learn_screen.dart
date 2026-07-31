import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/storage/user_prefs_storage.dart';
import '../../../../core/theme/app_colors.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  int _xp = 0;
  List<String> _completedQuizzes = [];
  List<String> _achievements = [];
  int _streak = 0;
  double _salary = 50000;

  static const _dailyTips = [
    'Invest at least 15% of your income for long-term wealth.',
    'Track every rupee — awareness is the first step to control.',
    'An emergency fund of 6 months stops small crises becoming big ones.',
    'SIPs work best when started early and kept consistent.',
    'Pay yourself first: automate your savings before spending.',
    'Compound interest rewards patience more than intelligence.',
    'Index funds beat most actively managed funds over 10 years.',
    'Zero-based budgeting gives every rupee a job.',
    'Lifestyle inflation is the silent wealth killer.',
    'Your biggest financial asset is your earning capacity.',
  ];

  String get _todayTip =>
      _dailyTips[DateTime.now().day % _dailyTips.length];

  int get _level {
    if (_xp >= 200) return 3;
    if (_xp >= 100) return 2;
    return 1;
  }

  String get _levelLabel {
    if (_level == 3) return 'Gold';
    if (_level == 2) return 'Silver';
    return 'Bronze';
  }

  int get _xpToNext {
    if (_level == 1) return 100;
    if (_level == 2) return 200;
    return 300;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final xp = await UserPrefsStorage.getTotalQuizScore();
    final completed = await UserPrefsStorage.getCompletedQuizzes();
    final achievements = await UserPrefsStorage.getAchievements();
    final salary = await UserPrefsStorage.getSalary();
    if (mounted) {
      setState(() {
        _xp = xp;
        _completedQuizzes = completed;
        _achievements = achievements;
        _salary = salary;
        _streak = completed.length;
      });
    }
  }

  final _modules = const [
    (
      letter: '50',
      bg: AppColors.questBlue,
      fg: Color(0xFF1565C0),
      title: '50-30-20 Rule',
      subtitle: 'Master your monthly budget split',
      xp: '+50 XP',
      quizId: 'salary_quiz_done',
      route: '_salary',
    ),
    (
      letter: 'P',
      bg: AppColors.questGreen,
      fg: Color(0xFF0F9D58),
      title: 'Power of Saving',
      subtitle: 'Emergency fund & Rule of 72',
      xp: '+50 XP',
      quizId: 'savings_quiz_done',
      route: '_savings',
    ),
    (
      letter: 'I',
      bg: AppColors.questPurple,
      fg: Color(0xFF6A1B9A),
      title: 'Investing Basics',
      subtitle: 'SIP, compounding, portfolio',
      xp: '+50 XP',
      quizId: 'investment_quiz_done',
      route: '_invest',
    ),
    (
      letter: 'B',
      bg: AppColors.questPeach,
      fg: Color(0xFFBF5820),
      title: 'Budget Like a Pro',
      subtitle: 'Zero-based budgeting strategy',
      xp: '+50 XP',
      quizId: 'budget_quiz_done',
      route: '_budget',
    ),
  ];

  void _openModule(String route) {
    final s = _salary.toStringAsFixed(2);
    late final Future<Object?> nav;
    switch (route) {
      case '_salary':
        nav = context.push('/detail/salary?salary=$s');
      case '_savings':
        nav = context.push(
          '/detail/savings?salary=$s&savings=${(_salary * 0.12).toStringAsFixed(2)}',
        );
      case '_invest':
        nav = context.push(
          '/detail/investment?salary=$s&investments=${(_salary * 0.08).toStringAsFixed(2)}',
        );
      case '_budget':
        nav = context.push(
          '/detail/budget?budget=${(_salary * 0.30).toStringAsFixed(2)}',
        );
      default:
        return;
    }
    // Refresh XP/achievements when user returns from detail screen.
    nav.then((_) { if (mounted) _load(); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Library',
                          style: GoogleFonts.dmSans(
                              color: AppColors.textPrimary,
                              fontSize: 26,
                              fontWeight: FontWeight.w800)),
                      Text('${_completedQuizzes.length}/${_modules.length} complete',
                          style: GoogleFonts.dmSans(
                              color: AppColors.textSecondary, fontSize: 14)),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.push('/leaderboard'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.leaderboard_outlined,
                              color: AppColors.orange, size: 16),
                          const SizedBox(width: 6),
                          Text('Board',
                              style: GoogleFonts.dmSans(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // XP / Level card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: Text(
                          '$_level',
                          style: GoogleFonts.dmSans(
                            color: AppColors.orange,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(_levelLabel,
                                  style: GoogleFonts.dmSans(
                                      color: AppColors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.orange,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('$_xp XP',
                                    style: GoogleFonts.dmSans(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: (_xp / _xpToNext).clamp(0.0, 1.0),
                            backgroundColor: AppColors.surfaceElevated,
                            valueColor: const AlwaysStoppedAnimation(
                                AppColors.orange),
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 4),
                          Text('$_xp / $_xpToNext XP to next level',
                              style: GoogleFonts.dmSans(
                                  color: AppColors.textSecondary,
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 22)),
                        Text('$_streak',
                            style: GoogleFonts.dmSans(
                                color: AppColors.orange,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                        Text('streak',
                            style: GoogleFonts.dmSans(
                                color: AppColors.textMuted, fontSize: 9)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              Text('Missions',
                  style: GoogleFonts.dmSans(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),

              for (final m in _modules) ...[
                _MissionCard(
                  letter: m.letter,
                  letterBg: m.bg,
                  letterColor: m.fg,
                  title: m.title,
                  subtitle: m.subtitle,
                  xp: m.xp,
                  isComplete: _completedQuizzes.contains(m.quizId),
                  onTap: () => _openModule(m.route),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 28),

              // Today's tip
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.questPeach,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('📖  TODAY\'S TIP',
                          style: GoogleFonts.dmSans(
                              color: const Color(0xFF5C3A00),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _todayTip,
                      style: GoogleFonts.playfairDisplay(
                        color: const Color(0xFF1A0A00),
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              if (_achievements.isNotEmpty) ...[
                const SizedBox(height: 28),
                Text('Achievements',
                    style: GoogleFonts.dmSans(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _achievements.map((a) {
                    final label = a
                        .replaceAll('_', ' ')
                        .split(' ')
                        .map((w) => w.isNotEmpty
                            ? '${w[0].toUpperCase()}${w.substring(1)}'
                            : w)
                        .join(' ');
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🏅', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(label,
                              style: GoogleFonts.dmSans(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({
    required this.letter,
    required this.letterBg,
    required this.letterColor,
    required this.title,
    required this.subtitle,
    required this.xp,
    required this.isComplete,
    required this.onTap,
  });

  final String letter, title, subtitle, xp;
  final Color letterBg, letterColor;
  final bool isComplete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: letterBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(letter,
                    style: GoogleFonts.dmSans(
                        color: letterColor,
                        fontSize: letter.length > 1 ? 13 : 20,
                        fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.dmSans(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.dmSans(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isComplete)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_rounded,
                        color: AppColors.success, size: 12),
                    const SizedBox(width: 4),
                    Text('Done',
                        style: GoogleFonts.dmSans(
                            color: AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(xp,
                    style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
          ],
        ),
      ),
    );
  }
}
