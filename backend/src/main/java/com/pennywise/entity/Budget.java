package com.pennywise.entity;

import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.UUID;

@Getter
@Setter
@Entity
@Table(name = "budgets")
public class Budget extends BaseEntity {

    private UUID userId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id")
    private Category category;

    private BigDecimal monthlyLimit;

    /** ISO period, e.g. "2026-07" */
    private String period;

    private BigDecimal spentSoFar = BigDecimal.ZERO;

    private boolean alertsEnabled = true;

    /** Percentage of limit at which to alert the user, e.g. 80 */
    private Integer alertThresholdPercent = 80;
}
