package com.pennywise.ai;

import com.pennywise.dto.AffordabilityRequest;
import com.pennywise.dto.AffordabilityResponse;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;

/**
 * Section 4 / Feature 4 of the PRD - Affordability Checker.
 *
 * This is a first-pass, explainable rule engine (Section 21 principle #2: every
 * recommendation must include a clear rationale). It intentionally uses simple,
 * auditable rules rather than a black-box model so users can trust the "why".
 *
 * TODO(Phase 3/4): once InvestmentPortfolio, Assets and Liabilities entities exist,
 * feed real EMI obligations and investment balances into this engine instead of
 * the current income/expense/emergency-fund approximation. See Section 14 - AI
 * Decision Engine for the full input/output contract this should grow into.
 */
@Component
public class AffordabilityEngine {

    private static final BigDecimal RECOMMENDED_EMERGENCY_FUND_MONTHS = BigDecimal.valueOf(6);
    private static final BigDecimal SAFE_SPEND_RATIO_OF_SURPLUS = BigDecimal.valueOf(0.5);

    /**
     * @param monthlyIncome        user's monthly take-home income
     * @param avgMonthlyExpenses    trailing average of monthly expenses (from transactions)
     * @param currentEmergencyFund  cash currently held as emergency savings
     * @param price                 price of the item being evaluated
     */
    public AffordabilityResponse evaluate(AffordabilityRequest request,
                                           BigDecimal monthlyIncome,
                                           BigDecimal avgMonthlyExpenses,
                                           BigDecimal currentEmergencyFund) {

        BigDecimal price = request.getPrice();
        BigDecimal monthlySurplus = monthlyIncome.subtract(avgMonthlyExpenses).max(BigDecimal.ZERO);
        BigDecimal recommendedEmergencyFund = avgMonthlyExpenses.multiply(RECOMMENDED_EMERGENCY_FUND_MONTHS);
        BigDecimal emergencyFundAfterPurchase = currentEmergencyFund.subtract(price);

        // Rule 1: no monthly surplus at all -> the purchase has no funding source that
        // doesn't eat directly into savings, regardless of emergency fund size.
        if (monthlySurplus.compareTo(BigDecimal.ZERO) <= 0) {
            return dontBuy(request);
        }

        // Rule 2: buying today must not drop the emergency fund below the recommended
        // floor (avgMonthlyExpenses x 6). If it would, tell the user to wait and save.
        if (emergencyFundAfterPurchase.compareTo(recommendedEmergencyFund) < 0) {
            return waitAndSave(request, monthlySurplus, currentEmergencyFund, recommendedEmergencyFund, price);
        }

        return safeToBuy(currentEmergencyFund, emergencyFundAfterPurchase, recommendedEmergencyFund);
    }

    private AffordabilityResponse safeToBuy(BigDecimal currentEmergencyFund,
                                             BigDecimal emergencyFundAfterPurchase,
                                             BigDecimal recommendedEmergencyFund) {
        return AffordabilityResponse.builder()
                .verdict("SAFE_TO_BUY")
                .reason("Buying this today keeps your emergency fund at or above the recommended "
                        + recommendedEmergencyFund + " safety floor and doesn't exceed your monthly surplus.")
                .emergencyFundImpact(currentEmergencyFund.subtract(emergencyFundAfterPurchase))
                .projectedEmergencyFundAfterPurchase(emergencyFundAfterPurchase)
                .build();
    }

    private AffordabilityResponse waitAndSave(AffordabilityRequest request, BigDecimal monthlySurplus,
                                               BigDecimal currentEmergencyFund, BigDecimal recommendedEmergencyFund,
                                               BigDecimal price) {
        BigDecimal recommendedMonthlySavings = monthlySurplus.multiply(SAFE_SPEND_RATIO_OF_SURPLUS)
                .setScale(0, RoundingMode.CEILING);

        // Amount that still needs to be saved before the purchase won't breach the
        // emergency-fund floor: price minus whatever buffer already exists above it.
        BigDecimal bufferAboveFloor = currentEmergencyFund.subtract(recommendedEmergencyFund).max(BigDecimal.ZERO);
        BigDecimal shortfall = price.subtract(bufferAboveFloor).max(BigDecimal.ZERO);

        int months = recommendedMonthlySavings.compareTo(BigDecimal.ZERO) > 0
                ? shortfall.divide(recommendedMonthlySavings, 0, RoundingMode.CEILING).intValue()
                : 12;
        months = Math.max(1, months);

        return AffordabilityResponse.builder()
                .verdict("WAIT_AND_SAVE")
                .reason("Buying " + request.getItemName() + " today would reduce your emergency fund below "
                        + "the recommended " + recommendedEmergencyFund + " safety level.")
                .recommendedWaitMonths(months)
                .recommendedMonthlySavings(recommendedMonthlySavings)
                .expectedPurchaseDate(LocalDate.now().plusMonths(months))
                .emergencyFundImpact(price)
                .investmentSuggestion(months <= 6 ? "liquid_fund" : "debt_plus_equity")
                .build();
    }

    private AffordabilityResponse dontBuy(AffordabilityRequest request) {
        return AffordabilityResponse.builder()
                .verdict("DONT_BUY")
                .reason("Your current monthly expenses already meet or exceed your income, so " + request.getItemName()
                        + " would need to come out of savings with no surplus to replace it.")
                .recommendedWaitMonths(null)
                .investmentSuggestion(null)
                .build();
    }
}
