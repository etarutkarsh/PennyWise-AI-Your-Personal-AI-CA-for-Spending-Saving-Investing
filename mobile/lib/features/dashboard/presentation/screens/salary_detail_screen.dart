import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/storage/user_prefs_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../learn/presentation/widgets/quiz_section.dart';
import '../widgets/detail_screen_widgets.dart';

class SalaryDetailScreen extends StatelessWidget {
  final double salary;

  const SalaryDetailScreen({super.key, required this.salary});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final needs = salary * 0.50;
    final wants = salary * 0.30;
    final savingsInv = salary * 0.20;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
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
                        const Text('💰 Your Salary',
                            style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          currency.format(salary),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text('Your Financial Foundation',
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
                DetailInfoCard(
                  child: const Text(
                    'Your take-home salary is the base of your entire financial plan. '
                    'Every rupee you earn should have a purpose — this is where it all starts.',
                    style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 20),
                const DetailSectionHeader(icon: '⚖️', title: 'The 50-30-20 Rule'),
                const SizedBox(height: 4),
                const Text(
                  'A simple framework used by millions to allocate their salary wisely.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                _RuleBar(
                  label: '🏠 Needs',
                  subtitle: 'Rent, food, bills, transport, medicine',
                  percentage: 50,
                  amount: currency.format(needs),
                  color: AppColors.secondary,
                ),
                const SizedBox(height: 10),
                _RuleBar(
                  label: '🎉 Wants',
                  subtitle: 'Dining out, shopping, entertainment',
                  percentage: 30,
                  amount: currency.format(wants),
                  color: AppColors.accent,
                ),
                const SizedBox(height: 10),
                _RuleBar(
                  label: '💰 Savings & Investments',
                  subtitle: 'Emergency fund, SIP, FD, PPF',
                  percentage: 20,
                  amount: currency.format(savingsInv),
                  color: AppColors.success,
                ),
                const SizedBox(height: 20),
                const DetailSectionHeader(icon: '📖', title: 'Real-Life Case Study'),
                const SizedBox(height: 12),
                const DetailCaseStudyCard(
                  name: 'Meet Priya',
                  story:
                      'Priya earns ₹65,000/month. She used to spend everything and had zero savings. '
                      'After learning the 50-30-20 rule, she now saves ₹13,000 every month automatically. '
                      'In just 2 years, she built an emergency fund of ₹3.1 lakhs — enough to survive '
                      'without income for 5 months!',
                  lesson: 'Small, consistent habits create unbreakable financial security.',
                  color: AppColors.accent,
                ),
                const SizedBox(height: 20),
                const DetailSectionHeader(icon: '🤯', title: 'Did You Know?'),
                const SizedBox(height: 12),
                const DetailFactChip(
                  fact: '₹1 saved today is worth ₹5 in 20 years at 8% annual interest 🚀',
                ),
                const SizedBox(height: 8),
                const DetailFactChip(
                  fact: 'Only 27% of Indians have any savings. Be in the top 27%! 💪',
                ),
                const SizedBox(height: 8),
                DetailFactChip(
                  fact:
                      'Your first goal: 3 months of salary as an emergency fund = ${currency.format(salary * 3)} 🎯',
                ),
                const SizedBox(height: 24),
                const DetailSectionHeader(icon: '🎮', title: 'Test Your Knowledge'),
                const SizedBox(height: 4),
                const Text('Answer 5 questions and earn XP points!',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 14),
                DetailInfoCard(
                  child: QuizSection(
                    quizId: 'salary_quiz',
                    title: 'Salary & Budgeting Quiz',
                    questions: _buildQuestions(currency, salary),
                    onCompleted: (score, total) async {
                      final isNew =
                          await UserPrefsStorage.addAchievement('salary_quiz_done');
                      if (isNew && context.mounted) {
                        showAchievementSnackbar(
                            context, '💰 Salary Scholar', 'Completed the salary quiz!');
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

  static List<QuizQuestion> _buildQuestions(
      NumberFormat currency, double sal) {
    final twentyPercent = currency.format(sal * 0.20);
    return [
      QuizQuestion(
        question:
            'If your salary is ${currency.format(sal)}, how much should you save monthly using the 20% rule?',
        options: [
          currency.format(sal * 0.10),
          twentyPercent,
          currency.format(sal * 0.30),
          currency.format(sal * 0.50),
        ],
        correctIndex: 1,
        explanation:
            '20% of ${currency.format(sal)} = $twentyPercent. This goes directly to savings and investments — non-negotiable!',
      ),
      const QuizQuestion(
        question: 'What is "take-home salary"?',
        options: [
          'Your salary before any deductions',
          'Salary after PF, income tax & all deductions',
          'Your salary plus all bonuses',
          'The salary promised when you joined',
        ],
        correctIndex: 1,
        explanation:
            'Take-home salary = Gross salary minus PF, income tax, professional tax, etc. It\'s what actually lands in your bank account.',
      ),
      const QuizQuestion(
        question: 'Which expense fits the "Needs" category in the 50-30-20 rule?',
        options: ['Movie tickets', 'New iPhone', 'Monthly rent', 'Vacation trip'],
        correctIndex: 2,
        explanation:
            'Needs are essentials you can\'t live without: rent, food, utilities, medicine, transport. Wants are optional — nice to have, not necessary.',
      ),
      const QuizQuestion(
        question:
            'Priya saves ₹5,000/month for 5 years at 7% annual interest. Roughly how much does she have?',
        options: ['₹3,00,000', '₹3,57,000', '₹5,00,000', '₹2,00,000'],
        correctIndex: 1,
        explanation:
            'Compound interest works magic! ₹5,000 × 60 months = ₹3L principal + ~₹57,000 interest ≈ ₹3.57 lakhs. Start early, earn more!',
      ),
      const QuizQuestion(
        question: 'Which is the FIRST thing to do when your salary arrives?',
        options: [
          'Buy something you\'ve been wanting',
          'Pay all bills, then freely spend the rest',
          'Transfer 20% to savings first, then budget the rest',
          'Invest everything in stocks immediately',
        ],
        correctIndex: 2,
        explanation:
            '"Pay yourself first" — set aside savings BEFORE spending. This ensures you always save, no matter what happens that month!',
      ),
    ];
  }
}

class _RuleBar extends StatelessWidget {
  final String label;
  final String subtitle;
  final int percentage;
  final String amount;
  final Color color;

  const _RuleBar({
    required this.label,
    required this.subtitle,
    required this.percentage,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              Row(
                children: [
                  Text(
                    '$percentage%',
                    style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(amount,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text(subtitle,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
