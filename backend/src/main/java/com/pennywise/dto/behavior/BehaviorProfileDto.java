package com.pennywise.dto.behavior;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BehaviorProfileDto {

    /** Letter grade for financial discipline: "A", "B+", etc. */
    private String discipline;

    /** Letter grade for impulse control */
    private String impulseControl;

    /** Letter grade for goal commitment */
    private String goalCommitment;

    /** Letter grade for savings consistency */
    private String savingsConsistency;

    /** Risk behavior label: "Conservative", "Moderate", "Aggressive" */
    private String riskBehavior;

    /** Primary behavioral archetype: "Consistent Saver", "Impulse Purchaser", etc. */
    private String primaryBehavior;

    /** Secondary behavioral tendency, may be null */
    private String secondaryBehavior;

    /** Percentage (0–100) of recommendations the user followed */
    private int followRate;

    /** Raw discipline score (0–100) */
    private int disciplineScore;

    /** 3-5 human-readable insight sentences */
    private List<String> insights;

    /** List of detected behavioral pattern names */
    private List<String> detectedPatterns;

    private int eventsAnalyzed;
    private int decisionsAnalyzed;
    private int monthsOfData;

    /** "LOW" if < 3 months of data, "MEDIUM" if 3–6, "HIGH" if 6+ */
    private String dataConfidence;

    private Instant lastUpdated;
}
