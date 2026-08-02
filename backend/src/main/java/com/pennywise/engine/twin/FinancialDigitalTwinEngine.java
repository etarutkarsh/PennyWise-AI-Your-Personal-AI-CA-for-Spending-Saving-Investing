package com.pennywise.engine.twin;

import com.pennywise.entity.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.*;

/**
 * Orchestrator that computes a complete FinancialDigitalTwin snapshot for a user.
 *
 * <p>Execution order:
 * <ol>
 *   <li>Assemble raw data via TwinAssembler</li>
 *   <li>Compute net worth, income/expense, DTI, EF coverage</li>
 *   <li>Compute behaviorFactor from BehaviorProfile</li>
 *   <li>Compute per-goal trajectories</li>
 *   <li>Generate projection series via FinancialProjectionEngine</li>
 *   <li>Calculate twinScore (data completeness 0–100)</li>
 * </ol>
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class FinancialDigitalTwinEngine {

    private final TwinAssembler assembler;
    private final FinancialProjectionEngine projectionEngine;

    // Pattern adjustment constants
    private static final double CONSISTENT_SAVER_BOOST  =  0.05;
    private static final double SALARY_EUPHORIA_PENALTY  = -0.08;
    private static final double IMPULSE_PURCHASER_PENALTY = -0.08;
    private static final double MIN_BEHAVIOR_FACTOR = 0.50;
    private static final double MAX_BEHAVIOR_FACTOR = 1.15;
    private static final double NEUTRAL_BEHAVIOR_FACTOR = 0.75;

    /**
     * Computes the Digital Twin snapshot for the given user.
     *
     * @param userId authenticated user's UUID
     * @return fully computed TwinSnapshot
     */
    public TwinSnapshot compute(UUID userId) {
        log.info("FinancialDigitalTwinEngine: computing twin for userId={}", userId);

        TwinAssembler.TwinData data = assembler.assemble(userId);
        User user = data.user();

        // ── 1. Asset totals ───────────────────────────────────────────────────
        BigDecimal totalAssets = data.assets().stream()
                .map(Asset::getValue)
                .filter(Objects::nonNull)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // Liquid assets: only "cash" type assets count for emergency fund
        BigDecimal liquidAssets = data.assets().stream()
                .filter(a -> "cash".equalsIgnoreCase(a.getAssetType()))
                .map(Asset::getValue)
                .filter(Objects::nonNull)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // ── 2. Liability totals ───────────────────────────────────────────────
        BigDecimal totalLiabilities = data.liabilities().stream()
                .map(Liability::getOutstanding)
                .filter(Objects::nonNull)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalMonthlyEmi = data.liabilities().stream()
                .map(Liability::getMonthlyEmi)
                .filter(Objects::nonNull)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // ── 3. Net worth ──────────────────────────────────────────────────────
        BigDecimal netWorth = totalAssets.subtract(totalLiabilities);

        // ── 4. Income & expenses ──────────────────────────────────────────────
        BigDecimal monthlyIncome = user.getMonthlyIncome() != null
                ? user.getMonthlyIncome()
                : BigDecimal.ZERO;

        // Average monthly DEBIT over last 90 days ÷ 3
        BigDecimal totalDebits = data.recentTransactions().stream()
                .filter(t -> t.getDirection() == Transaction.TransactionDirection.DEBIT)
                .map(Transaction::getAmount)
                .filter(Objects::nonNull)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal monthlyExpenses = totalDebits.divide(BigDecimal.valueOf(3), 2, RoundingMode.HALF_UP);

        BigDecimal monthlySurplus = monthlyIncome.subtract(monthlyExpenses);

        // ── 5. DTI ratio ──────────────────────────────────────────────────────
        BigDecimal dtiRatio;
        if (monthlyIncome.compareTo(BigDecimal.ZERO) > 0) {
            dtiRatio = totalMonthlyEmi.divide(monthlyIncome, 4, RoundingMode.HALF_UP);
        } else {
            dtiRatio = BigDecimal.ZERO;
        }

        // ── 6. Emergency fund coverage ────────────────────────────────────────
        BigDecimal efCoverageMonths;
        if (monthlyExpenses.compareTo(BigDecimal.ZERO) > 0) {
            efCoverageMonths = liquidAssets.divide(monthlyExpenses, 2, RoundingMode.HALF_UP);
        } else {
            efCoverageMonths = BigDecimal.ZERO;
        }

        // ── 7. Behavioral factor ──────────────────────────────────────────────
        double behaviorFactor = computeBehaviorFactor(data.behaviorProfile());

        // ── 8. Goal trajectories ──────────────────────────────────────────────
        List<GoalTrajectory> goalTrajectories = computeGoalTrajectories(
                data.goals(), monthlySurplus, behaviorFactor);

        // ── 9. Projection series ──────────────────────────────────────────────
        String riskAppetite = user.getRiskAppetite();
        List<ProjectionPoint> projectionSeries = projectionEngine.generateSeries(
                netWorth, monthlySurplus, behaviorFactor, riskAppetite);

        BigDecimal projection12m  = projectionEngine.projectAt(netWorth, monthlySurplus, behaviorFactor, riskAppetite, 12);
        BigDecimal projection3yr  = projectionEngine.projectAt(netWorth, monthlySurplus, behaviorFactor, riskAppetite, 36);
        BigDecimal projection5yr  = projectionEngine.projectAt(netWorth, monthlySurplus, behaviorFactor, riskAppetite, 60);
        BigDecimal projection10yr = projectionEngine.projectAt(netWorth, monthlySurplus, behaviorFactor, riskAppetite, 120);

        // ── 10. Twin score (data completeness) ────────────────────────────────
        int twinScore = computeTwinScore(
                monthlyIncome, data.assets(), data.liabilities(),
                data.goals(), data.behaviorProfile(), data.recentTransactions());

        log.info("FinancialDigitalTwinEngine: completed twin for userId={} twinScore={}", userId, twinScore);

        return TwinSnapshot.builder()
                .netWorth(netWorth.setScale(2, RoundingMode.HALF_UP))
                .totalAssets(totalAssets.setScale(2, RoundingMode.HALF_UP))
                .totalLiabilities(totalLiabilities.setScale(2, RoundingMode.HALF_UP))
                .monthlyIncome(monthlyIncome.setScale(2, RoundingMode.HALF_UP))
                .monthlyExpenses(monthlyExpenses.setScale(2, RoundingMode.HALF_UP))
                .monthlySurplus(monthlySurplus.setScale(2, RoundingMode.HALF_UP))
                .efCoverageMonths(efCoverageMonths)
                .dtiRatio(dtiRatio)
                .behaviorFactor(behaviorFactor)
                .twinScore(twinScore)
                .goalTrajectories(goalTrajectories)
                .projectionSeries(projectionSeries)
                .build();
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    private double computeBehaviorFactor(Optional<BehaviorProfile> profileOpt) {
        if (profileOpt.isEmpty()) {
            return NEUTRAL_BEHAVIOR_FACTOR;
        }
        BehaviorProfile profile = profileOpt.get();

        // Base formula: disciplineScore / 100 * 0.4 + 0.6 ensures ≥ 0.6
        double base = (profile.getDisciplineScore() / 100.0) * 0.4 + 0.6;

        // Apply pattern adjustments
        double adjustment = 0.0;
        String patterns = profile.getDetectedPatterns();
        if (patterns != null && !patterns.isBlank()) {
            // detectedPatterns is a JSON array string; do simple contains check
            String upper = patterns.toUpperCase();
            if (upper.contains("CONSISTENT_SAVER")) {
                adjustment += CONSISTENT_SAVER_BOOST;
            }
            if (upper.contains("SALARY_EUPHORIA")) {
                adjustment += SALARY_EUPHORIA_PENALTY;
            }
            if (upper.contains("IMPULSE_PURCHASER")) {
                adjustment += IMPULSE_PURCHASER_PENALTY;
            }
        }

        double factor = base + adjustment;
        return Math.max(MIN_BEHAVIOR_FACTOR, Math.min(MAX_BEHAVIOR_FACTOR, factor));
    }

    private List<GoalTrajectory> computeGoalTrajectories(
            List<Goal> goals,
            BigDecimal monthlySurplus,
            double behaviorFactor) {

        if (goals.isEmpty()) return List.of();

        // Filter active (non-achieved) goals to compute allocation
        List<Goal> activeGoals = goals.stream()
                .filter(g -> !g.isAchieved())
                .toList();

        // Simple equal allocation by priority weight
        // Priority: high=3, medium=2, low=1
        int totalWeight = activeGoals.stream()
                .mapToInt(g -> priorityWeight(g.getPriority()))
                .sum();

        double effectiveSurplus = monthlySurplus.max(BigDecimal.ZERO).doubleValue() * behaviorFactor;

        List<GoalTrajectory> trajectories = new ArrayList<>();

        for (Goal goal : goals) {
            if (goal.isAchieved()) {
                trajectories.add(GoalTrajectory.builder()
                        .goalId(goal.getId())
                        .goalName(goal.getName())
                        .targetAmount(goal.getTargetAmount())
                        .currentSaved(goal.getCurrentSaved())
                        .deadline(goal.getDeadline())
                        .completionProbability(1.0)
                        .monthsToCompletion(0)
                        .onTrack(true)
                        .status("ACHIEVED")
                        .build());
                continue;
            }

            BigDecimal target = goal.getTargetAmount() != null ? goal.getTargetAmount() : BigDecimal.ZERO;
            BigDecimal saved  = goal.getCurrentSaved() != null  ? goal.getCurrentSaved()  : BigDecimal.ZERO;
            BigDecimal remaining = target.subtract(saved).max(BigDecimal.ZERO);

            // Monthly allocation proportional to priority weight
            double allocationFraction = totalWeight > 0
                    ? (double) priorityWeight(goal.getPriority()) / totalWeight
                    : 1.0 / Math.max(activeGoals.size(), 1);
            double monthlyAllocation = effectiveSurplus * allocationFraction;

            // Months remaining until deadline
            long monthsRemaining = 0;
            if (goal.getDeadline() != null) {
                monthsRemaining = Math.max(0, ChronoUnit.MONTHS.between(LocalDate.now(), goal.getDeadline()));
            }

            // Completion probability: what fraction of target can we fund by deadline?
            double completionProbability;
            int monthsToCompletion;

            if (remaining.compareTo(BigDecimal.ZERO) == 0) {
                completionProbability = 1.0;
                monthsToCompletion = 0;
            } else if (monthlyAllocation <= 0) {
                completionProbability = saved.doubleValue() / Math.max(target.doubleValue(), 1);
                monthsToCompletion = Integer.MAX_VALUE;
            } else {
                double fundedByDeadline = monthlyAllocation * monthsRemaining + saved.doubleValue();
                completionProbability = Math.min(1.0, fundedByDeadline / Math.max(target.doubleValue(), 1));
                monthsToCompletion = (int) Math.ceil(remaining.doubleValue() / monthlyAllocation);
            }

            boolean onTrack = completionProbability >= 0.85
                    && (goal.getDeadline() == null || monthsToCompletion <= monthsRemaining);

            String status;
            if (completionProbability >= 0.85 && onTrack) {
                status = "ON_TRACK";
            } else if (completionProbability >= 0.50) {
                status = "AT_RISK";
            } else {
                status = "OFF_TRACK";
            }

            trajectories.add(GoalTrajectory.builder()
                    .goalId(goal.getId())
                    .goalName(goal.getName())
                    .targetAmount(target)
                    .currentSaved(saved)
                    .deadline(goal.getDeadline())
                    .completionProbability(Math.min(1.0, completionProbability))
                    .monthsToCompletion(monthsToCompletion == Integer.MAX_VALUE ? 999 : monthsToCompletion)
                    .onTrack(onTrack)
                    .status(status)
                    .build());
        }

        return Collections.unmodifiableList(trajectories);
    }

    private int priorityWeight(String priority) {
        if (priority == null) return 2;
        return switch (priority.toLowerCase()) {
            case "high"   -> 3;
            case "low"    -> 1;
            default       -> 2; // medium
        };
    }

    private int computeTwinScore(BigDecimal monthlyIncome,
                                 List<Asset> assets,
                                 List<Liability> liabilities,
                                 List<Goal> goals,
                                 Optional<BehaviorProfile> behaviorProfile,
                                 List<Transaction> recentTransactions) {
        int score = 0;
        if (monthlyIncome != null && monthlyIncome.compareTo(BigDecimal.ZERO) > 0) score += 20;
        if (!assets.isEmpty())                score += 20;
        if (!liabilities.isEmpty())           score += 15;
        if (!goals.isEmpty())                 score += 20;
        if (behaviorProfile.isPresent())      score += 15;
        if (!recentTransactions.isEmpty())    score += 10;
        return score;
    }
}
