import '../../domain/engines/merchant_resolver.dart';
import '../../domain/engines/transaction_normalizer.dart';
import '../../domain/ingestion/payment_rail.dart';
import '../../domain/ingestion/transaction_candidate.dart';
import '../../domain/shared/data_source.dart';

/// Converts raw ingestion events to normalized TransactionCandidates.
/// Classifies payment rail from hint strings and normalizes confidence per source.
class RuleBasedTransactionNormalizer implements TransactionNormalizer {
  const RuleBasedTransactionNormalizer(this._merchantResolver);

  final MerchantResolver _merchantResolver;

  static const _kVersion = 'normalizer-rule-v1';
  static int _seq = 0;

  @override
  String get engineVersion => _kVersion;

  @override
  TransactionCandidate normalize({
    required String rawId,
    required String rawMerchant,
    required double amount,
    required String direction,
    required DateTime date,
    required String source,
    String? paymentRailHint,
    double confidence = 0.80,
    String? accountLast4,
    String? rawText,
  }) {
    final dataSource = _mapSource(source);
    final rail = _classifyRail(paymentRailHint, rawText, rawMerchant);
    final merchant = _merchantResolver.resolve(rawMerchant);

    // Adjust confidence based on source + rail
    final adjustedConfidence = _adjustConfidence(confidence, dataSource, rail);

    _seq++;
    final candidateId = '${rawId}_n${_seq}_${date.millisecondsSinceEpoch}';

    return TransactionCandidate(
      id: candidateId,
      rawEventId: rawId,
      source: dataSource,
      amount: amount,
      direction: direction.toUpperCase(),
      merchant: merchant,
      rawMerchant: rawMerchant,
      paymentRail: rail,
      transactionDate: date,
      confidence: adjustedConfidence,
      accountLast4: accountLast4,
      rawText: rawText,
    );
  }

  PaymentRail _classifyRail(String? hint, String? rawText, String rawMerchant) {
    final signals = [
      hint?.toUpperCase() ?? '',
      rawText?.toUpperCase() ?? '',
      rawMerchant.toUpperCase(),
    ].join(' ');

    // Mandate rails — check first as they override UPI
    if (signals.contains('NACH DR') || signals.contains('NACH/')) return PaymentRail.nach;
    if (signals.contains('ECS DR') || signals.contains(' ECS ')) return PaymentRail.ecs;
    if (signals.contains('UPI-AUTOPAY') || signals.contains('UPI/AUTOPAY') ||
        signals.contains('UPI AUTOPAY') || signals.contains('AUTOPAY')) {
      return PaymentRail.upiAutopay;
    }
    if (signals.contains('SI ') || signals.contains('STANDING INST') ||
        signals.contains('STANDING INSTRUCTION')) {
      return PaymentRail.standingInstruction;
    }

    // Interbank
    if (signals.contains('NEFT') || signals.contains('/NEFT')) return PaymentRail.neft;
    if (signals.contains('IMPS') || signals.contains('/IMPS')) return PaymentRail.imps;
    if (signals.contains('RTGS') || signals.contains('/RTGS')) return PaymentRail.rtgs;

    // UPI (non-autopay)
    if (signals.contains('UPI') || signals.contains('@') ||
        signals.contains('/UPI') || signals.contains('UPI-')) {
      return PaymentRail.upi;
    }

    // Card
    if (signals.contains('ATM') || signals.contains('CASH WDL') ||
        signals.contains('WITHDRAWAL')) return PaymentRail.atm;
    if (signals.contains('POS') || signals.contains('SWIPE') ||
        signals.contains('CARD PURCHASE') || signals.contains('DEBIT CARD')) {
      return PaymentRail.cardSwipe;
    }
    if (signals.contains('CARD') || signals.contains('CREDIT CARD') ||
        signals.contains('ONLINE')) return PaymentRail.cardOnline;

    // Wallets
    if (signals.contains('PAYTM WALLET') || signals.contains('MOBIKWIK') ||
        signals.contains('WALLET')) return PaymentRail.wallet;

    return PaymentRail.unknown;
  }

  DataSource _mapSource(String source) {
    switch (source.toUpperCase()) {
      case 'AA_DATA':
      case 'ACCOUNT_AGGREGATOR':
        return DataSource.aaData;
      case 'SMS':
      case 'SMS_INTELLIGENCE':
        return DataSource.smsIntelligence;
      case 'MANUAL':
        return DataSource.manual;
      case 'TRANSACTION_HISTORY':
        return DataSource.transactionHistory;
      default:
        return DataSource.manual;
    }
  }

  double _adjustConfidence(double base, DataSource source, PaymentRail rail) {
    double conf = base;

    // Source authority
    switch (source) {
      case DataSource.aaData:
        conf = 1.0;
      case DataSource.smsIntelligence:
        conf = conf.clamp(0.75, 0.95);
      case DataSource.manual:
        conf = conf.clamp(0.90, 1.0); // User-entered is high confidence
      default:
        conf = conf.clamp(0.50, 0.85);
    }

    // Institutional rails add confidence
    if (rail.isInstitutionalRail) {
      conf = (conf + 0.05).clamp(0.0, 1.0);
    }

    return conf;
  }
}
