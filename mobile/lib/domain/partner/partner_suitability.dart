/// Qualitative suitability label for a partner program recommendation.
///
/// Users trust qualitative judgments over arbitrary percentages.
/// "Excellent Match" communicates more clearly than "92 score".
enum PartnerSuitability {
  excellentMatch,
  strongMatch,
  goodMatch,
  consider,
  notSuitable;

  String get label => switch (this) {
        PartnerSuitability.excellentMatch => 'Excellent Match',
        PartnerSuitability.strongMatch => 'Strong Match',
        PartnerSuitability.goodMatch => 'Good Match',
        PartnerSuitability.consider => 'Consider',
        PartnerSuitability.notSuitable => 'Not Suitable',
      };

  /// Short form for tight UI slots (badge chips).
  String get shortLabel => switch (this) {
        PartnerSuitability.excellentMatch => 'Excellent',
        PartnerSuitability.strongMatch => 'Strong',
        PartnerSuitability.goodMatch => 'Good Fit',
        PartnerSuitability.consider => 'Consider',
        PartnerSuitability.notSuitable => 'Low Fit',
      };

  /// Whether this program should be shown at all (filter below consider).
  bool get shouldShow =>
      this != PartnerSuitability.notSuitable;

  static PartnerSuitability fromScore(double score) {
    if (score >= 80) return PartnerSuitability.excellentMatch;
    if (score >= 65) return PartnerSuitability.strongMatch;
    if (score >= 50) return PartnerSuitability.goodMatch;
    if (score >= 35) return PartnerSuitability.consider;
    return PartnerSuitability.notSuitable;
  }
}
