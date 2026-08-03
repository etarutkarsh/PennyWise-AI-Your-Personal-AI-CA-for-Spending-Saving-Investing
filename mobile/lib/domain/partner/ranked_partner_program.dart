// Defines RankedPartnerProgram — a partner program with ranking metadata from the Partner Matching Engine.

import 'package:flutter/foundation.dart';
import 'partner_program.dart';

/// A partner program ranked by the Partner Matching Engine for a specific decision context.
@immutable
class RankedPartnerProgram {
  final PartnerProgram program;

  /// 1-based rank within the result set.
  final int rank;

  /// Match score from 0.0 to 1.0.
  final double matchScore;

  /// Human-readable explanation of why this program was ranked here.
  final String matchExplanation;

  /// Short trust statement shown in the UI (e.g. "No commission earned on this recommendation").
  final String trustStatement;

  /// CTA button label (e.g. "Start SIP", "Open Account").
  final String ctaLabel;

  const RankedPartnerProgram({
    required this.program,
    required this.rank,
    required this.matchScore,
    required this.matchExplanation,
    required this.trustStatement,
    required this.ctaLabel,
  }) : assert(matchScore >= 0.0 && matchScore <= 1.0,
            'matchScore must be between 0.0 and 1.0');

  RankedPartnerProgram copyWith({
    PartnerProgram? program,
    int? rank,
    double? matchScore,
    String? matchExplanation,
    String? trustStatement,
    String? ctaLabel,
  }) =>
      RankedPartnerProgram(
        program: program ?? this.program,
        rank: rank ?? this.rank,
        matchScore: matchScore ?? this.matchScore,
        matchExplanation: matchExplanation ?? this.matchExplanation,
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
  String toString() => 'RankedPartnerProgram(rank: $rank, program: $program, score: $matchScore)';
}
