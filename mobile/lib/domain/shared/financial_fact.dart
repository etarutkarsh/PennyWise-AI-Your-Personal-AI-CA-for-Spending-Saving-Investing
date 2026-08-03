// Defines FinancialFact — a typed, sourced, confidence-tagged financial datum.

import 'package:flutter/foundation.dart';

import '../decision/explanation.dart';
import 'data_source.dart';

/// A single piece of financial knowledge with full provenance.
///
/// Where [EvidenceItem] is an explanation output (shown to the user),
/// [FinancialFact] is an engine input (consumed by HealthScoreEngine,
/// DecisionEngine, etc.) before the explanation is assembled.
///
/// Every engine should consume [FinancialFact]s rather than raw primitives.
/// This means every input is self-describing: you know where it came from,
/// how confident we are in it, and whether it is stale.
///
/// Usage:
/// ```dart
/// final emergencyFund = FinancialFact<double>(
///   value: 2.1,
///   source: DataSource.goalData,
///   confidence: 0.85,
///   timestamp: DateTime.now(),
/// );
/// if (emergencyFund.isStale) // older than 7 days
/// ```
@immutable
class FinancialFact<T> {
  const FinancialFact({
    required this.value,
    required this.source,
    required this.confidence,
    required this.timestamp,
    this.unit,
    this.engineVersion,
  }) : assert(confidence >= 0.0 && confidence <= 1.0, 'confidence must be 0.0–1.0');

  /// The fact's value (typed — double, int, String, bool, etc.).
  final T value;

  /// Where this fact came from.
  final DataSource source;

  /// How reliable this value is. 1.0 = bank-verified; 0.3 = inferred estimate.
  final double confidence;

  /// When this fact was last observed or computed.
  final DateTime timestamp;

  /// Optional display unit (e.g. 'months', 'INR', '%').
  final String? unit;

  /// Which engine version produced this fact.
  final String? engineVersion;

  /// True if this value is bank-verified (Account Aggregator).
  bool get isVerified => source.isVerified;

  /// True if this fact is older than 7 days — stale evidence reduces Confidence.score.
  bool get isStale => DateTime.now().difference(timestamp).inDays > 7;

  /// High confidence: ≥ 0.80
  bool get isHighConfidence => confidence >= 0.80;

  /// Convert to [EvidenceItem] for inclusion in a Decision's [Explanation].
  EvidenceItem toEvidence({required String label}) => EvidenceItem(
        label: label,
        value: unit != null ? '${value}${unit!.isEmpty ? '' : ' $unit'}' : value.toString(),
        source: source.id,
        freshness: timestamp,
        confidence: confidence,
        engineVersion: engineVersion,
      );

  FinancialFact<T> copyWith({
    T? value,
    DataSource? source,
    double? confidence,
    DateTime? timestamp,
    String? unit,
    String? engineVersion,
  }) =>
      FinancialFact<T>(
        value: value ?? this.value,
        source: source ?? this.source,
        confidence: confidence ?? this.confidence,
        timestamp: timestamp ?? this.timestamp,
        unit: unit ?? this.unit,
        engineVersion: engineVersion ?? this.engineVersion,
      );

  @override
  String toString() =>
      'FinancialFact<${T.toString()}>(value: $value, source: ${source.id}, '
      'confidence: $confidence, stale: $isStale)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FinancialFact &&
          other.value == value &&
          other.source == source &&
          other.timestamp == timestamp);

  @override
  int get hashCode => Object.hash(value, source, timestamp);
}
