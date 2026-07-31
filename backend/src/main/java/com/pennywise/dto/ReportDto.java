package com.pennywise.dto;

import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
public class ReportDto {
    private String period;        // e.g. "2025-07"
    private BigDecimal totalSpend;
    private BigDecimal totalIncome;
    private BigDecimal netSavings;
    private List<CategorySpend> byCategory;

    @Data
    @Builder
    public static class CategorySpend {
        private String categoryName;
        private String categoryIcon;
        private BigDecimal amount;
        private double percentage;
    }
}
