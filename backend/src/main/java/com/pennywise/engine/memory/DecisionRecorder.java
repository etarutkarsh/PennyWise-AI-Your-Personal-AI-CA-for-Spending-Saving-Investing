package com.pennywise.engine.memory;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.pennywise.dto.AffordabilityResponse;
import com.pennywise.dto.ScenarioDto;
import com.pennywise.engine.decision.DecisionContext;
import com.pennywise.engine.events.EventBus;
import com.pennywise.engine.events.domain.DecisionRecordedEvent;
import com.pennywise.entity.DecisionMemory;
import com.pennywise.entity.User;
import com.pennywise.repository.DecisionMemoryRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;

@Slf4j
@Component
@RequiredArgsConstructor
public class DecisionRecorder {

    private final DecisionMemoryRepository repository;
    private final DecisionReviewScheduler reviewScheduler;
    private final ObjectMapper objectMapper;
    private final EventBus eventBus;

    public void record(User user, DecisionContext ctx, AffordabilityResponse response) {
        try {
            DecisionMemory memory = new DecisionMemory();
            memory.setUserId(user.getId());
            memory.setDecisionType("PURCHASE");
            memory.setItemName(ctx.getItemName());
            memory.setItemPrice(ctx.getPrice());
            memory.setRecommendation(response.getVerdict());
            memory.setRecommendationStrength(
                response.getRecommendationStrength() != null ? response.getRecommendationStrength() : "LOW");

            // Persist JSON blobs
            memory.setRecommendationEvidence(toJson(response.getStrengthEvidence()));

            ScenarioDto recommended = findRecommended(response.getScenarios());
            memory.setRecommendedScenario(toJson(recommended));

            List<ScenarioDto> alternatives = response.getScenarios() == null ? List.of()
                : response.getScenarios().stream().filter(s -> !s.isRecommended()).toList();
            memory.setAlternatives(toJson(alternatives));

            memory.setGoalImpacts(toJson(response.getGoalImpacts()));

            // Build and persist behavior snapshot
            BehaviorSnapshot snapshot = buildSnapshot(user, ctx, response);
            memory.setBehaviorSnapshot(toJson(snapshot));

            memory.setFinancialHealthAtDecision(0); // will be enriched by HealthScoreService later

            memory.setReviewAfter(reviewScheduler.reviewDateFor(ctx.getItemName()));
            memory.setStatus("PENDING_REVIEW");

            DecisionMemory saved = repository.save(memory);
            log.info("Recorded decision memory for user={} item={}", user.getId(), ctx.getItemName());
            eventBus.publish(new DecisionRecordedEvent(
                    user.getId(),
                    saved.getId(),
                    saved.getItemName(),
                    saved.getItemPrice(),
                    saved.getRecommendation(),
                    saved.getRecommendationStrength()));
        } catch (Exception e) {
            log.warn("Decision recording failed — not blocking API response", e);
        }
    }

    private BehaviorSnapshot buildSnapshot(User user, DecisionContext ctx, AffordabilityResponse response) {
        BigDecimal income = ctx.getMonthlyIncome();
        BigDecimal expenses = ctx.getAvgMonthlyExpenses();
        BigDecimal surplus = income.subtract(expenses).max(BigDecimal.ZERO);
        double savingsRate = income.compareTo(BigDecimal.ZERO) > 0
            ? surplus.divide(income, 4, RoundingMode.HALF_UP).doubleValue() * 100 : 0;

        double efMonths = (ctx.getCurrentEmergencyFund() != null && expenses.compareTo(BigDecimal.ZERO) > 0)
            ? ctx.getCurrentEmergencyFund().divide(expenses, 2, RoundingMode.HALF_UP).doubleValue() : 0;

        double dtiRatio = response.getDtiRatio() != null ? response.getDtiRatio().doubleValue() : 0;

        String riskProfile = dtiRatio > 40 ? "conservative"
            : savingsRate > 30 ? "aggressive" : "moderate";

        return BehaviorSnapshot.builder()
            .monthlyIncome(income)
            .monthlyExpense(expenses)
            .savingsRate(savingsRate)
            .emergencyFundMonths(efMonths)
            .debtRatio(dtiRatio)
            .riskProfile(riskProfile)
            .goalCount(response.getGoalImpacts() != null ? response.getGoalImpacts().size() : 0)
            .financialHealth(0)
            .build();
    }

    private ScenarioDto findRecommended(List<ScenarioDto> scenarios) {
        if (scenarios == null) return null;
        return scenarios.stream().filter(ScenarioDto::isRecommended).findFirst().orElse(null);
    }

    private String toJson(Object obj) {
        if (obj == null) return null;
        try {
            return objectMapper.writeValueAsString(obj);
        } catch (Exception e) {
            log.warn("JSON serialization failed for {}", obj.getClass().getSimpleName(), e);
            return null;
        }
    }
}
