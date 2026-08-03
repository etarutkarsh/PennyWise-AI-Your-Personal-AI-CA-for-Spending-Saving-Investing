// Defines RankedPartnerProgram — output of the Partner Matching Engine.

import 'package:flutter/foundation.dart';

import 'partner_program.dart';
import 'partner_suitability.dart';
import 'recommendation_explanation.dart';

/// A partner program ranked and explained by the Partner Matching Engine.
///
/// Every field beyond [program] and [rank] is the engine's reasoning made
/// explicit. The UI must surface explanation.because and explanation.whyNot
/// so the user can always ask "why is this shown?".
@immutable
class RankedPartnerProgram {
  const RankedPartnerProgram({
    required this.program,
    required this.rank,
    required this.matchScore,
    required this.suitability,
    required this.explanation,
    required this.trustStatement,
    required this.ctaLabel,
  }) : assert(matchScore >= 0.0 && matchScore <= 1.0,
            'matchScore must be between 0.0 and 1.0');

  final PartnerProgram program;

  /// 1-based rank within the result set.
  final int rank;

  /// Normalised score 0.0–1.0 (raw engine score / 100).
  final double matchScore;

  /// Qualitative suitability label — shown instead of raw score.
  final PartnerSuitability suitability;

  /// Full structured explanation of why this was recommended.
  final RecommendationExplanation explanation;

  /// Short trust statement sourced from PartnerBrand — shown on card face.
  final String trustStatement;

  /// CTA button label: 'Start SIP', 'Open Account', 'Compare Rates'.
  final String ctaLabel;

  // ── Convenience accessors ─────────────────────────────────────────────────

  /// Legacy accessor — use explanation.because for the structured form.
  String get matchExplanation => explanation.headline;

  RankedPartnerProgram copyWith({
    PartnerProgram? program,
    int? rank,
    double? matchScore,
    PartnerSuitability? suitability,
    RecommendationExplanation? explanation,
    String? trustStatement,
    String? ctaLabel,
  }) =>
      RankedPartnerProgram(
        program: program ?? this.program,
        rank: rank ?? this.rank,
        matchScore: matchScore ?? this.matchScore,
        suitability: suitability ?? this.suitability,
        explanation: explanation ?? this.explanation,
        trustStatement: trustStatement ?? this.trustStatement,
        ctaLabel: ctaLabel ?? this.ctaLabel,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RankedPartnerProgram &&
          other.program == program &&
          other.rank == rank);

  @override
  int get hashCode => Object.hash(program, rank);

  @override
  String toString() =>
      'RankedPartnerProgram(rank: $rank, suitability: ${suitability.label}, program: $program)';
}
