package com.pennywise.financial.model;

/**
 * Risk category buckets mapped from a 0–100 composite score.
 * The final score is min(willingnessScore, capacityScore) — capacity is the ceiling.
 */
public enum RiskCategory {
    CONSERVATIVE(0, 35),
    MODERATE(36, 60),
    AGGRESSIVE(61, 80),
    VERY_AGGRESSIVE(81, 100);

    public final int minScore;
    public final int maxScore;

    RiskCategory(int minScore, int maxScore) {
        this.minScore = minScore;
        this.maxScore = maxScore;
    }

    /**
     * Resolve category from a 0–100 score.
     */
    public static RiskCategory fromScore(int score) {
        for (RiskCategory cat : values()) {
            if (score >= cat.minScore && score <= cat.maxScore) return cat;
        }
        return CONSERVATIVE;
    }
}
