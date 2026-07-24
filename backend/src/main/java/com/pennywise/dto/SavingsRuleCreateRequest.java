package com.pennywise.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.util.Map;
import java.util.UUID;

@Data
public class SavingsRuleCreateRequest {

    @NotBlank
    private String triggerType;

    private UUID categoryId;

    private Map<String, Object> config;
}
