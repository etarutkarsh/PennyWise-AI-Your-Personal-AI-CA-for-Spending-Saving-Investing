package com.pennywise.entity;

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
@Table(name = "goals")
public class Goal extends BaseEntity {

    private UUID userId;

    private String name;

    /** house | car | vacation | laptop | wedding | emergency_fund | retirement | education | custom */
    private String goalType;

    private BigDecimal targetAmount;

    private BigDecimal currentSaved = BigDecimal.ZERO;

    private LocalDate deadline;

    /** low | medium | high */
    private String priority = "medium";

    /** Suggested monthly contribution to hit the deadline, computed by Goal AI. */
    private BigDecimal recommendedMonthlyContribution;

    /** liquid_fund | rd | hybrid_fund | equity | debt | fd | mixed */
    private String investmentSuggestion;

    private boolean achieved = false;
}
