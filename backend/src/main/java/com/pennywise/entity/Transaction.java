package com.pennywise.entity;

import jakarta.persistence.Column;
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

    // ── Tax-ready fields (Phase 3/4) ─────────────────────────────────────────

    /** URL to an uploaded receipt or invoice for this transaction. */
    private String receiptUrl;

    /**
     * Indian tax deduction / income category.
     * Examples: 80C, 80D, HRA, BUSINESS_EXPENSE, CAPITAL_GAINS, INTEREST_INCOME
     */
    private String taxCategory;

    /** Human-in-the-loop verification state for this transaction's tax data. */
    @Enumerated(EnumType.STRING)
    private VerificationStatus verificationStatus = VerificationStatus.UNVERIFIED;

    @Column(name = "is_business_expense")
    private boolean businessExpense = false;

    public enum TransactionDirection {
        DEBIT, CREDIT
    }

    public enum VerificationStatus {
        UNVERIFIED, VERIFIED, DISPUTED
    }
}
