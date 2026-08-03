import 'package:flutter/foundation.dart';
import '../shared/data_source.dart';
import 'merchant_profile.dart';
import 'payment_rail.dart';
import 'transaction_candidate.dart';

/// The final, deduplicated, reconciled transaction.
/// Output of the full pipeline: RawFinancialEvent → normalize → resolve → deduplicate → canonicalize.
///
/// A CanonicalTransaction may be backed by one or multiple sources
/// (e.g., the same transaction confirmed by both AA and SMS — confidence = 1.0).
/// It is the authoritative input to Health Engine, Decision Engine, and Behavioral Engine.
@immutable
class CanonicalTransaction {
  const CanonicalTransaction({
    required this.id,
    required this.amount,
    required this.direction,
    required this.merchant,
    required this.paymentRail,
    required this.transactionDate,
    required this.confidence,
    required this.masterSource,
    required this.sources,
    this.accountLast4,
    this.categoryId,
    this.note,
    this.isReconciled = false,
    this.reconciliationNote,
  }) : assert(confidence >= 0.0 && confidence <= 1.0);

  /// Stable master id.
  final String id;

  final double amount;

  /// 'DEBIT' or 'CREDIT'.
  final String direction;

  final MerchantProfile merchant;
  final PaymentRail paymentRail;
  final DateTime transactionDate;

  /// Reconciled confidence — max of all contributing sources.
  /// AA source = 1.0. Multi-source agreement further boosts confidence.
  final double confidence;

  /// Highest-authority source (AA > SMS > OCR > manual).
  final DataSource masterSource;

  /// All sources that contributed to this canonical record.
  final List<DataSource> sources;

  final String? accountLast4;
  final String? categoryId;
  final String? note;

  /// True if multiple sources confirmed this transaction (highest data quality).
  final bool isReconciled;
  final String? reconciliationNote;

  bool get isDebit => direction == 'DEBIT';
  bool get isCredit => direction == 'CREDIT';
  bool get isVerified => masterSource == DataSource.aaData || isReconciled;
  bool get isMandate => paymentRail.isMandate;
  bool get isMultiSource => sources.length > 1;

  /// Construct a CanonicalTransaction from a single non-duplicate TransactionCandidate.
  factory CanonicalTransaction.fromCandidate(TransactionCandidate candidate) =>
      CanonicalTransaction(
        id: 'canonical_${candidate.id}',
        amount: candidate.amount,
        direction: candidate.direction,
        merchant: candidate.merchant,
        paymentRail: candidate.paymentRail,
        transactionDate: candidate.transactionDate,
        confidence: candidate.confidence,
        masterSource: candidate.source,
        sources: [candidate.source],
        accountLast4: candidate.accountLast4,
        categoryId: candidate.categoryId,
        note: candidate.note,
        isReconciled: false,
      );

  /// Construct a reconciled CanonicalTransaction from multiple sources.
  /// The master source is the highest-authority one (AA > SMS > OCR > manual).
  factory CanonicalTransaction.reconcile(List<TransactionCandidate> candidates) {
    assert(candidates.isNotEmpty);

    final sorted = List<TransactionCandidate>.from(candidates)
      ..sort((a, b) => _sourceAuthority(b.source) - _sourceAuthority(a.source));

    final master = sorted.first;

    // Multi-source agreement gives a small confidence boost (capped at 1.0)
    final baseConfidence = master.confidence;
    final reconciliationBonus = candidates.length > 1 ? 0.05 : 0.0;
    final finalConfidence = (baseConfidence + reconciliationBonus).clamp(0.0, 1.0);

    return CanonicalTransaction(
      id: 'canonical_${master.id}',
      amount: master.amount,
      direction: master.direction,
      merchant: master.merchant,
      paymentRail: master.paymentRail,
      transactionDate: master.transactionDate,
      confidence: finalConfidence,
      masterSource: master.source,
      sources: sorted.map((c) => c.source).toList(),
      accountLast4: master.accountLast4,
      categoryId: master.categoryId,
      note: master.note,
      isReconciled: candidates.length > 1,
      reconciliationNote: candidates.length > 1
          ? 'Confirmed by ${candidates.map((c) => c.source.label).join(', ')}'
          : null,
    );
  }

  static int _sourceAuthority(DataSource source) {
    switch (source) {
      case DataSource.aaData:           return 100;
      case DataSource.smsIntelligence:  return 80;
      case DataSource.transactionHistory: return 70;
      case DataSource.manual:           return 50;
      default:                          return 30;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CanonicalTransaction && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CanonicalTransaction(${merchant.canonicalName} ₹$amount $direction '
      '[${masterSource.label}, conf: ${confidence.toStringAsFixed(2)}, '
      'reconciled: $isReconciled])';
}
