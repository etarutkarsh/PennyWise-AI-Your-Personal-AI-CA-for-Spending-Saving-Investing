package com.pennywise.engine.memory;

import org.springframework.stereotype.Component;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;

@Component
public class DecisionAccuracyEngine {

    /**
     * Scores how accurate a numeric prediction was (0–100).
     * A delta of 0 = 100%, delta of ±3 = ~75%, delta of ±10 = ~40%.
     */
    public double scoreNumericPrediction(double predicted, double actual) {
        if (predicted == 0 && actual == 0) return 100.0;
        double range = Math.max(Math.abs(predicted), Math.abs(actual));
        if (range == 0) return 100.0;
        double error = Math.abs(predicted - actual) / range;
        return Math.max(0, (1.0 - error) * 100.0);
    }

    /**
     * Scores recommendation follow-through and outcome quality.
     * followedRecommendation: did the user do what was suggested?
     * healthDelta: actual change in financial health score
     * predictedHealthDelta: what was implied by the recommendation
     */
    public BigDecimal computeOverallAccuracy(boolean followedRecommendation,
                                              Integer healthDelta,
                                              int predictedHealthDelta) {
        if (!followedRecommendation) {
            // Can't score accuracy if they didn't follow the recommendation
            return BigDecimal.valueOf(0);
        }
        if (healthDelta == null) {
            return BigDecimal.valueOf(50); // neutral / unverified
        }
        double score = scoreNumericPrediction(predictedHealthDelta, healthDelta);
        return BigDecimal.valueOf(score).setScale(2, RoundingMode.HALF_UP);
    }

    /**
     * Derives behavioral lessons from an outcome.
     */
    public List<String> deriveLessons(boolean followed, Integer healthDelta,
                                       String recommendation, String itemName) {
        List<String> lessons = new ArrayList<>();
        if (!followed) {
            lessons.add("User chose differently than recommended for " + itemName);
        }
        if (healthDelta != null) {
            if (healthDelta < -5) lessons.add("Financial health dropped after this decision — validate recommendation logic");
            else if (healthDelta > 5) lessons.add("Financial health improved after this decision — recommendation was accurate");
            else lessons.add("Financial health remained stable after this decision");
        }
        return lessons;
    }
}
