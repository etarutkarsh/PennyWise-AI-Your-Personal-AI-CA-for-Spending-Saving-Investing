import '../../../../domain/ingestion/field_extraction.dart';

/// Extracts the raw merchant name from a bank SMS before resolver processing.
///
/// Returns the best candidate merchant string; downstream MerchantResolver
/// maps it to a canonical [MerchantProfile].
class MerchantExtractor {
  const MerchantExtractor();

  static const _fieldName = 'merchant';

  static const _stopwords = [' on', ' via', ' ref', ' avl', ' info'];

  // Generic noise names that should not be returned as a merchant
  static const _genericNames = {'account', 'a/c', 'balance', 'unknown'};

  static final _patterns = <(RegExp, String, double)>[
    (
      RegExp(
        r'(?:at|to merchant)\s+([A-Z][A-Za-z0-9&.\-\s]{2,40})(?:\s+on\b|\s+Avl|\s+Info|[.,]|$)',
        caseSensitive: false,
      ),
      'at_merchant',
      0.90,
    ),
    (
      RegExp(
        r'(?:to|from)\s+([A-Z][A-Za-z0-9&.\-\s]{2,35})(?:\s+on\b|\s+via\b|\s+Ref\b|\s+\d|[.,]|$)',
        caseSensitive: false,
      ),
      'to_from_name',
      0.85,
    ),
    (
      RegExp(r'UPI[- /]([A-Za-z0-9@._\-]{3,50})', caseSensitive: false),
      'upi_vpa',
      0.88,
    ),
    (
      RegExp(
        r'(?:trf\s+to|transfer\s+to)\s+([A-Za-z0-9\s]{3,30})',
        caseSensitive: false,
      ),
      'trf_to',
      0.75,
    ),
    (
      RegExp(r'Info:\s*UPI[- /]([A-Za-z0-9@._\-]{3,50})', caseSensitive: false),
      'hdfc_info_upi',
      0.88,
    ),
    (
      RegExp(
        r'(?:NACH DR|ECS DR)\s+[\d.]+\s+(\S+)',
        caseSensitive: false,
      ),
      'nach_ecs_merchant',
      0.82,
    ),
  ];

  FieldExtraction<String> extract(String text) {
    for (final (pattern, ruleName, confidence) in _patterns) {
      final match = pattern.firstMatch(text);
      if (match == null) continue;

      final raw = match.group(1);
      if (raw == null) continue;

      var cleaned = _postProcess(raw);
      if (cleaned.isEmpty) continue;

      final lower = cleaned.toLowerCase();
      if (_genericNames.contains(lower)) continue;

      final ambiguity = cleaned.length < 4
          ? ' Merchant name very short — may be truncated'
          : '';

      return FieldExtraction<String>(
        value: cleaned,
        confidence: confidence,
        decision: ParseDecision(
          fieldName: _fieldName,
          type: ParseDecisionType.regexMatch,
          ruleApplied: ruleName,
          reason: '$ruleName matched, merchant="$cleaned"$ambiguity',
          confidence: confidence,
          regexMatched: pattern.pattern,
          rawExtracted: raw,
        ),
      );
    }

    return FieldExtraction<String>.missing(_fieldName);
  }

  String _postProcess(String raw) {
    var result = raw.trim();

    // Strip trailing stopwords (case-insensitive)
    for (final stopword in _stopwords) {
      if (result.toLowerCase().endsWith(stopword)) {
        result = result.substring(0, result.length - stopword.length).trim();
      }
    }

    // Strip trailing punctuation
    result = result.replaceAll(RegExp(r'[.,;:\-]+$'), '').trim();

    // Apply title case
    if (result.isNotEmpty) {
      result = result
          .split(RegExp(r'\s+'))
          .map((word) => word.isEmpty
              ? word
              : word[0].toUpperCase() + word.substring(1).toLowerCase())
          .join(' ');
    }

    return result;
  }
}
