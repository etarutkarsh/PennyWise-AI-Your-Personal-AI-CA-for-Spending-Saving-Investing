import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/goal_entity.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  // TODO: replace with GoalsBloc backed by GET /goals.
  final List<GoalEntity> _goals = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Goals')),
      body: _goals.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flag_outlined, size: 48, color: AppColors.textSecondary),
                    const SizedBox(height: 12),
                    const Text('No goals yet', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text(
                      'Set a goal (MacBook, vacation, emergency fund...) and PennyWise '
                      'will tell you how much to save each month.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _showCreateGoalSheet(context),
                      child: const Text('Create a goal'),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _goals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _GoalCard(goal: _goals[index]),
            ),
      floatingActionButton: _goals.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () => _showCreateGoalSheet(context),
              child: const Icon(Icons.add),
            ),
    );
  }

  void _showCreateGoalSheet(BuildContext context) {
    // TODO: build a form matching GoalCreateRequest (name, goalType, targetAmount,
    // deadline, priority) and POST to /goals.
    showModalBottomSheet(
      context: context,
      builder: (_) => const SizedBox(
        height: 200,
        child: Center(child: Text('Goal creation form goes here')),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});

  final GoalEntity goal;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(goal.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (goal.progressPercent / 100).clamp(0, 1),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              backgroundColor: AppColors.background,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              '${currency.format(goal.currentSaved)} of ${currency.format(goal.targetAmount)}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.savings_outlined, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Save ${currency.format(goal.recommendedMonthlyContribution)}/month '
                    '(${goal.investmentSuggestion.replaceAll('_', ' ')}) to hit this by '
                    '${DateFormat.yMMM().format(goal.deadline)}.',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
