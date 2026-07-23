import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/storage/user_prefs_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../learn/presentation/widgets/quiz_section.dart';
import '../widgets/detail_screen_widgets.dart';

class BudgetDetailScreen extends StatelessWidget {
  final double remainingBudget;

  const BudgetDetailScreen({super.key, required this.remainingBudget});

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final isHealthy = remainingBudget > 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF2A104), Color(0xFFE67E22)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text('🎯 Remaining Budget',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          currency.format(remainingBudget),
                          style: TextStyle(
                            color: isHealthy
                                ? Colors.white
                                : Colors.red.shade200,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          isHealthy
                              ? 'Your Monthly Runway — Looking Good! ✅'
                              : 'Overspent This Month — Time to Review ⚠️',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                DetailInfoCard(
                  child: Text(
                    isHealthy
                        ? 'Remaining Budget = Salary − Savings − Investments − Fixed Expenses. '
                            'You have ${currency.format(remainingBudget)} left to spend freely this month. Keep it positive!'
                        : 'Your spending has exceeded your budget this month. Don\'t panic — '
                            'awareness is the first step. Review your expenses and identify where you can cut back.',
                    style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 20),
                const DetailSectionHeader(
                    icon: '🎯', title: 'Zero-Based Budgeting'),
                const SizedBox(height: 12),
                const DetailInfoCard(child: _ZeroBasedExplainer()),
                const SizedBox(height: 20),
                const DetailSectionHeader(
                    icon: '⚠️', title: 'Common Budget Killers'),
                const SizedBox(height: 12),
                const _BudgetKillerCard(
                  emoji: '📱',
                  title: 'Impulse buying online',
                  fix:
                      'Add to cart, wait 24 hours before buying. Disable 1-click purchase!',
                ),
                const SizedBox(height: 8),
                const _BudgetKillerCard(
                  emoji: '📺',
                  title: 'Forgotten subscriptions',
                  fix:
                      'Audit all monthly subscriptions. Cancel anything unused for 30+ days.',
                ),
                const SizedBox(height: 8),
                const _BudgetKillerCard(
                  emoji: '🍕',
                  title: 'Excessive food delivery',
                  fix:
                      'Cook 3 more meals/week at home. Save ₹2,000–4,000/month easily.',
                ),
                const SizedBox(height: 8),
                const _BudgetKillerCard(
                  emoji: '🏧',
                  title: 'ATM & banking fees',
                  fix:
                      'Switch to a zero-fee digital bank. Every unnecessary fee is money lost.',
                ),
                const SizedBox(height: 8),
                const _BudgetKillerCard(
                  emoji: '💸',
                  title: 'Not tracking cash spending',
                  fix:
                      'Cash disappears invisibly. Log every cash expense for just 2 weeks.',
                ),
                const SizedBox(height: 20),
                const DetailSectionHeader(
                    icon: '🏆', title: 'The 30-Day Challenge'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accent.withOpacity(0.1),
                        AppColors.primary.withOpacity(0.06)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.accent.withOpacity(0.3)),
                  ),
                  child: const Column(
                    children: [
                      Text('🗓️', style: TextStyle(fontSize: 36)),
                      SizedBox(height: 8),
                      Text(
                        'Track EVERY expense for 30 days',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Most people discover they can save ₹3,000–8,000 MORE per month '
                        'just by becoming aware of their spending patterns.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const DetailSectionHeader(
                    icon: '📖', title: 'Real-Life Case Study'),
                const SizedBox(height: 12),
                const DetailCaseStudyCard(
                  name: 'Meet Kavya',
                  story:
                      'Kavya thought she was broke — salary spent before month-end every time. '
                      'She tracked every expense for 30 days and was shocked: '
                      '₹2,200 on café coffee, ₹1,800 on OTT subscriptions she\'d forgotten, '
                      '₹3,400 on food delivery apps. Total invisible spending: ₹7,400/month! '
                      'She redirected ₹5,000 to SIP. In 10 years, that\'s ₹11.5 lakhs.',
                  lesson:
                      'You can\'t manage what you don\'t measure. Awareness creates wealth.',
                  color: AppColors.accent,
                ),
                const SizedBox(height: 20),
                const DetailSectionHeader(icon: '🤯', title: 'Did You Know?'),
                const SizedBox(height: 12),
                const DetailFactChip(
                  fact:
                      'Lifestyle inflation is the #1 savings killer. Invest your salary increases instead of spending them! 📈',
                ),
                const SizedBox(height: 8),
                const DetailFactChip(
                  fact:
                      'People who write down a budget save on average 15% MORE than those who don\'t. Pen to paper = power! 📝',
                ),
                const SizedBox(height: 24),
                const DetailSectionHeader(
                    icon: '🎮', title: 'Test Your Knowledge'),
                const SizedBox(height: 4),
                const Text('5 questions, earn up to 50 XP!',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 14),
                DetailInfoCard(
                  child: QuizSection(
                    quizId: 'budget_quiz',
                    title: 'Budgeting Mastery Quiz',
                    questions: _budgetQuestions,
                    onCompleted: (score, total) async {
                      final isNew = await UserPrefsStorage.addAchievement(
                          'budget_quiz_done');
                      if (isNew && context.mounted) {
                        showAchievementSnackbar(context, '🎯 Budget Boss',
                            'Completed the budget quiz!');
                      }
                    },
                  ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  static const List<QuizQuestion> _budgetQuestions = [
    QuizQuestion(
      question: 'What does "zero-based budgeting" mean?',
      options: [
        'Having zero money left to save',
        'Assigning every rupee of income to a category until zero is left over',
        'Not spending anything for the month',
        'Starting savings from zero each year',
      ],
      correctIndex: 1,
      explanation:
          'In zero-based budgeting, income minus all allocations (needs, wants, savings) equals zero. Every rupee has a job. This prevents mindless spending!',
    ),
    QuizQuestion(
      question: 'Remaining Budget = ?',
      options: [
        'Salary + Investments',
        'Salary − Savings − Investments − Fixed Expenses',
        'Total money spent this month',
        'Monthly income divided by 2',
      ],
      correctIndex: 1,
      explanation:
          'Remaining budget is what\'s left after covering savings, investments, and fixed costs — it\'s your truly free-to-spend money for the month.',
    ),
    QuizQuestion(
      question: 'Which habit MOST helps people stick to a budget?',
      options: [
        'Earning more money',
        'Never spending on wants',
        'Tracking every expense, even small ones',
        'Using 5 different bank accounts',
      ],
      correctIndex: 2,
      explanation:
          'Awareness is everything! Research in behavioral economics shows that tracking spending — even without strict rules — naturally improves financial decisions.',
    ),
    QuizQuestion(
      question: 'What is "lifestyle inflation"?',
      options: [
        'Rising prices of food and rent',
        'Increasing spending as income grows, with savings staying the same',
        'Upgrading to premium brands as a reward',
        'Inflation in the luxury goods sector',
      ],
      correctIndex: 1,
      explanation:
          'Lifestyle inflation = spending more as you earn more, so savings never grow. Fight it by keeping your lifestyle stable when you get a raise and investing the extra!',
    ),
    QuizQuestion(
      question: 'Which is the BEST strategy to avoid impulse buying?',
      options: [
        'Never shop online at all',
        'Add to cart and wait 24 hours before purchasing',
        'Only carry ₹500 cash at all times',
        'Delete all shopping apps permanently',
      ],
      correctIndex: 1,
      explanation:
          'The 24-hour rule bypasses emotional impulse buying. After 24 hours, you rationally evaluate: 80% of impulse purchases get abandoned. A delay creates willpower!',
    ),
  ];
}

class _ZeroBasedExplainer extends StatelessWidget {
  const _ZeroBasedExplainer();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Give every rupee a job.',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 8),
        const Text(
          'At the start of each month, allocate ALL your salary to categories '
          'until zero is left over. You\'re not restricting yourself — you\'re making '
          'intentional choices about where your money goes.',
          style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 14),
        const _CategoryRow(emoji: '🏠', label: 'Needs (Rent, Food, Bills)', pct: '50%', color: AppColors.secondary),
        const SizedBox(height: 6),
        const _CategoryRow(emoji: '🎉', label: 'Wants (Fun, Shopping)', pct: '30%', color: AppColors.accent),
        const SizedBox(height: 6),
        const _CategoryRow(emoji: '💰', label: 'Savings & Investments', pct: '20%', color: AppColors.success),
        const Divider(height: 16),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total Allocated', style: TextStyle(fontWeight: FontWeight.w700)),
            Text('= Salary  (Remaining: ₹0)',
                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
          ],
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String emoji;
  final String label;
  final String pct;
  final Color color;

  const _CategoryRow({
    required this.emoji,
    required this.label,
    required this.pct,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        Text(pct, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class _BudgetKillerCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String fix;

  const _BudgetKillerCard(
      {required this.emoji, required this.title, required this.fix});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.warning, size: 14),
                    const SizedBox(width: 4),
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(fix,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
