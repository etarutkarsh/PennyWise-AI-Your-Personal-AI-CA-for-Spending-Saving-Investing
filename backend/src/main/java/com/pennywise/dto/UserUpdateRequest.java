package com.pennywise.dto;

import lombok.Data;

import java.math.BigDecimal;

@Data
public class UserUpdateRequest {
    private String fullName;
    private String phoneNumber;
    private BigDecimal monthlyIncome;
    private String riskAppetite;
    // Tax-ready fields
    private String pan;
    private String taxRegime;
    private Integer financialYearStart;
}
