package com.pennywise.financial.model;

import java.util.List;

/**
 * Composite 8-dimension financial health score result.
 */
public record HealthScoreResult(
        int totalScore,
        int maxScore,
        String grade,           // A+, A, B+, B, C, D
        String summary,
        List<DimensionScore> dimensions,
        List<String> topActions  // top 3 actions to improve the score
) {}
