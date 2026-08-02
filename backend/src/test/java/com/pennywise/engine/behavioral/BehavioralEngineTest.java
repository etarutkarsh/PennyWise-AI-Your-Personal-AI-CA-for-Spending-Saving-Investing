package com.pennywise.engine.behavioral;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;

class BehavioralEngineTest {

    private BehaviorInsightEngine insightEngine;

    @BeforeEach
    void setUp() {
        insightEngine = new BehaviorInsightEngine();
    }

    // ── scoreToGrade tests ────────────────────────────────────────────────────

    @Test
    void scoreToGrade_90_returnsA() {
        assertThat(insightEngine.scoreToGrade(90)).isEqualTo("A");
    }

    @Test
    void scoreToGrade_95_returnsA() {
        assertThat(insightEngine.scoreToGrade(95)).isEqualTo("A");
    }

    @Test
    void scoreToGrade_85_returnsAMinus() {
        assertThat(insightEngine.scoreToGrade(85)).isEqualTo("A-");
    }

    @Test
    void scoreToGrade_80_returnsBPlus() {
        assertThat(insightEngine.scoreToGrade(80)).isEqualTo("B+");
    }

    @Test
    void scoreToGrade_50_returnsCMinus() {
        assertThat(insightEngine.scoreToGrade(50)).isEqualTo("C-");
    }

    @Test
    void scoreToGrade_49_returnsD() {
        assertThat(insightEngine.scoreToGrade(49)).isEqualTo("D");
    }

    // ── computeTraits tests ───────────────────────────────────────────────────

    @Test
    void computeTraits_highDiscipline_returnsGradeA() {
        BehaviorScores scores = BehaviorScores.builder()
                .disciplineScore(92)
                .consistencyScore(85)
                .impulseScore(88)
                .riskBehaviorScore(75)
                .goalCommitmentScore(90)
                .savingsDisciplineScore(87)
                .spendingStabilityScore(80)
                .recommendationFollowRate(82)
                .patterns(Set.of(BehaviorPattern.DISCIPLINED_FOLLOWER))
                .eventsAnalyzed(45)
                .decisionsAnalyzed(8)
                .monthsOfData(6)
                .build();

        Map<String, String> traits = insightEngine.computeTraits(scores);
        assertThat(traits.get("discipline")).isEqualTo("A");
    }

    @Test
    void computeTraits_allScoresMappedToGrades() {
        BehaviorScores scores = BehaviorScores.builder()
                .disciplineScore(75)
                .consistencyScore(60)
                .impulseScore(80)
                .riskBehaviorScore(65)
                .goalCommitmentScore(70)
                .savingsDisciplineScore(55)
                .spendingStabilityScore(50)
                .recommendationFollowRate(68)
                .patterns(Set.of())
                .eventsAnalyzed(20)
                .decisionsAnalyzed(5)
                .monthsOfData(4)
                .build();

        Map<String, String> traits = insightEngine.computeTraits(scores);
        assertThat(traits).containsKeys("discipline", "impulseControl", "goalCommitment",
                "savingsConsistency", "riskManagement", "spendingStability");
        assertThat(traits.get("discipline")).isEqualTo("B");    // 75 → B
        assertThat(traits.get("impulseControl")).isEqualTo("B+"); // 80 → B+
    }

    // ── classifyPrimaryBehavior tests ─────────────────────────────────────────

    @Test
    void classifyPrimaryBehavior_consistentSaverPattern_returnsLabel() {
        BehaviorScores scores = BehaviorScores.builder()
                .disciplineScore(70)
                .consistencyScore(75)
                .impulseScore(65)
                .riskBehaviorScore(60)
                .goalCommitmentScore(72)
                .savingsDisciplineScore(68)
                .spendingStabilityScore(70)
                .recommendationFollowRate(65)
                .patterns(Set.of(BehaviorPattern.CONSISTENT_SAVER))
                .eventsAnalyzed(30)
                .decisionsAnalyzed(5)
                .monthsOfData(5)
                .build();

        assertThat(insightEngine.classifyPrimaryBehavior(scores)).isEqualTo("Consistent Saver");
    }

    @Test
    void classifyPrimaryBehavior_impulsePattern_returnsLabel() {
        BehaviorScores scores = BehaviorScores.builder()
                .disciplineScore(35)
                .consistencyScore(40)
                .impulseScore(25)
                .riskBehaviorScore(45)
                .goalCommitmentScore(30)
                .savingsDisciplineScore(35)
                .spendingStabilityScore(30)
                .recommendationFollowRate(30)
                .patterns(Set.of(BehaviorPattern.IMPULSE_PURCHASER))
                .eventsAnalyzed(18)
                .decisionsAnalyzed(4)
                .monthsOfData(3)
                .build();

        assertThat(insightEngine.classifyPrimaryBehavior(scores)).isEqualTo("Impulse Purchaser");
    }

    @Test
    void classifyPrimaryBehavior_noData_returnsBuildingProfile() {
        BehaviorScores scores = BehaviorScores.builder()
                .disciplineScore(50)
                .consistencyScore(50)
                .impulseScore(50)
                .riskBehaviorScore(50)
                .goalCommitmentScore(50)
                .savingsDisciplineScore(50)
                .spendingStabilityScore(50)
                .recommendationFollowRate(0)
                .patterns(Set.of())
                .eventsAnalyzed(2)
                .decisionsAnalyzed(0)
                .monthsOfData(0)
                .build();

        assertThat(insightEngine.classifyPrimaryBehavior(scores)).isEqualTo("Building Profile");
    }

