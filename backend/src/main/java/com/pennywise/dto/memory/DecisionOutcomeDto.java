package com.pennywise.dto.memory;

import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class DecisionOutcomeDto {
    private UUID id;
    private String actualChoice;
    private Boolean followedRecommendation;
    private String notes;
    private LocalDate reviewedAt;
    private Integer goalDelta;
    private Integer healthDelta;
    private BigDecimal accuracyScore;
    private String lessons; // JSON array
}
