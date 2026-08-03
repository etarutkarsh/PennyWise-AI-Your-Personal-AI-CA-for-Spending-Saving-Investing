class PartnerOptionModel {
  const PartnerOptionModel({
    required this.partner,
    required this.rate,
    required this.minAmount,
    required this.feature,
    required this.ctaLabel,
    required this.link,
  });

  final String partner;
  final double rate;
  final double minAmount;
  final String feature;
  final String ctaLabel;
  final String link;

  factory PartnerOptionModel.fromJson(Map<String, dynamic> json) =>
      PartnerOptionModel(
        partner: json['partner'] as String? ?? '',
        rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
        minAmount: (json['minAmount'] as num?)?.toDouble() ?? 0.0,
        feature: json['feature'] as String? ?? '',
        ctaLabel: json['ctaLabel'] as String? ?? 'View',
        link: json['link'] as String? ?? '',
      );
}

class DecisionImpactModel {
  const DecisionImpactModel({
    required this.healthScoreCurrent,
    required this.healthScoreAfter,
    required this.goalSuccessRateCurrent,
    required this.goalSuccessRateAfter,
    required this.runwayMonthsAdded,
    required this.monthlySavingsIncrease,
  });

  final int healthScoreCurrent;
  final int healthScoreAfter;
  final int goalSuccessRateCurrent;
  final int goalSuccessRateAfter;
  final int runwayMonthsAdded;
  final double monthlySavingsIncrease;

  factory DecisionImpactModel.fromJson(Map<String, dynamic> json) =>
      DecisionImpactModel(
        healthScoreCurrent: json['healthScoreCurrent'] as int? ?? 0,
        healthScoreAfter: json['healthScoreAfter'] as int? ?? 0,
        goalSuccessRateCurrent: json['goalSuccessRateCurrent'] as int? ?? 0,
        goalSuccessRateAfter: json['goalSuccessRateAfter'] as int? ?? 0,
        runwayMonthsAdded: json['runwayMonthsAdded'] as int? ?? 0,
        monthlySavingsIncrease:
            (json['monthlySavingsIncrease'] as num?)?.toDouble() ?? 0.0,
      );
}

class RecommendedActionModel {
  const RecommendedActionModel({
    required this.actionType,
    required this.monthlyAmount,
    required this.instrument,
    required this.timeline,
  });

  final String actionType;
  final double monthlyAmount;
  final String instrument;
  final String timeline;

  factory RecommendedActionModel.fromJson(Map<String, dynamic> json) =>
      RecommendedActionModel(
        actionType: json['actionType'] as String? ?? '',
        monthlyAmount: (json['monthlyAmount'] as num?)?.toDouble() ?? 0.0,
        instrument: json['instrument'] as String? ?? '',
        timeline: json['timeline'] as String? ?? '',
      );
}

class TodayDecisionModel {
  const TodayDecisionModel({
    required this.decisionId,
    required this.headline,
    required this.subheadline,
    required this.priority,
    required this.icon,
    required this.reasons,
    required this.impact,
    required this.recommendedAction,
    required this.partnerOptions,
  });

  final String decisionId;
  final String headline;
  final String subheadline;
  final String priority; // HIGH | MEDIUM | LOW
  final String icon;
  final List<String> reasons;
  final DecisionImpactModel impact;
  final RecommendedActionModel recommendedAction;
  final List<PartnerOptionModel> partnerOptions;

  factory TodayDecisionModel.fromJson(Map<String, dynamic> json) =>
      TodayDecisionModel(
        decisionId: json['decisionId'] as String? ?? '',
        headline: json['headline'] as String? ?? '',
        subheadline: json['subheadline'] as String? ?? '',
        priority: json['priority'] as String? ?? 'MEDIUM',
        icon: json['icon'] as String? ?? '💡',
        reasons: (json['reasons'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        impact: DecisionImpactModel.fromJson(
            json['impact'] as Map<String, dynamic>? ?? {}),
        recommendedAction: RecommendedActionModel.fromJson(
            json['recommendedAction'] as Map<String, dynamic>? ?? {}),
        partnerOptions: (json['partnerOptions'] as List<dynamic>?)
                ?.map((e) =>
                    PartnerOptionModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
