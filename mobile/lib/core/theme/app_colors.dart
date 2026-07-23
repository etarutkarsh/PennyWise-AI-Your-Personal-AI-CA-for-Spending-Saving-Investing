import 'package:flutter/material.dart';

/// PennyWise AI brand palette.
/// Green = growth/savings, deep navy = trust (CA-like authority),
/// amber = alerts/insights.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF0F9D58); // savings green
  static const Color primaryDark = Color(0xFF0B7A44);
  static const Color secondary = Color(0xFF16213E); // trust navy
  static const Color accent = Color(0xFFF2A104); // insight amber

  static const Color success = Color(0xFF2ECC71);
  static const Color danger = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFF39C12);

  static const Color background = Color(0xFFF7F9FC);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
}
