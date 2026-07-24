package com.pennywise.dto;

import lombok.*;

import java.math.BigDecimal;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserDto {
    private UUID id;
    private String email;
    private String fullName;
    private String phoneNumber;
    private String userType;
    private BigDecimal monthlyIncome;
    private String currency;
    private String riskAppetite;
    private boolean onboardingComplete;
}
