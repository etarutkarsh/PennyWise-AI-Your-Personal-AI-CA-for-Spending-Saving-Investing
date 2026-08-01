package com.pennywise.financial.model;

import java.util.List;

/**
 * Two-layer risk assessment result: willingness (psychographic) and capacity (financial).
 * The final score is min(willingness, capacity) — financial capacity is the hard ceiling.
 */
public record RiskProfile(
        int willingnessScore,              // 0–100 psychographic score
        int capacityScore,                 // 0–100 financial capacity score
        int finalScore,                    // min(willingness, capacity)
        RiskCategory category,             // CONSERVATIVE, MODERATE, AGGRESSIVE, VERY_AGGRESSIVE
        String rationale,                  // human-readable explanation
        List<String> capacityConstraints   // reasons capacity < willingness (if applicable)
) {}
