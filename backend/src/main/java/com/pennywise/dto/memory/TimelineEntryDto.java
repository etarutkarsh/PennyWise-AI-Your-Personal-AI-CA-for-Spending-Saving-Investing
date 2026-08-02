package com.pennywise.dto.memory;

import lombok.*;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class TimelineEntryDto {
    private UUID id;
    private String itemName;
    private BigDecimal itemPrice;
    private String recommendation;
    private String recommendationStrength;
    private LocalDate reviewAfter;
    private String status;
    private Instant createdAt;
    private Boolean followedRecommendation; // null if not yet reviewed
    private BigDecimal accuracyScore;       // null if not yet reviewed
}
