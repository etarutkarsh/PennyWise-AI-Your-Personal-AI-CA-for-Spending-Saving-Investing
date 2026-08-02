package com.pennywise.engine.events;

import com.pennywise.engine.events.domain.*;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for domain events — no Spring context needed.
 * Verifies correct eventType(), non-null base fields, and field mapping.
 */
class EventBusTest {

    private final UUID userId = UUID.randomUUID();

    @Test
    @DisplayName("TransactionAddedEvent has correct eventType")
    void transactionAddedEvent_correctType() {
        TransactionAddedEvent event = new TransactionAddedEvent(
                userId, new BigDecimal("5000"), "DEBIT", "Food", "Zomato");
        assertThat(event.eventType()).isEqualTo("TRANSACTION_ADDED");
        assertNonNullBaseFields(event);
        assertThat(event.getAmount()).isEqualByComparingTo("5000");
        assertThat(event.getDirection()).isEqualTo("DEBIT");
        assertThat(event.getCategory()).isEqualTo("Food");
        assertThat(event.getMerchant()).isEqualTo("Zomato");
    }

    @Test
    @DisplayName("GoalCreatedEvent has correct eventType")
    void goalCreatedEvent_correctType() {
        UUID goalId = UUID.randomUUID();
        GoalCreatedEvent event = new GoalCreatedEvent(userId, goalId, "Laptop Fund", new BigDecimal("80000"));
        assertThat(event.eventType()).isEqualTo("GOAL_CREATED");
        assertNonNullBaseFields(event);
        assertThat(event.getGoalId()).isEqualTo(goalId);
        assertThat(event.getGoalName()).isEqualTo("Laptop Fund");
        assertThat(event.getTargetAmount()).isEqualByComparingTo("80000");
    }

    @Test
    @DisplayName("GoalCompletedEvent has correct eventType")
    void goalCompletedEvent_correctType() {
        UUID goalId = UUID.randomUUID();
        GoalCompletedEvent event = new GoalCompletedEvent(userId, goalId, "Emergency Fund", new BigDecimal("150000"));
        assertThat(event.eventType()).isEqualTo("GOAL_COMPLETED");
        assertNonNullBaseFields(event);
        assertThat(event.getGoalId()).isEqualTo(goalId);
    }

    @Test
    @DisplayName("BudgetExceededEvent has correct eventType")
    void budgetExceededEvent_correctType() {
        BudgetExceededEvent event = new BudgetExceededEvent(
                userId, "Food", new BigDecimal("10000"), new BigDecimal("12500"));
        assertThat(event.eventType()).isEqualTo("BUDGET_EXCEEDED");
        assertNonNullBaseFields(event);
        assertThat(event.getCategory()).isEqualTo("Food");
        assertThat(event.getBudgetLimit()).isEqualByComparingTo("10000");
        assertThat(event.getActualSpend()).isEqualByComparingTo("12500");
    }

    @Test
    @DisplayName("LargePurchaseDetectedEvent has correct eventType")
    void largePurchaseDetectedEvent_correctType() {
        LargePurchaseDetectedEvent event = new LargePurchaseDetectedEvent(
                userId, new BigDecimal("25000"), "Apple Store", new BigDecimal("100000"), 25.0);
        assertThat(event.eventType()).isEqualTo("LARGE_PURCHASE_DETECTED");
        assertNonNullBaseFields(event);
        assertThat(event.getIncomePercent()).isEqualTo(25.0);
        assertThat(event.getMerchant()).isEqualTo("Apple Store");
    }

    @Test
    @DisplayName("DecisionRecordedEvent has correct eventType")
    void decisionRecordedEvent_correctType() {
        UUID memoryId = UUID.randomUUID();
        DecisionRecordedEvent event = new DecisionRecordedEvent(
                userId, memoryId, "MacBook Pro", new BigDecimal("199000"), "SAFE_TO_BUY", "HIGH");
        assertThat(event.eventType()).isEqualTo("DECISION_RECORDED");
        assertNonNullBaseFields(event);
        assertThat(event.getMemoryId()).isEqualTo(memoryId);
        assertThat(event.getRecommendation()).isEqualTo("SAFE_TO_BUY");
        assertThat(event.getRecommendationStrength()).isEqualTo("HIGH");
    }

    @Test
    @DisplayName("DecisionReviewedEvent has correct eventType")
    void decisionReviewedEvent_correctType() {
        UUID memoryId = UUID.randomUUID();
        DecisionReviewedEvent event = new DecisionReviewedEvent(
                userId, memoryId, true, new BigDecimal("85.5"), 5);
        assertThat(event.eventType()).isEqualTo("DECISION_REVIEWED");
        assertNonNullBaseFields(event);
        assertThat(event.isFollowedRecommendation()).isTrue();
        assertThat(event.getAccuracyScore()).isEqualByComparingTo("85.5");
        assertThat(event.getHealthDelta()).isEqualTo(5);
    }

    @Test
    @DisplayName("SalaryCreditedEvent has correct eventType")
    void salaryCreditedEvent_correctType() {
        SalaryCreditedEvent event = new SalaryCreditedEvent(userId, new BigDecimal("75000"));
        assertThat(event.eventType()).isEqualTo("SALARY_CREDITED");
        assertNonNullBaseFields(event);
        assertThat(event.getAmount()).isEqualByComparingTo("75000");
    }

    @Test
    @DisplayName("EmergencyFundMilestoneEvent has correct eventType")
    void emergencyFundMilestoneEvent_correctType() {
        EmergencyFundMilestoneEvent event = new EmergencyFundMilestoneEvent(userId, 3.2, 3);
        assertThat(event.eventType()).isEqualTo("EMERGENCY_FUND_MILESTONE");
        assertNonNullBaseFields(event);
        assertThat(event.getMonthsCovered()).isEqualTo(3.2);
        assertThat(event.getMilestone()).isEqualTo(3);
    }

    /** Asserts the three invariants required by all PennywiseEvent subclasses. */
    private void assertNonNullBaseFields(PennywiseEvent event) {
        assertThat(event.getUserId()).isNotNull();
        assertThat(event.getOccurredAt()).isNotNull();
        assertThat(event.getCorrelationId()).isNotNull();
    }
}
