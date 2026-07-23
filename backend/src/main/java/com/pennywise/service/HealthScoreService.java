package com.pennywise.service;

import com.pennywise.dto.HealthScoreResponse;
import com.pennywise.entity.Budget;
import com.pennywise.entity.Goal;
import com.pennywise.entity.Transaction;
import com.pennywise.entity.User;
import com.pennywise.repository.BudgetRepository;
import com.pennywise.repository.GoalRepository;
import com.pennywise.repository.TransactionRepository;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.YearMonth;
import java.time.ZoneOffset;
import java.util.List;

/**
 * Calculates a 0–100 financial health score from four pillars:
 *   Savings Rate (25) + Budget Adherence (25) + Goal Progress (25)
 *   + Activity (15) + Income Surplus (10)
 */
@Service
public class HealthScoreService {

    private final TransactionRepository transactionRepository;
    private final BudgetRepository budgetRepository;
    private final GoalRepository goalRepository;
    private final CurrentUserProvider currentUserProvider;

    public HealthScoreService(TransactionRepository transactionRepository,
                               BudgetRepository budgetRepository,
                               GoalRepository goalRepository,
                               CurrentUserProvider currentUserProvider) {
        this.transactionRepository = transactionRepository;
        this.budgetRepository = budgetRepository;
        this.goalRepository = goalRepository;
        this.currentUserProvider = currentUserProvider;
    }

    public HealthScoreResponse calculate() {
        User user = currentUserProvider.get();

        YearMonth current = YearMonth.now();
        Instant from = current.atDay(1).atStartOfDay().toInstant(ZoneOffset.UTC);
        Instant to   = current.atEndOfMonth().atTime(23, 59, 59).toInstant(ZoneOffset.UTC);

        List<Transaction> txs = transactionRepository
                .findByUserIdAndTransactionDateBetween(user.getId(), from, to);

        // ── Pillar 1: Savings Rate (25 pts) ────────────────────────────────
        // Score based on how much of income is left after spending.
        // If no salary stored, fall back to debit/credit ratio.
        int savingsScore = calcSavingsScore(user, txs);

        // ── Pillar 2: Budget Adherence (25 pts) ────────────────────────────
        int budgetScore = calcBudgetScore(user, current);

        // ── Pillar 3: Goal Progress (25 pts) ───────────────────────────────
        int goalScore = calcGoalScore(user);

        // ── Pillar 4: Activity (15 pts) ────────────────────────────────────
        int activityScore = txs.isEmpty() ? 0 : 15;

        // ── Pillar 5: Income Surplus (10 pts) ──────────────────────────────
        int surplusScore = calcSurplusScore(txs);

        int total = savingsScore + budgetScore + goalScore + activityScore + surplusScore;
        total = Math.min(100, Math.max(0, total));

        return HealthScoreResponse.builder()
                .score(total)
                .grade(grade(total))
                .summary(summary(total))
                .savingsScore(savingsScore)
                .budgetScore(budgetScore)
                .goalScore(goalScore)
                .activityScore(activityScore)
                .surplusScore(surplusScore)
                .build();
    }

    private int calcSavingsScore(User user, List<Transaction> txs) {
        BigDecimal salary = user.getMonthlyIncome();
        if (salary == null || salary.compareTo(BigDecimal.ZERO) <= 0) {
            // No salary on record — partial score if there are credit transactions
            boolean hasCredit = txs.stream()
                    .anyMatch(t -> t.getDirection().name().equals("CREDIT"));
            return hasCredit ? 12 : 5;
        }

        BigDecimal totalDebit = txs.stream()
                .filter(t -> t.getDirection().name().equals("DEBIT"))
                .map(Transaction::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // Savings rate = (salary - debit) / salary
        BigDecimal savingsRate = salary.subtract(totalDebit)
                .divide(salary, 4, RoundingMode.HALF_UP);

        if (savingsRate.compareTo(BigDecimal.valueOf(0.30)) >= 0) return 25;
        if (savingsRate.compareTo(BigDecimal.valueOf(0.20)) >= 0) return 20;
        if (savingsRate.compareTo(BigDecimal.valueOf(0.10)) >= 0) return 14;
        if (savingsRate.compareTo(BigDecimal.ZERO) >= 0)           return 8;
        return 0; // spending more than earning
    }

    private int calcBudgetScore(User user, YearMonth period) {
        List<Budget> budgets = budgetRepository.findByUserIdAndPeriod(
                user.getId(), period.toString());

        if (budgets.isEmpty()) return 10; // no budgets set — partial credit

        long total = budgets.size();
        long onTrack = budgets.stream()
                .filter(b -> b.getSpentSoFar().compareTo(b.getMonthlyLimit()) <= 0)
                .count();

        double ratio = (double) onTrack / total;
        if (ratio >= 1.0) return 25;
        if (ratio >= 0.75) return 18;
        if (ratio >= 0.50) return 12;
        return 5;
    }

    private int calcGoalScore(User user) {
        List<Goal> goals = goalRepository.findByUserIdOrderByDeadlineAsc(user.getId());
        if (goals.isEmpty()) return 10; // no goals yet — partial credit

        double avgProgress = goals.stream()
                .mapToDouble(g -> {
                    if (g.getTargetAmount().compareTo(BigDecimal.ZERO) <= 0) return 0;
                    return g.getCurrentSaved()
                            .divide(g.getTargetAmount(), 4, RoundingMode.HALF_UP)
                            .doubleValue() * 100;
                })
                .average()
                .orElse(0);

        if (avgProgress >= 75) return 25;
        if (avgProgress >= 50) return 18;
        if (avgProgress >= 25) return 12;
        if (avgProgress > 0)   return 7;
        return 3;
    }

    private int calcSurplusScore(List<Transaction> txs) {
        BigDecimal totalCredit = txs.stream()
                .filter(t -> t.getDirection().name().equals("CREDIT"))
                .map(Transaction::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalDebit = txs.stream()
                .filter(t -> t.getDirection().name().equals("DEBIT"))
                .map(Transaction::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        return totalCredit.compareTo(totalDebit) > 0 ? 10 : 0;
    }

    private String grade(int score) {
        if (score >= 80) return "Excellent";
        if (score >= 60) return "Good";
        if (score >= 40) return "Fair";
        return "Poor";
    }

    private String summary(int score) {
        if (score >= 80) return "Great job! Your finances are in excellent shape. Keep it up.";
        if (score >= 60) return "You're doing well. A few tweaks can push you to excellent.";
        if (score >= 40) return "There's room to improve. Focus on budgets and saving more.";
        return "Your finances need attention. Start by tracking all expenses and setting a budget.";
    }
}
