import 'package:flutter/foundation.dart';

/// Structured reasoning for a partner program recommendation.
///
/// Mirrors the ExplanationData shape used by the Decision Engine so the
/// Flutter and backend explanation contracts stay aligned. Every recommendation
/// must be explainable — this enforces that at the type level.
@immutable
class RecommendationExplanation {
  const RecommendationExplanation({
    required this.headline,
    required this.summary,
    required this.because,
    required this.whyNot,
    required this.assumptions,
    required this.limitations,
    required this.alternatives,
  });

  /// One-line positive framing: "Great fit for your Emergency Fund goal"
  final String headline;

  /// One-sentence summary combining the top reason and the key benefit.
  final String summary;

  /// 2–5 affirmative reasons this product was chosen.
  /// e.g. "Matches your 12-month timeline", "Capital is protected"
  final List<String> because;

  /// 1–3 reasons alternatives were NOT shown.
  /// e.g. "Equity SIP excluded: goal horizon too short at 8 months"
  /// Builds trust by showing the engine considered other options.
  final List<String> whyNot;

  /// Explicit assumptions the engine made about the user.
  /// e.g. "Assumes moderate risk tolerance based on your profile"
  final List<String> assumptions;

  /// Caveats about this recommendation.
  /// e.g. "Recommendation improves when your Account Aggregator data is connected"
  final List<String> limitations;

  /// 2–3 alternative product names the user could also consider.
  final List<String> alternatives;

  static const empty = RecommendationExplanation(
    headline: '',
    summary: '',
    because: [],
    whyNot: [],
    assumptions: [],
    limitations: [],
    alternatives: [],
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecommendationExplanation && other.headline == headline);

  @override
  int get hashCode => headline.hashCode;
}
