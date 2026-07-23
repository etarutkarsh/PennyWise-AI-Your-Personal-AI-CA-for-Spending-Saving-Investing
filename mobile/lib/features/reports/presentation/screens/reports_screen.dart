import 'package:flutter/material.dart';

import '../../../../shared/widgets/placeholder_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Reports',
      icon: Icons.bar_chart_rounded,
      description: 'Spending forecasts and monthly reports (Feature 9) land in Phase 2/3.',
    );
  }
}
