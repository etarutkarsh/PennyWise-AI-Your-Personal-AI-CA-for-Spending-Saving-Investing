package com.pennywise.engine.behavioral;

import com.pennywise.entity.FinancialEvent;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Detects spending psychology patterns from financial events.
 * <p>
 * Key patterns detected:
 * - SALARY_EUPHORIA: large purchase within 72 hours of salary credit (requires ≥ 2 occurrences)
 * - IMPULSE_PURCHASER: high variance in debit amounts, frequent large purchases
 */
@Slf4j
@Component
public class SpendingPsychologyEngine {

    private static final long EUPHORIA_WINDOW_HOURS = 72;
    private static final int MIN_PATTERN_OCCURRENCES = 2;

    public record SpendingResult(
            int impulseScore,
            int spendingStabilityScore,
            Set<BehaviorPattern> patterns
    ) {}

    public SpendingResult analyze(UUID userId, List<FinancialEvent> events) {
        if (events.isEmpty()) {
            return new SpendingResult(50, 50, Set.of());
        }

        List<FinancialEvent> salaryEvents = events.stream()
                .filter(e -> "SALARY_CREDITED".equals(e.getEventType()))
                .sorted(Comparator.comparing(FinancialEvent::getOccurredAt))
                .collect(Collectors.toList());

        List<FinancialEvent> largePurchaseEvents = events.stream()
                .filter(e -> "LARGE_PURCHASE_DETECTED".equals(e.getEventType()))
                .sorted(Comparator.comparing(FinancialEvent::getOccurredAt))
                .collect(Collectors.toList());

        // Detect SALARY_EUPHORIA
        int euphoriaCount = 0;
        for (FinancialEvent salary : salaryEvents) {
            for (FinancialEvent purchase : largePurchaseEvents) {
                long hoursAfterSalary = Duration.between(
                        salary.getOccurredAt(), purchase.getOccurredAt()).toHours();
                if (hoursAfterSalary >= 0 && hoursAfterSalary <= EUPHORIA_WINDOW_HOURS) {
                    euphoriaCount++;
                    break; // count once per salary event
                }
            }
        }

        Set<BehaviorPattern> patterns = new HashSet<>();
        if (euphoriaCount >= MIN_PATTERN_OCCURRENCES) {
            patterns.add(BehaviorPattern.SALARY_EUPHORIA);
        }

        // Compute impulse score — lower = more impulsive
        // Base: 70 (neutral), reduced by large purchase frequency
        int totalEvents = events.size();
        int largePurchaseCount = largePurchaseEvents.size();
        double largePurchaseRatio = totalEvents > 0 ? (double) largePurchaseCount / totalEvents : 0.0;

        // Impulse score: higher is better (more controlled)
        // Ratio > 30% = impulsive, < 10% = controlled
        int impulseScore;
        if (largePurchaseRatio > 0.30) {
            impulseScore = 30;
        } else if (largePurchaseRatio > 0.20) {
            impulseScore = 45;
        } else if (largePurchaseRatio > 0.10) {
            impulseScore = 60;
        } else {
            impulseScore = 75;
        }

        // If salary euphoria pattern detected, reduce impulse score
        if (patterns.contains(BehaviorPattern.SALARY_EUPHORIA)) {
            impulseScore = Math.max(20, impulseScore - 20);
            // Also detect IMPULSE_PURCHASER if high large-purchase ratio
            if (largePurchaseRatio > 0.15 && largePurchaseCount >= MIN_PATTERN_OCCURRENCES) {
                patterns.add(BehaviorPattern.IMPULSE_PURCHASER);
            }
        } else if (largePurchaseCount >= MIN_PATTERN_OCCURRENCES && largePurchaseRatio > 0.25) {
            patterns.add(BehaviorPattern.IMPULSE_PURCHASER);
        }

        // Spending stability score — based on consistency of spending events over time
        int spendingStabilityScore = computeSpendingStability(events);

        impulseScore = Math.min(100, Math.max(0, impulseScore));
        spendingStabilityScore = Math.min(100, Math.max(0, spendingStabilityScore));

        log.debug("SpendingPsychologyEngine: userId={} euphoriaCount={} impulseScore={} stabilityScore={}",
                userId, euphoriaCount, impulseScore, spendingStabilityScore);

        return new SpendingResult(impulseScore, spendingStabilityScore, patterns);
    }

    private int computeSpendingStability(List<FinancialEvent> events) {
        // Group events by month and count per month
        Map<String, Long> monthlyEventCounts = events.stream()
                .collect(Collectors.groupingBy(
                        e -> e.getOccurredAt().toString().substring(0, 7), // "YYYY-MM"
                        Collectors.counting()
                ));

        if (monthlyEventCounts.size() < 2) {
            return 50; // not enough data
        }

        List<Long> counts = new ArrayList<>(monthlyEventCounts.values());
        double mean = counts.stream().mapToLong(Long::longValue).average().orElse(0);
        if (mean == 0) return 50;

        double variance = counts.stream()
                .mapToDouble(c -> Math.pow(c - mean, 2))
                .average().orElse(0);
        double cv = Math.sqrt(variance) / mean; // coefficient of variation

        // Low CV = stable spending = high score
        if (cv < 0.2) return 85;
        if (cv < 0.4) return 70;
        if (cv < 0.6) return 55;
        if (cv < 0.8) return 40;
        return 25;
    }
}
