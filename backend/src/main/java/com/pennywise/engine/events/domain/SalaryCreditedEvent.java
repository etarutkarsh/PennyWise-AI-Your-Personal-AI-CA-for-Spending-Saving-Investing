package com.pennywise.engine.events.domain;

import lombok.Getter;
import java.math.BigDecimal;
import java.util.UUID;

@Getter
public class SalaryCreditedEvent extends PennywiseEvent {
    private final BigDecimal amount;

    public SalaryCreditedEvent(UUID userId, BigDecimal amount) {
        super(userId);
        this.amount = amount;
    }

    @Override public String eventType() { return "SALARY_CREDITED"; }
    @Override public String source() { return "TransactionService"; }
}
