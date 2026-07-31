package com.pennywise.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.Getter;
import lombok.Setter;

import java.util.UUID;

@Getter
@Setter
@Entity
@Table(name = "achievements",
       uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "code"}))
public class Achievement extends BaseEntity {

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    /** e.g. salary_quiz_done, savings_quiz_done, budget_boss, onboarding_complete */
    @Column(nullable = false)
    private String code;

    @Column(nullable = false)
    private String title;
}
