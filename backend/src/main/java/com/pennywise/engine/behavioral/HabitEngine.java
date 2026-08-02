package com.pennywise.engine.behavioral;

import com.pennywise.entity.FinancialEvent;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.*;
import java.util.stream.Collectors;

/**
 * Analyzes goal and budget behavior to compute habit-related scores.
 * <p>
 * Scores: goalCommitmentScore, savingsDisciplineScore
 * Patterns: CONSISTENT_SAVER, GOAL_DRIFT
 */
@Slf4j
@Component
public class HabitEngine {

    private static final int MIN_PATTERN_OCCURRENCES = 2;

    public record HabitResult(
            int goalCommitmentScore,
            int savingsDisciplineScore,
            Set<BehaviorPattern> patterns
    ) {}

    public HabitResult analyze(UUID userId, List<FinancialEvent> events) {
        if (events.isEmpty()) {
            return new HabitResult(50, 50, Set.of());
        }

        long goalsCreated = countByType(events, "GOAL_CREATED");
        long goalsCompleted = countByType(events, "GOAL_COMPLETED");
        long budgetExceeded = countByType(events, "BUDGET_EXCEEDED");
        long emergencyMilestones = countByType(events, "EMERGENCY_FUND_MILESTONE");
        long salaryCredited = countByType(events, "SALARY_CREDITED");

        // Goal commitment score
        int goalCommitmentScore = computeGoalCommitmentScore(goalsCreated, goalsCompleted, budgetExceeded);

        // Savings discipline score
        int savingsDisciplineScore = computeSavingsDisciplineScore(
                goalsCompleted, emergencyMilestones, budgetExceeded, salaryCredited);

        Set<BehaviorPattern> patterns = new HashSet<>();

        // CONSISTENT_SAVER: completed goals ≥ 2 and completion ratio > 50%
        if (goalsCompleted >= MIN_PATTERN_OCCURRENCES &&
                goalsCreated > 0 && (double) goalsCompleted / goalsCreated >= 0.5) {
            patterns.add(BehaviorPattern.CONSISTENT_SAVER);
        }

        // GOAL_DRIFT: budget exceeded ≥ 2 times and no goals completed
        if (budgetExceeded >= MIN_PATTERN_OCCURRENCES && goalsCompleted == 0 && goalsCreated > 0) {
            patterns.add(BehaviorPattern.GOAL_DRIFT);
        }

        goalCommitmentScore = Math.min(100, Math.max(0, goalCommitmentScore));
        savingsDisciplineScore = Math.min(100, Math.max(0, savingsDisciplineScore));

        log.debug("HabitEngine: userId={} goalsCreated={} goalsCompleted={} budgetExceeded={} " +
                        "goalScore={} savingsScore={}",
                userId, goalsCreated, goalsCompleted, budgetExceeded,
                goalCommitmentScore, savingsDisciplineScore);

        return new HabitResult(goalCommitmentScore, savingsDisciplineScore, patterns);
    }

    private int computeGoalCommitmentScore(long created, long completed, long budgetExceeded) {
        if (created == 0) {
            // No goals set — neutral, slightly penalized for budget exceedances
            return Math.max(30, 50 - (int) (budgetExceeded * 5));
        }

        double completionRatio = (double) completed / created;
        int baseScore = (int) Math.round(completionRatio * 80); // max 80 from completion
        // Penalty for budget exceedances (each one reduces by 5, max -25)
        int penalty = (int) Math.min(25, budgetExceeded * 5);
        return Math.max(0, baseScore + 20 - penalty); // 20 point base for having goals
    }

    private int computeSavingsDisciplineScore(long goalsCompleted, long emergencyMilestones,
                                               long budgetExceeded, long salaryCredited) {
        int score = 50; // neutral baseline

        // Emergency fund milestones strongly signal savings discipline
        score += Math.min(20, emergencyMilestones * 10);

        // Goal completions signal discipline
        score += Math.min(20, goalsCompleted * 8);

        // Budget exceedances reduce discipline score
        score -= Math.min(30, budgetExceeded * 6);

        // If salary is regularly credited, shows stable income (positive signal)
        if (salaryCredited >= 3) {
            score += 10;
        }

        return score;
    }

    private long countByType(List<FinancialEvent> events, String eventType) {
        return events.stream()
                .filter(e -> eventType.equals(e.getEventType()))
                .count();
    }
}
