package com.pennywise.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ScenarioDto {
    private String label;
    private String verdict;
    private int confidence;
    private String recommendationStrength;   // HIGH | MEDIUM | LOW
    private BigDecimal monthlyEmi;
    private BigDecimal totalInterest;
    private BigDecimal totalCost;
    private String summary;
    private boolean isRecommended;

    // Explainability
    private List<String> whyThis;      // reasons TO choose this
    private List<String> whyNot;       // reasons NOT to choose this
    private List<TradeoffDto> tradeoffs; // PRO/CON bullets
}
