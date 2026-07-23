package com.pennywise.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AffordabilityResponse {

    /** SAFE_TO_BUY | WAIT_AND_SAVE | DONT_BUY */
    private String verdict;

    private String reason;

    /** Populated when verdict is WAIT_AND_SAVE or DONT_BUY. */
    private Integer recommendedWaitMonths;

    private BigDecimal recommendedMonthlySavings;

    private LocalDate expectedPurchaseDate;

    private BigDecimal emergencyFundImpact;

    private BigDecimal projectedEmergencyFundAfterPurchase;

    private String investmentSuggestion;
}
