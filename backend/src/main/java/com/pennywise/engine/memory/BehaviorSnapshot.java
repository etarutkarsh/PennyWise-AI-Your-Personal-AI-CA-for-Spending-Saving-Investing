package com.pennywise.engine.memory;

import lombok.Builder;
import lombok.Data;
import java.math.BigDecimal;

@Data @Builder
public class BehaviorSnapshot {
    private BigDecimal monthlyIncome;
    private BigDecimal monthlyExpense;
    private double savingsRate;          // surplus / income * 100
    private double emergencyFundMonths;  // EF / avgExpenses
    private double debtRatio;            // totalEmi / income * 100
    private String riskProfile;          // conservative | moderate | aggressive
    private int goalCount;
    private int financialHealth;
}
