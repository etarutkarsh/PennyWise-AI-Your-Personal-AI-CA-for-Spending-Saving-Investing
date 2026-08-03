package com.pennywise.dto.decision;

import java.util.List;

public record TodayDecisionResponse(
        String decisionId,
        String headline,
        String subheadline,
        String priority,
        String icon,
        List<String> reasons,
        DecisionImpact impact,
        RecommendedAction recommendedAction,
        List<PartnerOption> partnerOptions
) {}
