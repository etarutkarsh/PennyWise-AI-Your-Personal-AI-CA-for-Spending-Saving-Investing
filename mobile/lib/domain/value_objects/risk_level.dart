// Defines the RiskLevel enum for classifying financial product and portfolio risk.

/// Risk level classifications used for financial instruments and user risk appetite.
enum RiskLevel {
  low,
  medium,
  high,
  veryHigh;

  String get label => switch (this) {
        RiskLevel.low => 'Low',
        RiskLevel.medium => 'Medium',
        RiskLevel.high => 'High',
        RiskLevel.veryHigh => 'Very High',
      };
}
