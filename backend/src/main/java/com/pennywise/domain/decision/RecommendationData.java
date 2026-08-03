package com.pennywise.domain.decision;

public record RecommendationData(
        String actionType,
        double monthlyAmount,
        String instrument,
        String timeline,
        double confidenceScore
) {}
