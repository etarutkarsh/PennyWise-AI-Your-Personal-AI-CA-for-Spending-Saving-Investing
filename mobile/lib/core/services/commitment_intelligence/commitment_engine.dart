// ignore_for_file: avoid_redundant_argument_values

import 'dart:math' as math;

import '../../../features/transactions/domain/entities/transaction_entity.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

/// What the obligation IS — stable across payment rails.
enum CommitmentType {
  emi,          // Loan EMIs — home, car, personal
  subscription, // Streaming, SaaS, telecom plans
  investment,   // SIP, mutual funds, NPS, PPF
  insurance,    // Health, life, vehicle
  utility,      // Electricity, water, gas, internet, FASTag
  rent,         // House rent, PG, society maintenance
  education,    // School fees, coaching, courses
  tax,          // Advance tax, GST
  savings,      // RD, recurring deposits
  membership,   // Gym, club memberships
  other,
}

/// HOW the payment is fulfilled — changes as rails evolve.
enum PaymentMechanism {
  nach,                // NACH DR bank mandate (loan EMIs, insurance)
  ecs,                 // Electronic Clearing Service (legacy)
  upiAutopay,          // UPI AutoPay mandate
  standingInstruction, // Bank standing instruction (SI)
  cardAutopay,         // Credit card recurring charge
  netbankingAutopay,   // Net banking scheduled payment
  manual,              // Manually paid but recurring pattern detected
  unknown,
}

/// How critical the obligation is to the user's financial health.
enum Criticality {
  essential,  // Cannot miss — EMI, rent, health insurance, utilities
  important,  // Should not miss — SIP, phone plan, internet
  optional,   // Nice to have — streaming, SaaS tools
  luxury,     // Purely discretionary
}

/// Whether the amount is predictable or varies.
enum Flexibility {
  fixed,    // Same amount every cycle (EMI, rent, subscriptions)
  variable, // Amount varies (electricity, gas)
  seasonal, // Charged at specific times of year (school fees)
  onDemand, // Charged when used (gas cylinder)
}

/// Health signal for proactive user warnings.
enum RiskLevel { low, medium, high }

enum RecurrencePeriod { weekly, biweekly, monthly, quarterly, semiannual, annual, irregular }

enum InsightType { waste, warning, tip, saving }

// ─── Models ───────────────────────────────────────────────────────────────────

class DetectedCommitment {
  const DetectedCommitment({
    required this.merchantKey,
    required this.displayName,
    required this.type,
    required this.mechanism,
    required this.criticality,
    required this.flexibility,
    required this.riskLevel,
    required this.period,
    required this.avgAmount,
    required this.lastAmount,
    required this.confidence,
    required this.lastCharge,
    required this.chargeDates,
    required this.likelyUnused,
  });

  final String merchantKey;
  final String displayName;
  final CommitmentType type;
  final PaymentMechanism mechanism;
  final Criticality criticality;
  final Flexibility flexibility;
  final RiskLevel riskLevel;
  final RecurrencePeriod period;
  final double avgAmount;
  final double lastAmount;
  final double confidence;
  final DateTime lastCharge;
  final List<DateTime> chargeDates;
  final bool likelyUnused;

  int get periodDays => _periodCanonicalDays[period] ?? 30;

  double get monthlyEquivalent {
    final days = periodDays;
    if (days <= 0) return avgAmount;
    return avgAmount * (30.0 / days);
  }

  DateTime get nextExpected => lastCharge.add(Duration(days: periodDays));
  int get daysUntilNext => nextExpected.difference(DateTime.now()).inDays;
}

class ForecastPayment {
  const ForecastPayment({
    required this.expectedDate,
    required this.merchantName,
    required this.estimatedAmount,
    required this.type,
    required this.mechanism,
    required this.isConfirmed,
  });

  final DateTime expectedDate;
  final String merchantName;
  final double estimatedAmount;
  final CommitmentType type;
  final PaymentMechanism mechanism;
  final bool isConfirmed;
}

class CommitmentInsight {
  const CommitmentInsight({
    required this.type,
    required this.message,
    this.monthlySaving,
    this.affectedMerchants = const [],
  });

  final InsightType type;
  final String message;
  final double? monthlySaving;
  final List<String> affectedMerchants;
}

class CommitmentSummary {
  const CommitmentSummary({
    required this.all,
    required this.totalMonthlyCommitted,
    required this.monthlyIncome,
    required this.byType,
    required this.unusedCommitments,
    required this.next30Days,
    required this.insights,
  });

