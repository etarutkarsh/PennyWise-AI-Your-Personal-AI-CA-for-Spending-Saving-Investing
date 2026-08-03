package com.pennywise.dto.decision;

public record DecisionImpact(
        int healthScoreCurrent,
        int healthScoreAfter,
        int goalSuccessRateCurrent,
        int goalSuccessRateAfter,
        int runwayMonthsAdded,
        double monthlySavingsIncrease
) {}
