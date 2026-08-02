package com.pennywise.engine.decision;

import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;

/**
 * Generates plain-English "Why This?" and "Why Not?" bullets for each scenario.
 * All explanation logic lives here — the UI renders, never invents.
 */
@Component
public class ExplainabilityEngine {

    private static final BigDecimal EF_TARGET_MONTHS = BigDecimal.valueOf(6);

    /**
     * Reasons to choose this scenario (positive case).
     */
    public List<String> whyThis(String verdict, BigDecimal confidence,
                                  BigDecimal dtiRatio, BigDecimal efAfterPurchase,
                                  BigDecimal avgMonthlyExpenses, BigDecimal surplusAfterEmi,
                                  BigDecimal monthlyIncome, String scenarioLabel) {
        List<String> reasons = new ArrayList<>();

        if ("SAFE_TO_BUY".equals(verdict)) {
            reasons.add("Emergency fund stays above the 6-month safety floor");
            if (dtiRatio.compareTo(BigDecimal.valueOf(36)) <= 0) {
                reasons.add("Debt-to-income ratio remains healthy at " + dtiRatio + "%");
            }
            if (monthlyIncome.compareTo(BigDecimal.ZERO) > 0) {
                BigDecimal surplusRatio = surplusAfterEmi.divide(monthlyIncome, 2, RoundingMode.HALF_UP)
                        .multiply(BigDecimal.valueOf(100));
                if (surplusRatio.compareTo(BigDecimal.valueOf(20)) >= 0) {
                    reasons.add(surplusRatio.setScale(0, RoundingMode.HALF_UP) + "% of income remains as free surplus");
                }
            }
        } else if ("WAIT_AND_SAVE".equals(verdict)) {
            if (avgMonthlyExpenses.compareTo(BigDecimal.ZERO) > 0) {
                BigDecimal efMonths = efAfterPurchase.divide(avgMonthlyExpenses, 1, RoundingMode.HALF_UP);
                if (efMonths.compareTo(EF_TARGET_MONTHS) >= 0) {
                    reasons.add("Emergency fund reaches " + efMonths + " months — above the safety floor");
                }
            }
            if (scenarioLabel.startsWith("Wait")) {
                reasons.add("Saving period improves financial cushion before commitment");
                reasons.add("Confidence improves with time — lower financial stress");
            }
        }

        if (confidence.compareTo(BigDecimal.valueOf(85)) >= 0) {
            reasons.add("High confidence — decision aligns with your financial profile");
        } else if (confidence.compareTo(BigDecimal.valueOf(70)) >= 0) {
            reasons.add("Moderate confidence — manageable risk with current income");
        }

        return reasons.isEmpty() ? List.of("Based on your current financial profile") : reasons;
    }

    /**
     * Reasons NOT to choose this scenario (counter-case).
     * For the recommended scenario, this is empty.
     */
    public List<String> whyNot(String verdict, int confidence, BigDecimal dtiRatio,
                                BigDecimal efAfterPurchase, BigDecimal avgMonthlyExpenses,
                                BigDecimal surplusAfterEmi, BigDecimal monthlyIncome,
                                boolean isRecommended, String recommendedLabel,
                                BigDecimal totalInterest) {
        if (isRecommended) return List.of();

        List<String> reasons = new ArrayList<>();

        if ("DONT_BUY".equals(verdict)) {
            reasons.add("Financial risk too high with current income and commitments");
        }

        if (avgMonthlyExpenses.compareTo(BigDecimal.ZERO) > 0) {
            BigDecimal efMonths = efAfterPurchase.divide(avgMonthlyExpenses, 1, RoundingMode.HALF_UP);
            if (efMonths.compareTo(BigDecimal.valueOf(3)) < 0) {
                reasons.add("Emergency fund falls critically low — less than 3 months of cover");
            } else if (efMonths.compareTo(EF_TARGET_MONTHS) < 0) {
                reasons.add("Emergency fund drops below the 6-month safety floor");
            }
        }

        if (dtiRatio.compareTo(BigDecimal.valueOf(40)) > 0) {
            reasons.add("Debt-to-income of " + dtiRatio + "% exceeds the recommended 40% ceiling");
        }

        if (monthlyIncome.compareTo(BigDecimal.ZERO) > 0) {
            BigDecimal surplusRatio = surplusAfterEmi.divide(monthlyIncome, 2, RoundingMode.HALF_UP)
                    .multiply(BigDecimal.valueOf(100));
            if (surplusRatio.compareTo(BigDecimal.valueOf(10)) < 0) {
                reasons.add("Less than 10% of income left as buffer — leaves no room for unexpected costs");
            }
        }

        if (confidence < 60) {
            reasons.add("Low recommendation strength — better alternatives exist");
        }

        if (!recommendedLabel.isEmpty() && !recommendedLabel.equals("unknown")) {
            reasons.add("'" + recommendedLabel + "' achieves a better financial outcome");
        }

        return reasons.isEmpty()
                ? List.of("A better-scoring option is available")
                : reasons;
    }

    /**
     * Positive evidence bullets for the RecommendationStrength display.
     */
    public List<String> strengthEvidence(int confidence, BigDecimal dtiRatio,
                                          BigDecimal efAfterPurchase, BigDecimal avgMonthlyExpenses,
                                          BigDecimal surplusAfterEmi, BigDecimal monthlyIncome) {
        List<String> evidence = new ArrayList<>();

        if (monthlyIncome.compareTo(BigDecimal.ZERO) > 0) {
            evidence.add("Stable income of ₹" + monthlyIncome.setScale(0, RoundingMode.HALF_UP) + "/month");
        }

        if (avgMonthlyExpenses.compareTo(BigDecimal.ZERO) > 0) {
            BigDecimal surplusRatio = surplusAfterEmi.divide(monthlyIncome.max(BigDecimal.ONE), 2, RoundingMode.HALF_UP)
                    .multiply(BigDecimal.valueOf(100));
            if (surplusRatio.compareTo(BigDecimal.valueOf(20)) >= 0) {
                evidence.add("Healthy monthly surplus (" + surplusRatio.setScale(0, RoundingMode.HALF_UP) + "% of income)");
            }
        }

        if (avgMonthlyExpenses.compareTo(BigDecimal.ZERO) > 0) {
            BigDecimal efMonths = efAfterPurchase.divide(avgMonthlyExpenses, 1, RoundingMode.HALF_UP);
            if (efMonths.compareTo(EF_TARGET_MONTHS) >= 0) {
                evidence.add("Emergency fund above 6-month target (" + efMonths + " months)");
            }
        }

        if (dtiRatio.compareTo(BigDecimal.valueOf(36)) <= 0) {
            evidence.add("Low debt burden — DTI " + dtiRatio + "% (well within limits)");
        }

        if (evidence.isEmpty()) {
            evidence.add("Based on current financial snapshot");
        }

        return evidence;
    }
}
