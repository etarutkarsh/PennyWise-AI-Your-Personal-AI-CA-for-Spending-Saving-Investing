package com.pennywise.dto;

import lombok.*;

import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NetWorthSummaryDto {
    private BigDecimal totalAssets;
    private BigDecimal totalLiabilities;
    private BigDecimal netWorth;
    private List<AssetDto> assets;
    private List<LiabilityDto> liabilities;
}
