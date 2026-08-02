package com.pennywise.engine.decision;

import com.pennywise.dto.TradeoffDto;
import com.pennywise.dto.TradeoffDto.TradeoffType;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;

/** Generates human-readable tradeoff bullets for each scenario. */
@Component
public class TradeoffEngine {

    public List<TradeoffDto> forScenario(String scenarioLabel,
                                          BigDecimal scenarioEmi,
                                          BigDecimal baselineEmi,
                                          BigDecimal totalInterest,
                                          BigDecimal baselineInterest,
                                          BigDecimal efAfterPurchase,
                                          BigDecimal avgMonthlyExpenses,
                                          BigDecimal surplusAfterEmi,
                                          BigDecimal monthlyIncome,
                                          boolean isRecommended) {
        List<TradeoffDto> list = new ArrayList<>();

        // EMI comparison
        if (scenarioEmi != null && baselineEmi != null && baselineEmi.compareTo(BigDecimal.ZERO) > 0) {
            BigDecimal emiDelta = baselineEmi.subtract(scenarioEmi);
            if (emiDelta.abs().compareTo(BigDecimal.valueOf(500)) > 0) {
                if (emiDelta.compareTo(BigDecimal.ZERO) > 0) {
                    list.add(TradeoffDto.pro("Lower monthly EMI by ₹" + emiDelta.setScale(0, RoundingMode.HALF_UP)));
                } else {
                    list.add(TradeoffDto.con("Higher monthly EMI by ₹" + emiDelta.abs().setScale(0, RoundingMode.HALF_UP)));
                }
            }
        }

        // Interest comparison
        if (totalInterest != null && baselineInterest != null) {
            BigDecimal interestDelta = totalInterest.subtract(baselineInterest);
            if (interestDelta.abs().compareTo(BigDecimal.valueOf(5000)) > 0) {
                if (interestDelta.compareTo(BigDecimal.ZERO) < 0) {
                    list.add(TradeoffDto.pro("Saves ₹" + interestDelta.abs().setScale(0, RoundingMode.HALF_UP) + " in total interest"));
                } else {
                    list.add(TradeoffDto.con("₹" + interestDelta.setScale(0, RoundingMode.HALF_UP) + " more in total interest"));
                }
            }
        }

        // Emergency fund
        if (avgMonthlyExpenses.compareTo(BigDecimal.ZERO) > 0) {
            BigDecimal efMonths = efAfterPurchase.divide(avgMonthlyExpenses, 1, RoundingMode.HALF_UP);
            if (efMonths.compareTo(BigDecimal.valueOf(6)) >= 0) {
                list.add(TradeoffDto.pro("Emergency fund stays above 6-month safety floor (" + efMonths + " months)"));
            } else if (efMonths.compareTo(BigDecimal.valueOf(3)) >= 0) {
                list.add(TradeoffDto.con("Emergency fund drops to " + efMonths + " months (below 6-month target)"));
            } else {
                list.add(TradeoffDto.con("Emergency fund critically low at " + efMonths + " months"));
            }
        }

        // Surplus / breathing room
        if (monthlyIncome.compareTo(BigDecimal.ZERO) > 0) {
            BigDecimal surplusRatio = surplusAfterEmi.divide(monthlyIncome, 2, RoundingMode.HALF_UP)
                    .multiply(BigDecimal.valueOf(100)).setScale(0, RoundingMode.HALF_UP);
            if (surplusRatio.compareTo(BigDecimal.valueOf(30)) >= 0) {
                list.add(TradeoffDto.pro(surplusRatio + "% of income remains free — good breathing room"));
            } else if (surplusRatio.compareTo(BigDecimal.valueOf(15)) < 0) {
                list.add(TradeoffDto.con("Only " + surplusRatio + "% income left as free surplus — very tight"));
            }
        }

        // Label-specific tradeoffs
        if (scenarioLabel.startsWith("Wait")) {
            list.add(TradeoffDto.con("Delayed purchase — opportunity cost of waiting"));
            list.add(TradeoffDto.pro("Lower financial stress during saving period"));
        }
        if (scenarioLabel.contains("Extend") || scenarioLabel.contains("-Yr")) {
            list.add(TradeoffDto.con("Longer loan duration — more months of debt obligation"));
        }
        if (scenarioLabel.contains("Down Payment")) {
            list.add(TradeoffDto.con("Larger upfront cash outlay required"));
            list.add(TradeoffDto.pro("Lower principal reduces total interest burden"));
        }

        return list;
    }
}
