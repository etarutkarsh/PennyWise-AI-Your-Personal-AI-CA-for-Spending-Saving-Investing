package com.pennywise.dto;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
public class InvestmentPortfolioCreateRequest {
    private String instrumentType;
    private String name;
    private BigDecimal investedAmount;
    private BigDecimal currentValue;
    private BigDecimal units;
    private LocalDate startedOn;
}
