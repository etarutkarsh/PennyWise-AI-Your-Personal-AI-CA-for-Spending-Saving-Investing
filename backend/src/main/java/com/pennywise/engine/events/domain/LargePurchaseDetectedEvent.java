package com.pennywise.engine.events.domain;

import lombok.Getter;
import java.math.BigDecimal;
import java.util.UUID;

@Getter
public class LargePurchaseDetectedEvent extends PennywiseEvent {
    private final BigDecimal amount;
    private final String merchant;
    private final BigDecimal monthlyIncome;
    private final double incomePercent; // amount/income * 100

    public LargePurchaseDetectedEvent(UUID userId, BigDecimal amount, String merchant,
                                       BigDecimal monthlyIncome, double incomePercent) {
        super(userId);
        this.amount = amount;
        this.merchant = merchant;
        this.monthlyIncome = monthlyIncome;
        this.incomePercent = incomePercent;
    }

    @Override public String eventType() { return "LARGE_PURCHASE_DETECTED"; }
    @Override public String source() { return "TransactionService"; }
}