  final List<DetectedCommitment> all;
  final double totalMonthlyCommitted;
  final double monthlyIncome;
  final Map<CommitmentType, double> byType;
  final List<DetectedCommitment> unusedCommitments;
  final List<ForecastPayment> next30Days;
  final List<CommitmentInsight> insights;

  double get commitmentRatio =>
      monthlyIncome > 0 ? (totalMonthlyCommitted / monthlyIncome).clamp(0.0, 1.0) : 0.0;

  double get flexibleIncome => monthlyIncome - totalMonthlyCommitted;
  double get annualDrain => totalMonthlyCommitted * 12;
}

// ─── Engine ───────────────────────────────────────────────────────────────────

const Map<RecurrencePeriod, int> _periodCanonicalDays = {
  RecurrencePeriod.weekly: 7,
  RecurrencePeriod.biweekly: 14,
  RecurrencePeriod.monthly: 30,
  RecurrencePeriod.quarterly: 90,
  RecurrencePeriod.semiannual: 180,
  RecurrencePeriod.annual: 365,
  RecurrencePeriod.irregular: 30,
};

const Map<String, String> _aliases = {
  // Streaming / entertainment
  'netflix': 'Netflix',
  'spotify': 'Spotify',
  'amazon prime video': 'Amazon Prime',
  'amazon prime': 'Amazon Prime',
  'prime video': 'Amazon Prime',
  'amzn prime': 'Amazon Prime',
  'hotstar': 'Disney+ Hotstar',
  'disney': 'Disney+ Hotstar',
  'zee5': 'ZEE5',
  'jio cinema': 'JioCinema',
  'sonyliv': 'SonyLIV',
  'youtube premium': 'YouTube Premium',
  // SaaS / AI tools
  'claude': 'Claude (Anthropic)',
  'anthropic': 'Claude (Anthropic)',
  'chatgpt': 'ChatGPT',
  'openai': 'ChatGPT',
  'gemini': 'Google Gemini',
  'github': 'GitHub',
  'canva': 'Canva',
  'adobe': 'Adobe Creative',
  'microsoft': 'Microsoft 365',
  'google one': 'Google One',
  'icloud': 'iCloud+',
  'dropbox': 'Dropbox',
  'notion': 'Notion',
  'figma': 'Figma',
  // Telecom
  'airtel': 'Airtel',
  'jio': 'Reliance Jio',
  'bsnl': 'BSNL',
  'vodafone': 'Vi (Vodafone Idea)',
  // Utilities
  'fastag': 'FASTag',
  // Investments
  'nps': 'NPS',
  'groww': 'Groww',
  'zerodha': 'Zerodha',
  'kuvera': 'Kuvera',
  'paytm money': 'Paytm Money',
  // Insurance
  'lic': 'LIC',
  'star health': 'Star Health',
  'hdfc ergo': 'HDFC ERGO',
  'bajaj allianz': 'Bajaj Allianz',
  'care health': 'Care Health',
  // Fitness
  'cult': 'Cult.fit',
  'healthifyme': 'HealthifyMe',
};

// Internal helper for risk computation before DetectedCommitment is fully built.
class _PartialCommitment {
  const _PartialCommitment({
    required this.criticality,
    required this.flexibility,
    required this.avgAmount,
    required this.likelyUnused,
    required this.daysUntilNext,
  });
  final Criticality criticality;
  final Flexibility flexibility;
  final double avgAmount;
  final bool likelyUnused;
  final int daysUntilNext;
}

class CommitmentEngine {
  CommitmentEngine._();

