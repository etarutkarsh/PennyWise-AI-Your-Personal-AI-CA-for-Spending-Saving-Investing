// Defines DecisionType enum — the ten categories of financial decisions PennyWise can generate.

/// Types of financial decisions the Decision Engine can generate.
enum DecisionType {
  buildEmergencyFund,
  increaseSavingsRate,
  startGoalSip,
  stepUpSip,
  optimizeTax,
  reduceDebt,
  getInsurance,
  optimizeSubscription,
  rebalancePortfolio,
  reviewPastDecision;

  String get label => switch (this) {
        DecisionType.buildEmergencyFund => 'Build Emergency Fund',
        DecisionType.increaseSavingsRate => 'Increase Savings Rate',
        DecisionType.startGoalSip => 'Start Goal SIP',
        DecisionType.stepUpSip => 'Step Up Your SIP',
        DecisionType.optimizeTax => 'Optimise Tax',
        DecisionType.reduceDebt => 'Reduce Debt',
        DecisionType.getInsurance => 'Get Insurance',
        DecisionType.optimizeSubscription => 'Optimise Subscriptions',
        DecisionType.rebalancePortfolio => 'Rebalance Portfolio',
        DecisionType.reviewPastDecision => 'Review Past Decision',
      };

  /// Emoji icon for UI display.
  String get icon => switch (this) {
        DecisionType.buildEmergencyFund => '🛡️',
        DecisionType.increaseSavingsRate => '📈',
        DecisionType.startGoalSip => '🎯',
        DecisionType.stepUpSip => '⬆️',
        DecisionType.optimizeTax => '🧾',
        DecisionType.reduceDebt => '⛓️',
        DecisionType.getInsurance => '🔒',
        DecisionType.optimizeSubscription => '✂️',
        DecisionType.rebalancePortfolio => '⚖️',
        DecisionType.reviewPastDecision => '🔍',
      };

  /// Priority ordering (lower number = higher priority in survive/stabilize states).
  int get priority => switch (this) {
        DecisionType.buildEmergencyFund => 1,
        DecisionType.getInsurance => 2,
        DecisionType.reduceDebt => 3,
        DecisionType.increaseSavingsRate => 4,
        DecisionType.startGoalSip => 5,
        DecisionType.stepUpSip => 6,
        DecisionType.optimizeTax => 7,
        DecisionType.optimizeSubscription => 8,
        DecisionType.rebalancePortfolio => 9,
        DecisionType.reviewPastDecision => 10,
      };
}
