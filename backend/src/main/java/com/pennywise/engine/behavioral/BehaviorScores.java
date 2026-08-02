package com.pennywise.engine.behavioral;

import lombok.Builder;
import lombok.Value;

import java.util.Set;

/**
 * Immutable value object holding all computed behavioral scores and patterns.
 * Computed in-memory during a behavioral analysis pass; never persisted directly.
 */
@Builder
@Value
public class BehaviorScores {
    int disciplineScore;
    int consistencyScore;
    int impulseScore;
    int riskBehaviorScore;
    int goalCommitmentScore;
    int savingsDisciplineScore;
    int spendingStabilityScore;
    int recommendationFollowRate;
    Set<BehaviorPattern> patterns;
    int eventsAnalyzed;
    int decisionsAnalyzed;
    int monthsOfData;
}
