package com.pennywise.financial.model;

import java.util.List;
import java.util.Map;

/**
 * All inputs required to compute the 8-dimension financial health score.
 */
public record HealthScoreInput(
        double monthlySalary,
        double monthlyExpenses,
        double totalSavings,
        double totalDebt,
        List<GoalProgress> goalList,
        TransactionSummary transactionSummary
) {

    /**
     * Summary of a single goal's progress toward target.
     *
     * @param currentSaved current amount saved
     * @param targetAmount total target amount
     * @param monthsRemaining months until deadline
     * @param hasRegularContribution whether contributions have been made recently
     */
    public record GoalProgress(
            double currentSaved,
            double targetAmount,
            int monthsRemaining,
            boolean hasRegularContribution
    ) {}

    /**
     * Aggregated transaction data for the current period.
     *
     * @param totalIncome  total income (CREDIT) transactions
     * @param totalExpenses total expenses (DEBIT) transactions
     * @param hasTransactions whether there are any transactions
     */
    public record TransactionSummary(
            double totalIncome,
            double totalExpenses,
            boolean hasTransactions
    ) {}
}
