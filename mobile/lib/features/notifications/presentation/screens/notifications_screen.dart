import 'package:flutter/material.dart';

import '../../../../shared/widgets/placeholder_screen.dart';

/// Feature 14 - AI Alerts (overspend warnings, subscription reminders, etc).
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Notifications',
      icon: Icons.notifications_none_rounded,
      description: 'AI spending alerts will show up here once /notifications is wired up.',
    );
  }
}
