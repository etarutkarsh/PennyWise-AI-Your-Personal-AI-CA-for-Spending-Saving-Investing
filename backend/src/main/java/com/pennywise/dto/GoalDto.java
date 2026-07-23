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
public class GoalDto {
    private UUID id;
    private String name;
    private String goalType;
    private BigDecimal targetAmount;
    private BigDecimal currentSaved;
    private LocalDate deadline;
    private String priority;
    private BigDecimal recommendedMonthlyContribution;
    private String investmentSuggestion;
    private double progressPercent;
    private boolean achieved;
}
