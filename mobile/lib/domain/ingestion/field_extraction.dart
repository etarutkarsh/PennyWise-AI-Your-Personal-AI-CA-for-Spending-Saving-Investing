import 'package:flutter/foundation.dart';

/// Describes the method by which a field value was extracted from raw SMS text.
enum ParseDecisionType {
  /// A regular expression pattern explicitly matched.
  regexMatch,

  /// A keyword or phrase match without a full regex.
  keywordMatch,

  /// Value was inferred from context (e.g. direction from rail type).
  inferred,

  /// A fallback heuristic was used when primary methods failed.
  fallback,

  /// Field could not be extracted.
  missing,
}

/// A structured audit record for a single field extraction attempt.
///
/// Attached to every [FieldExtraction] so the Decision Learning Loop can
/// inspect which rule fired, why, and at what confidence — enabling
/// systematic parser improvement.
@immutable
class ParseDecision {
  const ParseDecision({
    required this.fieldName,
    required this.type,
    required this.ruleApplied,
    required this.reason,
    required this.confidence,
    this.regexMatched,
    this.rawExtracted,
  });

  /// The logical field this decision covers.
  /// One of: 'amount', 'direction', 'merchant', 'rail', 'date', 'refId', 'account', 'balance'
  final String fieldName;

  /// How the value was obtained.
  final ParseDecisionType type;

  /// Identifier of the rule or pattern that fired, e.g. 'hdfc_upi_debit_pattern'.
  final String ruleApplied;

  /// Human-readable explanation, e.g. "₹ prefix matched, amount=1234.56".
  final String reason;

  /// Confidence score in [0.0, 1.0].
  final double confidence;

  /// The regex string that matched, if applicable.
  final String? regexMatched;

  /// The raw string captured before normalisation, e.g. "1,234.56".
  final String? rawExtracted;

  /// Factory for a field that was not found in the SMS.
  factory ParseDecision.missing(String fieldName) => ParseDecision(
        fieldName: fieldName,
        type: ParseDecisionType.missing,
        ruleApplied: 'none',
        reason: 'Field not found in SMS',
        confidence: 0.0,
      );

  /// Factory for a field that used a fallback heuristic.
  factory ParseDecision.fallback(String fieldName, String reason) => ParseDecision(
        fieldName: fieldName,
        type: ParseDecisionType.fallback,
        ruleApplied: 'fallback',
        reason: reason,
        confidence: 0.20,
      );

  @override
  String toString() =>
      'ParseDecision(field=$fieldName, type=$type, rule=$ruleApplied, '
      'conf=${confidence.toStringAsFixed(2)})';
}

/// A typed extraction result for a single SMS field, bundled with its audit trail.
///
/// [T] is the normalised value type, e.g. [double] for amount, [String] for merchant.
@immutable
class FieldExtraction<T> {
  const FieldExtraction({
    required this.value,
    required this.confidence,
    required this.decision,
  });

  final T? value;
  final double confidence;
  final ParseDecision decision;

  bool get isPresent => value != null;
  bool get isMissing => value == null;
  bool get isHighConfidence => confidence >= 0.85;
  bool get isAmbiguous => confidence >= 0.50 && confidence < 0.85;

  /// Return this extraction unchanged, or a new [FieldExtraction] using
  /// [fallbackValue] (at 0.20 confidence) if this extraction is missing.
  FieldExtraction<T> orFallback(T fallbackValue, String reason) => isMissing
      ? FieldExtraction<T>(
          value: fallbackValue,
          confidence: 0.20,
          decision: ParseDecision.fallback(decision.fieldName, reason),
        )
      : this;

  /// Factory for a field that could not be extracted.
  factory FieldExtraction.missing(String fieldName) => FieldExtraction<T>(
        value: null,
        confidence: 0.0,
        decision: ParseDecision.missing(fieldName),
      );

  @override
  String toString() =>
      'FieldExtraction<$T>(value=$value, conf=${confidence.toStringAsFixed(2)}, '
      'rule=${decision.ruleApplied})';
}
