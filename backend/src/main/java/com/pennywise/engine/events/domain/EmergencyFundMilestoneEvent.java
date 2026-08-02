package com.pennywise.engine.events.domain;

import lombok.Getter;
import java.util.UUID;

@Getter
public class EmergencyFundMilestoneEvent extends PennywiseEvent {
    private final double monthsCovered;
    private final int milestone; // 1, 3, or 6

    public EmergencyFundMilestoneEvent(UUID userId, double monthsCovered, int milestone) {
        super(userId);
        this.monthsCovered = monthsCovered;
        this.milestone = milestone;
    }

    @Override public String eventType() { return "EMERGENCY_FUND_MILESTONE"; }
    @Override public String source() { return "AffordabilityService"; }
}
