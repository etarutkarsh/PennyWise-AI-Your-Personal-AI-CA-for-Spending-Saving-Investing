package com.pennywise.engine.events.domain;

import lombok.Getter;
import java.math.BigDecimal;
import java.util.UUID;

@Getter
public class GoalCompletedEvent extends PennywiseEvent {
    private final UUID goalId;
    private final String goalName;
    private final BigDecimal targetAmount;

    public GoalCompletedEvent(UUID userId, UUID goalId, String goalName, BigDecimal targetAmount) {
        super(userId);
        this.goalId = goalId;
        this.goalName = goalName;
        this.targetAmount = targetAmount;
    }

    @Override public String eventType() { return "GOAL_COMPLETED"; }
    @Override public String source() { return "GoalService"; }
}
