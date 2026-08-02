package com.pennywise.engine.behavioral;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.pennywise.entity.DecisionMemory;
import com.pennywise.entity.FinancialEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.*;

/**
 * Analyzes risk-related behavior by parsing behaviorSnapshot JSON from DecisionMemory
 * and looking for emergency fund milestones in financial events.
 * <p>
 * Computes: riskBehaviorScore, consistencyScore
 * Patterns: EMERGENCY_RESILIENT, RISK_AVERSE
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class RiskBehaviorEngine {

    private final ObjectMapper objectMapper;

    private static final int MIN_PATTERN_OCCURRENCES = 2;

    public record RiskResult(
            int riskBehaviorScore,
            int consistencyScore,
            Set<BehaviorPattern> patterns
    ) {}

    public RiskResult analyze(UUID userId,
                               List<FinancialEvent> events,
                               List<DecisionMemory> decisions) {
        if (events.isEmpty() && decisions.isEmpty()) {
            return new RiskResult(50, 50, Set.of());
        }

        long emergencyMilestones = events.stream()
                .filter(e -> "EMERGENCY_FUND_MILESTONE".equals(e.getEventType()))
                .count();

        // Extract debtRatio and emergencyFundMonths from behaviorSnapshot JSON
        List<Double> debtRatios = new ArrayList<>();
        List<Double> emergencyFundMonthsList = new ArrayList<>();

        for (DecisionMemory dm : decisions) {
            if (dm.getBehaviorSnapshot() == null || dm.getBehaviorSnapshot().isBlank()) continue;
            try {
                JsonNode snapshot = objectMapper.readTree(dm.getBehaviorSnapshot());
                if (snapshot.has("debtRatio")) {
                    debtRatios.add(snapshot.get("debtRatio").asDouble());
                }
                if (snapshot.has("emergencyFundMonths")) {
                    emergencyFundMonthsList.add(snapshot.get("emergencyFundMonths").asDouble());
                }
            } catch (Exception e) {
                log.debug("Could not parse behaviorSnapshot for decision {}: {}", dm.getId(), e.getMessage());
            }
        }

        // Risk behavior score — higher = better risk management
        int riskBehaviorScore = computeRiskScore(debtRatios, emergencyFundMonthsList, emergencyMilestones);

        // Consistency score — how consistent is the user's financial health over time
        int consistencyScore = computeConsistencyScore(debtRatios, emergencyFundMonthsList, events);

        Set<BehaviorPattern> patterns = new HashSet<>();

        // EMERGENCY_RESILIENT: multiple emergency fund milestones
        if (emergencyMilestones >= MIN_PATTERN_OCCURRENCES) {
            patterns.add(BehaviorPattern.EMERGENCY_RESILIENT);
        }

        // RISK_AVERSE: consistently low debt ratio and high emergency fund
        boolean lowDebt = !debtRatios.isEmpty() &&
                debtRatios.stream().mapToDouble(Double::doubleValue).average().orElse(1.0) < 0.2;
        boolean highEmergencyFund = !emergencyFundMonthsList.isEmpty() &&
                emergencyFundMonthsList.stream().mapToDouble(Double::doubleValue).average().orElse(0) >= 6.0;
        if (lowDebt && highEmergencyFund && debtRatios.size() >= MIN_PATTERN_OCCURRENCES) {
            patterns.add(BehaviorPattern.RISK_AVERSE);
        }

        riskBehaviorScore = Math.min(100, Math.max(0, riskBehaviorScore));
        consistencyScore = Math.min(100, Math.max(0, consistencyScore));

        log.debug("RiskBehaviorEngine: userId={} emergencyMilestones={} riskScore={} consistencyScore={}",
                userId, emergencyMilestones, riskBehaviorScore, consistencyScore);

        return new RiskResult(riskBehaviorScore, consistencyScore, patterns);
    }

    private int computeRiskScore(List<Double> debtRatios,
                                  List<Double> emergencyFundMonths,
                                  long emergencyMilestones) {
        int score = 50;

        if (!debtRatios.isEmpty()) {
            double avgDebt = debtRatios.stream().mapToDouble(Double::doubleValue).average().orElse(0.5);
            // Low debt ratio = better risk management
            score += (int) Math.round((0.5 - avgDebt) * 40); // -20 to +20
        }

        if (!emergencyFundMonths.isEmpty()) {
            double avgMonths = emergencyFundMonths.stream().mapToDouble(Double::doubleValue).average().orElse(0);
            // 6+ months = excellent, 3-6 = good, < 3 = poor
            if (avgMonths >= 6.0) score += 20;
            else if (avgMonths >= 3.0) score += 10;
            else score -= 10;
        }

        // Emergency milestones are strong positive signals
        score += (int) Math.min(15, emergencyMilestones * 5);

        return score;
    }

    private int computeConsistencyScore(List<Double> debtRatios,
                                         List<Double> emergencyFundMonths,
                                         List<FinancialEvent> events) {
        // Consistency = low variance in financial health indicators over time
        if (debtRatios.size() < 2 && emergencyFundMonths.size() < 2) {
            // Use event frequency consistency as proxy
            return computeEventConsistency(events);
        }

        int score = 60;

        if (debtRatios.size() >= 2) {
            double debtVariance = computeVariance(debtRatios);
            // Low variance in debt ratio = consistent
            if (debtVariance < 0.01) score += 20;
            else if (debtVariance < 0.05) score += 10;
            else score -= 10;
        }

        if (emergencyFundMonths.size() >= 2) {
            double efVariance = computeVariance(emergencyFundMonths);
            // Growing emergency fund = positive consistency
            if (efVariance < 1.0) score += 10;
        }

        return score;
    }

    private int computeEventConsistency(List<FinancialEvent> events) {
        if (events.size() < 3) return 50;

        // Count events per month and check variance
        Map<String, Long> monthlyCount = new LinkedHashMap<>();
        for (FinancialEvent e : events) {
            String month = e.getOccurredAt().toString().substring(0, 7);
            monthlyCount.merge(month, 1L, Long::sum);
        }

        if (monthlyCount.size() < 2) return 50;

        List<Double> counts = new ArrayList<>();
        monthlyCount.values().forEach(v -> counts.add(v.doubleValue()));
        double cv = Math.sqrt(computeVariance(counts)) /
                counts.stream().mapToDouble(Double::doubleValue).average().orElse(1);

        if (cv < 0.2) return 80;
        if (cv < 0.4) return 65;
        if (cv < 0.6) return 50;
        return 35;
    }

    private double computeVariance(List<Double> values) {
        if (values.isEmpty()) return 0;
        double mean = values.stream().mapToDouble(Double::doubleValue).average().orElse(0);
        return values.stream().mapToDouble(v -> Math.pow(v - mean, 2)).average().orElse(0);
    }
}
