package com.pennywise.financial;

import com.pennywise.financial.engine.RiskEngine;
import com.pennywise.financial.model.RiskCapacityInput;
import com.pennywise.financial.model.RiskProfile;
import com.pennywise.financial.model.RiskWillingnessInput;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;

import static org.assertj.core.api.Assertions.assertThat;

class RiskEngineTest {

    private RiskEngine engine;

    @BeforeEach
    void setUp() {
        engine = new RiskEngine();
    }

    @Test
    @DisplayName("Willingness: max scores (5,5,5,5,5) should return 100")
    void scoreWillingness_maxScores_returns100() {
        var input = new RiskWillingnessInput(5, 5, 5, 5, 5);
        assertThat(engine.scoreWillingness(input)).isEqualTo(100);
    }

    @Test
    @DisplayName("Willingness: min scores (1,1,1,1,1) should return 0")
    void scoreWillingness_minScores_returns0() {
        var input = new RiskWillingnessInput(1, 1, 1, 1, 1);
        assertThat(engine.scoreWillingness(input)).isEqualTo(0);
    }

    @Test
    @DisplayName("Willingness: mid scores (3,3,3,3,3) should return ~50")
    void scoreWillingness_midScores_returnsApprox50() {
        var input = new RiskWillingnessInput(3, 3, 3, 3, 3);
        assertThat(engine.scoreWillingness(input)).isCloseTo(50, org.assertj.core.data.Offset.offset(2));
    }

    @Test
    @DisplayName("Capacity: no emergency fund reduces score and adds constraint")
    void scoreCapacity_noEmergencyFund_reducesScore() {
        var input = new RiskCapacityInput(
            100_000, 60_000,
            50_000, 0,
            0, false, true, 10
        );
        var constraints = new ArrayList<String>();
        int score = engine.scoreCapacity(input, constraints);
        assertThat(score).isLessThan(100);
        assertThat(constraints).anyMatch(c -> c.toLowerCase().contains("emergency"));
    }

    @Test
    @DisplayName("Capacity: high DTI > 50% reduces score by 30")
    void scoreCapacity_highDebt_reducesScoreSignificantly() {
        var input = new RiskCapacityInput(
            50_000, 30_000,
            100_000, 400_000,  // DTI = 400k / (50k*12) = 66% → penalty -30, +5 for 10yr goal = 75
            0, true, true, 10
        );
        var constraints = new ArrayList<String>();
        int score = engine.scoreCapacity(input, constraints);
        // Score starts at 100, -30 for high DTI, +5 for long goal horizon = 75
        assertThat(score).isLessThanOrEqualTo(80);
        assertThat(constraints).anyMatch(c -> c.contains("DTI") || c.toLowerCase().contains("debt"));
    }

    @Test
    @DisplayName("assess: high willingness + low capacity → capacity wins")
    void assess_highWillingnessLowCapacity_capacityWins() {
        var willingness = new RiskWillingnessInput(5, 5, 5, 5, 5);
        var capacity = new RiskCapacityInput(
            50_000, 55_000,    // spending exceeds income
            10_000, 500_000,   // huge debt, low savings
            3, false, false, 1 // all bad signals
        );
        RiskProfile profile = engine.assess(willingness, capacity);
        assertThat(profile.finalScore()).isLessThanOrEqualTo(profile.willingnessScore());
        assertThat(profile.capacityConstraints()).isNotEmpty();
    }

    @Test
    @DisplayName("assess: final score = min(willingness, capacity)")
    void assess_finalScoreEqualsMin() {
        var willingness = new RiskWillingnessInput(3, 3, 3, 3, 3);
        var capacity = new RiskCapacityInput(
            100_000, 60_000,
            600_000, 0,
            1, true, true, 10
        );
        RiskProfile profile = engine.assess(willingness, capacity);
        assertThat(profile.finalScore()).isEqualTo(
            Math.min(profile.willingnessScore(), profile.capacityScore()));
    }

    @Test
    @DisplayName("assess: category matches final score range")
    void assess_categoryMatchesFinalScore() {
        var willingness = new RiskWillingnessInput(5, 5, 5, 5, 5);
        var capacity = new RiskCapacityInput(
            200_000, 80_000,
            2_400_000, 0,
            0, true, true, 15
        );
        RiskProfile profile = engine.assess(willingness, capacity);
        assertThat(profile.finalScore()).isBetween(profile.category().minScore, profile.category().maxScore);
    }
}
