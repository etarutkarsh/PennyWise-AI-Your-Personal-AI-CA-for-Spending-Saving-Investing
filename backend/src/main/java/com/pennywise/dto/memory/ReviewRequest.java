package com.pennywise.dto.memory;

import lombok.Data;

@Data
public class ReviewRequest {
    private String actualChoice;          // which scenario they actually went with
    private Boolean followedRecommendation;
    private String notes;
    private Integer goalDelta;            // aggregate goal progress change (%)
    private Integer healthDelta;          // financial health score change
}
