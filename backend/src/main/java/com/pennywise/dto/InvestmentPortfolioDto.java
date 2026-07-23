package com.pennywise.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class InvestmentPortfolioDto {
    private UUID id;
    private String instrumentType;
    private String name;
    private BigDecimal investedAmount;
    private BigDecimal currentValue;
    private BigDecimal units;
    private LocalDate startedOn;
    private double returnsPercent;
    private BigDecimal returnsAmount;
}
