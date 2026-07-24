package com.pennywise.dto;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
public class AssetCreateRequest {
    private String assetType;
    private String name;
    private BigDecimal value;
    private LocalDate asOfDate;
}
