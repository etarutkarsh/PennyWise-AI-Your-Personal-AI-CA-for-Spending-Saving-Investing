import 'package:flutter/material.dart';

import '../../../../core/services/storage/user_prefs_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../dashboard/presentation/screens/budget_detail_screen.dart';
import '../../../dashboard/presentation/screens/investment_detail_screen.dart';
import '../../../dashboard/presentation/screens/salary_detail_screen.dart';
import '../../../dashboard/presentation/screens/savings_detail_screen.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  int _xp = 0;
  List<String> _completedQuizzes = [];
  List<String> _achievements = [];
  double _salary = 50000;
  String _levelName = 'Bronze';
  String _levelEmoji = '🥉';
  int _nextLevelXp = 200;
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final xp = await UserPrefsStorage.getTotalQuizScore();
    final quizzes = await UserPrefsStorage.getCompletedQuizzes();
    final achievements = await UserPrefsStorage.getAchievements();
    final salary = await UserPrefsStorage.getSalary();
    final level = await UserPrefsStorage.getLevel();
    final streak = await UserPrefsStorage.getStreak();
    if (mounted) {
      setState(() {
        _xp = xp;
        _completedQuizzes = quizzes;
        _achievements = achievements;
        _salary = salary;
        _levelName = level.$1;
        _levelEmoji = level.$2;
        _nextLevelXp = level.$4;
        _streak = streak;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn'),
        actions: [
          if (_streak > 0)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Chip(
                avatar: const Text('🔥', style: TextStyle(fontSize: 12)),
                label: Text('$_streak day',
                    style: const TextStyle(fontSize: 11)),
                backgroundColor: AppColors.danger.withValues(alpha: 0.1),
                padding: EdgeInsets.zero,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              avatar: Text(_levelEmoji, style: const TextStyle(fontSize: 12)),
              label: Text('$_levelName · $_xp XP',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 11)),
              backgroundColor: AppColors.accent.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            _ProgressBanner(
              completedCount: _completedQuizzes.length,
              totalCount: _modules.length,
              xp: _xp,
              levelName: _levelName,
              levelEmoji: _levelEmoji,
              nextLevelXp: _nextLevelXp,
            ),
            const SizedBox(height: 20),
            if (_achievements.isNotEmpty) ...[
              _SectionHeader(title: 'Your Badges'),
              const SizedBox(height: 10),
              _BadgesRow(achievements: _achievements),
              const SizedBox(height: 20),
            ],
            _SectionHeader(title: 'Finance Modules'),
            const SizedBox(height: 10),
            ..._modules.map((m) => _ModuleCard(
                  module: m,
                  isCompleted: _completedQuizzes.contains(m.quizId),
                  salary: _salary,
                )),
            const SizedBox(height: 20),
            _SectionHeader(title: 'Daily Finance Tips'),
            const SizedBox(height: 10),
            const _DailyTipsCard(),
          ],
        ),
      ),
    );
  }

  static final _modules = [
    _Module(
      quizId: 'salary_quiz',
      title: '50-30-20 Rule',
      subtitle: 'Master salary allocation',
      icon: '💰',
      color: AppColors.primary,
      xpReward: 50,
    ),
    _Module(
      quizId: 'savings_quiz',
      title: 'Power of Saving',
      subtitle: 'Build your safety net',
      icon: '🏦',
      color: AppColors.success,
      xpReward: 50,
    ),
    _Module(
      quizId: 'investment_quiz',
      title: 'Investing Basics',
      subtitle: 'Grow your wealth',
      icon: '📈',
      color: AppColors.secondary,
      xpReward: 50,
    ),
    _Module(
      quizId: 'budget_quiz',
      title: 'Budget Like a Pro',
      subtitle: 'Zero-based budgeting',
      icon: '🎯',
      color: AppColors.accent,
      xpReward: 50,
    ),
  ];
}

class _Module {
  const _Module({
    required this.quizId,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.xpReward,
  });
  final String quizId;
  final String title;
  final String subtitle;
  final String icon;
  final Color color;
  final int xpReward;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15));
  }
}

