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
@Table(name = "liabilities")
public class Liability extends BaseEntity {

    @Column(nullable = false)
    private UUID userId;

    /** home_loan | car_loan | personal_loan | credit_card | other */
    @Column(nullable = false)
    private String liabilityType;

    private String name;

    @Column(nullable = false)
    private BigDecimal outstanding;

    private BigDecimal monthlyEmi;

    private BigDecimal interestRate;

    private LocalDate asOfDate;
}
