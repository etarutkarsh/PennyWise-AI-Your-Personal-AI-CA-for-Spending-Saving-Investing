package com.pennywise.dto;

import lombok.Data;

import java.math.BigDecimal;

/** Partial-update DTO for PATCH /transactions/{id}. All fields are optional. */
@Data
public class TransactionUpdateRequest {

    private String merchant;

    private String note;

    private BigDecimal amount;

    /** UUID of the category to assign. */
    private String categoryId;

    /** UPI | CARD | CASH | NETBANKING | WALLET */
    private String paymentMethod;

    private Boolean recurring;
}
