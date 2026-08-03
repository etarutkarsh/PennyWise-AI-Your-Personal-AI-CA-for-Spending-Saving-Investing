import 'package:flutter/foundation.dart';

import 'partner_program.dart';

/// Records why a [PartnerProgram] was excluded from recommendations.
///
/// Rejection reasons power the "why not?" section of [RecommendationExplanation]
/// for programs that WERE shown — e.g., "Equity excluded: goal horizon too short."
/// They also support a future "hidden products" disclosure screen.
@immutable
class RejectionReason {
  const RejectionReason({
    required this.program,
    required this.code,
    required this.explanation,
  });

  final PartnerProgram program;

  /// Machine-readable rejection code for analytics and replay.
  /// e.g. 'LOCK_IN_EXCEEDS_HORIZON', 'INSTRUMENT_TOO_VOLATILE',
  ///      'DEBT_COST_EXCEEDS_RETURN', 'DUPLICATE_EXPOSURE'
  final String code;

  /// User-readable explanation. Shown in "Why wasn't X shown?" disclosure.
  final String explanation;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RejectionReason &&
          other.program == program &&
          other.code == code);

  @override
  int get hashCode => Object.hash(program, code);

  @override
  String toString() =>
      'RejectionReason(code: $code, program: ${program.productName})';
}
