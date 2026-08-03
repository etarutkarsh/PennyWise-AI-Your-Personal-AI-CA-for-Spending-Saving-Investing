// Defines FeatureFlag, RolloutTier, and PennyWiseFeatureFlags with production defaults.

import 'package:flutter/foundation.dart';
import 'engine_flags.dart';

/// Rollout tier controlling who sees a feature.
enum RolloutTier {
  experimental,
  beta,
  production,
  premiumOnly,
}

/// A feature flag binding an engine to its enabled state and rollout tier.
@immutable
class FeatureFlag {
  final EngineFlag engine;
  final bool enabled;
  final RolloutTier tier;

  const FeatureFlag({
    required this.engine,
    required this.enabled,
    required this.tier,
  });

  FeatureFlag copyWith({
    EngineFlag? engine,
    bool? enabled,
    RolloutTier? tier,
  }) =>
      FeatureFlag(
        engine: engine ?? this.engine,
        enabled: enabled ?? this.enabled,
        tier: tier ?? this.tier,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FeatureFlag &&
          other.engine == engine &&
          other.enabled == enabled &&
          other.tier == tier);

  @override
  int get hashCode => Object.hash(engine, enabled, tier);

  @override
  String toString() => 'FeatureFlag(engine: $engine, enabled: $enabled, tier: $tier)';
}

/// Hardcoded defaults representing what is enabled in production today.
class PennyWiseFeatureFlags {
  PennyWiseFeatureFlags._();

  static const Map<EngineFlag, bool> defaults = {
    EngineFlag.decisionEngineV1: true,
    EngineFlag.smsIntelligence: true,
    EngineFlag.decisionEngineV2: false,
    EngineFlag.behavioralEngine: false,
    EngineFlag.digitalTwin: false,
    EngineFlag.partnerMatchingEngine: false,
    EngineFlag.knowledgeGraph: false,
    EngineFlag.healthEngineV2: false,
    EngineFlag.accountAggregator: false,
    EngineFlag.stepUpSipFormula: false,
    EngineFlag.monteCarlo: false,
    EngineFlag.explainability: false,
    EngineFlag.eventSourcing: false,
    EngineFlag.subscriptionIntelligence: false,
    EngineFlag.academyAi: false,
  };

  static bool isEnabled(EngineFlag flag) => defaults[flag] ?? false;
}
