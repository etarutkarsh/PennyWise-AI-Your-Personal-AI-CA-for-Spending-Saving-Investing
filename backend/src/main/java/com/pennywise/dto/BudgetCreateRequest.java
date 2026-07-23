package com.pennywise.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Data;

import java.math.BigDecimal;
import java.util.UUID;

@Data
public class BudgetCreateRequest {

    @NotNull
    private UUID categoryId;

    @NotNull
    @Positive
    private BigDecimal monthlyLimit;

    /** ISO period "YYYY-MM"; defaults to current month if omitted. */
    private String period;

    private Integer alertThresholdPercent;
}
