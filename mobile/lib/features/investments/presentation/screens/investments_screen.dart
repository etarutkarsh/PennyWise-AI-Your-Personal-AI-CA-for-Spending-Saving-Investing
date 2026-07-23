import 'package:flutter/material.dart';

import '../../../../shared/widgets/placeholder_screen.dart';

/// Feature 7 - Investment Coach (Phase 3). Explains mutual funds, stocks,
/// ETFs, gold, FD, PPF, NPS, bonds, REITs and SIPs with a compounding simulator.
class InvestmentsScreen extends StatelessWidget {
  const InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Investments',
      icon: Icons.trending_up_rounded,
      description: 'Portfolio tracking and beginner-friendly investment guidance land in Phase 3.',
    );
  }
}
