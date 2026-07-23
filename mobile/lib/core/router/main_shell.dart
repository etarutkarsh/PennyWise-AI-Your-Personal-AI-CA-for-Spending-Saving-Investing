import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Bottom-nav shell wrapping the 5 primary tabs from PRD Section 8/17
/// (Dashboard, Transactions, Goals, Learn, Ask AI). Other screens
/// (Budget, Investments, Reports, Settings, ...) are pushed on top.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    (icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Dashboard'),
    (icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, label: 'Transactions'),
    (icon: Icons.flag_outlined, activeIcon: Icons.flag_rounded, label: 'Goals'),
    (icon: Icons.school_outlined, activeIcon: Icons.school_rounded, label: 'Learn'),
    (icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded, label: 'Ask AI'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: [
          for (final tab in _tabs)
            BottomNavigationBarItem(
              icon: Icon(tab.icon),
              activeIcon: Icon(tab.activeIcon),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}
