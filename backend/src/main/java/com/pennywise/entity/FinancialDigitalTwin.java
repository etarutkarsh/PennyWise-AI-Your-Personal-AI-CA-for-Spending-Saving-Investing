package com.pennywise.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@Entity
@Table(name = "financial_digital_twin")
public class FinancialDigitalTwin {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "user_id", nullable = false, unique = true)
    private UUID userId;

    @Column(name = "twin_score", nullable = false)
    private int twinScore = 0;

    @Column(name = "net_worth", precision = 18, scale = 2)
    private BigDecimal netWorth;

    @Column(name = "total_assets", precision = 18, scale = 2)
    private BigDecimal totalAssets;

    @Column(name = "total_liabilities", precision = 18, scale = 2)
    private BigDecimal totalLiabilities;

    @Column(name = "monthly_income", precision = 18, scale = 2)
    private BigDecimal monthlyIncome;

    @Column(name = "monthly_expenses", precision = 18, scale = 2)
    private BigDecimal monthlyExpenses;

    @Column(name = "monthly_surplus", precision = 18, scale = 2)
    private BigDecimal monthlySurplus;

    @Column(name = "ef_coverage_months", precision = 6, scale = 2)
    private BigDecimal efCoverageMonths;

    @Column(name = "dti_ratio", precision = 6, scale = 4)
    private BigDecimal dtiRatio;

    @Column(name = "behavior_factor", precision = 6, scale = 4)
    private BigDecimal behaviorFactor;

    @Column(name = "projection_12m", precision = 18, scale = 2)
    private BigDecimal projection12m;

    @Column(name = "projection_3yr", precision = 18, scale = 2)
    private BigDecimal projection3yr;

    @Column(name = "projection_5yr", precision = 18, scale = 2)
    private BigDecimal projection5yr;

    @Column(name = "projection_10yr", precision = 18, scale = 2)
    private BigDecimal projection10yr;

    @Column(name = "goal_trajectories", columnDefinition = "TEXT")
    private String goalTrajectories;

    @Column(name = "projection_series", columnDefinition = "TEXT")
    private String projectionSeries;

    @Column(name = "last_computed_at")
    private LocalDateTime lastComputedAt;
}
