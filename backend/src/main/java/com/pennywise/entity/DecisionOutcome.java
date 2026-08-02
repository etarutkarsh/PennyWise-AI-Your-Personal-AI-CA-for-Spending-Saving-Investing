package com.pennywise.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.UpdateTimestamp;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor
@Entity @Table(name = "decision_outcome")
public class DecisionOutcome {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false)
    private UUID decisionId;

    private String actualChoice;
    private Boolean followedRecommendation;
    private String notes;

    @Column(nullable = false)
    private LocalDate reviewedAt = LocalDate.now();

    private Integer goalDelta;
    private Integer healthDelta;
    private BigDecimal accuracyScore;

    @Column(columnDefinition = "text")
    private String lessons; // JSON array

    @Column(nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    @UpdateTimestamp
    private Instant updatedAt;
}
