package com.pennywise.engine.decision;

import com.pennywise.dto.AffordabilityResponse;
import com.pennywise.dto.ScenarioDto;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class DecisionEngineTest {

    private DecisionEngine engine;

    @BeforeEach
    void setUp() {
        RiskEngine riskEngine = new RiskEngine();
        TradeoffEngine tradeoffEngine = new TradeoffEngine();
        ExplainabilityEngine explainEngine = new ExplainabilityEngine();
        engine = new DecisionEngine(riskEngine, tradeoffEngine, explainEngine);
    }

    private DecisionContext ctx(double income, double expenses, double ef, double price) {
        return DecisionContext.builder()
                .itemName("Test Item")
                .price(BigDecimal.valueOf(price))
                .monthlyIncome(BigDecimal.valueOf(income))
                .avgMonthlyExpenses(BigDecimal.valueOf(expenses))
                .currentEmergencyFund(BigDecimal.valueOf(ef))
                .build();
    }

    private DecisionContext loanCtx(double income, double expenses, double ef,
                                     double price, double down, double rate, int tenure) {
        return DecisionContext.builder()
                .itemName("Test Item")
                .price(BigDecimal.valueOf(price))
                .downPayment(BigDecimal.valueOf(down))
                .interestRatePercent(BigDecimal.valueOf(rate))
                .tenureMonths(tenure)
                .monthlyIncome(BigDecimal.valueOf(income))
                .avgMonthlyExpenses(BigDecimal.valueOf(expenses))
                .currentEmergencyFund(BigDecimal.valueOf(ef))
                .build();
    }

    // ── Recommendation Strength ───────────────────────────────────────────

    @Test
    void high_strength_when_purchase_clearly_safe() {
        // Large income, tiny purchase, massive EF
        var ctx = ctx(200_000, 50_000, 800_000, 30_000);
        var response = engine.evaluate(ctx);
        assertThat(response.getVerdict()).isEqualTo("SAFE_TO_BUY");
        assertThat(response.getRecommendationStrength()).isEqualTo("HIGH");
        assertThat(response.getConfidence()).isGreaterThanOrEqualTo(85);
    }

    @Test
    void medium_strength_when_purchase_borderline() {
        // Moderate surplus, EF slightly above floor
        var ctx = ctx(80_000, 60_000, 360_000, 50_000);
        var response = engine.evaluate(ctx);
        assertThat(response.getRecommendationStrength()).isIn("MEDIUM", "LOW");
        assertThat(response.getConfidence()).isLessThan(85);
    }

    @Test
    void low_strength_when_financially_stressed() {
        // Expenses equal income, no surplus
        var ctx = ctx(50_000, 50_000, 100_000, 80_000);
        var response = engine.evaluate(ctx);
        assertThat(response.getVerdict()).isEqualTo("DONT_BUY");
        assertThat(response.getRecommendationStrength()).isEqualTo("LOW");
    }

    // ── Why Not generation ────────────────────────────────────────────────

    @Test
    void why_not_populated_for_non_recommended_scenarios() {
        var ctx = ctx(80_000, 50_000, 100_000, 150_000);
        var response = engine.evaluate(ctx);
        assertThat(response.getScenarios()).isNotEmpty();
        List<ScenarioDto> nonRecommended = response.getScenarios().stream()
                .filter(s -> !s.isRecommended())
                .toList();
        assertThat(nonRecommended).isNotEmpty();
        nonRecommended.forEach(s ->
                assertThat(s.getWhyNot()).as("whyNot for scenario: " + s.getLabel()).isNotEmpty()
        );
    }

    @Test
    void recommended_scenario_has_empty_why_not() {
        var ctx = ctx(80_000, 50_000, 100_000, 150_000);
        var response = engine.evaluate(ctx);
        ScenarioDto recommended = response.getScenarios().stream()
                .filter(ScenarioDto::isRecommended)
                .findFirst()
                .orElseThrow();
        assertThat(recommended.getWhyNot()).isEmpty();
    }

    // ── Tradeoff generation ───────────────────────────────────────────────

    @Test
    void tradeoffs_populated_for_all_scenarios() {
        var ctx = loanCtx(100_000, 40_000, 200_000, 800_000, 200_000, 9.5, 60);
        var response = engine.evaluate(ctx);
        response.getScenarios().forEach(s ->
                assertThat(s.getTradeoffs()).as("tradeoffs for: " + s.getLabel()).isNotEmpty()
        );
    }

    @Test
    void tradeoffs_have_pro_and_con_types() {
        var ctx = loanCtx(100_000, 40_000, 200_000, 800_000, 200_000, 9.5, 60);
        var response = engine.evaluate(ctx);
        boolean hasPro = response.getScenarios().stream()
                .flatMap(s -> s.getTradeoffs().stream())
                .anyMatch(t -> t.getType().name().equals("PRO"));
        boolean hasCon = response.getScenarios().stream()
                .flatMap(s -> s.getTradeoffs().stream())
                .anyMatch(t -> t.getType().name().equals("CON"));
        assertThat(hasPro).isTrue();
        assertThat(hasCon).isTrue();
    }

    // ── Scenario ordering ─────────────────────────────────────────────────

    @Test
    void exactly_one_scenario_is_recommended() {
        var ctx = loanCtx(100_000, 40_000, 200_000, 800_000, 200_000, 9.5, 60);
        var response = engine.evaluate(ctx);
        long count = response.getScenarios().stream().filter(ScenarioDto::isRecommended).count();
        assertThat(count).isEqualTo(1);
    }

    @Test
    void recommended_scenario_has_highest_confidence() {
        var ctx = ctx(80_000, 50_000, 100_000, 150_000);
        var response = engine.evaluate(ctx);
        int maxConf = response.getScenarios().stream().mapToInt(ScenarioDto::getConfidence).max().orElse(0);
        ScenarioDto recommended = response.getScenarios().stream()
                .filter(ScenarioDto::isRecommended).findFirst().orElseThrow();
        assertThat(recommended.getConfidence()).isEqualTo(maxConf);
    }

    // ── Backward compatibility ────────────────────────────────────────────

    @Test
    void verdict_field_still_populated() {
        var ctx = ctx(80_000, 50_000, 300_000, 50_000);
        var response = engine.evaluate(ctx);
        assertThat(response.getVerdict()).isNotBlank();
    }

    @Test
    void reason_field_still_populated() {
        var ctx = ctx(80_000, 50_000, 300_000, 50_000);
        var response = engine.evaluate(ctx);
        assertThat(response.getReason()).isNotBlank();
    }

    @Test
    void dti_is_zero_for_lump_sum_purchase() {
        var ctx = ctx(100_000, 40_000, 500_000, 50_000);
        var response = engine.evaluate(ctx);
        assertThat(response.getDtiRatio()).isEqualByComparingTo(BigDecimal.ZERO);
    }

    @Test
    void emi_populated_for_loan_purchase() {
        var ctx = loanCtx(100_000, 40_000, 500_000, 800_000, 200_000, 10.0, 60);
        var response = engine.evaluate(ctx);
        assertThat(response.getMonthlyEmi()).isNotNull();
        assertThat(response.getMonthlyEmi()).isGreaterThan(BigDecimal.ZERO);
    }
}
