import '../ingestion/extraction_result.dart';
import 'bank_sms_parser.dart';

/// Registry that routes raw SMS messages to the correct [BankSmsParser].
///
/// Parsers are registered in priority order: bank-specific parsers first,
/// the generic fallback parser last. Implementations live in
/// `infrastructure/sms/`.
abstract class SmsParserRegistry {
  /// Semantic version of this registry configuration, e.g. 'registry-v1'.
  String get registryVersion;

  /// All registered parsers in routing priority order.
  /// Bank-specific parsers appear before the generic fallback.
  List<BankSmsParser> get parsers;

  /// Find the best parser for the given TRAI sender address.
  ///
  /// Iterates [parsers] in order and returns the first parser whose
  /// [BankSmsParser.supports] returns true. Falls back to the generic
  /// parser if no bank-specific parser claims the sender.
  BankSmsParser findParser(String senderAddress);

  /// Parse a raw SMS into an [ExtractionResult], routing to the appropriate
  /// parser automatically.
  ///
  /// Equivalent to: `findParser(senderAddress).parse(rawText, senderAddress)`.
  ExtractionResult parse(String rawText, String senderAddress);

  /// Bank IDs for every registered parser, in registration order.
  List<String> get supportedBankIds => parsers.map((p) => p.bankId).toList();
}
