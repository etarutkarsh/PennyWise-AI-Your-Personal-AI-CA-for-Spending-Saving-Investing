import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/storage/user_prefs_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../learn/presentation/widgets/quiz_section.dart';
import '../widgets/detail_screen_widgets.dart';

class InvestmentDetailScreen extends StatelessWidget {
  final double salary;
  final double investments;

  const InvestmentDetailScreen(
      {super.key, required this.salary, required this.investments});

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    // 20% of salary → savings+investments; allocate 60% of that to investments
    final investBudget = salary * 0.20 * 0.60;
    final equityMF = investBudget * 0.50;
    final debtFund = investBudget * 0.25;
    final goldETF = investBudget * 0.15;
    final ppf = investBudget * 0.10;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF16213E), Color(0xFF0F3460)],
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
                        const Text('📈 Investments',
                            style:
                                TextStyle(color: Colors.white60, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          currency.format(investments),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w800),
                        ),
                        const Text('Your Wealth-Building Engine',
                            style:
                                TextStyle(color: Colors.white60, fontSize: 13)),
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
                    'Savings protect you. Investments GROW you. While savings sit in a bank at 4–7%, '
                    'well-chosen investments can grow 10–15% annually — beating inflation and building real wealth.',
                    style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 20),
                const DetailSectionHeader(icon: '🔺', title: 'The Investment Pyramid'),
                const SizedBox(height: 12),
                const _PyramidCard(),
                const SizedBox(height: 20),
                const DetailSectionHeader(
                    icon: '💼', title: 'Smart Portfolio for Your Salary'),
                const SizedBox(height: 4),
                Text(
                  'Based on ${currency.format(salary)}/month, here\'s your suggested monthly SIP allocation:',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                _PortfolioCard(
                  items: [
                    _PortfolioItem(
                      emoji: '💹',
                      label: 'Equity MF (Nifty 50 Index)',
                      amount: currency.format(equityMF),
                      pct: 50,
                      color: AppColors.primary,
                      note: 'High return, long-term (7+ yrs)',
                    ),
                    _PortfolioItem(
                      emoji: '🏛️',
                      label: 'Debt / Liquid Fund',
                      amount: currency.format(debtFund),
                      pct: 25,
                      color: AppColors.secondary,
                      note: 'Stable, low-risk, easily redeemable',
                    ),
                    _PortfolioItem(
                      emoji: '🥇',
                      label: 'Gold ETF',
                      amount: currency.format(goldETF),
                      pct: 15,
                      color: AppColors.accent,
                      note: 'Inflation hedge, safe haven',
                    ),
                    _PortfolioItem(
                      emoji: '🇮🇳',
                      label: 'PPF / ELSS (Tax Saving)',
                      amount: currency.format(ppf),
                      pct: 10,
                      color: AppColors.success,
                      note: 'Tax benefit under Section 80C',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const DetailSectionHeader(icon: '🚀', title: 'Power of SIP'),
                const SizedBox(height: 4),
                const Text(
                  'If you invest ₹5,000/month in a Nifty 50 index fund at 12% annual return:',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04), blurRadius: 8)
                    ],
                  ),
                  child: const Column(
                    children: [
                      _SIPRow(years: 5, amount: '~₹4 Lakhs', color: AppColors.accent),
                      Divider(height: 16),
                      _SIPRow(years: 10, amount: '~₹11.6 Lakhs', color: AppColors.primary),
                      Divider(height: 16),
                      _SIPRow(years: 20, amount: '~₹49.9 Lakhs', color: AppColors.success),
                      Divider(height: 16),
                      _SIPRow(years: 30, amount: '~₹1.76 Crore 🚀', color: AppColors.secondary),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const DetailFactChip(
                  fact:
                      'You invested only ₹18 lakhs over 30 years — but got ₹1.76 Crore! That\'s compounding magic. 🪄',
                ),
                const SizedBox(height: 20),
                const DetailSectionHeader(icon: '📖', title: 'Real-Life Case Study'),
                const SizedBox(height: 12),
                const DetailCaseStudyCard(
                  name: 'Aditya vs Rahul',
                  story:
                      'Aditya started a ₹3,000/month SIP in a Nifty 50 index fund at age 25. '
                      'His friend Rahul waited until 35. Same monthly amount, same fund. '
                      'By retirement at 60: Aditya has ₹3.5 Crore, Rahul has ₹65 Lakhs. '
                      'Aditya has 5× more — just because he started 10 years earlier!',
                  lesson:
                      'Time in the market beats timing the market. Start today, not tomorrow.',
                  color: AppColors.secondary,
                ),
                const SizedBox(height: 20),
                const DetailSectionHeader(icon: '🤯', title: 'Did You Know?'),
                const SizedBox(height: 12),
                const DetailFactChip(
                  fact:
                      'Warren Buffett made 99% of his wealth AFTER his 50th birthday — compounding takes time! ⏳',
                ),
                const SizedBox(height: 8),
                const DetailFactChip(
                  fact:
                      'Index funds beat ~80% of actively managed funds over 10+ years. Simple wins! 📊',
                ),
                const SizedBox(height: 24),
                const DetailSectionHeader(icon: '🎮', title: 'Test Your Knowledge'),
                const SizedBox(height: 4),
                const Text('5 questions, earn up to 50 XP!',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 14),
                DetailInfoCard(
                  child: QuizSection(
                    quizId: 'investment_quiz',
                    title: 'Investment Fundamentals Quiz',
                    questions: _investmentQuestions,
                    onCompleted: (score, total) async {
                      final isNew = await UserPrefsStorage.addAchievement(
                          'investment_quiz_done');
                      if (isNew && context.mounted) {
                        showAchievementSnackbar(context, '📈 Investment Pro',
                            'Completed the investment quiz!');
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

  static const List<QuizQuestion> _investmentQuestions = [
    QuizQuestion(
      question: 'What is a SIP (Systematic Investment Plan)?',
      options: [
        'A type of bank fixed deposit',
        'Investing a fixed amount in a mutual fund every month',
        'A government savings certificate',
        'Special Insurance Premium',
      ],
      correctIndex: 1,
      explanation:
          'SIP means investing a fixed amount regularly (monthly). It averages out market ups and downs — called rupee cost averaging — and builds wealth through discipline.',
    ),
    QuizQuestion(
      question: 'Which investment type typically delivers the highest long-term returns?',
      options: [
        'Fixed Deposits (FD)',
        'Savings Account',
        'Equity Mutual Funds',
        'Gold',
      ],
      correctIndex: 2,
      explanation:
          'Historically, equity mutual funds deliver 10–15% annually over long periods, far outperforming FDs (6–7%) and savings accounts (3–5%). Higher risk = higher reward over time.',
    ),
    QuizQuestion(
      question: 'What is "diversification" in investing?',
      options: [
        'Putting all money into one company you believe in',
        'Spreading investments across different assets to reduce risk',
        'Changing your investment platform often',
        'Investing only in gold for safety',
      ],
      correctIndex: 1,
      explanation:
          'Diversification = don\'t put all eggs in one basket! If one asset class falls, others may hold or rise, protecting your overall portfolio from big losses.',
    ),
    QuizQuestion(
      question: 'What is an Index Fund?',
      options: [
        'A fund where experts actively pick the best stocks',
        'A fund that mirrors a market index like Nifty 50',
        'A government bond with fixed interest',
        'An insurance product with investment component',
      ],
      correctIndex: 1,
      explanation:
          'Index funds passively track an index (e.g., Nifty 50 = top 50 Indian companies). They have low fees, broad diversification, and historically beat ~80% of actively managed funds!',
    ),
    QuizQuestion(
      question:
          'Asha invests ₹1,000/month at 12% annual return for 20 years. What does she roughly get?',
      options: ['₹2,40,000', '₹9,90,000', '₹5,00,000', '₹1,00,000'],
      correctIndex: 1,
      explanation:
          'At 12% compounding, ₹1,000/month for 20 years ≈ ₹9.9 lakhs — on just ₹2.4 lakhs invested! That extra ₹7.5 lakhs is pure compounding magic. Start today!',
    ),
  ];
}

class _PyramidCard extends StatelessWidget {
  const _PyramidCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        children: [
          _PyramidLevel(
            label: 'High Risk / High Return',
            examples: 'Direct Stocks, Crypto',
            percent: '5–10%',
            color: AppColors.danger,
            widthFactor: 0.4,
          ),
          const SizedBox(height: 8),
          _PyramidLevel(
            label: 'Medium Risk / Medium Return',
            examples: 'Equity MFs, Index Funds',
            percent: '40–50%',
            color: AppColors.accent,
            widthFactor: 0.65,
          ),
          const SizedBox(height: 8),
          _PyramidLevel(
            label: 'Low Risk / Stable Base',
            examples: 'FD, Debt Funds, Gold, PPF',
            percent: '40–50%',
            color: AppColors.success,
            widthFactor: 1.0,
          ),
          const SizedBox(height: 10),
          const Text(
            '↑ Build from the bottom up: secure base first, then grow upward',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

class _PyramidLevel extends StatelessWidget {
  final String label;
  final String examples;
  final String percent;
  final Color color;
  final double widthFactor;

  const _PyramidLevel({
    required this.label,
    required this.examples,
    required this.percent,
    required this.color,
    required this.widthFactor,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text(percent,
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: color,
                      fontSize: 13)),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600)),
              Text(examples,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PortfolioItem {
  final String emoji;
  final String label;
  final String amount;
  final int pct;
  final Color color;
  final String note;

  const _PortfolioItem({
    required this.emoji,
    required this.label,
    required this.amount,
    required this.pct,
    required this.color,
    required this.note,
  });
}

class _PortfolioCard extends StatelessWidget {
  final List<_PortfolioItem> items;

  const _PortfolioCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        children: items
            .expand((item) => [
                  _PortfolioRow(item: item),
                  if (item != items.last) const Divider(height: 14),
                ])
            .toList(),
      ),
    );
  }
}

class _PortfolioRow extends StatelessWidget {
  final _PortfolioItem item;

  const _PortfolioRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(item.emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              Text(item.note,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(item.amount,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: item.color,
                    fontSize: 13)),
            Text('${item.pct}%',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ],
    );
  }
}

class _SIPRow extends StatelessWidget {
  final int years;
  final String amount;
  final Color color;

  const _SIPRow(
      {required this.years, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('$years yrs',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
            const SizedBox(width: 10),
            const Text('@ 12% p.a.',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
        Text(amount,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 14)),
      ],
    );
  }
}
