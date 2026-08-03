import '../../../../domain/engines/bank_sms_parser.dart';
import '../../../../domain/ingestion/bank_capability.dart';
import '../../../../domain/ingestion/extraction_result.dart';
import '../extractors/account_extractor.dart';
import '../extractors/amount_extractor.dart';
import '../extractors/balance_extractor.dart';
import '../extractors/date_extractor.dart';
import '../extractors/direction_extractor.dart';
import '../extractors/merchant_extractor.dart';
import '../extractors/rail_extractor.dart';
import '../extractors/reference_extractor.dart';

/// Fallback SMS parser for any sender not claimed by a bank-specific parser.
///
/// The generic parser:
///  - Always returns true from [supports] — it is the last resort in the registry.
///  - Only attempts extraction if [isFinancialSms] returns true; otherwise rejects.
///  - Applies no bank-specific overrides; all fields come directly from extractors.
class GenericSmsParser implements BankSmsParser {
  const GenericSmsParser();

  static const _kBankId = 'generic';
  static const _kParserVersion = 'generic-v1';

  static final _amountExtractor = AmountExtractor();
  static final _directionExtractor = DirectionExtractor();
  static final _merchantExtractor = MerchantExtractor();
  static final _railExtractor = RailExtractor();
  static final _dateExtractor = DateExtractor();
  static final _referenceExtractor = ReferenceExtractor();
  static final _accountExtractor = AccountExtractor();
  static final _balanceExtractor = BalanceExtractor();

  // Generic capability — covers the broadest set of SMS types.
  static const _kCapability = BankCapability(
    bankId: _kBankId,
    displayName: 'Generic / Unknown Bank',
    capabilities: {
      BankSmsCapability.debitAlert,
      BankSmsCapability.creditAlert,
      BankSmsCapability.upiDebit,
      BankSmsCapability.upiCredit,
      BankSmsCapability.cardSwipe,
      BankSmsCapability.cardOnline,
      BankSmsCapability.atmWithdrawal,
      BankSmsCapability.nachDebit,
      BankSmsCapability.ecsDebit,
      BankSmsCapability.upiAutopay,
      BankSmsCapability.availableBalance,
      BankSmsCapability.salaryCredit,
      BankSmsCapability.loanEmi,
      BankSmsCapability.reversalCredit,
    },
    senderPrefixes: [], // Generic matches all — no prefix filter
    note: 'Fallback parser — no bank-specific overrides applied',
  );

  @override
  String get bankId => _kBankId;

  @override
  String get parserVersion => _kParserVersion;

  @override
  BankCapability get capability => _kCapability;

  /// Generic parser is the fallback — it supports any sender address.
  @override
  bool supports(String senderAddress) => true;

  @override
  ExtractionResult parse(String rawText, String senderAddress) {
    // Reject non-financial SMS upfront
    if (!isFinancialSms(rawText)) {
      return (ExtractionResultBuilder(parserVersion: parserVersion, rawText: rawText)
            ..reject('SMS does not contain financial keywords'))
          .build();
    }

    // Pre-debit check before extraction
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

    return builder.build();
  }

  @override
  bool isPreDebitAlert(String rawText) {
    final lower = rawText.toLowerCase();
    return lower.contains('will be debited') ||
        lower.contains('mandate of') ||
        (lower.contains('due on') && lower.contains('mandate'));
  }

  @override
  bool isFinancialSms(String rawText) {
    final lower = rawText.toLowerCase();
    return (lower.contains('debited') ||
            lower.contains('credited') ||
            lower.contains('deducted') ||
            lower.contains('received')) &&
        (lower.contains('rs') || lower.contains('inr') || lower.contains('₹'));
  }
}
