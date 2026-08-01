package com.pennywise.service;

import com.pennywise.dto.HealthScoreResponse;
import com.pennywise.entity.Goal;
import com.pennywise.entity.Transaction;
import com.pennywise.entity.User;
import com.pennywise.financial.engine.HealthScoreEngine;
import com.pennywise.financial.model.DimensionScore;
import com.pennywise.financial.model.HealthScoreInput;
import com.pennywise.financial.model.HealthScoreResult;
import com.pennywise.repository.GoalRepository;
import com.pennywise.repository.TransactionRepository;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.Period;
import java.time.YearMonth;
import java.time.ZoneOffset;
import java.util.List;

/**
 * Calculates the financial health score by delegating all scoring logic to
 * {@link HealthScoreEngine}. This service is responsible for gathering live
 * user data (transactions, goals) and mapping the engine result to the
 * existing HealthScoreResponse DTO for the /dashboard/health-score endpoint.
 */
@Service
public class HealthScoreService {

    private final TransactionRepository transactionRepository;
    private final GoalRepository goalRepository;
    private final CurrentUserProvider currentUserProvider;
    private final HealthScoreEngine healthScoreEngine;

    public HealthScoreService(TransactionRepository transactionRepository,
                               GoalRepository goalRepository,
                               CurrentUserProvider currentUserProvider,
                               HealthScoreEngine healthScoreEngine) {
        this.transactionRepository = transactionRepository;
        this.goalRepository = goalRepository;
        this.currentUserProvider = currentUserProvider;
        this.healthScoreEngine = healthScoreEngine;
    }

    /**
     * Computes the health score for the authenticated user by:
     * 1. Loading this month's transactions and all goals
     * 2. Building a HealthScoreInput from live data
     * 3. Delegating computation to HealthScoreEngine
     * 4. Mapping the rich HealthScoreResult back to the legacy HealthScoreResponse DTO
     */
    public HealthScoreResponse calculate() {
        User user = currentUserProvider.get();

        YearMonth current = YearMonth.now();
        Instant from = current.atDay(1).atStartOfDay().toInstant(ZoneOffset.UTC);
        Instant to   = current.atEndOfMonth().atTime(23, 59, 59).toInstant(ZoneOffset.UTC);

        List<Transaction> txs = transactionRepository
                .findByUserIdAndTransactionDateBetween(user.getId(), from, to);

        double totalIncome = txs.stream()
                .filter(t -> "CREDIT".equals(t.getDirection().name()))
                .mapToDouble(t -> t.getAmount().doubleValue())
                .sum();

        double totalExpenses = txs.stream()
                .filter(t -> "DEBIT".equals(t.getDirection().name()))
                .mapToDouble(t -> t.getAmount().doubleValue())
                .sum();

        List<Goal> goals = goalRepository.findByUserIdOrderByDeadlineAsc(user.getId());
        List<HealthScoreInput.GoalProgress> goalProgresses = goals.stream()
                .map(g -> {
                    long months = Period.between(LocalDate.now(), g.getDeadline()).toTotalMonths();
                    double currentSaved = g.getCurrentSaved().doubleValue();
                    double targetAmount = g.getTargetAmount().doubleValue();
                    boolean hasContribution = g.getRecommendedMonthlyContribution() != null
                            && g.getRecommendedMonthlyContribution().compareTo(BigDecimal.ZERO) > 0;
                    return new HealthScoreInput.GoalProgress(currentSaved, targetAmount, (int) months, hasContribution);
                })
                .toList();

        double monthlySalary = user.getMonthlyIncome() != null
                ? user.getMonthlyIncome().doubleValue() : 0.0;

        // Estimate monthly expenses: prefer actual transaction data, fall back to 70% of salary
        double monthlyExpenses = totalExpenses > 0 ? totalExpenses : monthlySalary * 0.7;

        HealthScoreInput input = new HealthScoreInput(
                monthlySalary,
                monthlyExpenses,
                0.0,  // totalSavings — Phase 2 will populate from portfolio/assets
                0.0,  // totalDebt   — Phase 2 will populate from liabilities
                goalProgresses,
                new HealthScoreInput.TransactionSummary(totalIncome, totalExpenses, !txs.isEmpty())
        );

        // Delegate all scoring to the engine
        HealthScoreResult result = healthScoreEngine.compute(input);

        // Map to the existing HealthScoreResponse DTO (maintains backward compatibility
        // with /dashboard/health-score). The richer HealthScoreResult is available
        // via /financial/health-score for Flutter screens that need dimension breakdowns.
        return mapToResponse(result);
    }

    /**
     * Maps the engine's HealthScoreResult to the legacy HealthScoreResponse DTO.
     * Pillar scores are extracted by dimension name to preserve backward compatibility.
     */
    private HealthScoreResponse mapToResponse(HealthScoreResult result) {
        int savingsScore   = findDimensionScore(result, "Savings Rate");
        int goalScore      = findDimensionScore(result, "Goal Progress");
        int activityScore  = findDimensionScore(result, "Cash Flow Health");
        int surplusScore   = findDimensionScore(result, "Investment Regularity");
        // Budget score not directly in the new engine (Phase 2 will add it);
        // use debt management as a proxy to fill the legacy field
        int budgetScore    = findDimensionScore(result, "Debt Management");

        return HealthScoreResponse.builder()
                .score(result.totalScore())
                .grade(result.grade())
                .summary(result.summary())
                .savingsScore(savingsScore)
                .budgetScore(budgetScore)
                .goalScore(goalScore)
                .activityScore(activityScore)
                .surplusScore(surplusScore)
                .build();
    }

    private int findDimensionScore(HealthScoreResult result, String dimensionName) {
        return result.dimensions().stream()
                .filter(d -> d.dimension().equals(dimensionName))
                .mapToInt(DimensionScore::score)
                .findFirst()
                .orElse(0);
    }
}
