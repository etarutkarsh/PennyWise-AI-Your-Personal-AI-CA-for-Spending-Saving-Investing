package com.pennywise.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BudgetDto {
    private UUID id;
    private UUID categoryId;
    private String categoryName;
    private BigDecimal monthlyLimit;
    private BigDecimal spentSoFar;
    private BigDecimal remaining;
    private double percentUsed;
    private String period;
    private boolean overBudget;
}
