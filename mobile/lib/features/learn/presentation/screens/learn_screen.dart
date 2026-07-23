import 'package:flutter/material.dart';

import '../../../../shared/widgets/placeholder_screen.dart';

/// Feature 11 - Learning Mode + Feature 12 - Money Stories (Phase 2).
class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Learn',
      icon: Icons.school_outlined,
      description: 'Daily finance lessons, quizzes and Money Stories arrive in Phase 2.',
    );
  }
}
