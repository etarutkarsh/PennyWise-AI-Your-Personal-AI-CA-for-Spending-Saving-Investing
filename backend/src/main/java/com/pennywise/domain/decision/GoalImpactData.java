package com.pennywise.domain.decision;

public record GoalImpactData(
        int healthScoreCurrent,
        int healthScoreAfter,
        int goalSuccessRateCurrent,
        int goalSuccessRateAfter,
        int runwayMonthsAdded,
        double monthlySavingsIncrease
) {}
