/// Age-band overlay that modifies but does not override archetype-based policy.
/// Captures horizon and obligation structure that [UserArchetype] alone cannot encode.
enum LifecycleStage {
  /// Age 18–29: habit building, early compounding, student debt.
  foundation,

  /// Age 30–44: family formation, home, EMIs, children's education.
  growth,

  /// Age 45–54: maximising accumulation, tax efficiency plateau.
  peak,

  /// Age 55–59: de-risking, NPS maturity, liquidity building.
  preRetirement,

  /// Age 60+: distribution phase, capital preservation.
  retirement;

  String get label => switch (this) {
        LifecycleStage.foundation => 'Foundation',
        LifecycleStage.growth => 'Growth',
        LifecycleStage.peak => 'Peak Accumulation',
        LifecycleStage.preRetirement => 'Pre-Retirement',
        LifecycleStage.retirement => 'Retirement',
      };

  /// Derive lifecycle stage from chronological age.
  static LifecycleStage fromAge(int age) {
    if (age < 30) return LifecycleStage.foundation;
    if (age < 45) return LifecycleStage.growth;
    if (age < 55) return LifecycleStage.peak;
    if (age < 60) return LifecycleStage.preRetirement;
    return LifecycleStage.retirement;
  }
}
