import 'package:flutter/foundation.dart';

/// Employment and life-stage classification. Primary input to [PolicySelector].
///
/// Determined primarily from the user's onboarding profile (employment type).
/// Partially inferred from [FinancialFacts] when profile data is unavailable —
/// e.g., if ageYears > 60 and income is pension/interest, the system infers [retiree].
///
/// Users cannot self-select away from protective invariants by changing archetype.
enum UserArchetype {
  /// No or minimal income, in education, age 18–26.
  student,

  /// Working, single, no dependents, age 22–28.
  youngProfessional,

  /// Salaried, may have dependents (spouse/children/parents).
  salariedWithFamily,

  /// Self-employed, irregular income, any age.
  freelancer,

  /// Has a registered business; complex personal-business finance interface.
  businessOwner,

  /// 5–10 years from planned retirement, any employment type.
  preRetiree,

  /// Distribution phase — age 60+ or explicitly retired.
  retiree;

  String get label => switch (this) {
        UserArchetype.student => 'Student',
        UserArchetype.youngProfessional => 'Young Professional',
        UserArchetype.salariedWithFamily => 'Salaried',
        UserArchetype.freelancer => 'Freelancer',
        UserArchetype.businessOwner => 'Business Owner',
        UserArchetype.preRetiree => 'Pre-Retiree',
        UserArchetype.retiree => 'Retiree',
      };

  String get description => switch (this) {
        UserArchetype.student =>
          'Building financial habits before wealth is available',
        UserArchetype.youngProfessional =>
          'Establishing financial foundation with stable income',
        UserArchetype.salariedWithFamily =>
          'Optimising deployment of a reliable monthly surplus',
        UserArchetype.freelancer =>
          'Managing irregular income with conservative cash-flow discipline',
        UserArchetype.businessOwner =>
          'Separating personal and business finance with elevated tax efficiency',
        UserArchetype.preRetiree =>
          'Transitioning from accumulation to preservation',
        UserArchetype.retiree =>
          'Sustainable withdrawal and capital preservation',
      };
}

/// Infers the most likely [UserArchetype] from available facts.
/// Returns [UserArchetype.salariedWithFamily] as the conservative default when
/// data is insufficient — this archetype's weights are closest to the population
/// median and degrade the least when the true archetype is unknown.
@immutable
class UserArchetypeInferrer {
  const UserArchetypeInferrer();

  UserArchetype infer({
    required int ageYears,
    UserArchetype? profileHint,
  }) {
    // Retirement is an override — age-based, not profile-hint overrideable.
    if (ageYears >= 60) return UserArchetype.retiree;
    if (ageYears >= 55) return UserArchetype.preRetiree;

    // Use explicit profile hint when available and plausible.
    if (profileHint != null) {
      // Do not allow a 25-year-old to self-select retiree.
      if (profileHint == UserArchetype.retiree && ageYears < 55) {
        return UserArchetype.youngProfessional;
      }
      return profileHint;
    }

    // Age-based default when no hint provided.
    if (ageYears < 27) return UserArchetype.youngProfessional;
    return UserArchetype.salariedWithFamily;
  }
}
