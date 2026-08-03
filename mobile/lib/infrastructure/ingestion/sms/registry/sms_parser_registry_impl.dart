import '../../../../domain/engines/bank_sms_parser.dart';
import '../../../../domain/engines/sms_parser_registry.dart';
import '../../../../domain/ingestion/extraction_result.dart';
import '../parsers/axis_sms_parser.dart';
import '../parsers/generic_sms_parser.dart';
import '../parsers/hdfc_sms_parser.dart';
import '../parsers/icici_sms_parser.dart';
import '../parsers/kotak_sms_parser.dart';
import '../parsers/sbi_sms_parser.dart';

/// Routes incoming SMS to the correct bank parser.
///
/// Priority order: bank-specific parsers first, GenericSmsParser last.
/// The first parser whose `supports()` returns true handles the message.
/// GenericSmsParser always returns true, so it acts as the catch-all fallback.
class SmsParserRegistryImpl implements SmsParserRegistry {
  SmsParserRegistryImpl()
      : _parsers = [
          const HdfcSmsParser(),
          const SbiSmsParser(),
          const IciciSmsParser(),
          const AxisSmsParser(),
          const KotakSmsParser(),
          const GenericSmsParser(), // must be last — supports() always true
        ];

  final List<BankSmsParser> _parsers;

  static const _kVersion = 'sms-registry-v1';

  @override
  String get registryVersion => _kVersion;

  @override
  List<BankSmsParser> get parsers => List.unmodifiable(_parsers);

  @override
  List<String> get supportedBankIds => _parsers.map((p) => p.bankId).toList();

  @override
  BankSmsParser findParser(String senderAddress) {
    for (final parser in _parsers) {
      if (parser.supports(senderAddress)) return parser;
    }
    // Should never reach here — GenericSmsParser always matches
    return const GenericSmsParser();
  }

  @override
  ExtractionResult parse(String rawText, String senderAddress) {
    final parser = findParser(senderAddress);
    return parser.parse(rawText, senderAddress);
  }
}
