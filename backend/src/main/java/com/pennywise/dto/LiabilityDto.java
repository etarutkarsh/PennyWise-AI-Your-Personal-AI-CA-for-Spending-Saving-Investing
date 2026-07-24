package com.pennywise.dto;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LiabilityDto {
    private UUID id;
    private String liabilityType;
    private String name;
    private BigDecimal outstanding;
    private BigDecimal monthlyEmi;
    private BigDecimal interestRate;
    private LocalDate asOfDate;
}
