package com.pennywise.dto.memory;

import lombok.*;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class DecisionMemoryDto {
    private UUID id;
    private String decisionType;
    private String itemName;
    private BigDecimal itemPrice;
    private String recommendation;
    private String recommendationStrength;
    private LocalDate reviewAfter;
    private String status;
    private Instant createdAt;
    private DecisionOutcomeDto outcome;
    // Evidence and snapshots as raw JSON strings (Flutter parses)
    private String recommendationEvidence;
    private String recommendedScenario;
    private String alternatives;
    private String goalImpacts;
    private String behaviorSnapshot;
}
