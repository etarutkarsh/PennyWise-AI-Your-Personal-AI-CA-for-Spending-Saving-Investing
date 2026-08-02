package com.pennywise.engine.memory;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;

class DecisionRecorderTest {

    private DecisionReviewScheduler reviewScheduler;
    private DecisionAccuracyEngine accuracyEngine;

    @BeforeEach
    void setUp() {
        reviewScheduler = new DecisionReviewScheduler();
        accuracyEngine = new DecisionAccuracyEngine();
    }

    // ── DecisionReviewScheduler tests ─────────────────────────────────────────

    @Test
    void reviewScheduler_macbookPro_returns3Months() {
        LocalDate result = reviewScheduler.reviewDateFor("MacBook Pro");
        LocalDate expected = LocalDate.now().plusMonths(3);
        assertThat(result).isEqualTo(expected);
    }

    @Test
    void reviewScheduler_car_returns6Months() {
        LocalDate result = reviewScheduler.reviewDateFor("Car");
        LocalDate expected = LocalDate.now().plusMonths(6);
        assertThat(result).isEqualTo(expected);
    }

    @Test
    void reviewScheduler_house_returns12Months() {
        LocalDate result = reviewScheduler.reviewDateFor("House in Pune");
        LocalDate expected = LocalDate.now().plusMonths(12);
        assertThat(result).isEqualTo(expected);
    }

    @Test
    void reviewScheduler_unknownItem_returns6Months() {
        LocalDate result = reviewScheduler.reviewDateFor("something random");
        LocalDate expected = LocalDate.now().plusMonths(6);
        assertThat(result).isEqualTo(expected);
    }

    @Test
    void reviewScheduler_nullItem_returns6Months() {
        LocalDate result = reviewScheduler.reviewDateFor(null);
        LocalDate expected = LocalDate.now().plusMonths(6);
        assertThat(result).isEqualTo(expected);
    }

    // ── DecisionAccuracyEngine tests ──────────────────────────────────────────

    @Test
    void scoreNumericPrediction_closePrediction_returnsHighScore() {
        double score = accuracyEngine.scoreNumericPrediction(8, 7);
        assertThat(score).isGreaterThanOrEqualTo(85.0);
    }

    @Test
    void computeOverallAccuracy_followedWithHealthDelta_returnsPositive() {
        BigDecimal result = accuracyEngine.computeOverallAccuracy(true, 7, 8);
        assertThat(result).isGreaterThan(BigDecimal.ZERO);
    }

    @Test
    void computeOverallAccuracy_notFollowed_returnsZero() {
        BigDecimal result = accuracyEngine.computeOverallAccuracy(false, 7, 8);
        assertThat(result).isEqualByComparingTo(BigDecimal.ZERO);
    }

    // ── BehaviorSnapshot builder test ─────────────────────────────────────────

    @Test
    void behaviorSnapshot_builderWorks() {
        BehaviorSnapshot snapshot = BehaviorSnapshot.builder()
            .monthlyIncome(BigDecimal.valueOf(100000))
            .monthlyExpense(BigDecimal.valueOf(60000))
            .savingsRate(40.0)
            .emergencyFundMonths(6.0)
            .debtRatio(10.0)
            .riskProfile("moderate")
            .goalCount(3)
            .financialHealth(75)
            .build();

        assertThat(snapshot.getMonthlyIncome()).isEqualByComparingTo(BigDecimal.valueOf(100000));
        assertThat(snapshot.getSavingsRate()).isEqualTo(40.0);
        assertThat(snapshot.getEmergencyFundMonths()).isEqualTo(6.0);
        assertThat(snapshot.getRiskProfile()).isEqualTo("moderate");
        assertThat(snapshot.getGoalCount()).isEqualTo(3);
        assertThat(snapshot.getFinancialHealth()).isEqualTo(75);
    }
}
