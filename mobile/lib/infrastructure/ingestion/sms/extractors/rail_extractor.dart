import '../../../../domain/ingestion/field_extraction.dart';
import '../../../../domain/ingestion/payment_rail.dart';

/// Detects the payment rail from a bank SMS using priority-ordered pattern matching.
///
/// Order matters — first match wins. NACH/ECS DR patterns are checked before
/// generic UPI to avoid misclassifying NACH messages.
class RailExtractor {
  const RailExtractor();

  static const _fieldName = 'rail';

  // Each entry: (pattern, rail, ruleName, confidence)
  // ORDER IS CRITICAL — do not reorder.
  static final _rules = <(RegExp, PaymentRail, String, double)>[
    (
      RegExp(r'NACH\s+DR|NACH/|\bNACH\b.*\bDR\b', caseSensitive: false),
      PaymentRail.nach,
      'nach_dr',
      0.99,
    ),
    (
      RegExp(r'ECS\s+DR|\bECS\b.*\bDR\b', caseSensitive: false),
      PaymentRail.ecs,
      'ecs_dr',
      0.99,
    ),
    (
      RegExp(
        r'UPI[-/\s]AUTOPAY|UPI\s+AUTO\s*PAY|AUTOPAY',
        caseSensitive: false,
      ),
      PaymentRail.upiAutopay,
      'upi_autopay',
      0.97,
    ),
    (
      RegExp(
        r'STANDING\s+INST|STANDING\s+INSTRUCTION|\bSI\s+\d',
        caseSensitive: false,
      ),
      PaymentRail.standingInstruction,
      'standing_instruction',
      0.95,
    ),
    (
      RegExp(r'\bNEFT\b', caseSensitive: false),
      PaymentRail.neft,
      'neft',
      0.99,
    ),
    (
      RegExp(r'\bIMPS\b', caseSensitive: false),
      PaymentRail.imps,
      'imps',
      0.99,
    ),
    (
      RegExp(r'\bRTGS\b', caseSensitive: false),
      PaymentRail.rtgs,
      'rtgs',
      0.99,
    ),
    (
      RegExp(
        r'ATM\s+WDL|ATM\s+CASH|CASH\s+WITHDRAWAL|\bATM\b',
        caseSensitive: false,
      ),
      PaymentRail.atm,
      'atm',
      0.97,
    ),
    (
      RegExp(r'\bPOS\b|CARD\s+SWIPE|DEBIT\s+CARD', caseSensitive: false),
      PaymentRail.cardSwipe,
      'pos_card_swipe',
      0.90,
    ),
    (
      RegExp(r'\bUPI\b|@[a-z]', caseSensitive: false),
      PaymentRail.upi,
      'upi',
      0.95,
    ),
    (
      RegExp(
        r'CREDIT\s+CARD|CARD\s+ONLINE|CARD.*PURCHASE',
        caseSensitive: false,
      ),
      PaymentRail.cardOnline,
      'card_online',
      0.88,
    ),
    (
      RegExp(r'PAYTM\s+WALLET|MOBIKWIK|\bWALLET\b', caseSensitive: false),
      PaymentRail.wallet,
      'wallet',
      0.88,
    ),
  ];

  FieldExtraction<PaymentRail> extract(String text) {
    for (final (pattern, rail, ruleName, confidence) in _rules) {
      if (pattern.hasMatch(text)) {
        return FieldExtraction<PaymentRail>(
          value: rail,
          confidence: confidence,
          decision: ParseDecision(
            fieldName: _fieldName,
            type: ParseDecisionType.regexMatch,
            ruleApplied: ruleName,
            reason: '$ruleName pattern matched → ${rail.label}',
            confidence: confidence,
            regexMatched: pattern.pattern,
          ),
        );
      }
    }

    return const FieldExtraction<PaymentRail>(
      value: PaymentRail.unknown,
      confidence: 0.0,
      decision: ParseDecision(
        fieldName: _fieldName,
        type: ParseDecisionType.missing,
        ruleApplied: 'none',
        reason: 'No rail pattern matched',
        confidence: 0.0,
      ),
    );
  }
}
