// STUB — replaced by domain contracts agent
import '../../../../domain/ingestion/field_extraction.dart';

/// Extracts the available balance from a bank SMS.
/// STUB: Minimal implementation covering the most common Indian bank balance label patterns.
class BalanceExtractor {
  const BalanceExtractor();

  static const _fieldName = 'balance';

  // Order: highest-confidence labels first
  static final _patterns = <(RegExp, String, double)>[
    (
      RegExp(r'Avl\.?\s*Bal(?:ance)?[:\s]*(?:Rs\.?|INR|₹)\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
      'avl_bal_label',
      0.95,
    ),
    (
      RegExp(r'Available\s+Balance\s+(?:is\s+)?(?:Rs\.?|INR|₹)\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
      'available_balance_label',
      0.95,
    ),
    (
      RegExp(r'Bal(?:ance)?[:\s]+(?:Rs\.?|INR|₹)\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
      'bal_label',
      0.88,
    ),
    (
      RegExp(r'(?:Rs\.?|INR|₹)\s*([\d,]+(?:\.\d{1,2})?)\s*(?:Avl|Available)', caseSensitive: false),
      'amount_before_avl',
      0.82,
    ),
  ];

  FieldExtraction<double> extract(String text) {
    for (final (pattern, ruleName, confidence) in _patterns) {
      final match = pattern.firstMatch(text);
      if (match == null) continue;

      final raw = match.group(1);
      if (raw == null) continue;

      final normalised = raw.replaceAll(',', '');
      final balance = double.tryParse(normalised);
      if (balance == null || balance < 0) continue;

      return FieldExtraction<double>(
        value: balance,
        confidence: confidence,
        decision: ParseDecision(
          fieldName: _fieldName,
          type: ParseDecisionType.regexMatch,
          ruleApplied: ruleName,
          reason: '$ruleName matched, balance=${balance.toStringAsFixed(2)}',
          confidence: confidence,
          regexMatched: pattern.pattern,
          rawExtracted: raw,
        ),
      );
    }

    return FieldExtraction<double>.missing(_fieldName);
  }
}
