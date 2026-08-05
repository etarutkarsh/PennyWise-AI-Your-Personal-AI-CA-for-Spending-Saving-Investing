import 'package:flutter/foundation.dart';

enum CommitmentAction { keep, review, reduce, eliminate }

@immutable
class CommitmentScoreDimension {
  const CommitmentScoreDimension({
    required this.name,
    required this.score,
    required this.explanation,
    required this.weight,
  });

  final String name;
  final double score;
  final String explanation;
  final double weight;

  double get weightedScore => score * weight;
}

@immutable
class CommitmentScore {
  const CommitmentScore({
    required this.merchantKey,
    required this.displayName,
    required this.necessity,
    required this.flexibility,
    required this.goalAlignment,
    required this.financialROI,
    required this.stressImpact,
    required this.behavioralValue,
    required this.opportunityCostScore,
    required this.overallScore,
    required this.confidence,
    required this.primaryInsight,
    required this.recommendedAction,
  });

  final String merchantKey;
  final String displayName;
  final CommitmentScoreDimension necessity;
  final CommitmentScoreDimension flexibility;
  final CommitmentScoreDimension goalAlignment;
  final CommitmentScoreDimension financialROI;
  final CommitmentScoreDimension stressImpact;
  final CommitmentScoreDimension behavioralValue;
  final CommitmentScoreDimension opportunityCostScore;
  final double overallScore;
  final double confidence;
  final String primaryInsight;
  final CommitmentAction recommendedAction;
}
