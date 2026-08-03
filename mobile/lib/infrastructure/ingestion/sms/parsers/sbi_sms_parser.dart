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

/// Bank-specific SMS parser for State Bank of India (SBI).
///
/// SBI SMS format:
///   "Your a/c no XXXXX1234 is debited Rs.5000.00 on 24.07.26 by UPI-PHONEPE-9876543210-YESB"
///
/// Handles:
///  - "by X" merchant extraction with trailing bank suffix stripping.
///  - SBI dot-separated date format (DD.MM.YY / DD.MM.YYYY).
class SbiSmsParser implements BankSmsParser {
  const SbiSmsParser();

  static const _kBankId = 'sbi';
  static const _kParserVersion = 'sbi-v1';

  static final _amountExtractor = AmountExtractor();
  static final _directionExtractor = DirectionExtractor();
  static final _merchantExtractor = MerchantExtractor();
  static final _railExtractor = RailExtractor();
  static final _dateExtractor = DateExtractor();
  static final _referenceExtractor = ReferenceExtractor();
  static final _accountExtractor = AccountExtractor();
  static final _balanceExtractor = BalanceExtractor();

  // SBI "by X" merchant pattern — e.g. "by UPI-PHONEPE-9876543210-YESB"
  static final _byMerchantPattern = RegExp(
    r'\bby\s+([A-Z][A-Za-z0-9._@\-]{2,40})',
    caseSensitive: false,
  );

  // Trailing bank suffix patterns to strip from SBI merchant strings
  // e.g. "-YESB", "-HDFC", "-ICIC", "-UTIB"
  static final _bankSuffixPattern = RegExp(
    r'-[A-Z]{4,6}$',
    caseSensitive: false,
  );

  // SBI dot-date: DD.MM.YY or DD.MM.YYYY
  static final _sbiDotDatePattern = RegExp(
    r'(\d{1,2})\.(\d{1,2})\.(\d{2,4})',
  );

  @override
  String get bankId => _kBankId;

  @override
  String get parserVersion => _kParserVersion;

  @override
  BankCapability get capability => BankCapability.sbi;

  @override
  bool supports(String senderAddress) {
    final bare = _extractBareId(senderAddress);
    return BankCapability.sbi.senderPrefixes.any(
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

    _applyBankSpecificOverrides(rawText, builder, amount, direction, merchant, rail, date);

    return builder.build();
  }

  void _applyBankSpecificOverrides(
    String rawText,
    ExtractionResultBuilder builder,
    FieldExtraction<double> amount,
    FieldExtraction<String> direction,
    FieldExtraction<String> merchant,
    FieldExtraction<PaymentRail> rail,
    FieldExtraction<DateTime> date,
  ) {
    // ── Override 1: SBI "by X" merchant extraction ───────────────────────────
    if (merchant.isMissing) {
      final byMatch = _byMerchantPattern.firstMatch(rawText);
      if (byMatch != null) {
        var extracted = byMatch.group(1) ?? '';
        // Strip trailing bank IFSC suffix (e.g. -YESB, -HDFC, -ICIC)
        extracted = extracted.replaceAll(_bankSuffixPattern, '').trim();
        if (extracted.length >= 3) {
          builder.setMerchant(extracted, high: false);
        }
      }
    }

    // ── Override 2: SBI dot-date fallback ────────────────────────────────────
    // DateExtractor handles DD-MM-YYYY and DD Mon YYYY but may miss DD.MM.YY
    // because the generic _dmyPattern uses [-/] separator.
    // When date extractor returned missing, try the SBI dot format.
    if (date.isMissing) {
      final dotMatch = _sbiDotDatePattern.firstMatch(rawText);
      if (dotMatch != null) {
        final day = int.tryParse(dotMatch.group(1)!);
        final month = int.tryParse(dotMatch.group(2)!);
        var yearRaw = int.tryParse(dotMatch.group(3)!);
        if (day != null && month != null && yearRaw != null) {
          if (yearRaw < 100) yearRaw += 2000;
          if (day >= 1 && day <= 31 && month >= 1 && month <= 12 && yearRaw >= 1900) {
            builder.setDate(DateTime(yearRaw, month, day), high: false,
                ambiguity: 'SBI dot-date fallback parser used');
          }
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
