package com.pennywise.dto;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
public class GoalUpdateRequest {
    private String name;
    private BigDecimal targetAmount;
    private LocalDate deadline;
    private String priority;
}
