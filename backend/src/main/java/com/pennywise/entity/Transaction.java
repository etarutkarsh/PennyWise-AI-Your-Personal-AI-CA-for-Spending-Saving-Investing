package com.pennywise.entity;

import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Getter
@Setter
@Entity
@Table(name = "transactions")
public class Transaction extends BaseEntity {

    private UUID userId;

    private BigDecimal amount;

    private String merchant;

    private String note;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id")
    private Category category;

    private Instant transactionDate;

    /** UPI | CARD | CASH | NETBANKING | WALLET */
    private String paymentMethod;

    /** DEBIT | CREDIT */
    @Enumerated(EnumType.STRING)
    private TransactionDirection direction;

    /** SMS | BANK_NOTIFICATION | MANUAL | EMAIL | OCR */
    private String source;

    private boolean recurring = false;

    /** Confidence score (0-1) from the auto-categorization AI model. */
    private Double categoryConfidence;

    public enum TransactionDirection {
        DEBIT, CREDIT
    }
}
