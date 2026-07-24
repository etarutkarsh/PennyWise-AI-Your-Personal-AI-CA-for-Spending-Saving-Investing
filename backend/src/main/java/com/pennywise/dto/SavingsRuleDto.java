package com.pennywise.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SavingsRuleDto {
    private UUID id;
    private String triggerType;
    private UUID categoryId;
    private String categoryName;
    private Map<String, Object> config;
    private boolean active;
}
