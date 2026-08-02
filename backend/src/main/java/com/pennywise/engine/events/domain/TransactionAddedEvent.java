package com.pennywise.engine.events.domain;

import lombok.Getter;
import java.math.BigDecimal;
import java.util.UUID;

@Getter
public class TransactionAddedEvent extends PennywiseEvent {
    private final BigDecimal amount;
    private final String direction; // DEBIT | CREDIT
    private final String category;
    private final String merchant;

    public TransactionAddedEvent(UUID userId, BigDecimal amount, String direction, String category, String merchant) {
        super(userId);
        this.amount = amount;
        this.direction = direction;
        this.category = category;
        this.merchant = merchant;
    }

    @Override public String eventType() { return "TRANSACTION_ADDED"; }
    @Override public String source() { return "TransactionService"; }
}
