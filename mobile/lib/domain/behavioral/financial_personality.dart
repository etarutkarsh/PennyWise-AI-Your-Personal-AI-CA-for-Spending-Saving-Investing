// Defines FinancialPersonality enum derived from the BehavioralVector.

import 'behavioral_vector.dart';

/// Four financial personality archetypes derived from the behavioral vector.
enum FinancialPersonality {
  guardian,     // high loss aversion — capital preservation above all
  accumulator,  // balanced, consistent SIP behaviour
  builder,      // moderate risk, goal-focused
  optimizer;    // low loss aversion, tax-efficient strategies

  String get label => switch (this) {
        FinancialPersonality.guardian => 'Guardian',
        FinancialPersonality.accumulator => 'Accumulator',
        FinancialPersonality.builder => 'Builder',
        FinancialPersonality.optimizer => 'Optimizer',
      };

  String get description => switch (this) {
        FinancialPersonality.guardian =>
          'High loss aversion drives you toward capital preservation. '
              'Fixed deposits and liquid funds feel safer than equity.',
        FinancialPersonality.accumulator =>
          'You invest consistently and methodically. SIPs run on autopilot; '
              'you rarely tinker with your portfolio.',
        FinancialPersonality.builder =>
          'Goal-focused and moderately risk-tolerant. You track progress '
              'toward specific milestones and adjust along the way.',
        FinancialPersonality.optimizer =>
          'Low loss aversion and tax-efficiency focused. You think in '
              'after-tax returns and rebalance for asset location.',
      };

  /// Derives the most likely personality from a [BehavioralVector].
  /// This is a heuristic — the real classification lives in the Behavioral Engine.
  static FinancialPersonality derivedFrom(BehavioralVector vector) {
    if (vector.lossAversion >= 2.2) return FinancialPersonality.guardian;
    if (vector.riskToleranceDrift >= 0.7) return FinancialPersonality.optimizer;
    if (vector.impulseVolatility <= 0.3 && vector.presentBias >= 0.8) {
      return FinancialPersonality.accumulator;
    }
    return FinancialPersonality.builder;
  }
}
