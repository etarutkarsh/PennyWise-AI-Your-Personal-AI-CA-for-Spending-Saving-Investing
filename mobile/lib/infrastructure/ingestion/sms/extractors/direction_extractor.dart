import '../../../../domain/ingestion/field_extraction.dart';

/// Extracts transaction direction (DEBIT / CREDIT) from a bank SMS.
///
/// DEBIT signals take priority over CREDIT signals when both are present.
class DirectionExtractor {
  const DirectionExtractor();

  static const _fieldName = 'direction';

  // Each entry: (pattern, ruleName, confidence)
  static final _debitPatterns = <(RegExp, String, double)>[
    (RegExp(r'\bNACH\s+DR\b|\bECS\s+DR\b', caseSensitive: false), 'nach_ecs_dr', 0.99),
    (RegExp(r'\bdebited\b', caseSensitive: false), 'debited', 0.97),
    (RegExp(r'\bdeducted\b', caseSensitive: false), 'deducted', 0.95),
    (RegExp(r'\bpayment\s+of\b|\bpaid\s+to\b', caseSensitive: false), 'payment_of_paid_to', 0.92),
    (RegExp(r'\bwithdrawn\b|\bcash\s+withdrawal\b', caseSensitive: false), 'withdrawn', 0.95),
    (RegExp(r'\bpurchase\b|\bspent\b', caseSensitive: false), 'purchase_spent', 0.88),
    (RegExp(r'\bsent\s+to\b|\btransferred\s+to\b', caseSensitive: false), 'sent_transferred_to', 0.88),
    (RegExp(r'/Dr\b', caseSensitive: false), 'slash_dr', 0.85),
    // 'debit' standalone — but not when it's part of 'credit card debit' handled via DEBIT priority
    (RegExp(r'\bdebit\b', caseSensitive: false), 'debit_standalone', 0.85),
  ];

  static final _creditPatterns = <(RegExp, String, double)>[
    (RegExp(r'\bcredited\b', caseSensitive: false), 'credited', 0.97),
    (RegExp(r'\breceived\b', caseSensitive: false), 'received', 0.90),
    (RegExp(r'\bdeposited\b', caseSensitive: false), 'deposited', 0.90),
    (RegExp(r'\bsalary\b', caseSensitive: false), 'salary', 0.95),
    (RegExp(r'\brefund\b', caseSensitive: false), 'refund', 0.90),
    (RegExp(r'/Cr\b', caseSensitive: false), 'slash_cr', 0.85),
    (RegExp(r'\btransfer\s+credit\b', caseSensitive: false), 'transfer_credit', 0.88),
    (RegExp(r'\bcredit\b', caseSensitive: false), 'credit_standalone', 0.80),
  ];

  FieldExtraction<String> extract(String text) {
    (String rule, double conf)? debitHit;
    (String rule, double conf)? creditHit;

    for (final (pattern, ruleName, confidence) in _debitPatterns) {
      if (pattern.hasMatch(text)) {
        debitHit = (ruleName, confidence);
        break; // highest-priority DEBIT match wins
      }
    }

    for (final (pattern, ruleName, confidence) in _creditPatterns) {
      if (pattern.hasMatch(text)) {
        creditHit = (ruleName, confidence);
        break; // highest-priority CREDIT match wins
      }
    }

    if (debitHit != null) {
      final ambiguity = creditHit != null
          ? ' Both debit and credit signals found — DEBIT wins'
          : '';
      final (ruleName, confidence) = debitHit;
      return FieldExtraction<String>(
        value: 'DEBIT',
        confidence: confidence,
        decision: ParseDecision(
          fieldName: _fieldName,
          type: ParseDecisionType.keywordMatch,
          ruleApplied: ruleName,
          reason: '$ruleName matched → DEBIT$ambiguity',
          confidence: confidence,
        ),
      );
    }

    if (creditHit != null) {
      final (ruleName, confidence) = creditHit;
      return FieldExtraction<String>(
        value: 'CREDIT',
        confidence: confidence,
        decision: ParseDecision(
          fieldName: _fieldName,
          type: ParseDecisionType.keywordMatch,
          ruleApplied: ruleName,
          reason: '$ruleName matched → CREDIT',
          confidence: confidence,
        ),
      );
    }

    return FieldExtraction<String>.missing(_fieldName);
  }
}
