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
@Table(name = "assets")
public class Asset extends BaseEntity {

    @Column(nullable = false)
    private UUID userId;

    /** real_estate | vehicle | cash | jewelry | other */
    @Column(nullable = false)
    private String assetType;

    private String name;

    @Column(nullable = false)
    private BigDecimal value;

    private LocalDate asOfDate;
}
