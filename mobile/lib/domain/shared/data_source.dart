// Defines DataSource — the origin of a piece of financial evidence.

/// Where a piece of evidence was sourced from.
///
/// Used in [EvidenceItem.source] to communicate data freshness and trust.
/// Higher-fidelity sources (AA_DATA, SMS_INTELLIGENCE) produce stronger
/// evidence than MANUAL entry.
enum DataSource {
  /// Bank-verified data via RBI Account Aggregator (Setu SDK).
  aaData,

  /// Parsed from SMS bank alerts (another_telephony).
  smsIntelligence,

  /// User-entered transaction or profile data.
  manual,

  /// Computed from transaction history already in the system.
  transactionHistory,

  /// Goal data (target amount, saved amount, deadline, contribution).
  goalData,

  /// Behavioral profile (calibrated vector θ from BehavioralEngine).
  behavioralProfile,

  /// Knowledge graph semantic relationship.
  knowledgeGraph,

  /// Commitment/recurring-payment detection engine.
  commitmentEngine;

  /// Human-readable label for UI display.
  String get label => switch (this) {
        DataSource.aaData => 'Account Aggregator',
        DataSource.smsIntelligence => 'SMS Intelligence',
        DataSource.manual => 'Manual Entry',
        DataSource.transactionHistory => 'Transaction History',
        DataSource.goalData => 'Goal Data',
        DataSource.behavioralProfile => 'Behavioral Profile',
        DataSource.knowledgeGraph => 'Knowledge Graph',
        DataSource.commitmentEngine => 'Commitment Engine',
      };

  /// Machine-readable identifier stored in [EvidenceItem.source].
  String get id => switch (this) {
        DataSource.aaData => 'AA_DATA',
        DataSource.smsIntelligence => 'SMS_INTELLIGENCE',
        DataSource.manual => 'MANUAL',
        DataSource.transactionHistory => 'TRANSACTION_HISTORY',
        DataSource.goalData => 'GOAL_DATA',
        DataSource.behavioralProfile => 'BEHAVIORAL_PROFILE',
        DataSource.knowledgeGraph => 'KNOWLEDGE_GRAPH',
        DataSource.commitmentEngine => 'COMMITMENT_ENGINE',
      };

  /// Whether this source produces bank-grade verified data.
  bool get isVerified => this == DataSource.aaData;
}
