// Defines Explanation and its sub-components for transparent, auditable decision rationale.

import 'package:flutter/foundation.dart';

/// A single piece of evidence supporting a decision, with full provenance.
///
/// Provenance fields ([confidence], [engineVersion]) make recommendations
/// auditable: you can see exactly how confident we were in each fact,
/// and which engine version produced it. This is the XAI contract.
@immutable
class EvidenceItem {
  final String label;
  final String value;

  /// Data source identifier (use [DataSource.id] values).
  final String source;

  /// When this evidence was last observed or computed.
  final DateTime freshness;

  /// Confidence in this evidence. 1.0 = bank-verified. 0.3 = estimated.
  /// Evidence older than 7 days or sourced from MANUAL gets a lower confidence.
  final double confidence;

  /// Which engine version produced this evidence. null = manually entered.
  final String? engineVersion;

  const EvidenceItem({
    required this.label,
    required this.value,
    required this.source,
    required this.freshness,
    this.confidence = 1.0,
    this.engineVersion,
  }) : assert(confidence >= 0.0 && confidence <= 1.0,
            'confidence must be 0.0–1.0');

  bool get isStale => DateTime.now().difference(freshness).inDays > 7;
  bool get isHighConfidence => confidence >= 0.80;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EvidenceItem && other.label == label && other.source == source);

  @override
  int get hashCode => Object.hash(label, source, freshness);

  @override
  String toString() =>
      'EvidenceItem(label: $label, source: $source, confidence: $confidence)';
}

/// An alternative action the user could take instead of the primary recommendation.
@immutable
class AlternativeAction {
  final String action;
  final String instrument;
  final String tradeoff;

  const AlternativeAction({
    required this.action,
    required this.instrument,
    required this.tradeoff,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlternativeAction &&
          other.action == action &&
          other.instrument == instrument);

  @override
  int get hashCode => Object.hash(action, instrument);

  @override
  String toString() => 'AlternativeAction(action: $action, instrument: $instrument)';
}

/// Full explainability payload for a Decision — what, why, evidence, and alternatives.
@immutable
class Explanation {
  /// Primary headline ≤ 80 characters.
  final String headline;

  /// 2–3 sentence summary.
  final String summary;

  /// Bullet-point reasons for this recommendation.
  final List<String> because;

  /// Data evidence items supporting the recommendation.
  final List<EvidenceItem> evidence;

  /// Assumptions made by the engine when data was missing.
  final List<String> assumptions;

  /// Alternative actions the user could take.
  final List<AlternativeAction> alternatives;

  /// Why other options were not recommended.
  final List<String> whyNot;

  /// Explicit tradeoffs of the primary recommendation.
  final List<String> tradeoffs;

  /// What drove the confidence score.
  final List<String> confidenceDrivers;

  /// Known limitations of this recommendation.
  final List<String> limitations;

  /// Engine invocation trace for auditing.
  final List<String> engineTrace;

  const Explanation({
    required this.headline,
    required this.summary,
    required this.because,
    required this.evidence,
    required this.assumptions,
    required this.alternatives,
    required this.whyNot,
    required this.tradeoffs,
    required this.confidenceDrivers,
    required this.limitations,
    required this.engineTrace,
  });

  /// Empty explanation used as a safe default before the Explainability Engine is built.
  factory Explanation.empty() => const Explanation(
        headline: '',
        summary: '',
        because: [],
        evidence: [],
        assumptions: [],
        alternatives: [],
        whyNot: [],
        tradeoffs: [],
        confidenceDrivers: [],
        limitations: [],
        engineTrace: [],
      );

  bool get isEmpty => headline.isEmpty;

  Explanation copyWith({
    String? headline,
    String? summary,
    List<String>? because,
    List<EvidenceItem>? evidence,
    List<String>? assumptions,
    List<AlternativeAction>? alternatives,
    List<String>? whyNot,
    List<String>? tradeoffs,
    List<String>? confidenceDrivers,
    List<String>? limitations,
    List<String>? engineTrace,
  }) =>
      Explanation(
        headline: headline ?? this.headline,
        summary: summary ?? this.summary,
        because: because ?? this.because,
        evidence: evidence ?? this.evidence,
        assumptions: assumptions ?? this.assumptions,
        alternatives: alternatives ?? this.alternatives,
        whyNot: whyNot ?? this.whyNot,
        tradeoffs: tradeoffs ?? this.tradeoffs,
        confidenceDrivers: confidenceDrivers ?? this.confidenceDrivers,
        limitations: limitations ?? this.limitations,
        engineTrace: engineTrace ?? this.engineTrace,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Explanation && other.headline == headline && other.summary == summary);

  @override
  int get hashCode => Object.hash(headline, summary);

  @override
  String toString() => 'Explanation(headline: "$headline")';
}
