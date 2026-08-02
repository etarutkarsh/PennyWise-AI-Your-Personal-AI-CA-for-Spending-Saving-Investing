package com.pennywise.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GoalImpactDto {

    private String goalName;
    private String goalType;

    /** Current progress percentage (0–100), based on currentSaved / targetAmount. */
    private double currentProgressPct;

    /** Projected progress percentage in 12 months under the recommended scenario. */
    private double projectedProgressPct;

    /** Months until goal is fully funded at the current savings rate. Null if contribution unknown. */
    private Integer monthsToTargetNow;

    /** Months until goal is fully funded after the recommended purchase. Null if contribution stalls. */
    private Integer monthsToTargetAfter;

    /**
     * monthsToTargetAfter - monthsToTargetNow.
     * Positive = delayed, negative = accelerated (rare), 0 = unaffected.
     */
    private int monthsDelayed;

    /** UNAFFECTED | DELAYED | AT_RISK | ACCELERATED */
    private String statusChange;
}
