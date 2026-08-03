package com.pennywise.domain.decision;

public record PartnerRecommendation(
        String programId,
        String partnerName,
        String productName,
        String keyMetric,
        String keyMetricLabel,
        double returnRate,
        double minAmount,
        String riskLevel,
        boolean taxBenefit,
        int rank,
        double matchScore,
        String matchExplanation,
        String trustStatement,
        String ctaLabel
) {}
