import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/storage/user_prefs_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../learn/presentation/widgets/quiz_section.dart';
import '../widgets/detail_screen_widgets.dart';

class SavingsDetailScreen extends StatelessWidget {
  final double salary;
  final double savings;

  const SavingsDetailScreen({super.key, required this.salary, required this.savings});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final threeMonthFund = salary * 3;
    final sixMonthFund = salary * 6;
    final progress3 = (savings / threeMonthFund).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.success, AppColors.success.withOpacity(0.75)],
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
                        const Text('🏦 Your Savings',
                            style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          currency.format(savings),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800),
                        ),
                        const Text('Your Safety Net & Future Fund',
                            style: TextStyle(color: Colors.white70, fontSize: 13)),
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
                const DetailInfoCard(
                  child: Text(
                    'Savings = money you don\'t spend today so future-you has options. '
                    'Think of it as paying your future self first. No savings = no safety net.',
                    style: TextStyle(
                        fontSize: 14, height: 1.5, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 20),
                const DetailSectionHeader(icon: '🛡️', title: 'Emergency Fund Calculator'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FundGoalRow(
                        label: '3-Month Fund',
                        amount: currency.format(threeMonthFund),
                        subtitle: 'Minimum recommended',
                        color: AppColors.accent,
                      ),
                      const SizedBox(height: 12),
                      _FundGoalRow(
                        label: '6-Month Fund',
                        amount: currency.format(sixMonthFund),
                        subtitle: 'Ideal safety net',
                        color: AppColors.success,
                      ),
                      const Divider(height: 24),
                      const Text('Your Progress (toward 3-month goal)',
                          style:
                              TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress3,
                          backgroundColor: AppColors.background,
                          valueColor:
                              const AlwaysStoppedAnimation(AppColors.success),
                          minHeight: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            currency.format(savings),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.success),
                          ),
                          Text(
                            currency.format(threeMonthFund),
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const DetailSectionHeader(icon: '⚡', title: '5 Power Tips to Save More'),
                const SizedBox(height: 12),
                const _TipCard(
                  icon: '💳',
                  tip:
                      'Automate your savings — set up auto-transfer on salary day before you can spend it.',
                ),
                const SizedBox(height: 8),
                const _TipCard(
                  icon: '☕',
                  tip:
                      'Cut one ₹150 coffee daily = ₹4,500/month saved. Small habits, big impact.',
                ),
                const SizedBox(height: 8),
                const _TipCard(
                  icon: '📱',
                  tip:
                      'Review subscriptions monthly — cancel unused ones. Most people waste ₹500-2,000/month!',
                ),
                const SizedBox(height: 8),
                const _TipCard(
                  icon: '🛒',
                  tip:
                      'Always shop with a list. Never shop when hungry or emotionally stressed.',
                ),
                const SizedBox(height: 8),
                const _TipCard(
                  icon: '🎯',
                  tip:
                      'Name your savings goals: "Emergency Fund" feels more real than just "Savings Account".',
                ),
                const SizedBox(height: 20),
                const DetailSectionHeader(icon: '🔢', title: 'The Rule of 72'),
                const SizedBox(height: 12),
                const DetailInfoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Want to know when your money doubles? Just divide 72 by your annual interest rate!',
                        style: TextStyle(fontSize: 14, height: 1.5),
                      ),
                      SizedBox(height: 12),
                      _Rule72Row(rate: 6, years: 12),
                      SizedBox(height: 6),
                      _Rule72Row(rate: 8, years: 9),
                      SizedBox(height: 6),
                      _Rule72Row(rate: 12, years: 6),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const DetailSectionHeader(icon: '📖', title: 'Real-Life Case Study'),
                const SizedBox(height: 12),
                const DetailCaseStudyCard(
                  name: 'Meet Arjun',
                  story:
                      'Arjun lost his job during COVID. He had zero savings and had to borrow from family and friends. '
                      'It took 3 painful years to pay off ₹4 lakhs in debt and rebuild his career. '
                      'Today he religiously keeps 6 months of salary in a liquid fund. '
                      '"That one crisis changed my entire relationship with money," he says.',
                  lesson:
                      'An emergency fund isn\'t pessimism — it\'s the highest form of self-respect.',
                  color: AppColors.success,
                ),
                const SizedBox(height: 20),
                const DetailSectionHeader(icon: '🤯', title: 'Did You Know?'),
                const SizedBox(height: 12),
                const DetailFactChip(
                  fact:
                      '72% of Indians have less than ₹5,000 in savings. Don\'t be the 72%! 🚀',
                ),
                const SizedBox(height: 8),
                const DetailFactChip(
                  fact:
                      'A high-interest savings account at 6-7% beats a regular one at 3-4% — double-check your bank! 🏦',
                ),
                const SizedBox(height: 24),
                const DetailSectionHeader(icon: '🎮', title: 'Test Your Knowledge'),
                const SizedBox(height: 4),
                const Text('5 questions, earn up to 50 XP!',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 14),
                DetailInfoCard(
                  child: QuizSection(
                    quizId: 'savings_quiz',
                    title: 'Savings & Emergency Fund Quiz',
                    questions: _savingsQuestions,
                    onCompleted: (score, total) async {
                      final isNew =
                          await UserPrefsStorage.addAchievement('savings_quiz_done');
                      if (isNew && context.mounted) {
                        showAchievementSnackbar(
                            context, '🏦 Savings Expert', 'Completed the savings quiz!');
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

  static const List<QuizQuestion> _savingsQuestions = [
    QuizQuestion(
      question: 'How many months of expenses should an emergency fund cover?',
      options: ['1 month', '3–6 months', '12 months', '2 weeks'],
      correctIndex: 1,
      explanation:
          '3–6 months of expenses is the golden rule. It covers job loss, medical emergencies, or major unexpected repairs without going into debt.',
    ),
    QuizQuestion(
      question:
          'At 6% annual interest, how long does it take to double your money? (Rule of 72)',
      options: ['6 years', '9 years', '12 years', '15 years'],
      correctIndex: 2,
      explanation:
          '72 ÷ 6 = 12 years. The Rule of 72 is a quick mental math shortcut every financially savvy person should know!',
    ),
    QuizQuestion(
      question: 'What is the BEST place to keep your emergency fund?',
      options: [
        'Stock market for higher returns',
        'Under your mattress for safety',
        'High-interest savings account or liquid mutual fund',
        'Cryptocurrency for fast growth',
      ],
      correctIndex: 2,
      explanation:
          'Emergency funds need to be safe and instantly accessible. Liquid funds or high-interest savings accounts offer both — unlike stocks that can fall 30% overnight.',
    ),
    QuizQuestion(
      question: 'If you save ₹500/day consistently, how much do you have in a year?',
      options: ['₹1,50,000', '₹1,82,500', '₹2,00,000', '₹6,000'],
      correctIndex: 1,
      explanation:
          '₹500 × 365 days = ₹1,82,500. Small daily habits compound into life-changing results. That\'s the power of consistency!',
    ),
    QuizQuestion(
      question: 'What does "pay yourself first" mean?',
      options: [
        'Buy yourself gifts as a reward',
        'Transfer savings before spending anything else',
        'Pay your highest bill first',
        'Spend freely on needs before saving',
      ],
      correctIndex: 1,
      explanation:
          '"Pay yourself first" means savings come before spending — automatically, on salary day. Make it non-negotiable and you\'ll always save!',
    ),
  ];
}

class _FundGoalRow extends StatelessWidget {
  final String label;
  final String amount;
  final String subtitle;
  final Color color;

  const _FundGoalRow({
    required this.label,
    required this.amount,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 40,
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
        Text(
          amount,
          style: TextStyle(
              fontWeight: FontWeight.w800, color: color, fontSize: 15),
        ),
      ],
    );
  }
}

class _TipCard extends StatelessWidget {
  final String icon;
  final String tip;

  const _TipCard({required this.icon, required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(tip, style: const TextStyle(fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _Rule72Row extends StatelessWidget {
  final int rate;
  final int years;

  const _Rule72Row({required this.rate, required this.years});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$rate%/yr',
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.success,
                fontSize: 12),
          ),
        ),
        const SizedBox(width: 8),
        Text('72 ÷ $rate = ',
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text('$years years to double',
            style:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}
