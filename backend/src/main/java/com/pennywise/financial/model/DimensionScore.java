package com.pennywise.financial.model;

/**
 * Score for a single financial health dimension.
 */
public record DimensionScore(
        String dimension,
        int score,
        int maxScore,
        String status,           // "Excellent", "Good", "Fair", "Poor"
        String insight,          // specific insight about the user's situation
        String recommendation    // actionable advice to improve this dimension
) {}
