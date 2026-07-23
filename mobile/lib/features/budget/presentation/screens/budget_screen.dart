import 'package:flutter/material.dart';

import '../../../../shared/widgets/placeholder_screen.dart';

/// Feature: budget tracking (Phase 1). Backed by GET/POST /budgets.
class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Budgets',
      icon: Icons.pie_chart_outline_rounded,
      description: 'Set per-category monthly limits and get alerted before you go over.',
    );
  }
}
