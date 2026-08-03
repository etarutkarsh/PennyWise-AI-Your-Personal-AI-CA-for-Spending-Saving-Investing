package com.pennywise.domain.decision;

import java.util.List;

public record DecisionResponse(
        String decisionId,
        DecisionVersioning versioning,
        DecisionData decision,
        ExplanationData explanation,
        BehavioralContextData behavioralContext,
        List<PartnerRecommendation> partnerPrograms,
        TrustData trust,
        String generatedAt
) {}
