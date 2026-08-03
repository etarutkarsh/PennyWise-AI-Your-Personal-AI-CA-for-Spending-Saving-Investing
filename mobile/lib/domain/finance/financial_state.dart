// Defines the FinancialState enum classifying a user's financial life stage.

/// The four financial life stages from the SMRT protocol.
/// Determines which decision engines and recommendations are relevant.
enum FinancialState {
  survive,    // No insurance or emergency fund — fix structure first
  stabilize,  // High-interest debt — debt avalanche before SIP
  build,      // Automated Step-Up compounding — primary mode
  optimize;   // Tax, asset location, estate planning

  String get label => switch (this) {
        FinancialState.survive => 'Survive',
        FinancialState.stabilize => 'Stabilize',
        FinancialState.build => 'Build',
        FinancialState.optimize => 'Optimize',
      };

  String get description => switch (this) {
        FinancialState.survive =>
          'No insurance or emergency fund — fix financial structure first before any investment.',
        FinancialState.stabilize =>
          'High-interest debt present — follow debt avalanche strategy before starting SIPs.',
        FinancialState.build =>
          'Automated Step-Up SIP compounding is the primary mode — grow wealth systematically.',
        FinancialState.optimize =>
          'Focus on tax efficiency, asset location, and estate planning for maximum compounding.',
      };
}
