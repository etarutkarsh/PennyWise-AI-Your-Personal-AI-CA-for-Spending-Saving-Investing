package com.pennywise.dto;

/**
 * Serializable dimension breakdown for the /health-score response.
 *
 * Maps 1:1 to [com.pennywise.financial.model.DimensionScore] for
 * the REST API. The Flutter client maps this to [DimensionScore] in
 * the Flutter domain layer.
 */
public record HealthDimensionDto(
        String name,          // e.g. "Savings Rate"
        int score,            // 0–max
        int maxScore,         // dimension maximum (e.g. 20)
        String status,        // "Excellent" | "Good" | "Fair" | "Poor"
        String insight,       // what the data shows
        String recommendation // actionable next step
) {}
