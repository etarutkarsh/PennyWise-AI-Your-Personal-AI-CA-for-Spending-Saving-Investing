/// Qualitative recommendation strength — Flutter domain equivalent of the
/// backend RecommendationStrength enum.
///
/// Derived from [DecisionConfidenceReport.compoundConfidence] via
/// [RecommendationStrength.fromCompound].
enum RecommendationStrength {
  low,
  medium,
  high,
  veryHigh;

  /// Thresholds are calibrated to the multiplicative CTO formula:
  ///   compound = dataConf × decisionConf × behaviorConf × historicalAcc
  ///
  /// New user (manual data only):   ~0.05–0.12 → medium
  /// SMS connected, growing:        ~0.12–0.25 → high
  /// Full power user + calibrated:  ~0.28–0.45 → veryHigh
  static RecommendationStrength fromCompound(double compound) {
    if (compound >= 0.28) return RecommendationStrength.veryHigh;
    if (compound >= 0.12) return RecommendationStrength.high;
    if (compound >= 0.04) return RecommendationStrength.medium;
    return RecommendationStrength.low;
  }

  String get label => switch (this) {
        RecommendationStrength.low => 'Low',
        RecommendationStrength.medium => 'Medium',
        RecommendationStrength.high => 'High',
        RecommendationStrength.veryHigh => 'Very High',
      };

  String get userLabel => switch (this) {
        RecommendationStrength.low =>
          'Limited data — connect more sources for better guidance',
        RecommendationStrength.medium =>
          'Moderate confidence — more data would improve accuracy',
        RecommendationStrength.high =>
          'High confidence — based on strong financial signals',
        RecommendationStrength.veryHigh =>
          'Very high confidence — excellent data and calibrated patterns',
      };

  bool get isAtLeastMedium =>
      this == RecommendationStrength.medium ||
      this == RecommendationStrength.high ||
      this == RecommendationStrength.veryHigh;
}
