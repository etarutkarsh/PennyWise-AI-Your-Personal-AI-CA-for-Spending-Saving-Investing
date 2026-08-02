package com.pennywise.dto.twin;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

@Getter
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class DigitalTwinDto {

    /** 0–100 completeness/confidence score */
    private int twinScore;

    private BigDecimal netWorth;
    private BigDecimal totalAssets;
    private BigDecimal totalLiabilities;
    private BigDecimal monthlyIncome;
    private BigDecimal monthlyExpenses;
    private BigDecimal monthlySurplus;

    /** Months of expenses covered by liquid (cash) assets */
    private BigDecimal efCoverageMonths;

    /** Monthly EMIs / monthly income */
    private BigDecimal dtiRatio;

    /** Behavioral execution factor (0.5–1.15) */
    private double behaviorFactor;

    private BigDecimal projection12m;
    private BigDecimal projection3yr;
    private BigDecimal projection5yr;
    private BigDecimal projection10yr;

    private List<GoalTrajectoryDto> goalTrajectories;

    /** 24-month sparkline + 3 milestone points (36, 60, 120 months) */
    private List<ProjectionPointDto> projectionSeries;

    /** BASIC (score <50) | GOOD (50–79) | COMPLETE (80+) */
    private String dataQuality;
}
