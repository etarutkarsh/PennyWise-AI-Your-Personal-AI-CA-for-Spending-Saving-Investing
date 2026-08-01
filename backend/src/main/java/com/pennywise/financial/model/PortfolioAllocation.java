package com.pennywise.financial.model;

/**
 * Age-adjusted, risk-based portfolio allocation across asset classes.
 * All percent fields sum to 100.
 */
public record PortfolioAllocation(
        double equityPercent,
        double debtPercent,
        double goldPercent,
        double cashPercent,
        double internationalEquityPercent,
        RiskCategory basedOnRisk,
        int basedOnAge,
        String rationale
) {
    /**
     * Compact constructor that validates the allocation sums to 100.
     */
    public PortfolioAllocation {
        double total = equityPercent + debtPercent + goldPercent + cashPercent + internationalEquityPercent;
        // Allow minor floating-point rounding (within 0.01)
        if (Math.abs(total - 100.0) > 0.01) {
            throw new IllegalArgumentException(
                    "Portfolio allocation must sum to 100%%, got: " + total);
        }
    }
}
