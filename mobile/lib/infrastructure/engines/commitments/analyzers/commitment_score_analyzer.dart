import '../../../../core/services/commitment_intelligence/commitment_engine.dart';
import '../../../../domain/commitments/commitment_score.dart';
import '../../../../domain/shared/analyzer_result.dart';

class CommitmentScoreAnalyzer {
  const CommitmentScoreAnalyzer();

  AnalyzerResult<Map<String, CommitmentScore>> analyze(
    List<DetectedCommitment> commitments,
    double monthlyIncome,
  ) {
    final startedAt = DateTime.now();
    final scores = <String, CommitmentScore>{};

    for (final c in commitments) {
      scores[c.merchantKey] = _scoreCommitment(c, monthlyIncome);
    }

    return AnalyzerResult.of(
      analyzerId: 'commitment_score_analyzer',
      result: scores,
      confidence: commitments.isEmpty ? 0.30 : 0.80,
      startedAt: startedAt,
    );
  }

  CommitmentScore _scoreCommitment(
      DetectedCommitment c, double monthlyIncome) {
    // Necessity score (weight 0.25)
    final necessityScore = _necessityScore(c);
    final necessity = CommitmentScoreDimension(
      name: 'Necessity',
      score: necessityScore,
      explanation: _necessityExplanation(c),
      weight: 0.25,
    );

    // Flexibility score (weight 0.15) — higher = easier to cut
    final flexScore = _flexibilityScore(c);
    final flexibility = CommitmentScoreDimension(
      name: 'Flexibility',
      score: flexScore,
      explanation: _flexibilityExplanation(c),
      weight: 0.15,
    );

    // Goal alignment score (weight 0.20)
    final goalScore = _goalAlignmentScore(c);
    final goalAlignment = CommitmentScoreDimension(
      name: 'Goal Alignment',
      score: goalScore,
      explanation: _goalAlignmentExplanation(c),
      weight: 0.20,
    );

    // Financial ROI score (weight 0.15)
    final roiScore = _financialROIScore(c);
    final financialROI = CommitmentScoreDimension(
      name: 'Financial ROI',
      score: roiScore,
      explanation: _roiExplanation(c),
      weight: 0.15,
    );

    // Stress impact score (weight 0.10)
    final stressScore = _stressImpactScore(c);
    final stressImpact = CommitmentScoreDimension(
      name: 'Stress Impact',
      score: stressScore,
      explanation: _stressExplanation(c),
      weight: 0.10,
    );

    // Behavioral value score (weight 0.10)
    final behaviorScore = _behavioralValueScore(c);
    final behavioralValue = CommitmentScoreDimension(
      name: 'Behavioral Value',
      score: behaviorScore,
      explanation: _behavioralExplanation(c),
      weight: 0.10,
    );

    // Opportunity cost score (weight 0.05)
    final ocScore = _opportunityCostScore(c);
    final opportunityCostScore = CommitmentScoreDimension(
      name: 'Opportunity Cost',
      score: ocScore,
      explanation: _ocExplanation(c),
      weight: 0.05,
    );

    final overallScore = necessity.weightedScore +
        flexibility.weightedScore +
        goalAlignment.weightedScore +
        financialROI.weightedScore +
        stressImpact.weightedScore +
        behavioralValue.weightedScore +
        opportunityCostScore.weightedScore;

    final action = overallScore >= 70
        ? CommitmentAction.keep
        : overallScore >= 50
            ? CommitmentAction.review
            : overallScore >= 35
                ? CommitmentAction.reduce
                : CommitmentAction.eliminate;

    final confidence = c.chargeDates.length >= 4 ? 0.85 : 0.65;

    return CommitmentScore(
      merchantKey: c.merchantKey,
      displayName: c.displayName,
      necessity: necessity,
      flexibility: flexibility,
      goalAlignment: goalAlignment,
      financialROI: financialROI,
      stressImpact: stressImpact,
      behavioralValue: behavioralValue,
      opportunityCostScore: opportunityCostScore,
      overallScore: overallScore,
      confidence: confidence,
      primaryInsight: _primaryInsight(c, action),
      recommendedAction: action,
    );
  }

  double _necessityScore(DetectedCommitment c) => switch (c.type) {
        CommitmentType.emi => 95,
        CommitmentType.rent => 95,
        CommitmentType.tax => 95,
        CommitmentType.insurance => c.criticality == Criticality.essential
            ? 90
            : 70,
        CommitmentType.utility =>
          c.criticality == Criticality.essential ? 85 : 70,
        CommitmentType.investment => 88,
        CommitmentType.savings => 88,
        CommitmentType.education => 82,
        CommitmentType.subscription =>
          c.criticality == Criticality.important ? 75 : 30,
        CommitmentType.membership => 28,
        CommitmentType.other => 50,
      };

  String _necessityExplanation(DetectedCommitment c) => switch (c.type) {
        CommitmentType.emi ||
        CommitmentType.rent ||
        CommitmentType.tax =>
          'Essential financial obligation',
        CommitmentType.investment ||
        CommitmentType.savings =>
          'Wealth-building commitment',
        CommitmentType.insurance => 'Risk protection',
        CommitmentType.utility => 'Infrastructure necessity',
        CommitmentType.education => 'Future-value investment',
        CommitmentType.subscription => c.criticality == Criticality.important
            ? 'Important connectivity service'
            : 'Discretionary service',
        _ => 'Standard commitment',
      };

