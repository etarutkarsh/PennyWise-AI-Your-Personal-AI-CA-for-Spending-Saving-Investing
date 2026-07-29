import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Core dark shell
  static const Color background      = Color(0xFF09090B);
  static const Color surface         = Color(0xFF111827);
  static const Color surfaceElevated = Color(0xFF1A1F2E);
  static const Color border          = Color(0xFF1E2535);

  // Brand CTA (keep orange for CTAs, add blue/indigo for hero + primary actions)
  static const Color orange  = Color(0xFFF4722B);
  static const Color amber   = Color(0xFFFFB830);
  static const Color primary = Color(0xFFF4722B);
  static const Color accent  = Color(0xFFFFB830);

  // Premium blue-indigo scale (hero gradients, primary nav, trust signals)
  static const Color blue     = Color(0xFF3B82F6);
  static const Color indigo   = Color(0xFF6366F1);
  static const Color deepBlue = Color(0xFF1E3A8A);
  static const Color violet   = Color(0xFF7C3AED);

  // Text
  static const Color textPrimary   = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF8A8FA8);
  static const Color textMuted     = Color(0xFF4A4F62);

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color danger  = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // Quest card pastel backgrounds (used on dark shell)
  static const Color questPeach  = Color(0xFFF4E4D0);
  static const Color questGreen  = Color(0xFFD4EDDA);
  static const Color questPurple = Color(0xFFE8D5F5);
  static const Color questBlue   = Color(0xFFD0E8FF);
  static const Color questYellow = Color(0xFFFFF3CD);
  static const Color questRose   = Color(0xFFFFE4E4);

  // Legacy aliases (keeps other screens compiling)
  static const Color primaryDark = Color(0xFFBF5820);
  static const Color secondary   = Color(0xFF111827);
  static const Color emeraldGlow = Color(0xFF22C55E);
  static const Color goldLeaf    = Color(0xFFFFB830);
  static const Color heroStart   = Color(0xFF09090B);
  static const Color heroMid     = Color(0xFF111827);
  static const Color heroEnd     = Color(0xFF1A1F2E);
  static const Color glassWhite  = Color(0x10FFFFFF);
  static const Color glassBorder = Color(0x1AFFFFFF);

  // Money card gradients
  static const List<Color> salaryGradient  = [Color(0xFF1D4ED8), Color(0xFF06B6D4)];
  static const List<Color> savingsGradient = [Color(0xFF059669), Color(0xFF22C55E)];
  static const List<Color> investGradient  = [Color(0xFF6D28D9), Color(0xFF8B5CF6)];
  static const List<Color> budgetGradient  = [Color(0xFFD97706), Color(0xFFF97316)];
}
