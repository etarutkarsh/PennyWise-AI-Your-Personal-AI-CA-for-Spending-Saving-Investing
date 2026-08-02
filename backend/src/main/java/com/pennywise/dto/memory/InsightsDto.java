package com.pennywise.dto.memory;

import lombok.*;
import java.util.List;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class InsightsDto {
    private int totalDecisions;
    private int reviewedDecisions;
    private double followRate;          // % of recommendations followed
    private Double averageAccuracy;     // avg accuracy score
    private int pendingReviews;
    private List<String> observations;  // behavioral insight bullets
}
