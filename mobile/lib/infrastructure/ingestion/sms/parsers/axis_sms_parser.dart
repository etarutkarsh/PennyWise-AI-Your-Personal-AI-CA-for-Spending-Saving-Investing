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

/// Bank-specific SMS parser for Axis Bank.
///
/// Axis SMS formats:
///   "INR 1,000.00 debited from your Axis Bank a/c XX1234 towards NETFLIX on 24-Jul-26."
///   "Your Axis Bank a/c XX1234 is debited with INR 5000.00 on 24-Jul-2026 for UPI-SWIGGY-swiggy@okicici"
///
/// Handles:
///  - "towards MERCHANT on" pattern extraction.
///  - "for UPI-MERCHANTNAME-vpa@bank" pattern extraction.
///  - VPA extraction preferred over "towards X" when both patterns fire.
class AxisSmsParser implements BankSmsParser {
  const AxisSmsParser();

  static const _kBankId = 'axis';
  static const _kParserVersion = 'axis-v1';

  static final _amountExtractor = AmountExtractor();
  static final _directionExtractor = DirectionExtractor();
  static final _merchantExtractor = MerchantExtractor();
  static final _railExtractor = RailExtractor();
  static final _dateExtractor = DateExtractor();
  static final _referenceExtractor = ReferenceExtractor();
  static final _accountExtractor = AccountExtractor();
  static final _balanceExtractor = BalanceExtractor();

  // "towards MERCHANT on date" — e.g. "towards NETFLIX on 24-Jul-26"
  static final _towardsMerchantPattern = RegExp(
    r'\btowards\s+([A-Z][A-Za-z0-9\s&.@\-]{2,40})\s+on\b',
    caseSensitive: false,
  );

  // "for UPI-MERCHANTNAME-vpa@bank" — e.g. "for UPI-SWIGGY-swiggy@okicici"
  // Group 1 = merchant name, Group 2 = VPA
  static final _forUpiPattern = RegExp(
    r'\bfor\s+UPI[- /]([^-\s]+)[- /]([^-\s@]+@[^-\s]*)',
    caseSensitive: false,
  );

  @override
  String get bankId => _kBankId;

  @override
  String get parserVersion => _kParserVersion;

  @override
  BankCapability get capability => BankCapability.axis;

  @override
  bool supports(String senderAddress) {
    final bare = _extractBareId(senderAddress);
    return BankCapability.axis.senderPrefixes.any(
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
    if (direction.isPresent) {
      builder.setDirection(direction.value!, high: direction.isHighConfidence);
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
    // ── Override 1: "for UPI-X-vpa@bank" — VPA extraction (highest priority) ─
    final upiMatch = _forUpiPattern.firstMatch(rawText);
    if (upiMatch != null) {
      final merchantName = upiMatch.group(1);
      if (merchantName != null && merchantName.isNotEmpty) {
        // Spec: 0.90 confidence for the VPA-backed merchant name
        builder.setMerchant(merchantName, high: true);
      }
      return; // VPA match wins — skip "towards" pattern
    }

    // ── Override 2: "towards MERCHANT on date" ───────────────────────────────
    // Only fires when the UPI pattern didn't fire
    if (merchant.isMissing) {
      final towardsMatch = _towardsMerchantPattern.firstMatch(rawText);
      if (towardsMatch != null) {
        final extracted = towardsMatch.group(1)?.trim();
        if (extracted != null && extracted.isNotEmpty) {
          // Spec: 0.90 — high: true gives 0.90 via builder
          builder.setMerchant(extracted, high: true);
        }
      }
    }
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