  /// Main entry point.
  ///
  /// Detection order: Rail Detection → Strip prefix → Merchant Normalization
  /// → Commitment Classification → Confidence Score
  static CommitmentSummary analyze(
    List<TransactionEntity> transactions,
    double monthlyIncome,
  ) {
    final cutoff = DateTime.now().subtract(const Duration(days: 180));

    final debits = transactions
        .where((t) => t.direction == 'DEBIT' && t.transactionDate.isAfter(cutoff))
        .toList();

    // Step 1: Rail Detection first, then normalize
    final groups = <String, List<TransactionEntity>>{};
    final merchantMechanisms = <String, PaymentMechanism>{};

    for (final txn in debits) {
      final mechanism = _detectRail(txn.merchant);
      final stripped = _stripRailPrefix(txn.merchant);
      final key = _normalizeMerchant(stripped);
      if (key.isEmpty) continue;
      groups.putIfAbsent(key, () => []).add(txn);
      // Keep most specific mechanism (non-unknown wins)
      if (!merchantMechanisms.containsKey(key) || mechanism != PaymentMechanism.unknown) {
        merchantMechanisms[key] = mechanism;
      }
    }

    // Step 2: Recurrence detection + confidence scoring
    final commitments = <DetectedCommitment>[];
    for (final entry in groups.entries) {
      final key = entry.key;
      final txns = entry.value;
      if (txns.length < 2) continue;

      txns.sort((a, b) => a.transactionDate.compareTo(b.transactionDate));
      final dates = txns.map((t) => t.transactionDate).toList();

      final intervals = <int>[];
      for (var i = 1; i < dates.length; i++) {
        intervals.add(dates[i].difference(dates[i - 1]).inDays);
      }
      if (intervals.isEmpty) continue;

      final medianInterval = _median(intervals);
      final stdDev = _stdDev(intervals, medianInterval);

      RecurrencePeriod? bestPeriod;
      var bestScore = double.maxFinite;
      for (final period in RecurrencePeriod.values) {
        if (period == RecurrencePeriod.irregular) continue;
        final canonical = _periodCanonicalDays[period]!.toDouble();
        final diff = (medianInterval - canonical).abs();
        if (diff / canonical <= 0.20 && diff < bestScore) {
          bestScore = diff;
          bestPeriod = period;
        }
      }
      if (bestPeriod == null) continue;

      final canonicalDays = _periodCanonicalDays[bestPeriod]!.toDouble();
      final cvPart = medianInterval > 0
          ? (stdDev / medianInterval).clamp(0.0, 1.0)
          : 1.0;
      final expectedOccurrences = (180.0 / canonicalDays).clamp(1.0, double.maxFinite);
      final coveragePart = (txns.length / expectedOccurrences).clamp(0.0, 1.0);
      final confidence = (1.0 - cvPart) * coveragePart;
      if (confidence < 0.45) continue;

      final amounts = txns.map((t) => t.amount).toList();
      final avgAmount = amounts.reduce((a, b) => a + b) / amounts.length;
      final lastAmount = txns.last.amount;
      final lastCharge = txns.last.transactionDate;
      final likelyUnused =
          DateTime.now().difference(lastCharge).inDays > canonicalDays * 1.5;

      final displayName = _resolveDisplayName(key);
      final mechanism = merchantMechanisms[key] ?? PaymentMechanism.unknown;
      final type = _classifyType(key, mechanism, txns.first.categoryName);
      final criticality = _criticalityFor(type, key);
      final flexibility = _flexibilityFor(type);
      final daysUntil = lastCharge.add(Duration(days: canonicalDays.round()))
          .difference(DateTime.now()).inDays;
      final riskLevel = _riskFor(_PartialCommitment(
        criticality: criticality,
        flexibility: flexibility,
        avgAmount: avgAmount,
        likelyUnused: likelyUnused,
        daysUntilNext: daysUntil,
      ));

      commitments.add(DetectedCommitment(
        merchantKey: key,
        displayName: displayName,
        type: type,
        mechanism: mechanism,
        criticality: criticality,
        flexibility: flexibility,
        riskLevel: riskLevel,
        period: bestPeriod,
        avgAmount: avgAmount,
        lastAmount: lastAmount,
        confidence: confidence,
        lastCharge: lastCharge,
        chargeDates: dates.reversed.toList(),
        likelyUnused: likelyUnused,
      ));
    }

    // Step 3: Aggregate
    final byType = <CommitmentType, double>{};
    var totalMonthly = 0.0;
    for (final c in commitments) {
      final monthly = c.monthlyEquivalent;
      byType[c.type] = (byType[c.type] ?? 0) + monthly;
      totalMonthly += monthly;
    }

    final unused = commitments.where((c) => c.likelyUnused).toList();

    final now = DateTime.now();
    final in30 = now.add(const Duration(days: 30));
    final next30 = <ForecastPayment>[];
    for (final c in commitments) {
      final expected = c.nextExpected;
      if (expected.isAfter(now) && expected.isBefore(in30)) {
        next30.add(ForecastPayment(
          expectedDate: expected,
          merchantName: c.displayName,
          estimatedAmount: c.avgAmount,
          type: c.type,
          mechanism: c.mechanism,
          isConfirmed: c.confidence > 0.85,
        ));
      }
    }
    next30.sort((a, b) => a.expectedDate.compareTo(b.expectedDate));

    final partial = CommitmentSummary(
      all: commitments,
      totalMonthlyCommitted: totalMonthly,
      monthlyIncome: monthlyIncome,
      byType: byType,
      unusedCommitments: unused,
      next30Days: next30,
      insights: [],
    );
    final insights = _generateInsights(commitments, monthlyIncome, partial);

    return CommitmentSummary(
      all: commitments,
      totalMonthlyCommitted: totalMonthly,
      monthlyIncome: monthlyIncome,
      byType: byType,
      unusedCommitments: unused,
      next30Days: next30,
      insights: insights,
    );
  }

