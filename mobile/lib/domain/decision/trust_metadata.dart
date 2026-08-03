// Defines TrustMetadata — provenance and fiduciary metadata for every Decision.

import 'package:flutter/foundation.dart';

/// Provenance and fiduciary metadata attached to every Decision for full auditability.
@immutable
class TrustMetadata {
  final String algorithmVersion;

  /// Knowledge graph version, null until Knowledge Graph Engine is built.
  final String? knowledgeGraphVersion;

  final DateTime decisionDate;
  final Duration dataFreshness;

  /// Data sources that were unavailable when generating this decision.
  final List<String> missingData;

  /// Always false — PennyWise never has a commission conflict (fiduciary invariant).
  final bool commissionConflict;

  /// External sources that were verified when generating this decision.
  final List<String> verifiedSources;

  final String fiduciaryStatement;

  /// PennyWise's fiduciary commitment shown on every recommendation.
  static const String defaultFiduciaryStatement =
      'PennyWise earns nothing from this recommendation. '
      'Partner programs are ranked purely by fit for your financial situation — '
      'never by commission. Your interests are the only ranking signal.';

  const TrustMetadata({
    required this.algorithmVersion,
    this.knowledgeGraphVersion,
    required this.decisionDate,
    required this.dataFreshness,
    required this.missingData,
    this.commissionConflict = false,
    required this.verifiedSources,
    required this.fiduciaryStatement,
  }) : assert(!commissionConflict,
            'Fiduciary invariant violated: commissionConflict must always be false');

  TrustMetadata copyWith({
    String? algorithmVersion,
    String? knowledgeGraphVersion,
    DateTime? decisionDate,
    Duration? dataFreshness,
    List<String>? missingData,
    List<String>? verifiedSources,
    String? fiduciaryStatement,
  }) =>
      TrustMetadata(
        algorithmVersion: algorithmVersion ?? this.algorithmVersion,
        knowledgeGraphVersion: knowledgeGraphVersion ?? this.knowledgeGraphVersion,
        decisionDate: decisionDate ?? this.decisionDate,
        dataFreshness: dataFreshness ?? this.dataFreshness,
        missingData: missingData ?? this.missingData,
        commissionConflict: false,
        verifiedSources: verifiedSources ?? this.verifiedSources,
        fiduciaryStatement: fiduciaryStatement ?? this.fiduciaryStatement,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrustMetadata &&
          other.algorithmVersion == algorithmVersion &&
          other.decisionDate == decisionDate);

  @override
  int get hashCode => Object.hash(algorithmVersion, decisionDate);

  @override
  String toString() =>
      'TrustMetadata(version: $algorithmVersion, commissionConflict: $commissionConflict)';
}
