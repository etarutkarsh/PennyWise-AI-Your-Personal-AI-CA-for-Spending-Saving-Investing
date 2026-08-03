import 'package:flutter/foundation.dart';
import 'payment_rail.dart';

/// Per-field confidence weights — each field contributes to the overall ExtractionResult confidence.
/// Based on SMS_PARSING_SPEC.md §10 confidence scoring.
class FieldConfidence {
  static const double amountHigh = 0.30;
  static const double amountAmbiguous = 0.15;
  static const double amountMissing = -0.30;

  static const double directionHigh = 0.25;
  static const double directionAmbiguous = 0.10;
  static const double directionMissing = -0.25;

  static const double dateHigh = 0.15;
  static const double dateAmbiguous = 0.08;
  static const double dateMissing = -0.10;

  static const double merchantHigh = 0.15;
  static const double merchantAmbiguous = 0.05;
  // missing merchant = 0 (no penalty — merchant may be inferred from rail context)

  static const double railHigh = 0.10;
  static const double railAmbiguous = 0.05;

  static const double refIdHigh = 0.05;
  static const double refIdAmbiguous = 0.02;

  /// Thresholds
  static const double thresholdHigh = 0.85;
  static const double thresholdMedium = 0.60;
  // < thresholdMedium → queue for manual review
}

/// Confidence tier for the overall extraction.
enum ExtractionTier {
  /// ≥ 0.85 — all key fields present, no ambiguities.
  high,

  /// 0.60–0.84 — some fields missing or ambiguous; still usable.
  medium,

  /// < 0.60 — too many missing or ambiguous fields; queue for manual review.
  review,
}

/// The output of a single SMS (or other raw-text) parse attempt.
///
/// Wraps the extracted fields with per-field confidence scores,
/// a list of ambiguities, and a parser version stamp so historical
/// events can be re-processed when the parser improves (Phase 8.2 Event Replay).
///
/// This sits between raw SMS text and TransactionCandidate:
///   RawSmsText → SmsParserService → ExtractionResult
///                                 → TransactionNormalizer → TransactionCandidate
@immutable
class ExtractionResult {
  const ExtractionResult({
    required this.parserVersion,
    required this.rawText,
    required this.overallConfidence,
    this.amount,
    this.amountConfidence = 0.0,
    this.direction,
    this.directionConfidence = 0.0,
    this.rawMerchant,
    this.merchantConfidence = 0.0,
    this.paymentRail,
    this.railConfidence = 0.0,
    this.transactionDate,
    this.dateConfidence = 0.0,
    this.referenceId,
    this.refIdConfidence = 0.0,
    this.accountLast4,
    this.availableBalance,
    this.ambiguities = const [],
    this.isPreDebitAlert = false,
    this.isRejected = false,
    this.rejectionReason,
  }) : assert(overallConfidence >= 0.0 && overallConfidence <= 1.0);

  /// The parser version that produced this result, e.g. 'sms-parser-v1'.
  /// Must be carried forward to RawFinancialEvent for event replay.
  final String parserVersion;

  /// Original raw SMS body, preserved for replay and debugging.
  final String rawText;

  /// Computed overall confidence — see FieldConfidence constants for weighting.
  final double overallConfidence;

  // ── Extracted fields ────────────────────────────────────────────────────────

  final double? amount;
  final double amountConfidence;

  /// 'DEBIT' or 'CREDIT'
  final String? direction;
  final double directionConfidence;

  final String? rawMerchant;
  final double merchantConfidence;

  final PaymentRail? paymentRail;
  final double railConfidence;

  final DateTime? transactionDate;
  final double dateConfidence;

  final String? referenceId;
  final double refIdConfidence;

  final String? accountLast4;
  final double? availableBalance;

  // ── Quality signals ─────────────────────────────────────────────────────────

  /// Human-readable descriptions of any ambiguities encountered during parsing.
  /// Examples:
  ///   'Amount appears twice with different values (₹500 and ₹5.00)'
  ///   'Direction keyword missing — inferred DEBIT from context'
  ///   'Merchant name truncated at 20 chars'
  final List<String> ambiguities;

  /// True when the SMS is a pre-debit notification (RBI mandate alert), NOT a transaction.
  /// Pre-debit alerts must never be ingested as transactions.
  /// Filter phrase: "will be debited"/"mandate of"/"due on"
  final bool isPreDebitAlert;

  /// True when this SMS was actively rejected (spam/OTP/non-financial).
  final bool isRejected;
  final String? rejectionReason;

  // ── Computed properties ─────────────────────────────────────────────────────

  ExtractionTier get tier {
    if (overallConfidence >= FieldConfidence.thresholdHigh) return ExtractionTier.high;
    if (overallConfidence >= FieldConfidence.thresholdMedium) return ExtractionTier.medium;
    return ExtractionTier.review;
  }

  bool get isHighConfidence => tier == ExtractionTier.high;
  bool get needsReview => tier == ExtractionTier.review;

  /// True if the minimum fields for a TransactionCandidate are present.
  bool get isUsable =>
      !isPreDebitAlert && !isRejected && amount != null && direction != null && transactionDate != null;

  bool get hasAmbiguities => ambiguities.isNotEmpty;

  bool get isMerchantResolvable => rawMerchant != null && rawMerchant!.isNotEmpty;

