package com.pennywise.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
public class GoalCreateRequest {

    @NotBlank
    private String name;

    @NotBlank
    private String goalType;

    @NotNull
    @Positive
    private BigDecimal targetAmount;

    private BigDecimal currentSaved;

    @NotNull
    private LocalDate deadline;

    private String priority;
}
