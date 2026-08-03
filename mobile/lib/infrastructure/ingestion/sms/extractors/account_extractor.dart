import '../../../../domain/ingestion/field_extraction.dart';

/// Extracts the last 4 digits of the account or card number from a bank SMS.
///
/// Bank SMS messages mask account numbers as: a/c **1234, card **1234, XXXX1234.
class AccountExtractor {
  const AccountExtractor();

  static const _fieldName = 'account';

  static final _patterns = <(RegExp, String, double)>[
    (
      RegExp(
        r'(?:a/c|acct|account|ac)\s*[*xX]+\s*(\d{4})\b',
        caseSensitive: false,
      ),
      'masked_account',
      0.95,
    ),
    (
      RegExp(r'card\s*[*xX]+\s*(\d{4})\b', caseSensitive: false),
      'masked_card',
      0.92,
    ),
    (
      RegExp(r'\b[xX*]+(\d{4})\b', caseSensitive: false),
      'generic_masked',
      0.80,
    ),
    (
      RegExp(r'no\.?\s*[xX*]+(\d{4})\b', caseSensitive: false),
      'account_no_format',
      0.85,
    ),
  ];

  FieldExtraction<String> extract(String text) {
    for (final (pattern, ruleName, confidence) in _patterns) {
      final match = pattern.firstMatch(text);
      if (match == null) continue;

      final raw = match.group(1);
      if (raw == null) continue;

      // Validate: exactly 4 digits
      if (raw.length != 4 || !RegExp(r'^\d{4}$').hasMatch(raw)) continue;

      return FieldExtraction<String>(
        value: raw,
        confidence: confidence,
        decision: ParseDecision(
          fieldName: _fieldName,
          type: ParseDecisionType.regexMatch,
          ruleApplied: ruleName,
          reason: '$ruleName matched, last4="$raw"',
          confidence: confidence,
          regexMatched: pattern.pattern,
          rawExtracted: raw,
        ),
      );
    }

    return FieldExtraction<String>.missing(_fieldName);
  }
}
