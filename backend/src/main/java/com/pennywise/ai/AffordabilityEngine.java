package com.pennywise.ai;

import com.pennywise.dto.AffordabilityRequest;
import com.pennywise.dto.AffordabilityResponse;
import com.pennywise.engine.decision.DecisionContext;
import com.pennywise.engine.decision.DecisionEngine;
import org.springframework.stereotype.Component;
import java.math.BigDecimal;

/** @deprecated Use {@link DecisionEngine} directly. Kept for backward compatibility. */
@Deprecated
@Component
public class AffordabilityEngine {

    private final DecisionEngine decisionEngine;

    public AffordabilityEngine(DecisionEngine decisionEngine) {
        this.decisionEngine = decisionEngine;
    }

    public AffordabilityResponse evaluate(AffordabilityRequest request,
                                           BigDecimal monthlyIncome,
                                           BigDecimal avgMonthlyExpenses,
                                           BigDecimal currentEmergencyFund) {
        DecisionContext ctx = DecisionContext.builder()
                .itemName(request.getItemName())
                .price(request.getPrice())
                .downPayment(request.getDownPayment())
                .interestRatePercent(request.getInterestRatePercent())
                .tenureMonths(request.getTenureMonths())
                .existingMonthlyEmi(request.getExistingMonthlyEmi())
                .monthlyIncome(monthlyIncome)
                .avgMonthlyExpenses(avgMonthlyExpenses)
                .currentEmergencyFund(currentEmergencyFund)
                .build();
        return decisionEngine.evaluate(ctx);
    }
}