  // ── Rail Detection (BEFORE normalization) ─────────────────────────────────

  static PaymentMechanism _detectRail(String raw) {
    final u = raw.toUpperCase();
    if (u.startsWith('NACH') || u.contains('NACH DR') || u.contains('NACH CR')) {
      return PaymentMechanism.nach;
    }
    if (u.startsWith('ECS') || u.contains('ECS DR') || u.contains('ECS CR')) {
      return PaymentMechanism.ecs;
    }
    if (u.contains('UPI AUTOPAY') || u.contains('UPI/AUTOPAY') || u.contains('UPI-AUTOPAY')) {
      return PaymentMechanism.upiAutopay;
    }
    if (u.startsWith('SI-') || u.startsWith('SI ') ||
        u.contains('STANDING INSTRUCTION') || u.contains('STDINSTR')) {
      return PaymentMechanism.standingInstruction;
    }
    if (u.contains('CARD AUTOPAY') || u.contains('CC AUTOPAY') ||
        u.contains('CREDIT CARD AUTO')) {
      return PaymentMechanism.cardAutopay;
    }
    if (u.contains('NETBANKING') || u.contains('NET BANKING') || u.contains('INFT')) {
      return PaymentMechanism.netbankingAutopay;
    }
    return PaymentMechanism.unknown;
  }

  static String _stripRailPrefix(String raw) => raw
      .replaceAll(RegExp(r'^NACH\s+(DR|CR)[-\s]*', caseSensitive: false), '')
      .replaceAll(RegExp(r'^ECS\s+(DR|CR)[-\s]*', caseSensitive: false), '')
      .replaceAll(RegExp(r'^UPI[-/\s]AUTOPAY[-\s]*', caseSensitive: false), '')
      .replaceAll(RegExp(r'^SI[-\s]', caseSensitive: false), '')
      .replaceAll(RegExp(r'^STDINSTR[-\s]*', caseSensitive: false), '')
      .trim();

  // ── Normalization (AFTER rail strip) ──────────────────────────────────────

