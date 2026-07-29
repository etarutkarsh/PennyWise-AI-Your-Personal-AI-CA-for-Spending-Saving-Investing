import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Core dark shell ──────────────────────────────────────────────────────
  static const Color background       = Color(0xFF0F0F0F);
  static const Color surface          = Color(0xFF1A1A1A);
  static const Color surfaceElevated  = Color(0xFF252525);
  static const Color border           = Color(0xFF2A2A2A);

  // ── Brand accents ────────────────────────────────────────────────────────
  static const Color orange   = Color(0xFFF4722B); // Level-style orange
  static const Color amber    = Color(0xFFFFB830); // gold/XP
  static const Color primary  = Color(0xFFF4722B); // alias
  static const Color accent   = Color(0xFFFFB830); // alias

  // ── Text ────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF888888);
  static const Color textMuted     = Color(0xFF555555);

  // ── Semantic ────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF2ECC71);
  static const Color danger  = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFF39C12);

  // ── Quest card pastel backgrounds (used on dark shell) ──────────────────
  static const Color questPeach  = Color(0xFFF4E4D0); // warm orange detail
  static const Color questGreen  = Color(0xFFD4EDDA);
  static const Color questPurple = Color(0xFFE8D5F5);
  static const Color questBlue   = Color(0xFFD0E8FF);
  static const Color questYellow = Color(0xFFFFF3CD);
  static const Color questRose   = Color(0xFFFFE4E4);

  // ── Legacy aliases (keeps other screens compiling) ───────────────────────
  static const Color primaryDark    = Color(0xFFBF5820);
  static const Color secondary      = Color(0xFF1A1A1A);
  static const Color emeraldGlow    = Color(0xFF2ECC71);
  static const Color goldLeaf       = Color(0xFFFFB830);
  static const Color heroStart      = Color(0xFF0F0F0F);
  static const Color heroMid        = Color(0xFF1A1A1A);
  static const Color heroEnd        = Color(0xFF252525);
  static const Color glassWhite     = Color(0x10FFFFFF);
  static const Color glassBorder    = Color(0x1AFFFFFF);

  // ── Money card gradients ─────────────────────────────────────────────────
  static const List<Color> salaryGradient = [Color(0xFF0F9D58), Color(0xFF00D47E)];
  static const List<Color> savingsGradient= [Color(0xFF1565C0), Color(0xFF1E88E5)];
  static const List<Color> investGradient = [Color(0xFF6A1B9A), Color(0xFFAB47BC)];
  static const List<Color> budgetGradient = [Color(0xFFE65100), Color(0xFFFF7043)];
}
