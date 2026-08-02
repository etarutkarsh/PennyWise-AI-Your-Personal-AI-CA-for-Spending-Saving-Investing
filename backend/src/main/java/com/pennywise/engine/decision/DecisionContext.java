package com.pennywise.engine.decision;

import lombok.Builder;
import lombok.Value;
import java.math.BigDecimal;

/**
 * Immutable financial snapshot passed into every sub-engine.
 * Decouples the engine from HTTP request/response DTOs.
 */
@Value
@Builder
public class DecisionContext {
    // ── User financial state ───────────────────────────────────────────────
    BigDecimal monthlyIncome;
    BigDecimal avgMonthlyExpenses;
    BigDecimal currentEmergencyFund;

    // ── Purchase parameters ───────────────────────────────────────────────
    String itemName;
    BigDecimal price;
    BigDecimal downPayment;
    BigDecimal interestRatePercent;
    Integer tenureMonths;
    BigDecimal existingMonthlyEmi;

    // ── Derived helpers ────────────────────────────────────────────────────
    public BigDecimal grossSurplus() {
        return monthlyIncome.subtract(avgMonthlyExpenses).max(BigDecimal.ZERO);
    }

    public boolean isLoan() {
        return tenureMonths != null && tenureMonths > 0
                && orZero(downPayment).compareTo(price) < 0;
    }

    public BigDecimal loanAmount() {
        return price.subtract(orZero(downPayment)).max(BigDecimal.ZERO);
    }

    public static BigDecimal orZero(BigDecimal v) {
        return v != null ? v : BigDecimal.ZERO;
    }
}
