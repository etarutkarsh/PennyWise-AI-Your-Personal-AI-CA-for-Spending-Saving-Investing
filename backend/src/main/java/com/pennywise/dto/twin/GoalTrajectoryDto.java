package com.pennywise.dto.twin;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.UUID;

@Getter
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class GoalTrajectoryDto {

    private UUID goalId;
    private String goalName;
    private BigDecimal targetAmount;
    private BigDecimal currentSaved;

    /** ISO date string: "2026-12-01" */
    private String deadline;

    /** Formatted deadline for display: "Dec 2026" */
    private String deadlineFormatted;

    /** 0.0–1.0 */
    private double completionProbability;

    private int monthsToCompletion;

    private boolean onTrack;

    /** ON_TRACK | AT_RISK | OFF_TRACK | ACHIEVED */
    private String status;
}
