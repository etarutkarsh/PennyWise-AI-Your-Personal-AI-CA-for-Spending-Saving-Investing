package com.pennywise.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TransactionDto {
    private UUID id;
    private BigDecimal amount;
    private String merchant;
    private String note;
    private UUID categoryId;
    private String categoryName;
    private Instant transactionDate;
    private String paymentMethod;
    private String direction;
    private String source;
    private boolean recurring;
}
