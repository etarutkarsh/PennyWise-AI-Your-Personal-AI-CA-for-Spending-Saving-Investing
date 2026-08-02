package com.pennywise.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.UpdateTimestamp;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor
@Entity @Table(name = "decision_memory")
public class DecisionMemory {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false)
    private UUID userId;

    @Column(nullable = false)
    private String decisionType = "PURCHASE";

    private String itemName;
    private BigDecimal itemPrice;

    @Column(nullable = false)
    private String recommendation;   // SAFE_TO_BUY | WAIT_AND_SAVE | DONT_BUY

    @Column(nullable = false)
    private String recommendationStrength;  // HIGH | MEDIUM | LOW

    @Column(columnDefinition = "text")
    private String recommendationEvidence;  // JSON array

    @Column(columnDefinition = "text")
    private String recommendedScenario;    // JSON

    @Column(columnDefinition = "text")
    private String alternatives;           // JSON array

    @Column(columnDefinition = "text")
    private String goalImpacts;            // JSON array

    @Column(columnDefinition = "text")
    private String behaviorSnapshot;       // JSON

    private int financialHealthAtDecision = 0;

    @Column(nullable = false)
    private LocalDate reviewAfter;

    @Column(nullable = false)
    private String status = "PENDING_REVIEW"; // PENDING_REVIEW | REVIEWED | EXPIRED

    @Column(nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    @UpdateTimestamp
    private Instant updatedAt;
}
