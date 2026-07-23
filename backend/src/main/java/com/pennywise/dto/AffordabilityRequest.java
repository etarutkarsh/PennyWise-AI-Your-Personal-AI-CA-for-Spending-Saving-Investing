package com.pennywise.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Data;

import java.math.BigDecimal;

@Data
public class AffordabilityRequest {

    @NotBlank
    private String itemName;

    @NotNull
    @Positive
    private BigDecimal price;

    /** Optional: if the user would pay via EMI instead of lump sum. */
    private Integer emiMonths;
}
