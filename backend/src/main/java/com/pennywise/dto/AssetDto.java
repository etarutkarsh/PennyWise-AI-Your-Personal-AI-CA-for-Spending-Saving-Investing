package com.pennywise.dto;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AssetDto {
    private UUID id;
    private String assetType;
    private String name;
    private BigDecimal value;
    private LocalDate asOfDate;
}
