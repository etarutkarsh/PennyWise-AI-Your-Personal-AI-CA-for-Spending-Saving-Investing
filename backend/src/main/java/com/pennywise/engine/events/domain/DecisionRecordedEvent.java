package com.pennywise.engine.events.domain;

import lombok.Getter;
import java.math.BigDecimal;
import java.util.UUID;

@Getter
public class DecisionRecordedEvent extends PennywiseEvent {
    private final UUID memoryId;
    private final String itemName;
    private final BigDecimal itemPrice;
    private final String recommendation;
    private final String recommendationStrength;

    public DecisionRecordedEvent(UUID userId, UUID memoryId, String itemName, BigDecimal itemPrice,
                                  String recommendation, String recommendationStrength) {
        super(userId);
        this.memoryId = memoryId;
        this.itemName = itemName;
        this.itemPrice = itemPrice;
        this.recommendation = recommendation;
        this.recommendationStrength = recommendationStrength;
    }

    @Override public String eventType() { return "DECISION_RECORDED"; }
    @Override public String source() { return "DecisionRecorder"; }
}
