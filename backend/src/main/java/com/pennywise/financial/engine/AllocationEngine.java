package com.pennywise.financial.engine;

import com.pennywise.financial.model.PortfolioAllocation;
import com.pennywise.financial.model.RiskCategory;
import org.springframework.stereotype.Service;

/**
 * Determines the recommended asset allocation based on risk category and investor age.
 *
 * Base allocations follow standard multi-asset portfolio construction principles.
 * Age adjustment: for every 5 years above age 40, equity is reduced by 5% (moved to debt),
 * with a floor of 10% equity regardless of age or risk category.
 *
 * Reference: Vanguard Target-Date Fund methodology; SEBI hybrid fund categorisation.
 */
@Service
public class AllocationEngine {

    // Base allocations by risk category: {equity, debt, gold, cash, international}
    private static final double[][] BASE_ALLOCATIONS = {
            // CONSERVATIVE
            { 20, 55, 15, 10, 0 },
            // MODERATE
            { 45, 35, 12, 5, 3 },
            // AGGRESSIVE
            { 65, 20, 10, 3, 2 },
            // VERY_AGGRESSIVE
            { 75, 10, 8, 2, 5 }
    };

    /**
     * Computes the recommended portfolio allocation for a given risk category and investor age.
     *
     * @param category the investor's risk category
     * @param age      the investor's age in years
     * @return a PortfolioAllocation whose percentages sum to 100
     */
    public PortfolioAllocation allocate(RiskCategory category, int age) {
        double[] base = BASE_ALLOCATIONS[category.ordinal()].clone();

        double equity        = base[0];
        double debt          = base[1];
        double gold          = base[2];
        double cash          = base[3];
        double international = base[4];

        // Age adjustment: reduce equity by 5% for every 5 years above 40
        if (age > 40) {
            int fiveYearBands = (age - 40) / 5;
            double equityReduction = fiveYearBands * 5.0;
            // Floor equity at 10%
            equityReduction = Math.min(equityReduction, equity - 10.0);
            if (equityReduction > 0) {
                equity -= equityReduction;
                debt   += equityReduction;
            }
        }

        String rationale = buildRationale(category, age, equity);

        return new PortfolioAllocation(equity, debt, gold, cash, international, category, age, rationale);
    }

    private String buildRationale(RiskCategory category, int age, double finalEquity) {
        StringBuilder sb = new StringBuilder();
        sb.append(category.name()).append(" risk profile. ");

        if (age > 40) {
            int fiveYearBands = (age - 40) / 5;
            if (fiveYearBands > 0) {
                sb.append("Age adjustment applied: equity reduced by ")
                  .append(fiveYearBands * 5)
                  .append("% for age ").append(age).append(" (>40). ");
            }
        }

        sb.append("Final equity allocation: ").append((int) finalEquity).append("%. ");

        if (finalEquity <= 10) {
            sb.append("Equity floored at 10% minimum. ");
        }

        sb.append("Gold provides inflation hedge; cash ensures liquidity for near-term needs.");

        return sb.toString();
    }
}
