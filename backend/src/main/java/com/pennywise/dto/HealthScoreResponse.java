package com.pennywise.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class HealthScoreResponse {
    // ── Composite score ───────────────────────────────────────────────
    private int score;          // 0–100 weighted composite
    private String grade;       // A+ | A | B+ | B | C | D
    private String summary;

    // ── Legacy pillar scores (backward compat — kept for existing Flutter clients) ──
    private int savingsScore;
    private int budgetScore;
    private int goalScore;
    private int activityScore;
    private int surplusScore;

    // ── Full dimension breakdown (Sprint 6) ───────────────────────────
    // Each item: name, score, maxScore, status, insight, recommendation.
    // Flutter maps these to the 10-dimension health model.
    private List<HealthDimensionDto> dimensions;

    // Top 3 highest-ROI actions sorted by weighted score gap.
    private List<String> topActions;
}
