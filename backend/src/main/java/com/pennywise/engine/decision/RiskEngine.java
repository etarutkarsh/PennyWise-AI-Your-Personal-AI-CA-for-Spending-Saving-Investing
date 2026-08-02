package com.pennywise.engine.decision;

import org.springframework.stereotype.Component;
import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * Evaluates individual risk dimensions.
 * Each method returns a 0–5 integer (bars on the Risk Meter UI).
 */
@Component("decisionRiskEngine")
public class RiskEngine {

    private static final BigDecimal EF_MONTHS_TARGET = BigDecimal.valueOf(6);

    /** Liquidity risk: how thin is the emergency fund after the purchase? */
    public int liquidityRisk(BigDecimal efAfterPurchase, BigDecimal avgMonthlyExpenses) {
        if (avgMonthlyExpenses.compareTo(BigDecimal.ZERO) <= 0) return 3;
        BigDecimal months = efAfterPurchase.divide(avgMonthlyExpenses, 2, RoundingMode.HALF_UP);
        if (months.compareTo(BigDecimal.ONE) < 0) return 5;
        if (months.compareTo(BigDecimal.valueOf(2)) < 0) return 4;
        if (months.compareTo(BigDecimal.valueOf(4)) < 0) return 3;
        if (months.compareTo(BigDecimal.valueOf(6)) < 0) return 2;
        return 1;
    }

    /** Debt risk: how high is the total debt-to-income ratio? */
    public int debtRisk(BigDecimal dtiPercent) {
        if (dtiPercent.compareTo(BigDecimal.valueOf(50)) > 0) return 5;
        if (dtiPercent.compareTo(BigDecimal.valueOf(40)) > 0) return 4;
        if (dtiPercent.compareTo(BigDecimal.valueOf(36)) > 0) return 3;
        if (dtiPercent.compareTo(BigDecimal.valueOf(20)) > 0) return 2;
        return 1;
    }

    /** Income risk: how much free surplus remains relative to income? */
    public int incomeRisk(BigDecimal surplusAfterEmi, BigDecimal monthlyIncome) {
        if (monthlyIncome.compareTo(BigDecimal.ZERO) <= 0) return 3;
        BigDecimal ratio = surplusAfterEmi.divide(monthlyIncome, 4, RoundingMode.HALF_UP);
        if (ratio.compareTo(BigDecimal.valueOf(0.05)) < 0) return 5;
        if (ratio.compareTo(BigDecimal.valueOf(0.10)) < 0) return 4;
        if (ratio.compareTo(BigDecimal.valueOf(0.20)) < 0) return 3;
        if (ratio.compareTo(BigDecimal.valueOf(0.35)) < 0) return 2;
        return 1;
    }

    /** Overall risk level 1–5 used for confidence scoring adjustments. */
    public int overall(int liquidity, int debt, int income) {
        return (int) Math.round((liquidity + debt + income) / 3.0);
    }
}
