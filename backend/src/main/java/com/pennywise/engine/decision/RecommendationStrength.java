package com.pennywise.engine.decision;

/** Maps a numeric confidence score (0–100) to a human-readable strength label. */
public enum RecommendationStrength {
    HIGH, MEDIUM, LOW;

    public static RecommendationStrength from(int confidence) {
        if (confidence >= 85) return HIGH;
        if (confidence >= 60) return MEDIUM;
        return LOW;
    }
}
