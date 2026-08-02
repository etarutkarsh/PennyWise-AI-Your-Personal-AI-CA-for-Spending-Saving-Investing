package com.pennywise.engine.decision;

import com.pennywise.dto.GoalImpactDto;
import com.pennywise.entity.Goal;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Computes how a recommended purchase scenario affects each of the user's active goals.
 *
 * Logic:
 *  - surplusRatio = surplusAfterPurchase / grossSurplus
 *  - Adjusted monthly contribution = original * surplusRatio
 *  - months to target now vs after → delta = monthsDelayed
 *  - 12-month projected progress % for the "after" state
 */
@Component
public class GoalImpactEngine {

    public List<GoalImpactDto> evaluate(
            List<Goal> goals,
            BigDecimal grossSurplus,
            BigDecimal surplusAfterPurchase,
            BigDecimal immediateOutflow,  // cash out today: down payment or full price
            BigDecimal currentEmergencyFund
    ) {
        double surplusRatio = computeSurplusRatio(grossSurplus, surplusAfterPurchase);

        return goals.stream()
                .filter(g -> !g.isAchieved())
                .filter(g -> g.getTargetAmount() != null && g.getTargetAmount().compareTo(BigDecimal.ZERO) > 0)
                .map(g -> evaluateGoal(g, surplusRatio))
                .collect(Collectors.toList());
    }

    private double computeSurplusRatio(BigDecimal grossSurplus, BigDecimal surplusAfterPurchase) {
        if (grossSurplus == null || grossSurplus.compareTo(BigDecimal.ZERO) <= 0) return 1.0;
        double ratio = surplusAfterPurchase
                .divide(grossSurplus, 6, RoundingMode.HALF_UP)
                .doubleValue();
        return Math.max(0.0, Math.min(1.0, ratio));
    }

    private GoalImpactDto evaluateGoal(Goal goal, double surplusRatio) {
        BigDecimal target = goal.getTargetAmount();
        BigDecimal saved = orZero(goal.getCurrentSaved());
        BigDecimal contrib = orZero(goal.getRecommendedMonthlyContribution());

        double currentPct = saved.divide(target, 6, RoundingMode.HALF_UP).doubleValue() * 100.0;
        currentPct = Math.min(100.0, currentPct);

        BigDecimal remaining = target.subtract(saved).max(BigDecimal.ZERO);

        Integer monthsNow = computeMonthsToTarget(remaining, contrib);

        BigDecimal adjustedContrib = contrib
                .multiply(BigDecimal.valueOf(surplusRatio))
                .setScale(2, RoundingMode.HALF_UP);

        Integer monthsAfter = computeMonthsToTarget(remaining, adjustedContrib);

        // 12-month projected progress under the post-purchase contribution rate
        double projectedPct;
        if (adjustedContrib.compareTo(BigDecimal.ZERO) > 0) {
            BigDecimal savedIn12Months = saved.add(adjustedContrib.multiply(BigDecimal.valueOf(12)));
            projectedPct = savedIn12Months.min(target)
                    .divide(target, 6, RoundingMode.HALF_UP)
                    .doubleValue() * 100.0;
        } else {
            projectedPct = currentPct;
        }
        projectedPct = Math.min(100.0, projectedPct);

        int monthsDelayed = 0;
        if (monthsNow != null && monthsAfter != null) {
            monthsDelayed = monthsAfter - monthsNow;
        } else if (monthsNow != null) {
            // contribution stalled — treat as severely delayed
            monthsDelayed = Integer.MAX_VALUE / 2;
        }

        String statusChange = classifyStatus(monthsDelayed, surplusRatio);

        return GoalImpactDto.builder()
                .goalName(goal.getName())
                .goalType(goal.getGoalType())
                .currentProgressPct(round1(currentPct))
                .projectedProgressPct(round1(projectedPct))
                .monthsToTargetNow(monthsNow)
                .monthsToTargetAfter(monthsAfter)
                .monthsDelayed(monthsDelayed == Integer.MAX_VALUE / 2 ? 999 : monthsDelayed)
                .statusChange(statusChange)
                .build();
    }

    private Integer computeMonthsToTarget(BigDecimal remaining, BigDecimal monthlyContrib) {
        if (remaining.compareTo(BigDecimal.ZERO) <= 0) return 0;
        if (monthlyContrib.compareTo(BigDecimal.ZERO) <= 0) return null;
        return remaining.divide(monthlyContrib, 0, RoundingMode.CEILING).intValue();
    }

    private String classifyStatus(int monthsDelayed, double surplusRatio) {
        if (monthsDelayed <= 1) return "UNAFFECTED";
        if (monthsDelayed < 0) return "ACCELERATED";
        if (surplusRatio <= 0.05) return "AT_RISK";
        if (monthsDelayed <= 3) return "DELAYED";
        return "AT_RISK";
    }

    private double round1(double v) {
        return Math.round(v * 10.0) / 10.0;
    }

    private static BigDecimal orZero(BigDecimal v) {
        return v != null ? v : BigDecimal.ZERO;
    }
}
