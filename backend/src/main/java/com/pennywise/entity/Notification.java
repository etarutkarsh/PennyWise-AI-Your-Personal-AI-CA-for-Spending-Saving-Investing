package com.pennywise.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

import java.util.UUID;

@Getter
@Setter
@Entity
@Table(name = "notifications")
public class Notification extends BaseEntity {

    @Column(nullable = false)
    private UUID userId;

    /** overspend | goal_behind | budget_exceeded | sip_suggestion | savings_tip */
    @Column(nullable = false)
    private String type;

    @Column(nullable = false)
    private String title;

    private String body;

    private boolean read = false;
}
