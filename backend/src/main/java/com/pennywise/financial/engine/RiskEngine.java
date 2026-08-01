package com.pennywise.financial.engine;

import com.pennywise.financial.model.RiskCapacityInput;
import com.pennywise.financial.model.RiskCategory;
import com.pennywise.financial.model.RiskProfile;
import com.pennywise.financial.model.RiskWillingnessInput;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

/**
 * Two-layer risk assessment engine.
 *
 * Layer 1: Psychographic willingness (how much risk the investor WANTS to take).
 * Layer 2: Financial capacity (how much risk they CAN AFFORD to take).
 *
 * Final score = min(willingness, capacity). Capacity is the hard ceiling because
 * no amount of risk appetite makes it prudent to invest aggressively when financially fragile.
 *
 * Reference: Kitces Research on risk tolerance; SEBI investor suitability framework.
 */
@Service
public class RiskEngine {

    /**
     * Full two-layer risk assessment.
     *
     * @param willingness psychographic questionnaire responses
     * @param capacity    financial facts about the investor
     * @return RiskProfile with scores, category, rationale and capacity constraints
     */
    public RiskProfile assess(RiskWillingnessInput willingness, RiskCapacityInput capacity) {
        List<String> constraints = new ArrayList<>();
        int willingnessScore = scoreWillingness(willingness);
        int capacityScore = scoreCapacity(capacity, constraints);
        int finalScore = Math.min(willingnessScore, capacityScore);

        RiskCategory category = RiskCategory.fromScore(finalScore);

        String rationale = buildRationale(willingnessScore, capacityScore, finalScore, category, constraints);

        return new RiskProfile(willingnessScore, capacityScore, finalScore, category, rationale, constraints);
    }

    /**
     * Scores investor willingness on a 0–100 scale using weighted Likert inputs.
     *
     * Weights (must sum to 1.0):
     *   lossReaction:         30% — most predictive of actual behaviour
     *   timeHorizon:          25%
     *   volatilityComfort:    20%
     *   investmentExperience: 15%
     *   goalFlexibility:      10%
     *
     * Each dimension score is (raw - 1) / 4 * 100, then weighted.
     */
    public int scoreWillingness(RiskWillingnessInput input) {
        double lossReactionNorm      = normalize(input.lossReaction());
        double timeHorizonNorm       = normalize(input.timeHorizon());
        double volatilityComfortNorm = normalize(input.volatilityComfort());
        double experienceNorm        = normalize(input.investmentExperience());
        double goalFlexNorm          = normalize(input.goalFlexibility());

        double weighted =
                lossReactionNorm      * 0.30 +
                timeHorizonNorm       * 0.25 +
                volatilityComfortNorm * 0.20 +
                experienceNorm        * 0.15 +
                goalFlexNorm          * 0.10;

        return clamp((int) Math.round(weighted * 100));
    }

    /**
     * Scores financial capacity on a 0–100 scale by penalizing risk factors.
     * Collects reasons when capacity falls below willingness.
     *
     * @param input       financial facts
     * @param constraints mutable list that receives constraint descriptions
     */
    public int scoreCapacity(RiskCapacityInput input, List<String> constraints) {
        int score = 100;

        // ── Debt burden ──────────────────────────────────────────────────────
        double annualIncome = input.monthlyIncome() * 12;
        if (annualIncome > 0) {
            double debtToIncome = input.totalDebt() / annualIncome;
            if (debtToIncome > 0.50) {
                score -= 30;
                constraints.add("High debt burden (DTI > 50%)");
            } else if (debtToIncome > 0.35) {
                score -= 15;
                constraints.add("Elevated debt burden (DTI > 35%)");
            } else if (debtToIncome > 0.20) {
                score -= 5;
            }
        }

        // ── Emergency fund ───────────────────────────────────────────────────
        if (!input.hasEmergencyFund()) {
            score -= 20;
            constraints.add("No emergency cushion (need ≥ 3 months' expenses)");
        } else {
            double months = (input.monthlyExpenses() > 0)
                    ? input.totalSavings() / input.monthlyExpenses()
                    : 6.0;
            if (months < 3) {
                score -= 10;
                constraints.add("Emergency fund below 3 months of expenses");
            }
        }

        // ── Dependents ───────────────────────────────────────────────────────
        if (input.dependents() == 0) {
            // No penalty
        } else if (input.dependents() == 1) {
            score -= 5;
        } else if (input.dependents() == 2) {
            score -= 10;
        } else {
            score -= 20;
            constraints.add("Multiple dependents reduce capacity for risk");
        }

        // ── Job stability ────────────────────────────────────────────────────
        if (!input.hasStableJob()) {
            score -= 15;
            constraints.add("Variable income — reduces ability to sustain losses");
        }

        // ── Savings buffer ───────────────────────────────────────────────────
        if (input.monthlyExpenses() > 0) {
            double savingsMonths = input.totalSavings() / input.monthlyExpenses();
            if (savingsMonths < 1) {
                score -= 10;
                constraints.add("Liquid savings cover less than 1 month of expenses");
            } else if (savingsMonths > 6) {
                score += 5; // Healthy buffer bonus
            }
        }

        // ── Time to major goal ───────────────────────────────────────────────
        if (input.yearsToMajorGoal() < 1) {
            score -= 20;
            constraints.add("Major goal within 1 year — capital preservation priority");
        } else if (input.yearsToMajorGoal() < 3) {
            score -= 10;
            constraints.add("Major goal within 3 years — limit equity exposure");
        } else if (input.yearsToMajorGoal() > 7) {
            score += 5; // Long horizon bonus
        }

        return clamp(score);
    }

    // ── Private helpers ──────────────────────────────────────────────────────

    /** Normalises a 1–5 Likert value to 0.0–1.0. */
    private double normalize(int likert) {
        int clamped = Math.max(1, Math.min(5, likert));
        return (clamped - 1) / 4.0;
    }

    /** Clamps a score to the 0–100 range. */
    private int clamp(int score) {
        return Math.max(0, Math.min(100, score));
    }

    private String buildRationale(int willingness, int capacity, int finalScore,
                                   RiskCategory category, List<String> constraints) {
        StringBuilder sb = new StringBuilder();
        sb.append("Risk profile: ").append(category.name()).append(" (score: ").append(finalScore).append("/100). ");
        sb.append("Willingness: ").append(willingness).append(", Capacity: ").append(capacity).append(". ");

        if (capacity < willingness) {
            sb.append("Your financial capacity (").append(capacity)
              .append(") is the binding constraint — it is lower than your risk appetite (")
              .append(willingness).append("). ");
            if (!constraints.isEmpty()) {
                sb.append("Key constraints: ").append(String.join("; ", constraints)).append(".");
            }
        } else if (willingness < capacity) {
            sb.append("Your risk appetite (").append(willingness)
              .append(") is more conservative than your financial capacity (")
              .append(capacity).append(") — this is fine; never invest beyond your comfort zone.");
        } else {
            sb.append("Your willingness and capacity are well-aligned.");
        }

        return sb.toString();
    }
}
