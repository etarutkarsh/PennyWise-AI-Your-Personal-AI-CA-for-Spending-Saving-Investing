package com.pennywise.engine.twin;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

/**
 * In-memory value object produced by the FinancialDigitalTwinEngine.
 * Contains all computed figures for a single user at a point in time.
 */
@Getter
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class TwinSnapshot {

    private BigDecimal netWorth;
    private BigDecimal totalAssets;
    private BigDecimal totalLiabilities;
    private BigDecimal monthlyIncome;
    private BigDecimal monthlyExpenses;
    private BigDecimal monthlySurplus;

    /** How many months of expenses are covered by liquid (cash) assets. */
    private BigDecimal efCoverageMonths;

    /** Debt-to-income ratio: total monthly EMIs / monthly income. */
    private BigDecimal dtiRatio;

    /**
     * Behavioral execution factor (0.5–1.15).
     * Scales projected savings to account for real-world follow-through.
     */
    private double behaviorFactor;

    /** Completeness/confidence score (0–100). */
    private int twinScore;

    private List<GoalTrajectory> goalTrajectories;

    /** Monthly sparkline series (months 1–24) plus key milestone points. */
    private List<ProjectionPoint> projectionSeries;
}
