package com.pennywise.engine.twin;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Computed trajectory for a single financial goal.
 */
@Getter
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class GoalTrajectory {

    private UUID goalId;

    private String goalName;

    private BigDecimal targetAmount;

    private BigDecimal currentSaved;

    private LocalDate deadline;

    /** Probability of reaching target by the deadline (0.0–1.0). */
    private double completionProbability;

    /** Estimated months until fully funded at the current effective saving rate. */
    private int monthsToCompletion;

    /** True if the goal is expected to be achieved on or before deadline. */
    private boolean onTrack;

    /** ON_TRACK | AT_RISK | OFF_TRACK | ACHIEVED */
    private String status;
}
