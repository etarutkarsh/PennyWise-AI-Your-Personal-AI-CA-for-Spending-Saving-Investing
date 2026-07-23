package com.pennywise.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Data;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/** Used for both manual entry (Feature: manual transaction entry) and parsed-SMS ingestion. */
@Data
public class TransactionCreateRequest {

    @NotNull
    @Positive
    private BigDecimal amount;

    private String merchant;

    private String note;

    private UUID categoryId;

    @NotNull
    private Instant transactionDate;

    private String paymentMethod;

    /** DEBIT | CREDIT */
    @NotNull
    private String direction;

    /** SMS | BANK_NOTIFICATION | MANUAL | EMAIL | OCR - defaults to MANUAL if omitted */
    private String source;

    /** Raw SMS/notification text, if this transaction originated from auto-detection. */
    private String rawText;
}
