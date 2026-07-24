package com.pennywise.dto;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
public class LiabilityCreateRequest {
    private String liabilityType;
    private String name;
    private BigDecimal outstanding;
    private BigDecimal monthlyEmi;
    private BigDecimal interestRate;
    private LocalDate asOfDate;
}
