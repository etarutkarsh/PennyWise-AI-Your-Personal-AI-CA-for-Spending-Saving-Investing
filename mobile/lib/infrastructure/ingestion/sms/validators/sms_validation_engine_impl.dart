import '../../../../domain/engines/sms_validation_engine.dart';
import '../../../../domain/ingestion/extraction_result.dart';

/// Validates an ExtractionResult before it enters the TransactionNormalizer.
///
/// Checks:
///   1. Trusted sender (TRAI allowlist)
///   2. Pre-debit alert filter (never ingest RBI mandate notifications)
///   3. Minimum required fields (amount + direction + date)
///   4. Confidence threshold (reject if overall < 0.15 — essentially unreadable)
class SmsValidationEngineImpl implements SmsValidationEngine {
  const SmsValidationEngineImpl();

  /// TRAI sender ID bare prefixes for known banks and financial institutions.
  /// Covers DLT-registered senders as of 2025.
  /// TRAI 2025 format: [XX]-[BAREID] or [XX]-[BAREID]-S
  static const _trustedSenderPrefixes = [
    // Banks
    'HDFCBK', 'HDFCBN', 'HDFC',
    'SBIBNK', 'SBICRD', 'SBI', 'SBIPSG',
    'ICICIB', 'ICICI', 'ICICIBK',
    'AXISBK', 'AXIS', 'AXISBN',
    'KOTAKB', 'KOTAK', 'KTKMBL',
    'YESBNK', 'YESBK',
    'PNBSMS', 'PNB',
    'BOBSMS', 'BOB',
    'CANBNK', 'CANARA',
    'IDBIBK', 'IDBI',
    'FEDBNK', 'FEDERAL',
    'RBLBNK', 'RBL',
    'IDFCBK', 'IDFC',
    'BOISMS', 'BOI',
    'UNIONB', 'UNION',
    'INDBNK', 'INDIAN',
    'SCBANK', 'SC', // Standard Chartered
    'HSBCIN', 'HSBC',
    'CITIBK', 'CITI',
    // UPI + Payments
    'PHPEPE', 'PHONEP', // PhonePe
    'GPAYSI', 'GPAY',  // Google Pay
    'PAYTMB', 'PAYTM',
    'AMAZPB', // Amazon Pay
    'JUSPAY',
    'BHARATPE',
    // Mutual Fund / Investment
    'GROWWM', 'GROWW',
    'ZERODH', 'ZERODHA',
    'NIPPON', 'NIPPNM',
    'SBIMU', 'SBIMF',
    'HDFCMU', 'HDFCMF',
    // Insurance
    'LICIND', 'LICINS',
    'HDFCLI', 'HDFCLIFE',
    'ICICIP', 'ICICIPRU',
    'BAJALI', 'BAJAJLIF',
  ];

  static const double _minConfidenceThreshold = 0.15;

  @override
  bool isTrustedSender(String senderAddress) {
    final bare = _extractBareId(senderAddress).toUpperCase();
    return _trustedSenderPrefixes.any((prefix) => bare.startsWith(prefix));
  }

  @override
  SmsValidationResult validate(ExtractionResult result, String senderAddress) {
    // 1. Pre-debit alert — must never be ingested as a transaction
    if (result.isPreDebitAlert) {
      return SmsValidationResult.preDebitAlert();
    }

    // 2. Already marked as rejected by the parser
    if (result.isRejected) {
      return SmsValidationResult.rejected([
        result.rejectionReason ?? 'Parser rejected this SMS',
      ]);
    }

    final failures = <String>[];
    final trusted = isTrustedSender(senderAddress);

    // 3. Minimum confidence floor — below 0.15 means almost nothing was extracted
    if (result.overallConfidence < _minConfidenceThreshold) {
      failures.add(
        'Overall confidence ${result.overallConfidence.toStringAsFixed(2)} '
        'below minimum threshold $_minConfidenceThreshold',
      );
    }

    // 4. Required fields
    if (result.amount == null) {
      failures.add('Amount not found — cannot create transaction');
    }
    if (result.direction == null) {
      failures.add('Direction (DEBIT/CREDIT) not found');
    }
    if (result.transactionDate == null) {
      failures.add('Transaction date not found');
    }

    if (failures.isNotEmpty) {
      return SmsValidationResult.rejected(failures);
    }

    // 5. Amount sanity check
    if (result.amount! <= 0) {
      return SmsValidationResult.rejected(['Amount must be positive (got ${result.amount})']);
    }

    return SmsValidationResult.passed(isTrustedSender: trusted);
  }

  String _extractBareId(String sender) {
    final parts = sender.toUpperCase().split('-');
    if (parts.length >= 2) {
      final withoutPrefix = parts.sublist(1).join('-');
      return withoutPrefix.endsWith('-S')
          ? withoutPrefix.substring(0, withoutPrefix.length - 2)
          : withoutPrefix;
    }
    return sender.toUpperCase();
  }
}