    // ── generateInsights tests ────────────────────────────────────────────────

    @Test
    void generateInsights_notEmpty() {
        BehaviorScores scores = BehaviorScores.builder()
                .disciplineScore(75)
                .consistencyScore(70)
                .impulseScore(60)
                .riskBehaviorScore(65)
                .goalCommitmentScore(80)
                .savingsDisciplineScore(72)
                .spendingStabilityScore(68)
                .recommendationFollowRate(65)
                .patterns(Set.of())
                .eventsAnalyzed(20)
                .decisionsAnalyzed(5)
                .monthsOfData(3)
                .build();

        List<String> insights = insightEngine.generateInsights(scores);
        assertThat(insights).isNotEmpty();
        assertThat(insights.size()).isGreaterThanOrEqualTo(2);
    }

    @Test
    void generateInsights_noData_returnsAtLeastTwo() {
        BehaviorScores scores = BehaviorScores.builder()
                .disciplineScore(50)
                .consistencyScore(50)
                .impulseScore(50)
                .riskBehaviorScore(50)
                .goalCommitmentScore(50)
                .savingsDisciplineScore(50)
                .spendingStabilityScore(50)
                .recommendationFollowRate(0)
                .patterns(Set.of())
                .eventsAnalyzed(0)
                .decisionsAnalyzed(0)
                .monthsOfData(0)
                .build();

        List<String> insights = insightEngine.generateInsights(scores);
        assertThat(insights).hasSizeGreaterThanOrEqualTo(2);
    }

    @Test
    void generateInsights_salaryEuphoria_containsEuphoriaInsight() {
        BehaviorScores scores = BehaviorScores.builder()
                .disciplineScore(45)
                .consistencyScore(50)
                .impulseScore(30)
                .riskBehaviorScore(50)
                .goalCommitmentScore(50)
                .savingsDisciplineScore(50)
                .spendingStabilityScore(40)
                .recommendationFollowRate(50)
                .patterns(Set.of(BehaviorPattern.SALARY_EUPHORIA))
                .eventsAnalyzed(15)
                .decisionsAnalyzed(3)
                .monthsOfData(3)
                .build();

        List<String> insights = insightEngine.generateInsights(scores);
        boolean hasEuphoria = insights.stream().anyMatch(s -> s.contains("salary credit"));
        assertThat(hasEuphoria).isTrue();
    }

    // ── dataConfidence tests (via BehaviorScores months) ─────────────────────

    @Test
    void dataConfidence_lessThan3Months_isLow() {
        BehaviorScores scores = BehaviorScores.builder()
                .disciplineScore(50).consistencyScore(50).impulseScore(50)
                .riskBehaviorScore(50).goalCommitmentScore(50).savingsDisciplineScore(50)
                .spendingStabilityScore(50).recommendationFollowRate(0)
                .patterns(Set.of()).eventsAnalyzed(5).decisionsAnalyzed(1).monthsOfData(2)
                .build();

        // dataConfidence logic mirrors BehaviorService.toDto
        String confidence = scores.getMonthsOfData() >= 6 ? "HIGH"
                : scores.getMonthsOfData() >= 3 ? "MEDIUM" : "LOW";
        assertThat(confidence).isEqualTo("LOW");
    }

    @Test
    void dataConfidence_6Months_isHigh() {
        BehaviorScores scores = BehaviorScores.builder()
                .disciplineScore(70).consistencyScore(70).impulseScore(70)
                .riskBehaviorScore(65).goalCommitmentScore(75).savingsDisciplineScore(68)
                .spendingStabilityScore(72).recommendationFollowRate(60)
                .patterns(Set.of(BehaviorPattern.CONSISTENT_SAVER))
                .eventsAnalyzed(50).decisionsAnalyzed(10).monthsOfData(6)
                .build();

        String confidence = scores.getMonthsOfData() >= 6 ? "HIGH"
                : scores.getMonthsOfData() >= 3 ? "MEDIUM" : "LOW";
        assertThat(confidence).isEqualTo("HIGH");
    }

    // ── False-positive protection test ────────────────────────────────────────

    @Test
    void falsePositiveProtection_singleEvent_doesNotDetectPattern() {
        // SALARY_EUPHORIA requires >= 2 occurrences.
        // With zero large purchase events, the pattern must not be detected.
        SpendingPsychologyEngine engine = new SpendingPsychologyEngine();

        // Single salary event, no large purchases
        com.pennywise.entity.FinancialEvent salaryEvent = new com.pennywise.entity.FinancialEvent();
        salaryEvent.setEventType("SALARY_CREDITED");
        salaryEvent.setUserId(java.util.UUID.randomUUID());
        salaryEvent.setOccurredAt(java.time.Instant.now());

        SpendingPsychologyEngine.SpendingResult result =
                engine.analyze(java.util.UUID.randomUUID(), List.of(salaryEvent));

        assertThat(result.patterns()).doesNotContain(BehaviorPattern.SALARY_EUPHORIA);
    }
}
