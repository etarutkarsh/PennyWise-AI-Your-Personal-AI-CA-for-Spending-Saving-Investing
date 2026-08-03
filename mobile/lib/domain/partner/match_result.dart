import 'package:flutter/foundation.dart';

/// The output of a single [MatchingPolicy] evaluation for one program.
///
/// Every dimension of the scoring decision is recorded here.
/// The engine aggregates MatchResults from all evaluations into the
/// final [RankedPartnerProgram.explanation].
@immutable
class MatchResult {
  const MatchResult({
    required this.score,
    required this.reasons,
    required this.warnings,
    required this.assumptions,
    required this.limitations,
  }) : assert(score >= 0.0 && score <= 1.0, 'score must be 0.0–1.0');

  /// Normalised fit score 0.0–1.0. Never starts from a hardcoded value —
  /// it is derived from the policy's reasoning.
  final double score;

  /// Positive reasons this product was chosen. Surface to the user.
  final List<String> reasons;

  /// Concerns or caveats about this recommendation.
  final List<String> warnings;

  /// Assumptions the engine made about the user when data was incomplete.
  final List<String> assumptions;

  /// Where this recommendation could improve with more data.
  final List<String> limitations;

  static const empty = MatchResult(
    score: 0.0,
    reasons: [],
    warnings: [],
    assumptions: [],
    limitations: [],
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is MatchResult && other.score == score);

  @override
  int get hashCode => score.hashCode;
}
