package com.pennywise.engine.events.domain;

import lombok.Getter;
import java.math.BigDecimal;
import java.util.UUID;

@Getter
public class BudgetExceededEvent extends PennywiseEvent {
    private final String category;
    private final BigDecimal budgetLimit;
    private final BigDecimal actualSpend;

    public BudgetExceededEvent(UUID userId, String category, BigDecimal budgetLimit, BigDecimal actualSpend) {
        super(userId);
        this.category = category;
        this.budgetLimit = budgetLimit;
        this.actualSpend = actualSpend;
    }

    @Override public String eventType() { return "BUDGET_EXCEEDED"; }
    @Override public String source() { return "TransactionService"; }
}
