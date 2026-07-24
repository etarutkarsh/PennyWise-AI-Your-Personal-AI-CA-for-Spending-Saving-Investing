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
@Table(name = "savings_rules")
public class SavingsRule extends BaseEntity {

    private UUID userId;

    /** round_up | surplus_sweep | fixed_monthly | category_limit_alert */
    @Column(name = "trigger_type", nullable = false, length = 64)
    private String triggerType;

    @Column(name = "category_id")
    private UUID categoryId;

    /** Stored as a JSON string, e.g. {"percent": 10} */
    @Column(name = "config", columnDefinition = "jsonb")
    private String configJson;

    @Column(name = "active")
    private boolean active = true;
}
