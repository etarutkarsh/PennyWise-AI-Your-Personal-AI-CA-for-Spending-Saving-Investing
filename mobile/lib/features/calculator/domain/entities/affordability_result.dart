// Mirrors com.pennywise.dto.AffordabilityResponse + ScenarioDto on the backend.

enum RecommendationStrength { high, medium, low }

extension RecommendationStrengthX on RecommendationStrength {
  String get label => switch (this) {
        RecommendationStrength.high => 'HIGH',
        RecommendationStrength.medium => 'MEDIUM',
        RecommendationStrength.low => 'LOW',
      };

  static RecommendationStrength parse(String? s) => switch (s?.toUpperCase()) {
        'HIGH' => RecommendationStrength.high,
        'MEDIUM' => RecommendationStrength.medium,
        _ => RecommendationStrength.low,
      };
}

enum TradeoffType { pro, con }

class Tradeoff {
  const Tradeoff({required this.type, required this.description});
  final TradeoffType type;
  final String description;

  factory Tradeoff.fromJson(Map<String, dynamic> json) => Tradeoff(
        type: json['type'] == 'PRO' ? TradeoffType.pro : TradeoffType.con,
        description: json['description'] as String? ?? '',
      );
}

class AffordabilityResult {
  const AffordabilityResult({
    required this.verdict,
    required this.reason,
    this.recommendedWaitMonths,
    this.recommendedMonthlySavings,
    this.expectedPurchaseDate,
    this.investmentSuggestion,
    this.confidence = 0,
    this.recommendationStrength = RecommendationStrength.low,
    this.strengthEvidence = const [],
    this.monthlyEmi,
    this.dtiRatio,
    this.remainingMonthlySurplus,
    this.maxAffordablePrice,
    this.reasons = const [],
    this.warnings = const [],
    this.recommendations = const [],
    this.scenarios = const [],
    this.goalImpacts = const [],
  });

  final String verdict; // SAFE_TO_BUY | WAIT_AND_SAVE | DONT_BUY
  final String reason;
  final int? recommendedWaitMonths;
  final double? recommendedMonthlySavings;
  final DateTime? expectedPurchaseDate;
  final String? investmentSuggestion;

  // Intelligence
  final int confidence;
  final RecommendationStrength recommendationStrength;
  final List<String> strengthEvidence;
  final double? monthlyEmi;
  final double? dtiRatio;
  final double? remainingMonthlySurplus;
  final double? maxAffordablePrice;
  final List<String> reasons;
  final List<String> warnings;
  final List<String> recommendations;
  final List<AffordabilityScenario> scenarios;
  final List<GoalImpact> goalImpacts;

  static DateTime? _parseDateNullable(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) return DateTime.parse(raw);
    if (raw is List) return DateTime(raw[0] as int, raw[1] as int, raw[2] as int);
    return null;
  }

  factory AffordabilityResult.fromJson(Map<String, dynamic> json) => AffordabilityResult(
        verdict: json['verdict'] as String,
        reason: json['reason'] as String? ?? '',
        recommendedWaitMonths: json['recommendedWaitMonths'] as int?,
        recommendedMonthlySavings: (json['recommendedMonthlySavings'] as num?)?.toDouble(),
        expectedPurchaseDate: _parseDateNullable(json['expectedPurchaseDate']),
        investmentSuggestion: json['investmentSuggestion'] as String?,
        confidence: json['confidence'] as int? ?? 0,
        recommendationStrength:
            RecommendationStrengthX.parse(json['recommendationStrength'] as String?),
        strengthEvidence:
            (json['strengthEvidence'] as List?)?.map((e) => e as String).toList() ?? [],
        monthlyEmi: (json['monthlyEmi'] as num?)?.toDouble(),
        dtiRatio: (json['dtiRatio'] as num?)?.toDouble(),
        remainingMonthlySurplus: (json['remainingMonthlySurplus'] as num?)?.toDouble(),
        maxAffordablePrice: (json['maxAffordablePrice'] as num?)?.toDouble(),
        reasons: (json['reasons'] as List?)?.map((e) => e as String).toList() ?? [],
        warnings: (json['warnings'] as List?)?.map((e) => e as String).toList() ?? [],
        recommendations:
            (json['recommendations'] as List?)?.map((e) => e as String).toList() ?? [],
        scenarios: (json['scenarios'] as List?)
                ?.map((e) => AffordabilityScenario.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        goalImpacts: (json['goalImpacts'] as List?)
                ?.map((e) => GoalImpact.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class GoalImpact {
  const GoalImpact({
    required this.goalName,
    required this.goalType,
    required this.currentProgressPct,
    required this.projectedProgressPct,
    this.monthsToTargetNow,
    this.monthsToTargetAfter,
    required this.monthsDelayed,
    required this.statusChange,
  });

  final String goalName;
  final String goalType;
  final double currentProgressPct;
  final double projectedProgressPct;
  final int? monthsToTargetNow;
  final int? monthsToTargetAfter;
  final int monthsDelayed;
  final String statusChange; // UNAFFECTED | DELAYED | AT_RISK | ACCELERATED

  factory GoalImpact.fromJson(Map<String, dynamic> json) => GoalImpact(
        goalName: json['goalName'] as String? ?? 'Goal',
        goalType: json['goalType'] as String? ?? 'custom',
        currentProgressPct: (json['currentProgressPct'] as num).toDouble(),
        projectedProgressPct: (json['projectedProgressPct'] as num).toDouble(),
        monthsToTargetNow: json['monthsToTargetNow'] as int?,
        monthsToTargetAfter: json['monthsToTargetAfter'] as int?,
        monthsDelayed: json['monthsDelayed'] as int? ?? 0,
        statusChange: json['statusChange'] as String? ?? 'UNAFFECTED',
      );
}

class AffordabilityScenario {
  const AffordabilityScenario({
    required this.label,
    required this.verdict,
    required this.confidence,
    required this.recommendationStrength,
    required this.summary,
    required this.isRecommended,
    this.monthlyEmi,
    this.totalInterest,
    this.totalCost,
    this.whyThis = const [],
    this.whyNot = const [],
    this.tradeoffs = const [],
  });

  final String label;
  final String verdict;
  final int confidence;
  final RecommendationStrength recommendationStrength;
  final String summary;
  final bool isRecommended;
  final double? monthlyEmi;
  final double? totalInterest;
  final double? totalCost;
  final List<String> whyThis;
  final List<String> whyNot;
  final List<Tradeoff> tradeoffs;

  factory AffordabilityScenario.fromJson(Map<String, dynamic> json) => AffordabilityScenario(
        label: json['label'] as String,
        verdict: json['verdict'] as String,
        confidence: json['confidence'] as int,
        recommendationStrength:
            RecommendationStrengthX.parse(json['recommendationStrength'] as String?),
        summary: json['summary'] as String,
        isRecommended: (json['isRecommended'] ?? json['recommended']) as bool? ?? false,
        monthlyEmi: (json['monthlyEmi'] as num?)?.toDouble(),
        totalInterest: (json['totalInterest'] as num?)?.toDouble(),
        totalCost: (json['totalCost'] as num?)?.toDouble(),
        whyThis: (json['whyThis'] as List?)?.map((e) => e as String).toList() ?? [],
        whyNot: (json['whyNot'] as List?)?.map((e) => e as String).toList() ?? [],
        tradeoffs: (json['tradeoffs'] as List?)
                ?.map((e) => Tradeoff.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
