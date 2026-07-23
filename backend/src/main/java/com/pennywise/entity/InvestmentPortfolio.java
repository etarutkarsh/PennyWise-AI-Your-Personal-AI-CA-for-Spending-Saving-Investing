package com.pennywise.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

@Getter
@Setter
@Entity
@Table(name = "investment_portfolio")
public class InvestmentPortfolio extends BaseEntity {

    private UUID userId;

    /** mutual_fund | stock | etf | gold | fd | ppf | nps | bond | reit | sip */
    @Column(nullable = false)
    private String instrumentType;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private BigDecimal investedAmount;

    private BigDecimal currentValue;

    private BigDecimal units;

    private LocalDate startedOn;
}
