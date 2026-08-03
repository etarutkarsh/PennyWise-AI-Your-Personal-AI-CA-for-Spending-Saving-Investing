package com.pennywise.domain.decision;

public record DecisionData(
        String type,
        String headline,
        String subheadline,
        String priority,
        String icon,
        RecommendationData recommendation,
        GoalImpactData goalImpact
) {}
