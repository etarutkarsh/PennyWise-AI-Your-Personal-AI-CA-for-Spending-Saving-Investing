package com.pennywise.engine.twin;

import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.MathContext;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;

/**
 * Generates net-worth projection series and key milestone points.
 *
 * <p>Monthly compounding formula:
 * <pre>
 *   FV(n) = currentNetWorth * (1 + r)^n  +  effectiveMonthlySaving * ((1+r)^n - 1) / r
 * </pre>
 * where r = annualRate / 12  and  effectiveMonthlySaving = monthlySurplus * behaviorFactor.
 */
@Component
public class FinancialProjectionEngine {

    private static final MathContext MC = new MathContext(10, RoundingMode.HALF_UP);
    private static final int[] MILESTONE_MONTHS = {12, 36, 60, 120};
    private static final int SPARKLINE_MONTHS = 24;

    /**
     * Generates the full projection series (24-month sparkline + 4 milestone points).
     *
     * @param currentNetWorth starting net worth
     * @param monthlySurplus  raw monthly surplus (income - expenses)
     * @param behaviorFactor  execution factor (0.5–1.15)
     * @param riskAppetite    "conservative" | "moderate" | "aggressive"
     * @return list of ProjectionPoints; months 1–24 are the sparkline, then 36, 60, 120
     */
    public List<ProjectionPoint> generateSeries(
            BigDecimal currentNetWorth,
            BigDecimal monthlySurplus,
            double behaviorFactor,
            String riskAppetite) {

        double annualRate = annualRateFor(riskAppetite);
        double monthlyRate = annualRate / 12.0;

        BigDecimal effectiveSaving = monthlySurplus
                .multiply(BigDecimal.valueOf(behaviorFactor), MC)
                .max(BigDecimal.ZERO);

        List<ProjectionPoint> series = new ArrayList<>();

        // 24-month sparkline
        for (int month = 1; month <= SPARKLINE_MONTHS; month++) {
            BigDecimal nw = projectNetWorth(currentNetWorth, effectiveSaving, monthlyRate, month);
            BigDecimal cumSavings = effectiveSaving.multiply(BigDecimal.valueOf(month), MC);
            series.add(ProjectionPoint.builder()
                    .monthsFromNow(month)
                    .netWorth(nw.setScale(2, RoundingMode.HALF_UP))
                    .cumulativeSavings(cumSavings.setScale(2, RoundingMode.HALF_UP))
                    .build());
        }

        // Milestone points beyond sparkline: 36, 60, 120
        for (int month : MILESTONE_MONTHS) {
            if (month > SPARKLINE_MONTHS) {
                BigDecimal nw = projectNetWorth(currentNetWorth, effectiveSaving, monthlyRate, month);
                BigDecimal cumSavings = effectiveSaving.multiply(BigDecimal.valueOf(month), MC);
                series.add(ProjectionPoint.builder()
                        .monthsFromNow(month)
                        .netWorth(nw.setScale(2, RoundingMode.HALF_UP))
                        .cumulativeSavings(cumSavings.setScale(2, RoundingMode.HALF_UP))
                        .build());
            }
        }

        return series;
    }

    /**
     * Returns a specific projection point for a given milestone month.
     */
    public BigDecimal projectAt(BigDecimal currentNetWorth,
                                BigDecimal monthlySurplus,
                                double behaviorFactor,
                                String riskAppetite,
                                int months) {
        double monthlyRate = annualRateFor(riskAppetite) / 12.0;
        BigDecimal effectiveSaving = monthlySurplus
                .multiply(BigDecimal.valueOf(behaviorFactor), MC)
                .max(BigDecimal.ZERO);
        return projectNetWorth(currentNetWorth, effectiveSaving, monthlyRate, months)
                .setScale(2, RoundingMode.HALF_UP);
    }

    // FV(n) = P*(1+r)^n + PMT*((1+r)^n - 1)/r
    private BigDecimal projectNetWorth(BigDecimal initialNW,
                                       BigDecimal pmt,
                                       double monthlyRate,
                                       int months) {
        if (monthlyRate == 0.0) {
            // No returns — simple linear accumulation
            return initialNW.add(pmt.multiply(BigDecimal.valueOf(months), MC), MC);
        }
        double growth = Math.pow(1 + monthlyRate, months);
        double fvInitial = initialNW.doubleValue() * growth;
        double fvSavings = pmt.doubleValue() * (growth - 1) / monthlyRate;
        return BigDecimal.valueOf(fvInitial + fvSavings);
    }

    private double annualRateFor(String riskAppetite) {
        if (riskAppetite == null) return 0.10;
        return switch (riskAppetite.toLowerCase()) {
            case "conservative" -> 0.07;
            case "aggressive"   -> 0.13;
            default             -> 0.10; // moderate
        };
    }
}
