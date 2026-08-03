package com.pennywise.dto.decision;

public record RecommendedAction(
        String actionType,
        double monthlyAmount,
        String instrument,
        String timeline
) {}
