package com.pennywise.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor
@Entity
@Table(name = "behavior_profile")
public class BehaviorProfile {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, unique = true)
    private UUID userId;

    // ── Behavior scores (0–100) ────────────────────────────────────────────────
    @Column(nullable = false)
    private int disciplineScore = 50;

    @Column(nullable = false)
    private int consistencyScore = 50;

    /** Lower = more impulsive */
    @Column(nullable = false)
    private int impulseScore = 50;

    @Column(nullable = false)
    private int riskBehaviorScore = 50;

    @Column(nullable = false)
    private int goalCommitmentScore = 50;

    @Column(nullable = false)
    private int savingsDisciplineScore = 50;

    @Column(nullable = false)
    private int spendingStabilityScore = 50;

    /** Percentage (0–100) of recommendations the user followed */
    @Column(nullable = false)
    private int recommendationFollowRate = 0;

    // ── JSON blobs ─────────────────────────────────────────────────────────────
    /** JSON array of detected BehaviorPattern names */
    @Column(columnDefinition = "text")
    private String detectedPatterns;

    /** JSON object: {"discipline":"A","impulseControl":"B+",...} */
    @Column(columnDefinition = "text")
    private String traitsJson;

    /** JSON array of human-readable insight strings */
    @Column(columnDefinition = "text")
    private String insightsJson;

    // ── Classifications ────────────────────────────────────────────────────────
    @Column(length = 60)
    private String primaryBehavior;

    @Column(length = 60)
    private String secondaryBehavior;

    // ── Sample sizes ───────────────────────────────────────────────────────────
    @Column(nullable = false)
    private int eventsAnalyzed = 0;

    @Column(nullable = false)
    private int decisionsAnalyzed = 0;

    @Column(nullable = false)
    private int monthsOfData = 0;

    // ── Timestamps ─────────────────────────────────────────────────────────────
    private Instant lastComputedAt;

    @Column(nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    @UpdateTimestamp
    private Instant updatedAt;
}
