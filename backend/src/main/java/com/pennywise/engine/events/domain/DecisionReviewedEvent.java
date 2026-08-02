package com.pennywise.engine.events.domain;

import lombok.Getter;
import java.math.BigDecimal;
import java.util.UUID;

@Getter
public class DecisionReviewedEvent extends PennywiseEvent {
    private final UUID memoryId;
    private final boolean followedRecommendation;
    private final BigDecimal accuracyScore;
    private final Integer healthDelta;

    public DecisionReviewedEvent(UUID userId, UUID memoryId, boolean followedRecommendation,
                                  BigDecimal accuracyScore, Integer healthDelta) {
        super(userId);
        this.memoryId = memoryId;
        this.followedRecommendation = followedRecommendation;
        this.accuracyScore = accuracyScore;
        this.healthDelta = healthDelta;
    }

    @Override public String eventType() { return "DECISION_REVIEWED"; }
    @Override public String source() { return "DecisionMemoryService"; }
}
