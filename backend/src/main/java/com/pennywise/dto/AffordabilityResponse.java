package com.pennywise.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AffordabilityResponse {

    // ── Core verdict (backward-compatible) ───────────────────────────────────
    private String verdict;
    private String reason;
    private Integer recommendedWaitMonths;
    private BigDecimal recommendedMonthlySavings;
    private LocalDate expectedPurchaseDate;
    private BigDecimal emergencyFundImpact;
    private BigDecimal projectedEmergencyFundAfterPurchase;
    private String investmentSuggestion;

    // ── Extended intelligence ─────────────────────────────────────────────────
    private int confidence;
    private BigDecimal monthlyEmi;
    private BigDecimal dtiRatio;
    private BigDecimal remainingMonthlySurplus;
    private BigDecimal maxAffordablePrice;
    private List<String> reasons;
    private List<String> warnings;
    private List<String> recommendations;
    private List<ScenarioDto> scenarios;

    // Recommendation strength (replaces raw confidence % in UI)
    private String recommendationStrength; // HIGH | MEDIUM | LOW
    private List<String> strengthEvidence; // bullets explaining why

    // Goal Impact Engine — shows how this recommendation changes each goal
    private List<GoalImpactDto> goalImpacts;
}
