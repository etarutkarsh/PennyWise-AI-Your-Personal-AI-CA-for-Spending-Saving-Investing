package com.pennywise.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Data;

import java.math.BigDecimal;

@Data
public class AffordabilityRequest {

    @NotBlank
    private String itemName;

    @NotNull
    @Positive
    private BigDecimal price;

    /** Upfront payment; null or 0 means full lump-sum purchase. */
    private BigDecimal downPayment;

    /** Annual interest rate in percent (e.g. 10.5 means 10.5%). */
    private BigDecimal interestRatePercent;

    /** Loan repayment period in months. */
    private Integer tenureMonths;

    /** Sum of all existing monthly EMI obligations. */
    private BigDecimal existingMonthlyEmi;
}
