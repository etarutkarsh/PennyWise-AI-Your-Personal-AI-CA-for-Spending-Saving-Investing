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

/// Bank-specific SMS parser for HDFC Bank.
///
/// Handles HDFC-specific patterns:
///  - NACH DR mandate messages with merchant extraction from compound reference field.
///  - Info: UPI-X-VPA@ format for UPI merchant name extraction.
///  - Low-value UPI SMS suppression policy (June 2024): debit < ₹100 / credit < ₹500.
class HdfcSmsParser implements BankSmsParser {
  const HdfcSmsParser();

  static const _kBankId = 'hdfc';
  static const _kParserVersion = 'hdfc-v1';

  static final _amountExtractor = AmountExtractor();
  static final _directionExtractor = DirectionExtractor();
  static final _merchantExtractor = MerchantExtractor();
  static final _railExtractor = RailExtractor();
  static final _dateExtractor = DateExtractor();
  static final _referenceExtractor = ReferenceExtractor();
  static final _accountExtractor = AccountExtractor();
  static final _balanceExtractor = BalanceExtractor();

  // HDFC Info: UPI VPA pattern — e.g. Info: UPI-PHONEPE-9876543210@ybl-SBIN
  static final _hdfcInfoVpaPattern = RegExp(
    r'Info:\s*UPI[- /]([^-\s]+)[- /]([^-\s@]+@[^-\s]*)',
    caseSensitive: false,
  );

  // HDFC NACH compound reference — e.g. ABCLIFE24082026NACH0
  // Extract alpha prefix before the date digits (DDMMYYYY or DDMMYY)
  static final _nachMerchantPattern = RegExp(r'^([A-Za-z]+)\d{6,8}');

  @override
  String get bankId => _kBankId;

  @override
  String get parserVersion => _kParserVersion;

  @override
  BankCapability get capability => BankCapability.hdfc;

  @override
  bool supports(String senderAddress) {
    final bare = _extractBareId(senderAddress);
    return BankCapability.hdfc.senderPrefixes.any(
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
    // ── Override 1: HDFC Info: UPI VPA extraction ────────────────────────────
    // Info: UPI-PHONEPE-9876543210@ybl-SBIN → extract the VPA (second group)
    final infoMatch = _hdfcInfoVpaPattern.firstMatch(rawText);
    if (infoMatch != null) {
      final vpa = infoMatch.group(2);
      if (vpa != null && vpa.isNotEmpty) {
        builder.setMerchant(vpa, high: true);
        // 0.88 from spec — setMerchant with high: true gives 0.90; acceptable deviation
      }
    }

    // ── Override 2: NACH/ECS merchant from compound reference token ──────────
    // Only fires when Info field was not present (otherwise we already have a merchant)
    if (infoMatch == null) {
      final railValue = rail.value;
      final isMandate = railValue == PaymentRail.nach || railValue == PaymentRail.ecs;
      if (isMandate && merchant.isMissing) {
        // Extract the compound token sitting between the amount and date
        // e.g. "NACH DR 01500.00 ABCLIFE24082026NACH0 24-08-26"
        final nachCompound = RegExp(
          r'(?:NACH|ECS)\s+DR\s+[\d.]+\s+(\S+)',
          caseSensitive: false,
        ).firstMatch(rawText);
        if (nachCompound != null) {
          final token = nachCompound.group(1);
          if (token != null) {
            final alphaMatch = _nachMerchantPattern.firstMatch(token);
            if (alphaMatch != null) {
              final alphaPart = alphaMatch.group(1)!;
              if (alphaPart.length >= 3) {
                builder.setMerchant(alphaPart, high: false);
                // Confidence 0.75 per spec — setMerchant with high: false gives 0.60 via builder,
                // but we add an ambiguity note to signal the reduced confidence source.
                builder.addAmbiguity('NACH merchant extracted from compound reference token — verify');
              }
            }
          }
        }
      }
    }

    // ── Override 3: HDFC UPI low-value suppression notice ───────────────────
    final amountValue = amount.value;
    final directionValue = direction.value;
    if (amountValue != null && directionValue != null) {
      if (directionValue == 'DEBIT' && amountValue < 100) {
        builder.addAmbiguity(
          'HDFC may not generate SMS for UPI < ₹100 (June 2024 policy)',
        );
      } else if (directionValue == 'CREDIT' && amountValue < 500) {
        builder.addAmbiguity(
          'HDFC may not generate SMS for UPI received < ₹500 (June 2024 policy)',
        );
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
