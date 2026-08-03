// Defines BehavioralVector — the θ_user parameter vector from Kahneman/Prospect Theory research.

import 'package:flutter/foundation.dart';

/// The behavioral parameter vector describing a user's financial psychology.
/// All fields are calibrated by the Behavioral Engine; use [BehavioralVector.uncalibrated]
/// before the engine is built.
@immutable
class BehavioralVector {
  /// Loss aversion coefficient λ (default 1.8 — Kahneman/Tversky baseline).
  final double lossAversion;

  /// Risk tolerance drift R_t (0.0 = fully risk-averse, 1.0 = fully risk-seeking).
  final double riskToleranceDrift;

  /// Impulse spending volatility I_v.
  final double impulseVolatility;

  /// Present bias β (hyperbolic discounting — lower = more present-biased).
  final double presentBias;

  /// Overconfidence calibration O_c (higher = more overconfident).
  final double overconfidenceCalib;

  /// Status quo bias σ (resistance to change default options).
  final double statusQuoBias;

  /// Mental accounting rigidity μ (tendency to treat money in separate buckets).
  final double mentalAccountingRigidity;

  /// Regret aversion ρ (avoidance of decisions that might be regretted).
  final double regretAversion;

  /// Salience susceptibility s (reaction to prominent/vivid financial information).
  final double salienceSusceptibility;

  /// Hyperbolic discounting γ.
  final double hyperbolicDiscounting;

  const BehavioralVector({
    required this.lossAversion,
    required this.riskToleranceDrift,
    required this.impulseVolatility,
    required this.presentBias,
    required this.overconfidenceCalib,
    required this.statusQuoBias,
    required this.mentalAccountingRigidity,
    required this.regretAversion,
    required this.salienceSusceptibility,
    required this.hyperbolicDiscounting,
  });

  /// Default uncalibrated vector used before the Behavioral Engine computes real values.
  static const BehavioralVector uncalibrated = BehavioralVector(
    lossAversion: 1.8,
    riskToleranceDrift: 0.5,
    impulseVolatility: 0.5,
    presentBias: 0.7,
    overconfidenceCalib: 0.5,
    statusQuoBias: 0.5,
    mentalAccountingRigidity: 0.5,
    regretAversion: 0.5,
    salienceSusceptibility: 0.5,
    hyperbolicDiscounting: 0.5,
  );

  BehavioralVector copyWith({
    double? lossAversion,
    double? riskToleranceDrift,
    double? impulseVolatility,
    double? presentBias,
    double? overconfidenceCalib,
    double? statusQuoBias,
    double? mentalAccountingRigidity,
    double? regretAversion,
    double? salienceSusceptibility,
    double? hyperbolicDiscounting,
  }) =>
      BehavioralVector(
        lossAversion: lossAversion ?? this.lossAversion,
        riskToleranceDrift: riskToleranceDrift ?? this.riskToleranceDrift,
        impulseVolatility: impulseVolatility ?? this.impulseVolatility,
        presentBias: presentBias ?? this.presentBias,
        overconfidenceCalib: overconfidenceCalib ?? this.overconfidenceCalib,
        statusQuoBias: statusQuoBias ?? this.statusQuoBias,
        mentalAccountingRigidity: mentalAccountingRigidity ?? this.mentalAccountingRigidity,
        regretAversion: regretAversion ?? this.regretAversion,
        salienceSusceptibility: salienceSusceptibility ?? this.salienceSusceptibility,
        hyperbolicDiscounting: hyperbolicDiscounting ?? this.hyperbolicDiscounting,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BehavioralVector &&
          other.lossAversion == lossAversion &&
          other.riskToleranceDrift == riskToleranceDrift &&
          other.impulseVolatility == impulseVolatility &&
          other.presentBias == presentBias);

  @override
  int get hashCode => Object.hash(
        lossAversion,
        riskToleranceDrift,
        impulseVolatility,
        presentBias,
        overconfidenceCalib,
        statusQuoBias,
      );

  @override
  String toString() =>
      'BehavioralVector(λ=$lossAversion, R_t=$riskToleranceDrift, β=$presentBias)';
}
