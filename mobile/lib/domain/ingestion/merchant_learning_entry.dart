import 'package:flutter/foundation.dart';

/// The review status of an unresolved merchant in the learning queue.
enum MerchantLearningStatus {
  /// Seen in SMS/AA data but never matched to a canonical profile.
  needsReview,

  /// A human (or future ML pass) has confirmed the canonical merchant id.
  resolved,

  /// Intentionally ignored — spam, noise, or internal bank text.
  ignored,
}

/// A single entry in the MerchantLearningQueue.
///
/// Created when MerchantResolver.resolve() returns UnknownMerchantProfile.
/// Accumulates occurrence counts so high-frequency unknowns are prioritised
/// for review. When status → resolved, the canonical id is used to backfill
/// historical CanonicalTransactions via Event Replay.
@immutable
class MerchantLearningEntry {
  const MerchantLearningEntry({
    required this.rawMerchant,
    required this.normalizedKey,
    required this.status,
    required this.occurrenceCount,
    required this.firstSeen,
    required this.lastSeen,
    this.resolvedCanonicalId,
    this.resolvedAt,
    this.resolvedByParserVersion,
    this.sampleRawTexts = const [],
  }) : assert(occurrenceCount >= 1);

  /// The raw merchant string exactly as extracted from the source.
  final String rawMerchant;

  /// Normalized form used for grouping duplicates (lowercase, no punctuation).
  /// Two raw strings that normalize to the same key are counted as one entry.
  final String normalizedKey;

  final MerchantLearningStatus status;

  /// How many times this raw merchant has appeared across all parsed events.
  final int occurrenceCount;

  final DateTime firstSeen;
  final DateTime lastSeen;

  /// Populated when status = resolved.
  final String? resolvedCanonicalId;
  final DateTime? resolvedAt;

  /// The parser version active when this entry was created.
  /// Used to scope event replay: only re-run events parsed before this version.
  final String? resolvedByParserVersion;

  /// Up to 3 sample raw SMS bodies for context during review.
  final List<String> sampleRawTexts;

  bool get isResolved => status == MerchantLearningStatus.resolved;
  bool get needsReview => status == MerchantLearningStatus.needsReview;

  /// Higher priority = review this first. Factors: frequency + recency.
  int get reviewPriority {
    final daysSinceSeen = DateTime.now().difference(lastSeen).inDays;
    // Frequency weighted heavily — a merchant seen 50 times is more valuable to resolve
    return (occurrenceCount * 10) - daysSinceSeen;
  }

  MerchantLearningEntry increment(DateTime seenAt, {String? rawText}) {
    final updatedSamples = List<String>.from(sampleRawTexts);
    if (rawText != null && updatedSamples.length < 3) {
      updatedSamples.add(rawText);
    }
    return MerchantLearningEntry(
      rawMerchant: rawMerchant,
      normalizedKey: normalizedKey,
      status: status,
      occurrenceCount: occurrenceCount + 1,
      firstSeen: firstSeen,
      lastSeen: seenAt,
      resolvedCanonicalId: resolvedCanonicalId,
      resolvedAt: resolvedAt,
      resolvedByParserVersion: resolvedByParserVersion,
      sampleRawTexts: List.unmodifiable(updatedSamples),
    );
  }

  MerchantLearningEntry resolve({
    required String canonicalId,
    required String resolvedByVersion,
  }) =>
      MerchantLearningEntry(
        rawMerchant: rawMerchant,
        normalizedKey: normalizedKey,
        status: MerchantLearningStatus.resolved,
        occurrenceCount: occurrenceCount,
        firstSeen: firstSeen,
        lastSeen: lastSeen,
        resolvedCanonicalId: canonicalId,
        resolvedAt: DateTime.now(),
        resolvedByParserVersion: resolvedByVersion,
        sampleRawTexts: sampleRawTexts,
      );

  MerchantLearningEntry ignore() => MerchantLearningEntry(
        rawMerchant: rawMerchant,
        normalizedKey: normalizedKey,
        status: MerchantLearningStatus.ignored,
        occurrenceCount: occurrenceCount,
        firstSeen: firstSeen,
        lastSeen: lastSeen,
        resolvedCanonicalId: resolvedCanonicalId,
        resolvedAt: resolvedAt,
        resolvedByParserVersion: resolvedByParserVersion,
        sampleRawTexts: sampleRawTexts,
      );

  @override
  String toString() =>
      'MerchantLearningEntry($rawMerchant, count=$occurrenceCount, status=$status)';
}

/// In-memory registry of unresolved merchant strings.
///
/// Phase 8.2 implementation: stores entries in memory for the current session.
/// Phase 8.3 upgrade: persist to local SQLite / backend merchant_learning table.
///
/// The queue is the feedback loop for the MerchantResolver:
///   Unknown merchant → queued here → human review → resolver updated → event replay
class MerchantLearningQueue {
  MerchantLearningQueue();

  final Map<String, MerchantLearningEntry> _entries = {};

  static String _normalize(String raw) =>
      raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), '').replaceAll(RegExp(r'\s+'), ' ').trim();

  /// Record an unresolved merchant. If already queued, increments occurrence count.
  void record(String rawMerchant, {required String parserVersion, String? rawText}) {
    final key = _normalize(rawMerchant);
    if (key.isEmpty) return;

    final now = DateTime.now();
    final existing = _entries[key];
    if (existing == null) {
      _entries[key] = MerchantLearningEntry(
        rawMerchant: rawMerchant,
        normalizedKey: key,
        status: MerchantLearningStatus.needsReview,
        occurrenceCount: 1,
        firstSeen: now,
        lastSeen: now,
        resolvedByParserVersion: parserVersion,
        sampleRawTexts: rawText != null ? [rawText] : const [],
      );
    } else {
      _entries[key] = existing.increment(now, rawText: rawText);
    }
  }

  /// Mark an entry as resolved — triggers event replay for historical events.
  void resolve(String rawMerchant, {required String canonicalId, required String parserVersion}) {
    final key = _normalize(rawMerchant);
    final existing = _entries[key];
    if (existing == null) return;
    _entries[key] = existing.resolve(canonicalId: canonicalId, resolvedByVersion: parserVersion);
  }

  void ignore(String rawMerchant) {
    final key = _normalize(rawMerchant);
    final existing = _entries[key];
    if (existing == null) return;
    _entries[key] = existing.ignore();
  }

  /// All entries needing review, sorted by review priority (highest first).
  List<MerchantLearningEntry> get reviewQueue => _entries.values
      .where((e) => e.needsReview)
      .toList()
    ..sort((a, b) => b.reviewPriority.compareTo(a.reviewPriority));

  /// Recently resolved entries — used to trigger event replay.
  List<MerchantLearningEntry> get pendingReplay =>
      _entries.values.where((e) => e.isResolved).toList();

  int get queueLength => _entries.values.where((e) => e.needsReview).length;

  bool get hasUnresolved => queueLength > 0;
}
