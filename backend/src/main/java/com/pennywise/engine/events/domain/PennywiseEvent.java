package com.pennywise.engine.events.domain;

import lombok.Getter;
import java.time.Instant;
import java.util.UUID;

@Getter
public abstract class PennywiseEvent {
    private final UUID userId;
    private final Instant occurredAt = Instant.now();
    private final UUID correlationId;

    protected PennywiseEvent(UUID userId) {
        this.userId = userId;
        this.correlationId = UUID.randomUUID();
    }

    protected PennywiseEvent(UUID userId, UUID correlationId) {
        this.userId = userId;
        this.correlationId = correlationId;
    }

    public abstract String eventType();
    public abstract String source();
}
