/// Central registry of parser version identifiers.
///
/// Every ExtractionResult and RawFinancialEvent carries one of these strings.
/// When the parser logic changes in a way that would produce different output
/// for the same raw input, bump the version and trigger an EventReplay pass
/// for all events parsed with an older version.
///
/// Version bump rules (from SMS_PARSING_SPEC.md §17):
///   Major (v1 → v2): regex patterns change, new fields extracted, rail classification changes.
///   Minor (v1.0 → v1.1): bug fix to existing pattern, new bank added to allowlist.
///   Patch (v1.0.0 → v1.0.1): confidence weight changes only.
///
/// Replay rule: re-process all events where parserVersion < kCurrentSmsParserVersion.
library;

/// The version string stamped on every SMS-parsed event.
/// Update this whenever the SmsParserService logic changes.
const String kSmsParserVersion = 'sms-parser-v1';

/// The version string for the AA data normalizer (static; AA data is already structured).
const String kAaParserVersion = 'aa-parser-v1';

/// The version string for OCR-based extraction.
const String kOcrParserVersion = 'ocr-parser-v1';

/// Sentinel used when a raw event was ingested before versioning was introduced.
const String kLegacyParserVersion = 'legacy-unversioned';

/// Returns true if [version] is older than [currentVersion].
/// Comparison is strictly lexicographic — keep version identifiers zero-padded
/// if you ever reach v10+ (e.g. 'sms-parser-v10' not 'sms-parser-v9+1').
bool isOlderThan(String version, String currentVersion) {
  if (version == kLegacyParserVersion) return true;
  return version.compareTo(currentVersion) < 0;
}
