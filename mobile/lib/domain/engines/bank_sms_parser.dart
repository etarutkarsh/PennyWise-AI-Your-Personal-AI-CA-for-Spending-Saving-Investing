import '../ingestion/bank_capability.dart';
import '../ingestion/extraction_result.dart';

/// Abstract contract for a bank-specific SMS parser.
///
/// Implementations live in `infrastructure/sms/` and must never import Flutter
/// widgets or platform plugins — only pure Dart logic.
///
/// The registry ([SmsParserRegistry]) routes each incoming SMS to the correct
/// parser by calling [supports] on each registered parser in priority order.
abstract class BankSmsParser {
  /// Short identifier matching [BankCapability.bankId], plus 'generic'.
  /// E.g. 'hdfc', 'sbi', 'icici', 'axis', 'kotak', 'generic'.
  String get bankId;

  /// Semantic version of this parser's rule set, e.g. 'hdfc-v1', 'sbi-v1'.
  /// Stored on [ExtractionResult.parserVersion] to enable event replay when
  /// rules change.
  String get parserVersion;

  /// Capability profile for this bank — used by callers to pre-check whether
  /// a specific alert type (e.g. SIP deduction) could appear in this bank's SMS.
  BankCapability get capability;

  /// Returns true if this parser handles the given TRAI sender address.
  ///
  /// Sender format follows TRAI 2025: [XX]-[BAREID] or [XX]-[BAREID]-S
  /// Examples: 'VK-HDFCBK', 'VD-HDFCBK-S', 'AM-SBIBNK'.
  bool supports(String senderAddress);

  /// Parse a raw SMS body into an [ExtractionResult].
  ///
  /// [senderAddress] is provided for context — some banks embed account
  /// suffix information in the sender ID.
  ExtractionResult parse(String rawText, String senderAddress);

  /// Returns true if the SMS body is a pre-debit RBI mandate notification.
  ///
  /// Pre-debit alerts MUST NEVER be ingested as transactions. They are
  /// advance warnings that a mandate will execute in the future.
  bool isPreDebitAlert(String rawText) {
    final lower = rawText.toLowerCase();
    return lower.contains('will be debited') ||
        lower.contains('mandate of') ||
        (lower.contains('due on') && lower.contains('mandate'));
  }

  /// Returns true if this SMS body looks like a financial SMS even when no
  /// bank-specific parser claims the sender address.
  ///
  /// Used by the generic fallback parser to decide whether to attempt
  /// extraction or reject the message entirely.
  bool isFinancialSms(String rawText) {
    final lower = rawText.toLowerCase();
    return (lower.contains('debited') ||
            lower.contains('credited') ||
            lower.contains('deducted') ||
            lower.contains('received')) &&
        (lower.contains('rs') || lower.contains('inr') || lower.contains('₹'));
  }
}
