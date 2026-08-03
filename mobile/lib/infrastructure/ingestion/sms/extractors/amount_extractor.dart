import '../../../../domain/ingestion/field_extraction.dart';

/// Extracts the transaction amount from a bank SMS.
///
/// Supports Indian currency formats: ₹1,234.56 / Rs.1,234.56 / Rs 1,50,000 / INR 1234.56.
/// Handles the Indian number system (lakhs): 1,50,000 → 150000.
class AmountExtractor {
  const AmountExtractor();

  static const _fieldName = 'amount';

  static const _maxReasonableAmount = 10000000.0; // ₹1 crore

  // Pattern → (ruleName, confidence)
  static final _patterns = <(RegExp, String, double)>[
    (
      RegExp(r'₹\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
      'rupee_symbol',
      0.95,
    ),
    (
      RegExp(r'Rs\.?\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
      'rs_prefix',
      0.92,
    ),
    (
      RegExp(r'INR\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
      'inr_prefix',
      0.92,
    ),
    (
      RegExp(
        r'([\d,]+(?:\.\d{1,2})?)\s*(?:Rs\.?|INR|₹)',
        caseSensitive: false,
      ),
      'trailing_currency',
      0.80,
    ),
  ];

  FieldExtraction<double> extract(String text) {
    for (final (pattern, ruleName, baseConfidence) in _patterns) {
      final match = pattern.firstMatch(text);
      if (match == null) continue;

      final raw = match.group(1);
      if (raw == null) continue;

      final normalised = raw.replaceAll(',', '');
      final amount = double.tryParse(normalised);
      if (amount == null || amount <= 0) continue;

      if (amount >= _maxReasonableAmount) {
        // Likely a parse error — skip this pattern and try the next
        continue;
      }

      final ambiguityNote = amount > 100000
          ? ' Amount unusually large — verify'
          : '';

      return FieldExtraction<double>(
        value: amount,
        confidence: baseConfidence,
        decision: ParseDecision(
          fieldName: _fieldName,
          type: ParseDecisionType.regexMatch,
          ruleApplied: ruleName,
          reason:
              '$ruleName matched, amount=${amount.toStringAsFixed(2)}$ambiguityNote',
          confidence: baseConfidence,
          regexMatched: pattern.pattern,
          rawExtracted: raw,
        ),
      );
    }

    return FieldExtraction<double>.missing(_fieldName);
  }
}
