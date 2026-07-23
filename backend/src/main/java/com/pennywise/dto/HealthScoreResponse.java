package com.pennywise.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class HealthScoreResponse {
    private int score;          // 0–100
    private String grade;       // Excellent | Good | Fair | Poor
    private String summary;
    private int savingsScore;   // max 25
    private int budgetScore;    // max 25
    private int goalScore;      // max 25
    private int activityScore;  // max 15
    private int surplusScore;   // max 10
}
