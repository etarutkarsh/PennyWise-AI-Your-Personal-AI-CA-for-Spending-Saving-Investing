import '../../../../domain/ingestion/field_extraction.dart';

/// Extracts the transaction reference number (Ref No, UTR, TXN ID) from a bank SMS.
class ReferenceExtractor {
  const ReferenceExtractor();

  static const _fieldName = 'refId';

  static final _patterns = <(RegExp, String, double)>[
    (
      RegExp(r'Ref\s*No\.?\s*[:\-]?\s*(\d{8,20})', caseSensitive: false),
      'ref_no',
      0.92,
    ),
    (
      RegExp(r'UPI\s*Ref\s*[:\-]?\s*(\d{8,20})', caseSensitive: false),
      'upi_ref',
      0.95,
    ),
    (
      RegExp(r'IMPS\s*Ref\s*[:\-]?\s*(\d{8,20})', caseSensitive: false),
      'imps_ref',
      0.95,
    ),
    (
      RegExp(r'UTR\s*[:\-]?\s*(\w{8,22})', caseSensitive: false),
      'utr',
      0.92,
    ),
    (
      RegExp(r'TXN\s*ID\s*[:\-]?\s*(\w{8,20})', caseSensitive: false),
      'txn_id',
      0.88,
    ),
    (
      RegExp(r'Transaction\s*ID\s*[:\-]?\s*(\w{8,20})', caseSensitive: false),
      'transaction_id',
      0.88,
    ),
    (
      RegExp(r'(\d{12,20})'),
      'bare_number',
      0.65,
    ),
  ];

  FieldExtraction<String> extract(String text) {
    for (final (pattern, ruleName, confidence) in _patterns) {
      final match = pattern.firstMatch(text);
      if (match == null) continue;

      final raw = match.group(1);
      if (raw == null || raw.isEmpty) continue;

      final ambiguity = ruleName == 'bare_number'
          ? ' Reference extracted as bare number — may not be a ref ID'
          : '';

      return FieldExtraction<String>(
        value: raw,
        confidence: confidence,
        decision: ParseDecision(
          fieldName: _fieldName,
          type: ParseDecisionType.regexMatch,
          ruleApplied: ruleName,
          reason: '$ruleName matched, ref="$raw"$ambiguity',
          confidence: confidence,
          regexMatched: pattern.pattern,
          rawExtracted: raw,
        ),
      );
    }

    return FieldExtraction<String>.missing(_fieldName);
  }
}
