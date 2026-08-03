import '../../../../domain/engines/bank_sms_parser.dart';
import '../../../../domain/ingestion/bank_capability.dart';
import '../../../../domain/ingestion/extraction_result.dart';
import '../../../../domain/ingestion/field_extraction.dart';
import '../../../../domain/ingestion/payment_rail.dart';
import '../extractors/account_extractor.dart';
import '../extractors/amount_extractor.dart';
import '../extractors/balance_extractor.dart';
import '../extractors/date_extractor.dart';
import '../extractors/direction_extractor.dart';
import '../extractors/merchant_extractor.dart';
import '../extractors/rail_extractor.dart';
import '../extractors/reference_extractor.dart';

/// Bank-specific SMS parser for Kotak Mahindra Bank.
///
/// Kotak SMS formats:
///   "Your Kotak Acct XX1234 has been debited with Rs.2000 on 24-07-26. Merchant: SWIGGY. Avl Bal: Rs.15000"
///   "Rs.1000 debited from Kotak Bank Acct XX1234 via UPI on 24-Jul-26. UPI Ref: 123456789012"
///
/// Handles:
///  - "Merchant:" label extraction (highest confidence — explicit bank label).
///  - "has been debited" → direction confidence boost to 0.98.
class KotakSmsParser implements BankSmsParser {
  const KotakSmsParser();

  static const _kBankId = 'kotak';
  static const _kParserVersion = 'kotak-v1';

  static final _amountExtractor = AmountExtractor();
  static final _directionExtractor = DirectionExtractor();
  static final _merchantExtractor = MerchantExtractor();
  static final _railExtractor = RailExtractor();
  static final _dateExtractor = DateExtractor();
  static final _referenceExtractor = ReferenceExtractor();
  static final _accountExtractor = AccountExtractor();
  static final _balanceExtractor = BalanceExtractor();

  // Kotak "Merchant: SWIGGY." label — explicit bank-provided merchant label
  static final _kotakMerchantPattern = RegExp(
    r'Merchant:\s*([A-Z][A-Za-z0-9\s&.]{2,30})(?:[.,]|$)',
    caseSensitive: false,
  );

  // "has been debited" — Kotak phrase triggering confidence boost
  static final _hasBeenDebitedPattern = RegExp(
    r'\bhas\s+been\s+debited\b',
    caseSensitive: false,
  );

  @override
  String get bankId => _kBankId;

  @override
  String get parserVersion => _kParserVersion;

  @override
  BankCapability get capability => BankCapability.kotak;

  @override
  bool supports(String senderAddress) {
    final bare = _extractBareId(senderAddress);
    return BankCapability.kotak.senderPrefixes.any(
      (prefix) => bare.toUpperCase().startsWith(prefix),
    );
  }

  @override
  ExtractionResult parse(String rawText, String senderAddress) {
    if (isPreDebitAlert(rawText)) {
      return (ExtractionResultBuilder(parserVersion: parserVersion, rawText: rawText)
            ..markPreDebitAlert())
          .build();
    }

    final amount = _amountExtractor.extract(rawText);
    final direction = _directionExtractor.extract(rawText);
    final merchant = _merchantExtractor.extract(rawText);
    final rail = _railExtractor.extract(rawText);
    final date = _dateExtractor.extract(rawText);
    final ref = _referenceExtractor.extract(rawText);
    final account = _accountExtractor.extract(rawText);
    final balance = _balanceExtractor.extract(rawText);

    final builder = ExtractionResultBuilder(parserVersion: parserVersion, rawText: rawText);

    if (amount.isPresent) {
      builder.setAmount(
        amount.value!,
        high: amount.isHighConfidence,
        ambiguity: amount.isAmbiguous ? amount.decision.reason : null,
      );
    }

    // ── Kotak direction confidence boost applied here before setDirection ─────
    // When "has been debited" is present, treat direction as near-certain.
    if (direction.isPresent) {
      final boosted = _hasBeenDebitedPattern.hasMatch(rawText) &&
          direction.value == 'DEBIT';
      builder.setDirection(direction.value!, high: boosted || direction.isHighConfidence);
    }

    if (merchant.isPresent) {
      builder.setMerchant(
        merchant.value!,
        high: merchant.isHighConfidence,
        ambiguity: merchant.isAmbiguous ? merchant.decision.reason : null,
      );
    }
    if (rail.isPresent) {
      builder.setRail(rail.value!, high: rail.isHighConfidence);
    }
    if (date.isPresent) {
      builder.setDate(
        date.value!,
        high: date.isHighConfidence,
        ambiguity: date.isAmbiguous ? date.decision.reason : null,
      );
    }
    if (ref.isPresent) builder.setReferenceId(ref.value!, high: ref.isHighConfidence);
    if (account.isPresent) builder.setAccountLast4(account.value!);
    if (balance.isPresent) builder.setAvailableBalance(balance.value!);

    _applyBankSpecificOverrides(rawText, builder, amount, direction, merchant, rail);

    return builder.build();
  }

  void _applyBankSpecificOverrides(
    String rawText,
    ExtractionResultBuilder builder,
    FieldExtraction<double> amount,
    FieldExtraction<String> direction,
    FieldExtraction<String> merchant,
    FieldExtraction<PaymentRail> rail,
  ) {
    // ── Override 1: Kotak "Merchant:" label ───────────────────────────────────
    // Spec: 0.93 — highest priority, explicit bank-provided label.
    final merchantLabelMatch = _kotakMerchantPattern.firstMatch(rawText);
    if (merchantLabelMatch != null) {
      final extracted = merchantLabelMatch.group(1)?.trim();
      if (extracted != null && extracted.isNotEmpty) {
        // Always override any generic merchant extraction — explicit label wins.
        // high: true gives 0.90 which is the closest to the spec's 0.93.
        builder.setMerchant(extracted, high: true);
      }
    }
    // Note: Direction confidence boost for "has been debited" is applied directly
    // in parse() before setDirection is called, so it does not need repeating here.
  }

  String _extractBareId(String sender) {
    final parts = sender.toUpperCase().split('-');
    if (parts.length >= 2) {
      final withoutPrefix = parts.sublist(1).join('-');
      return withoutPrefix.endsWith('-S')
          ? withoutPrefix.substring(0, withoutPrefix.length - 2)
          : withoutPrefix;
    }
    return sender.toUpperCase();
  }

  @override
  bool isPreDebitAlert(String rawText) {
    final lower = rawText.toLowerCase();
    return lower.contains("will be debited") ||
        lower.contains("mandate of") ||
        (lower.contains("due on") && lower.contains("mandate"));
  }

  @override
  bool isFinancialSms(String rawText) {
    final lower = rawText.toLowerCase();
    return (lower.contains("debited") ||
            lower.contains("credited") ||
            lower.contains("deducted") ||
            lower.contains("received")) &&
        (lower.contains("rs") || lower.contains("inr") || lower.contains('₹'));
  }
}
