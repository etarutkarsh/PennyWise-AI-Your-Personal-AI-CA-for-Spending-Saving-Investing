package com.pennywise.financial;

import com.pennywise.financial.engine.HealthScoreEngine;
import com.pennywise.financial.model.HealthScoreInput;
import com.pennywise.financial.model.HealthScoreResult;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class HealthScoreEngineTest {

    private HealthScoreEngine engine;

    @BeforeEach
    void setUp() {
        engine = new HealthScoreEngine();
    }

    private HealthScoreInput buildInput(double salary, double expenses, double savings,
                                        double debt, int activeGoals, int goalsOnTrack,
                                        double monthlyInvestment) {
        List<HealthScoreInput.GoalProgress> goals = java.util.stream.IntStream.range(0, activeGoals)
            .mapToObj(i -> new HealthScoreInput.GoalProgress(
                i < goalsOnTrack ? 50_000 : 1_000,  // on-track: 50% progress
                100_000, 24, i < goalsOnTrack))
            .toList();

        return new HealthScoreInput(
            salary, expenses, savings, debt,
            goals,
            new HealthScoreInput.TransactionSummary(salary, expenses, salary > 0)
        );
    }

    @Test
    @DisplayName("Total score is within 0–100")
    void totalScoreIsWithin0And100() {
        var input = buildInput(100_000, 60_000, 600_000, 0, 3, 3, 20_000);
        HealthScoreResult result = engine.compute(input);
        assertThat(result.totalScore()).isBetween(0, 100);
    }

    @Test
    @DisplayName("Each dimension score is within its max")
    void dimensionScoresAreWithinMax() {
        var input = buildInput(100_000, 70_000, 50_000, 200_000, 2, 1, 5_000);
        HealthScoreResult result = engine.compute(input);
        result.dimensions().forEach(d ->
            assertThat(d.score())
                .withFailMessage("Dimension '%s' score %d exceeds max %d", d.dimension(), d.score(), d.maxScore())
                .isBetween(0, d.maxScore()));
    }

    @Test
    @DisplayName("Excellent saver with no debt gets high total score")
    void excellentSaverGetsHighScore() {
        var input = buildInput(200_000, 80_000, 2_400_000, 0, 5, 5, 50_000);
        HealthScoreResult result = engine.compute(input);
        assertThat(result.totalScore()).isGreaterThan(70);
    }

    @Test
    @DisplayName("Top actions list is not empty for struggling profile")
    void topActionsNotEmpty() {
        var input = buildInput(50_000, 55_000, 0, 500_000, 0, 0, 0);
        HealthScoreResult result = engine.compute(input);
        assertThat(result.topActions()).isNotEmpty();
    }

    @Test
    @DisplayName("Grade matches score range")
    void gradeMatchesScore() {
        var input = buildInput(200_000, 80_000, 2_400_000, 0, 5, 5, 50_000);
        HealthScoreResult result = engine.compute(input);
        int score = result.totalScore();
        if (score >= 90) assertThat(result.grade()).isEqualTo("A+");
        else if (score >= 80) assertThat(result.grade()).isEqualTo("A");
        else if (score >= 70) assertThat(result.grade()).isEqualTo("B+");
        else if (score >= 60) assertThat(result.grade()).isEqualTo("B");
        else if (score >= 50) assertThat(result.grade()).isEqualTo("C");
        else assertThat(result.grade()).isEqualTo("D");
    }

    @Test
    @DisplayName("Exactly 8 dimensions are returned")
    void exactly8Dimensions() {
        var input = buildInput(100_000, 60_000, 360_000, 0, 2, 2, 15_000);
        HealthScoreResult result = engine.compute(input);
        assertThat(result.dimensions()).hasSize(8);
    }

    @Test
    @DisplayName("Summary is non-blank")
    void summaryIsNonBlank() {
        var input = buildInput(100_000, 60_000, 360_000, 100_000, 2, 1, 10_000);
        HealthScoreResult result = engine.compute(input);
        assertThat(result.summary()).isNotBlank();
    }
}
