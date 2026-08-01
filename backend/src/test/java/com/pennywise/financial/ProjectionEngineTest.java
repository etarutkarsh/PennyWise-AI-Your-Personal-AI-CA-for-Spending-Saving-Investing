package com.pennywise.financial;

import com.pennywise.financial.engine.ProjectionEngine;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;

/**
 * Unit tests for ProjectionEngine financial formulas.
 * All values are verified against known financial calculator outputs.
 */
class ProjectionEngineTest {

    private ProjectionEngine engine;

    @BeforeEach
    void setUp() {
        engine = new ProjectionEngine();
    }

    // ── SIP Future Value ─────────────────────────────────────────────────────

    @Test
    @DisplayName("SIP: ₹5,000/month at 12% for 10 years should be ~₹11.5L")
    void sipFutureValue_standardCase() {
        // FV = 5000 × [(1 + 0.01)^120 - 1] / 0.01  (ordinary annuity, end-of-period)
        // Expected: approximately 11,50,193
        double result = engine.sipFutureValue(5000, 12.0, 120);
        assertThat(result).isCloseTo(1_150_193.0, within(1000.0));
    }

    @Test
    @DisplayName("SIP: Zero return rate returns monthlyInvestment × months")
    void sipFutureValue_zeroReturnRate() {
        double result = engine.sipFutureValue(1000, 0, 12);
        assertThat(result).isEqualTo(12_000.0);
    }

    @Test
    @DisplayName("SIP: Zero months returns 0")
    void sipFutureValue_zeroMonths() {
        double result = engine.sipFutureValue(5000, 12.0, 0);
        assertThat(result).isEqualTo(0.0);
    }

    @Test
    @DisplayName("SIP: ₹1,000/month at 8% for 5 years (60 months) ~₹73,476")
    void sipFutureValue_eightPercent() {
        double result = engine.sipFutureValue(1000, 8.0, 60);
        assertThat(result).isCloseTo(73_476.0, within(500.0));
    }

    // ── Goal Monthly Contribution ─────────────────────────────────────────────

    @Test
    @DisplayName("Goal PMT: Need ₹5L in 36 months at 7% annual")
    void goalMonthlyContribution_standardCase() {
        // Monthly needed to accumulate 5,00,000 in 36 months at 7% annual
        double result = engine.goalMonthlyContribution(500_000, 7.0, 36);
        // No interest case would be ~13,889; with 7% compounding it should be less
        assertThat(result).isGreaterThan(0);
        assertThat(result).isLessThan(14_000); // less than simple division
        assertThat(result).isCloseTo(12_522.0, within(200.0));
    }

    @Test
    @DisplayName("Goal PMT: Zero return falls back to simple division")
    void goalMonthlyContribution_zeroReturn() {
        double result = engine.goalMonthlyContribution(120_000, 0, 12);
        assertThat(result).isEqualTo(10_000.0);
    }

    @Test
    @DisplayName("Goal PMT: Zero months returns full amount")
    void goalMonthlyContribution_zeroMonths() {
        double result = engine.goalMonthlyContribution(100_000, 10.0, 0);
        assertThat(result).isEqualTo(100_000.0);
    }

    @Test
    @DisplayName("Goal PMT: Higher return means lower monthly contribution")
    void goalMonthlyContribution_higherReturnMeansLessContribution() {
        double lowReturn  = engine.goalMonthlyContribution(500_000, 6.0, 60);
        double highReturn = engine.goalMonthlyContribution(500_000, 12.0, 60);
        assertThat(lowReturn).isGreaterThan(highReturn);
    }

    // ── EMI ──────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("EMI: ₹10L home loan at 8.5% for 20 years should be ~₹8,678")
    void emi_homeLoanStandardCase() {
        double result = engine.emi(1_000_000, 8.5, 240);
        assertThat(result).isCloseTo(8_678.0, within(50.0));
    }

    @Test
    @DisplayName("EMI: Zero interest rate returns principal/months")
    void emi_zeroInterestRate() {
        double result = engine.emi(120_000, 0, 12);
        assertThat(result).isEqualTo(10_000.0);
    }

    @Test
    @DisplayName("EMI: Zero months returns principal")
    void emi_zeroMonths() {
        double result = engine.emi(100_000, 8.5, 0);
        assertThat(result).isEqualTo(100_000.0);
    }

    @Test
    @DisplayName("EMI: Total payments exceed principal (interest is positive)")
    void emi_totalPaymentsExceedPrincipal() {
        double emi = engine.emi(500_000, 12.0, 60);
        double total = emi * 60;
        assertThat(total).isGreaterThan(500_000);
    }

    // ── Additional formulas ───────────────────────────────────────────────────

    @Test
    @DisplayName("Compound growth: ₹1L at 12% for 10 years ~₹3.1L")
    void compoundGrowth_standardCase() {
        double result = engine.compoundGrowth(100_000, 12.0, 10);
        assertThat(result).isCloseTo(310_585.0, within(100.0));
    }

    @Test
    @DisplayName("Rule of 72: 12% return doubles in ~6 years")
    void ruleOf72_twelvePercent() {
        double result = engine.ruleOf72(12.0);
        assertThat(result).isCloseTo(6.0, within(0.01));
    }

    @Test
    @DisplayName("Real return: 12% nominal minus 6% inflation = 6% real")
    void realReturn_standardCase() {
        double result = engine.realReturn(12.0, 6.0);
        assertThat(result).isEqualTo(6.0);
    }

    @Test
    @DisplayName("Inflation-adjusted return: Fisher equation gives slightly less than 6%")
    void inflationAdjustedReturn_fisherEquation() {
        // Fisher: (1.12 / 1.06) - 1 = 0.05660... = 5.66%
        double result = engine.inflationAdjustedReturn(12.0, 6.0);
        assertThat(result).isCloseTo(5.66, within(0.01));
    }
}
