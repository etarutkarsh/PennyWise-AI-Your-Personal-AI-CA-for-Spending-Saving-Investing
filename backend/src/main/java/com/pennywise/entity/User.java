package com.pennywise.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDate;

@Getter
@Setter
@Entity
@Table(name = "users")
public class User extends BaseEntity {

    @Column(nullable = false, unique = true)
    private String email;

    @Column(name = "password_hash")
    private String passwordHash;

    private String fullName;

    private String phoneNumber;

    /** student | professional | freelancer | family */
    private String userType;

    private LocalDate dateOfBirth;

    /** Monthly take-home salary / income, in the user's base currency (e.g. INR). */
    private BigDecimal monthlyIncome;

    @Column(length = 3)
    private String currency = "INR";

    /** low | medium | high - drives investment suggestion tone */
    private String riskAppetite;

    private boolean onboardingComplete = false;

    // ── Tax-ready fields (Phase 3/4) ─────────────────────────────────────────

    /** Permanent Account Number — stored as-is, masked on display. */
    @Column(length = 10)
    private String pan;

    /** NEW | OLD — user's preferred Indian income tax regime. */
    private String taxRegime = "NEW";

    /** Month the financial year starts (4 = April for Indian FY). */
    private Integer financialYearStart = 4;
}
