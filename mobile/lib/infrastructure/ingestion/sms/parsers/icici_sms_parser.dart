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

/// Bank-specific SMS parser for ICICI Bank.
///
/// ICICI SMS formats:
///   "ICICI Bank Acct XX1234 debited for Rs 1,234.00 on 24-Jul-2026. Info: UPI-NETFLIX-netflix@icici"
///   "Dear Customer, Rs.1499.00 debited from a/c XX1234 for NETFLIX on 24-Jul-26. Avl Bal:Rs.10000.00"
///
/// Handles:
///  - "Info: UPI-MERCHANTNAME-vpa@bank" extraction — merchant name + VPA.
///  - "for MERCHANT on date" pattern extraction.
///  - UPI Info field preferred over generic "for X" extraction.
class IciciSmsParser implements BankSmsParser {
  const IciciSmsParser();

  static const _kBankId = 'icici';
  static const _kParserVersion = 'icici-v1';

  static final _amountExtractor = AmountExtractor();
  static final _directionExtractor = DirectionExtractor();
  static final _merchantExtractor = MerchantExtractor();
  static final _railExtractor = RailExtractor();
  static final _dateExtractor = DateExtractor();
  static final _referenceExtractor = ReferenceExtractor();
  static final _accountExtractor = AccountExtractor();
  static final _balanceExtractor = BalanceExtractor();

  // ICICI "Info: UPI-MERCHANTNAME-vpa@bank"
  // Group 1 = merchant name, Group 2 = VPA
  static final _iciciInfoPattern = RegExp(
    r'Info:\s*UPI[- /]([^-\s]+)[- /]([^-\s@]+@[^-\s]*)',
    caseSensitive: false,
  );

  // ICICI "for MERCHANT on date" — e.g. "for NETFLIX on 24-Jul-26"
  static final _forMerchantPattern = RegExp(
    r'\bfor\s+([A-Z][A-Za-z0-9\s&.]{2,30})\s+on\b',
    caseSensitive: false,
  );

  @override
  String get bankId => _kBankId;

  @override
  String get parserVersion => _kParserVersion;

  @override
  BankCapability get capability => BankCapability.icici;

  @override
  bool supports(String senderAddress) {
    final bare = _extractBareId(senderAddress);
    return BankCapability.icici.senderPrefixes.any(
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
    // ── Override 1: ICICI "Info: UPI-NAME-vpa@bank" ──────────────────────────
    // Prefer the merchant name (group 1) directly — highest confidence.
    // VPA (group 2) is also captured but merchant name is cleaner.
    final infoMatch = _iciciInfoPattern.firstMatch(rawText);
    if (infoMatch != null) {
      final merchantName = infoMatch.group(1);
      if (merchantName != null && merchantName.isNotEmpty) {
        // 0.90 confidence per spec — high: true gives 0.90 via builder
        builder.setMerchant(merchantName, high: true);
      }
      return; // Info field extraction preferred — skip "for X" pattern
    }

    // ── Override 2: ICICI "for MERCHANT on date" ─────────────────────────────
    // Only fires when Info field was not present
    if (merchant.isMissing) {
      final forMatch = _forMerchantPattern.firstMatch(rawText);
      if (forMatch != null) {
        final extracted = forMatch.group(1)?.trim();
        if (extracted != null && extracted.isNotEmpty) {
          // 0.87 confidence per spec — high: false gives 0.60, add ambiguity note
          builder.setMerchant(extracted, high: false,
              ambiguity: 'ICICI "for X on date" pattern used — verify merchant');
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
