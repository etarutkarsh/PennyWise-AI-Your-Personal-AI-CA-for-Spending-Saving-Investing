import 'package:flutter/foundation.dart';
import '../ingestion/extraction_result.dart';

/// The outcome of validating an [ExtractionResult] before it enters the
/// normalisation pipeline.
///
/// [SmsValidationEngine.validate] produces one of these for every parsed SMS.
@immutable
class SmsValidationResult {
  const SmsValidationResult({
    required this.isUsable,
    required this.isTrustedSender,
    required this.isPreDebitAlert,
    required this.failureReasons,
    this.suggestedTier,
  });

  /// True when the extraction is safe to pass to [TransactionNormalizer].
  final bool isUsable;

  /// True when the sender address is in the known bank / financial institution
  /// allowlist (does not imply the extraction itself is usable).
  final bool isTrustedSender;

  /// True when the SMS is an RBI pre-debit mandate notification — not a
  /// completed transaction and must never be ingested.
  final bool isPreDebitAlert;

  /// Human-readable reasons why this extraction was rejected or downgraded.
  final List<String> failureReasons;

  /// If set, the validator wants to override the parser's tier assignment
  /// (e.g. downgrade a medium-confidence result to review).
  final ExtractionTier? suggestedTier;

  bool get hasFailures => failureReasons.isNotEmpty;

  /// Convenience factory: validation passed with no failures.
  factory SmsValidationResult.passed({required bool isTrustedSender}) =>
      SmsValidationResult(
        isUsable: true,
        isTrustedSender: isTrustedSender,
        isPreDebitAlert: false,
        failureReasons: const [],
      );

  /// Convenience factory: validation failed for one or more reasons.
  factory SmsValidationResult.rejected(List<String> reasons) =>
      SmsValidationResult(
        isUsable: false,
        isTrustedSender: false,
        isPreDebitAlert: false,
        failureReasons: reasons,
      );

  /// Convenience factory: the SMS is an RBI pre-debit alert.
  factory SmsValidationResult.preDebitAlert() => SmsValidationResult(
        isUsable: false,
        isTrustedSender: true,
        isPreDebitAlert: true,
        failureReasons: const [
          'Pre-debit RBI mandate alert — not a transaction',
        ],
      );
}

/// Abstract contract for validating an [ExtractionResult] before normalisation.
///
/// Called after [BankSmsParser.parse] and before [TransactionNormalizer].
/// Implementations live in `infrastructure/sms/`.
abstract class SmsValidationEngine {
  /// Validate an [ExtractionResult].
  ///
  /// [senderAddress] is provided so trust checks can be performed independently
  /// of the extraction result (e.g. a rejected extraction from a trusted sender
  /// is handled differently from an unknown sender).
  SmsValidationResult validate(ExtractionResult result, String senderAddress);

  /// Returns true if [senderAddress] belongs to a known bank or financial
  /// institution in the SMS allowlist.
  bool isTrustedSender(String senderAddress);
}