  @override
  String toString() =>
      'ExtractionResult(v=$parserVersion, conf=${overallConfidence.toStringAsFixed(2)}, '
      'tier=$tier, ₹$amount $direction, merchant=$rawMerchant, '
      'ambiguities=${ambiguities.length})';
}

/// Builder for constructing ExtractionResult with auto-computed overall confidence.
/// Usage pattern:
///   final result = ExtractionResultBuilder(parserVersion: kSmsParserVersion, rawText: sms)
///     ..setAmount(500.0, high: true)
///     ..setDirection('DEBIT', high: true)
///     ..setDate(DateTime.now(), high: true)
///     ..setMerchant('NETFLIX', high: false, ambiguity: 'Truncated merchant name')
///     .build();
class ExtractionResultBuilder {
  ExtractionResultBuilder({
    required this.parserVersion,
    required this.rawText,
  });

  final String parserVersion;
  final String rawText;

  double? _amount;
  double _amountConfidence = 0.0;
  double _amountScore = FieldConfidence.amountMissing;

  String? _direction;
  double _directionConfidence = 0.0;
  double _directionScore = FieldConfidence.directionMissing;

  String? _rawMerchant;
  double _merchantConfidence = 0.0;
  double _merchantScore = 0.0;

  PaymentRail? _paymentRail;
  double _railConfidence = 0.0;
  double _railScore = 0.0;

  DateTime? _transactionDate;
  double _dateConfidence = 0.0;
  double _dateScore = FieldConfidence.dateMissing;

  String? _referenceId;
  double _refIdConfidence = 0.0;
  double _refIdScore = 0.0;

  String? _accountLast4;
  double? _availableBalance;

  final List<String> _ambiguities = [];
  bool _isPreDebitAlert = false;
  bool _isRejected = false;
  String? _rejectionReason;

  void setAmount(double amount, {required bool high, String? ambiguity}) {
    _amount = amount;
    _amountScore = high ? FieldConfidence.amountHigh : FieldConfidence.amountAmbiguous;
    _amountConfidence = high ? 0.95 : 0.70;
    if (ambiguity != null) _ambiguities.add(ambiguity);
  }

  void setDirection(String direction, {required bool high, String? ambiguity}) {
    _direction = direction.toUpperCase();
    _directionScore = high ? FieldConfidence.directionHigh : FieldConfidence.directionAmbiguous;
    _directionConfidence = high ? 0.95 : 0.65;
    if (ambiguity != null) _ambiguities.add(ambiguity);
  }

  void setMerchant(String merchant, {required bool high, String? ambiguity}) {
    _rawMerchant = merchant;
    _merchantScore = high ? FieldConfidence.merchantHigh : FieldConfidence.merchantAmbiguous;
    _merchantConfidence = high ? 0.90 : 0.60;
    if (ambiguity != null) _ambiguities.add(ambiguity);
  }

  void setRail(PaymentRail rail, {required bool high, String? ambiguity}) {
    _paymentRail = rail;
    _railScore = high ? FieldConfidence.railHigh : FieldConfidence.railAmbiguous;
    _railConfidence = high ? 0.95 : 0.70;
    if (ambiguity != null) _ambiguities.add(ambiguity);
  }

  void setDate(DateTime date, {required bool high, String? ambiguity}) {
    _transactionDate = date;
    _dateScore = high ? FieldConfidence.dateHigh : FieldConfidence.dateAmbiguous;
    _dateConfidence = high ? 0.95 : 0.75;
    if (ambiguity != null) _ambiguities.add(ambiguity);
  }

  void setReferenceId(String refId, {required bool high}) {
    _referenceId = refId;
    _refIdScore = high ? FieldConfidence.refIdHigh : FieldConfidence.refIdAmbiguous;
    _refIdConfidence = high ? 0.95 : 0.70;
  }

  void setAccountLast4(String last4) => _accountLast4 = last4;
  void setAvailableBalance(double balance) => _availableBalance = balance;

  void addAmbiguity(String description) => _ambiguities.add(description);

  void markPreDebitAlert() => _isPreDebitAlert = true;

  void reject(String reason) {
    _isRejected = true;
    _rejectionReason = reason;
  }

  ExtractionResult build() {
    // Base confidence = 0.05 (any parseable SMS starts slightly above zero)
    const base = 0.05;
    final rawScore = base +
        _amountScore +
        _directionScore +
        _dateScore +
        _merchantScore +
        _railScore +
        _refIdScore;
    final overall = rawScore.clamp(0.0, 1.0);

    return ExtractionResult(
      parserVersion: parserVersion,
      rawText: rawText,
      overallConfidence: overall,
      amount: _amount,
      amountConfidence: _amountConfidence,
      direction: _direction,
      directionConfidence: _directionConfidence,
      rawMerchant: _rawMerchant,
      merchantConfidence: _merchantConfidence,
      paymentRail: _paymentRail,
      railConfidence: _railConfidence,
      transactionDate: _transactionDate,
      dateConfidence: _dateConfidence,
      referenceId: _referenceId,
      refIdConfidence: _refIdConfidence,
      accountLast4: _accountLast4,
      availableBalance: _availableBalance,
      ambiguities: List.unmodifiable(_ambiguities),
      isPreDebitAlert: _isPreDebitAlert,
      isRejected: _isRejected,
      rejectionReason: _rejectionReason,
    );
  }
}
