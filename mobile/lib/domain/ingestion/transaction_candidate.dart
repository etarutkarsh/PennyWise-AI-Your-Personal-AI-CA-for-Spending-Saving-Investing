import 'package:flutter/foundation.dart';
import '../shared/data_source.dart';
import 'merchant_profile.dart';
import 'payment_rail.dart';

/// The normalized intermediate form of a transaction.
/// Produced by TransactionNormalizer from a RawFinancialEvent.
/// Consumed by DuplicateDetector and then promoted to CanonicalTransaction.
///
/// This is the stage where merchant identity is resolved, payment rail is classified,
/// and per-source confidence is assigned.
@immutable
class TransactionCandidate {
  const TransactionCandidate({
    required this.id,
    required this.rawEventId,
    required this.source,
    required this.amount,
    required this.direction,
    required this.merchant,
    required this.rawMerchant,
    required this.paymentRail,
    required this.transactionDate,
    required this.confidence,
    this.accountLast4,
    this.categoryId,
    this.note,
    this.rawText,
    this.isDuplicate = false,
    this.masterCandidateId,
  }) : assert(confidence >= 0.0 && confidence <= 1.0);

  /// Stable candidate id (generated at normalization time).
  final String id;

  /// The source event this was derived from.
  final String rawEventId;

  /// Which data source produced this candidate.
  final DataSource source;

  final double amount;

  /// 'DEBIT' or 'CREDIT'.
  final String direction;

  /// Resolved canonical merchant (may be UnknownMerchantProfile if unresolvable).
  final MerchantProfile merchant;

  /// Original raw merchant string before resolution.
  final String rawMerchant;

  final PaymentRail paymentRail;
  final DateTime transactionDate;

  /// Source-specific confidence (AA = 1.0, SMS = 0.85–0.95, OCR = 0.60–0.85).
  final double confidence;

  final String? accountLast4;
  final String? categoryId;
  final String? note;
  final String? rawText;

  /// True if this candidate was identified as a duplicate of another.
  final bool isDuplicate;

  /// If this is a duplicate, points to the master candidate's id.
  final String? masterCandidateId;

  bool get isDebit => direction == 'DEBIT';
  bool get isCredit => direction == 'CREDIT';
  bool get isMerchantKnown => merchant.isKnown;
  bool get isMandate => paymentRail.isMandate;

  TransactionCandidate markAsDuplicate(String masterId) => TransactionCandidate(
        id: id,
        rawEventId: rawEventId,
        source: source,
        amount: amount,
        direction: direction,
        merchant: merchant,
        rawMerchant: rawMerchant,
        paymentRail: paymentRail,
        transactionDate: transactionDate,
        confidence: confidence,
        accountLast4: accountLast4,
        categoryId: categoryId,
        note: note,
        rawText: rawText,
        isDuplicate: true,
        masterCandidateId: masterId,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionCandidate && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'TransactionCandidate(${merchant.canonicalName} ₹$amount $direction '
      '[${source.label}, conf: ${confidence.toStringAsFixed(2)}])';
}