class _ProgressBanner extends StatelessWidget {
  const _ProgressBanner({
    required this.completedCount,
    required this.totalCount,
    required this.xp,
    required this.levelName,
    required this.levelEmoji,
    required this.nextLevelXp,
  });
  final int completedCount;
  final int totalCount;
  final int xp;
  final String levelName;
  final String levelEmoji;
  final int nextLevelXp;

  @override
  Widget build(BuildContext context) {
    final prevLevelXp = levelName == 'Bronze' ? 0 : levelName == 'Silver' ? 200 : levelName == 'Gold' ? 500 : 1000;
    final levelFraction = nextLevelXp > prevLevelXp
        ? ((xp - prevLevelXp) / (nextLevelXp - prevLevelXp)).clamp(0.0, 1.0)
        : 1.0;

    return Card(
      color: AppColors.secondary,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(levelEmoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$levelName · $xp XP',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                      const SizedBox(height: 2),
                      Text('$completedCount of $totalCount modules done · ${nextLevelXp - xp} XP to next level',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: levelFraction,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation(AppColors.accent),
              ),
            ),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('$xp XP', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10)),
              Text('$nextLevelXp XP', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10)),
            ]),
          ],
        ),
      ),
    );
  }
}

class _BadgesRow extends StatelessWidget {
  const _BadgesRow({required this.achievements});
  final List<String> achievements;

  static const _badgeMap = {
    'onboarding_complete': ('🚀', 'Started'),
    'salary_quiz_done': ('💰', 'Salary Scholar'),
    'savings_quiz_done': ('🏦', 'Savings Expert'),
    'investment_quiz_done': ('📈', 'Investment Pro'),
    'budget_quiz_done': ('🎯', 'Budget Boss'),
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: achievements.map((id) {
          final badge = _badgeMap[id] ?? ('⭐', id);
          return Container(
            margin: const EdgeInsets.only(right: 10),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(badge.$1,
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(badge.$2,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.module,
    required this.isCompleted,
    required this.salary,
  });

  final _Module module;
  final bool isCompleted;
  final double salary;

  void _navigate(BuildContext context) {
    final route = switch (module.quizId) {
      'salary_quiz' => MaterialPageRoute(
          builder: (_) => SalaryDetailScreen(salary: salary)),
      'savings_quiz' => MaterialPageRoute(
          builder: (_) => SavingsDetailScreen(
              salary: salary, savings: salary * 0.12)),
      'investment_quiz' => MaterialPageRoute(
          builder: (_) => InvestmentDetailScreen(
              salary: salary, investments: salary * 0.08)),
      'budget_quiz' => MaterialPageRoute(
          builder: (_) =>
              BudgetDetailScreen(remainingBudget: salary * 0.30)),
      _ => null,
    };
    if (route != null) Navigator.of(context).push(route);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _navigate(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: module.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(module.icon,
                      style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(module.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(module.subtitle,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('✓ Done',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.success,
                          fontWeight: FontWeight.w700)),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('+${module.xpReward} XP',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700)),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyTipsCard extends StatelessWidget {
  const _DailyTipsCard();

  static const _tips = [
    ('💡', 'Pay yourself first — transfer savings the moment your salary arrives.'),
    ('📊', 'Track every expense for 30 days. Awareness is the first step to change.'),
    ('🏦', 'An emergency fund of 6 months\' expenses is your financial superpower.'),
    ('📈', 'Start a SIP with even ₹500/month. Time in market beats timing the market.'),
    ('✂️', 'Cut one unused subscription today — that\'s ₹1,200+ back per year.'),
    ('🎯', 'Set a specific savings goal. Vague intentions don\'t move money.'),
    ('⚡', 'Avoid lifestyle inflation — when income rises, save the difference first.'),
    ('🛡️', 'Insurance is not an expense — it\'s protection for your wealth.'),
    ('💳', 'Pay your credit card in full every month. Interest is wealth destruction.'),
    ('🌱', 'Invest in yourself — a new skill can increase your income more than any fund.'),
  ];

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().day;
    final tip = _tips[today % _tips.length];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(tip.$1, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                const Text("Today's Tip",
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 10),
            Text(tip.$2,
                style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