  static String _normalizeMerchant(String raw) {
    var s = raw.toLowerCase().trim();
    for (final r in const [
      'pvt ltd', 'private limited', 'india pvt', 'india',
      '.com', '.in', 'payment', 'autopay', 'auto',
    ]) {
      s = s.replaceAll(r, '');
    }
    s = s.replaceAll(RegExp(r'\*\d+'), '');
    s = s.replaceAll(RegExp(r'\d+$'), '');
    s = s.replaceAll(RegExp(r'[^a-z0-9 ]'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (s.length > 30) s = s.substring(0, 30).trim();
    return s;
  }

  static String _resolveDisplayName(String key) {
    var bestKey = '';
    var bestDisplay = '';
    for (final entry in _aliases.entries) {
      if (key.contains(entry.key) && entry.key.length > bestKey.length) {
        bestKey = entry.key;
        bestDisplay = entry.value;
      }
    }
    if (bestDisplay.isNotEmpty) return bestDisplay;
    return key
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  // ── Classification ────────────────────────────────────────────────────────

  static CommitmentType _classifyType(
      String k, PaymentMechanism mechanism, String categoryName) {
    // EMI / Loans
    if (_containsAny(k, [
      'emi', 'loan', 'home loan', 'car loan', 'personal loan',
      'bajaj finance', 'hdfc home', 'icici home', 'sbi home', 'axis home',
    ])) return CommitmentType.emi;
    // NACH from a bank = likely EMI or mandate
    if ((mechanism == PaymentMechanism.nach || mechanism == PaymentMechanism.ecs) &&
        _containsAny(k, ['hdfc', 'icici', 'sbi', 'axis', 'kotak', 'yes bank', 'bank'])) {
      return CommitmentType.emi;
    }

    // Investments
    if (_containsAny(k, [
      'sip', 'nps', 'ppf', 'mutual fund', 'groww', 'zerodha', 'kuvera',
      'coin', 'paytm money', 'mf ', 'fund', 'direct plan',
    ])) return CommitmentType.investment;

    // Savings instruments
    if (_containsAny(k, ['rd', 'recurring deposit', 'fixed deposit', 'fd'])) {
      return CommitmentType.savings;
    }

    // Insurance
    if (_containsAny(k, [
      'lic', 'insurance', 'insur', 'health plan', 'life cover', 'policy',
      'hdfc ergo', 'bajaj allianz', 'star health', 'care health',
    ])) return CommitmentType.insurance;

    // Utilities (including transport pass / FASTag)
    if (_containsAny(k, [
      'electricity', 'electric', 'bescom', 'msedcl', 'tpddl', 'water',
      'gas', 'cylinder', 'lpg', 'broadband', 'fiber', 'internet', 'wifi',
      'fastag', 'metro', 'toll',
    ])) return CommitmentType.utility;

    // Rent / Housing
    if (_containsAny(k, [
      'rent', 'maintenance', 'society', 'hoa', 'accommodation', 'pg', 'hostel',
    ])) return CommitmentType.rent;

    // Education
    if (_containsAny(k, [
      'school', 'tuition', 'coaching', 'childcare', 'daycare',
      'fees', 'college', 'university', 'course',
    ])) return CommitmentType.education;

    // Tax
    if (_containsAny(k, ['advance tax', 'gst', 'tds', 'income tax'])) {
      return CommitmentType.tax;
    }

    // Gym / Memberships
    if (_containsAny(k, ['gym', 'cult', 'fitness', 'healthifyme', 'club'])) {
      return CommitmentType.membership;
    }

    // Subscriptions (streaming + SaaS + telecom)
    if (_containsAny(k, [
      'netflix', 'spotify', 'hotstar', 'zee5', 'jio cinema', 'sonyliv',
      'youtube premium', 'apple', 'prime video', 'amazon prime',
      'airtel', 'jio', 'bsnl', 'vodafone', 'vi ', 'recharge', 'mobile', 'postpaid',
      'claude', 'chatgpt', 'openai', 'gemini', 'github', 'canva', 'adobe',
      'microsoft', 'google one', 'icloud', 'dropbox', 'notion', 'figma',
    ])) return CommitmentType.subscription;

    // Fallback: map categoryName
    final cat = categoryName.toLowerCase();
    if (cat.contains('loan') || cat.contains('emi')) return CommitmentType.emi;
    if (cat.contains('investment') || cat.contains('sip')) return CommitmentType.investment;
    if (cat.contains('insurance')) return CommitmentType.insurance;
    if (cat.contains('utilit')) return CommitmentType.utility;
    if (cat.contains('rent') || cat.contains('housing')) return CommitmentType.rent;
    if (cat.contains('entertainment') || cat.contains('subscription')) {
      return CommitmentType.subscription;
    }
    return CommitmentType.other;
  }

  static Criticality _criticalityFor(CommitmentType type, String k) {
    switch (type) {
      case CommitmentType.emi:
      case CommitmentType.rent:
      case CommitmentType.tax:
        return Criticality.essential;
      case CommitmentType.insurance:
        if (_containsAny(k, ['health', 'lic', 'life'])) return Criticality.essential;
        return Criticality.important;
      case CommitmentType.utility:
        if (_containsAny(k, ['electricity', 'electric', 'bescom', 'msedcl', 'water', 'gas'])) {
          return Criticality.essential;
        }
        return Criticality.important;
      case CommitmentType.investment:
      case CommitmentType.savings:
      case CommitmentType.education:
        return Criticality.important;
      case CommitmentType.subscription:
        // Telecom = important; streaming/SaaS = optional
        if (_containsAny(k, ['airtel', 'jio', 'bsnl', 'vodafone', 'internet', 'broadband'])) {
          return Criticality.important;
        }
        return Criticality.optional;
      case CommitmentType.membership:
      case CommitmentType.other:
        return Criticality.optional;
    }
  }

  static Flexibility _flexibilityFor(CommitmentType type) => switch (type) {
        CommitmentType.emi ||
        CommitmentType.rent ||
        CommitmentType.subscription ||
        CommitmentType.membership =>
          Flexibility.fixed,
        CommitmentType.utility => Flexibility.variable,
        CommitmentType.education => Flexibility.seasonal,
        _ => Flexibility.fixed,
      };

  static RiskLevel _riskFor(_PartialCommitment c) {
    if (c.criticality == Criticality.essential && c.likelyUnused) return RiskLevel.high;
    if (c.daysUntilNext <= 2 && c.avgAmount > 5000) return RiskLevel.high;
    if (c.likelyUnused) return RiskLevel.medium;
    if (c.flexibility == Flexibility.variable && c.avgAmount > 3000) return RiskLevel.medium;
    return RiskLevel.low;
  }

  // ── Insights ───────────────────────────────────────────────────────────────

  static List<CommitmentInsight> _generateInsights(
    List<DetectedCommitment> commitments,
    double income,
    CommitmentSummary summary,
  ) {
    final insights = <CommitmentInsight>[];

    // Unused commitments
    final unused = commitments.where((c) => c.likelyUnused).toList();
    if (unused.isNotEmpty) {
      final saving = unused.fold<double>(0, (s, c) => s + c.monthlyEquivalent);
      insights.add(CommitmentInsight(
        type: InsightType.waste,
        message:
            '${unused.length} commitment${unused.length > 1 ? "s" : ""} may be unused — save ₹${saving.round()}/month',
        monthlySaving: saving,
        affectedMerchants: unused.map((c) => c.displayName).toList(),
      ));
    }

    // Commitment ratio > 60%
    if (summary.commitmentRatio > 0.6) {
      final pct = (summary.commitmentRatio * 100).round();
      insights.add(CommitmentInsight(
        type: InsightType.warning,
        message: '$pct% of income is pre-committed — tighten lifestyle before cutting investments',
      ));
    }

    // Annual plan tip
    if (summary.commitmentRatio > 0.4 && summary.commitmentRatio <= 0.6) {
      insights.add(const CommitmentInsight(
        type: InsightType.tip,
        message: 'Switch annual subscriptions to yearly billing to save ~15%',
      ));
    }

    // Subscription bloat > ₹2000/month
    final subTotal = summary.byType[CommitmentType.subscription] ?? 0.0;
    if (subTotal > 2000) {
      insights.add(CommitmentInsight(
        type: InsightType.tip,
        message:
            'Subscriptions cost ₹${subTotal.round()}/month — a shared family plan could cut this by 40%',
        affectedMerchants: commitments
            .where((c) => c.type == CommitmentType.subscription)
            .map((c) => c.displayName)
            .toList(),
      ));
    }

    // Investment rate < 10% of income
    final investTotal = (summary.byType[CommitmentType.investment] ?? 0.0) +
        (summary.byType[CommitmentType.savings] ?? 0.0);
    if (income > 0 && investTotal < income * 0.1) {
      final pct = income > 0 ? ((investTotal / income) * 100).round() : 0;
      insights.add(CommitmentInsight(
        type: InsightType.tip,
        message: 'Investments are only $pct% of income — target 20% for financial freedom',
      ));
    }

    // Bank mandate balance warning
    final mandateCount = commitments
        .where((c) =>
            c.mechanism == PaymentMechanism.nach || c.mechanism == PaymentMechanism.ecs)
        .length;
    if (mandateCount > 0) {
      insights.add(CommitmentInsight(
        type: InsightType.tip,
        message:
            '$mandateCount bank mandate${mandateCount > 1 ? "s" : ""} active — keep buffer in your account before each due date',
      ));
    }

    return insights;
  }

  // ── Math helpers ───────────────────────────────────────────────────────────

  static double _median(List<int> values) {
    final sorted = List<int>.from(values)..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[mid].toDouble();
    return (sorted[mid - 1] + sorted[mid]) / 2.0;
  }

  static double _stdDev(List<int> values, double mean) {
    if (values.length < 2) return 0.0;
    final variance =
        values.fold<double>(0, (sum, v) => sum + math.pow(v - mean, 2)) /
            (values.length - 1);
    return math.sqrt(variance);
  }

  static bool _containsAny(String text, List<String> keywords) =>
      keywords.any((kw) => text.contains(kw));
}