  double _flexibilityScore(DetectedCommitment c) => switch (c.flexibility) {
        Flexibility.fixed => 20,
        Flexibility.variable => 55,
        Flexibility.seasonal => 60,
        Flexibility.onDemand => 80,
      };

  String _flexibilityExplanation(DetectedCommitment c) => switch (c.flexibility) {
        Flexibility.fixed => 'Fixed amount — cannot easily reduce',
        Flexibility.variable => 'Variable amount — can be reduced',
        Flexibility.seasonal => 'Seasonal — can be planned ahead',
        Flexibility.onDemand => 'On-demand — easy to pause or reduce',
      };

  double _goalAlignmentScore(DetectedCommitment c) => switch (c.type) {
        CommitmentType.investment => 90,
        CommitmentType.savings => 90,
        CommitmentType.insurance => 80,
        CommitmentType.education => 78,
        CommitmentType.emi => 50,
        CommitmentType.rent => 45,
        CommitmentType.utility => 55,
        CommitmentType.tax => 55,
        CommitmentType.subscription => 25,
        CommitmentType.membership => 25,
        CommitmentType.other => 35,
      };

  String _goalAlignmentExplanation(DetectedCommitment c) => switch (c.type) {
        CommitmentType.investment ||
        CommitmentType.savings =>
          'Directly builds long-term wealth',
        CommitmentType.insurance => 'Protects your financial goals',
        CommitmentType.education => 'Builds future earning capacity',
        CommitmentType.emi => 'Building asset but carries debt',
        _ => 'Indirect goal alignment',
      };

  double _financialROIScore(DetectedCommitment c) {
    if (c.type == CommitmentType.investment) return 92;
    if (c.type == CommitmentType.savings) return 85;
    if (c.type == CommitmentType.insurance) return 80;
    if (c.type == CommitmentType.education) return 78;
    if (c.type == CommitmentType.utility) return 65;
    if (c.type == CommitmentType.emi) return 55;
    if (c.type == CommitmentType.subscription ||
        c.type == CommitmentType.membership) {
      return c.likelyUnused ? 10 : 40;
    }
    return 50;
  }

  String _roiExplanation(DetectedCommitment c) {
    if (c.type == CommitmentType.investment ||
        c.type == CommitmentType.savings) {
      return 'High financial return — compounds over time';
    }
    if (c.likelyUnused) return 'No usage detected — zero ROI';
    return 'Standard utility value';
  }

  double _stressImpactScore(DetectedCommitment c) {
    if (c.riskLevel == RiskLevel.high) return 20;
    if (c.riskLevel == RiskLevel.medium) return 50;
    if (c.likelyUnused &&
        (c.type == CommitmentType.subscription ||
            c.type == CommitmentType.membership)) {
      return 30;
    }
    if (c.criticality == Criticality.essential) return 85;
    return 80;
  }

  String _stressExplanation(DetectedCommitment c) {
    if (c.riskLevel == RiskLevel.high) {
      return 'High risk — overdue or unused essential';
    }
    if (c.likelyUnused) return 'Paying for unused service — wasteful';
    return 'Well-managed commitment';
  }

  double _behavioralValueScore(DetectedCommitment c) {
    if (c.type == CommitmentType.investment ||
        c.type == CommitmentType.savings) return 92;
    if (c.type == CommitmentType.education) return 80;
    if (c.type == CommitmentType.insurance) return 75;
    if (c.type == CommitmentType.membership && !c.likelyUnused) return 60;
    if (c.type == CommitmentType.subscription ||
        c.type == CommitmentType.membership) {
      return c.likelyUnused ? 8 : 55;
    }
    return 60;
  }

  String _behavioralExplanation(DetectedCommitment c) {
    if (c.type == CommitmentType.investment ||
        c.type == CommitmentType.savings) {
      return 'Builds disciplined saving habit';
    }
    if (c.likelyUnused) return 'No usage — sunk cost bias risk';
    return 'Neutral behavioral impact';
  }

  double _opportunityCostScore(DetectedCommitment c) {
    if (c.type == CommitmentType.subscription ||
        c.type == CommitmentType.membership) {
      return (100 - (c.monthlyEquivalent / 500) * 20).clamp(0, 100);
    }
    return 70;
  }

  String _ocExplanation(DetectedCommitment c) {
    if (c.type == CommitmentType.subscription ||
        c.type == CommitmentType.membership) {
      final annualCost = c.monthlyEquivalent * 12;
      return '₹${annualCost.round()}/year could compound significantly if invested';
    }
    return 'Cost is justified by necessity';
  }

  String _primaryInsight(DetectedCommitment c, CommitmentAction action) {
    if (c.type == CommitmentType.investment ||
        c.type == CommitmentType.savings) {
      return 'Builds long-term wealth — maintain or increase.';
    }
    if (c.type == CommitmentType.emi ||
        c.type == CommitmentType.rent ||
        c.type == CommitmentType.tax) {
      return 'Core financial obligation — no action needed.';
    }
    if (c.likelyUnused && action == CommitmentAction.eliminate) {
      return 'No activity detected for 2+ months — worth cancelling.';
    }
    if (action == CommitmentAction.review &&
        (c.type == CommitmentType.subscription ||
            c.type == CommitmentType.membership)) {
      return 'Review for value — consider annual billing for savings.';
    }
    if (action == CommitmentAction.keep) {
      return 'Good value for the cost — keep as-is.';
    }
    return 'Review this commitment for ongoing value.';
  }
}
