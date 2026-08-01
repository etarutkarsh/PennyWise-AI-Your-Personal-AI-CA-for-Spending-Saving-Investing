package com.pennywise.financial.engine;

import com.pennywise.financial.model.DimensionScore;
import com.pennywise.financial.model.HealthScoreInput;
import com.pennywise.financial.model.HealthScoreResult;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

/**
 * Computes a composite 8-dimension financial health score (max 100).
 *
 * Dimensions and weights:
 *   1. Savings Rate            — max 20
 *   2. Emergency Fund          — max 20
 *   3. Debt Management         — max 15
 *   4. Cash Flow Health        — max 10
 *   5. Investment Regularity   — max 15
 *   6. Insurance Coverage      — max 10 (placeholder until Phase 2 data)
 *   7. Tax Efficiency          — max 5  (placeholder until Phase 2 data)
 *   8. Goal Progress           — max 5
 *
 * Total: 100 points.
 *
 * Reference: CFP Board financial planning standards; SEBI investor awareness framework.
 */
@Service
public class HealthScoreEngine {

    /**
     * Computes the full 8-dimension health score.
     *
     * @param input all financial inputs needed for scoring
     * @return HealthScoreResult with total score, grade, and per-dimension breakdowns
     */
    public HealthScoreResult compute(HealthScoreInput input) {
        List<DimensionScore> dimensions = new ArrayList<>();

        dimensions.add(scoreSavingsRate(input));
        dimensions.add(scoreEmergencyFund(input));
        dimensions.add(scoreDebtManagement(input));
        dimensions.add(scoreCashFlowHealth(input));
        dimensions.add(scoreInvestmentRegularity(input));
        dimensions.add(scoreInsuranceCoverage());
        dimensions.add(scoreTaxEfficiency());
        dimensions.add(scoreGoalProgress(input));

        int totalScore = dimensions.stream().mapToInt(DimensionScore::score).sum();
        totalScore = Math.max(0, Math.min(100, totalScore));

        String grade = computeGrade(totalScore);
        String summary = computeSummary(totalScore);

        // Top 3 actions: dimensions with the most room to improve, excluding placeholders
        List<String> topActions = dimensions.stream()
                .filter(d -> !d.dimension().equals("Insurance Coverage") && !d.dimension().equals("Tax Efficiency"))
                .sorted(Comparator.comparingInt(d -> (d.maxScore() - d.score())))
                .limit(3)
                .map(DimensionScore::recommendation)
                .collect(java.util.stream.Collectors.toList());
        java.util.Collections.reverse(topActions);

        return new HealthScoreResult(totalScore, 100, grade, summary, dimensions, topActions);
    }

    // ── Dimension 1: Savings Rate (max 20) ───────────────────────────────────

    private DimensionScore scoreSavingsRate(HealthScoreInput input) {
        final int MAX = 20;
        double salary = input.monthlySalary();
        double expenses = input.monthlyExpenses();

        if (salary <= 0) {
            return new DimensionScore("Savings Rate", 0, MAX, "Poor",
                    "Monthly income not on record — unable to compute savings rate.",
                    "Add your monthly income to enable savings rate tracking.");
        }

        double savingsRate = (salary - expenses) / salary * 100;
        int score;
        String status;
        String insight;

        if (savingsRate >= 30) {
            score = 20; status = "Excellent";
            insight = String.format("You save %.1f%% of income. Excellent — far above the 20%% target.", savingsRate);
        } else if (savingsRate >= 20) {
            score = 16; status = "Good";
            insight = String.format("You save %.1f%% of income. Good. Target is 20%% minimum.", savingsRate);
        } else if (savingsRate >= 10) {
            score = 11; status = "Fair";
            insight = String.format("You save %.1f%% of income. Target is 20%% minimum.", savingsRate);
        } else if (savingsRate > 0) {
            score = 6; status = "Poor";
            insight = String.format("You save only %.1f%% of income. Target is 20%% minimum.", savingsRate);
        } else {
            score = 0; status = "Poor";
            insight = String.format("Expenses exceed income by %.1f%%. Immediate action needed.", Math.abs(savingsRate));
        }

        String recommendation = savingsRate >= 30
                ? "Maintain your savings rate and consider increasing investments."
                : "Aim to cut discretionary spending to reach a 20% savings rate.";

        return new DimensionScore("Savings Rate", score, MAX, status, insight, recommendation);
    }

    // ── Dimension 2: Emergency Fund (max 20) ─────────────────────────────────

    private DimensionScore scoreEmergencyFund(HealthScoreInput input) {
        final int MAX = 20;
        double expenses = input.monthlyExpenses();
        double savings = input.totalSavings();

        if (expenses <= 0) {
            return new DimensionScore("Emergency Fund", 8, MAX, "Fair",
                    "Monthly expenses not recorded — using savings balance only.",
                    "Log your monthly expenses to compute emergency fund coverage.");
        }

        double months = savings / expenses;
        int score;
        String status;
        String insight;
        String recommendation;

        if (months >= 6) {
            score = 20; status = "Excellent";
            insight = String.format("Emergency fund covers %.1f months of expenses. Excellent.", months);
            recommendation = "Emergency fund is solid. Redirect surplus into long-term investments.";
        } else if (months >= 3) {
            score = 15; status = "Good";
            insight = String.format("Emergency fund covers %.1f months. Target is 6 months.", months);
            recommendation = String.format("Save %.0f more to reach 6 months of expenses.",
                    (6 * expenses) - savings);
        } else if (months >= 1) {
            score = 8; status = "Fair";
            insight = String.format("Emergency fund covers only %.1f months. Minimum target is 3 months.", months);
            recommendation = String.format("Build emergency fund to at least %.0f (3 months of expenses).",
                    3 * expenses);
        } else {
            score = 0; status = "Poor";
            insight = "Emergency fund covers less than 1 month of expenses. Financial safety net is critical.";
            recommendation = String.format("Immediate priority: save %.0f to cover 1 month of expenses.",
                    expenses - savings);
        }

        return new DimensionScore("Emergency Fund", score, MAX, status, insight, recommendation);
    }

    // ── Dimension 3: Debt Management (max 15) ────────────────────────────────

    private DimensionScore scoreDebtManagement(HealthScoreInput input) {
        final int MAX = 15;
        double annualIncome = input.monthlySalary() * 12;
        double debt = input.totalDebt();

        if (debt <= 0) {
            return new DimensionScore("Debt Management", 15, MAX, "Excellent",
                    "No outstanding debt. Excellent financial discipline.",
                    "Stay debt-free. If taking a home loan, keep EMI below 40% of take-home.");
        }

        if (annualIncome <= 0) {
            return new DimensionScore("Debt Management", 5, MAX, "Fair",
                    "Cannot compute debt-to-income ratio without income data.",
                    "Add your monthly income to enable debt ratio tracking.");
        }

        double debtToIncome = debt / annualIncome;
        int score;
        String status;
        String insight = String.format("Debt-to-annual-income ratio: %.0f%%.", debtToIncome * 100);
        String recommendation;

        if (debtToIncome < 0.20) {
            score = 12; status = "Good";
            recommendation = "Debt is manageable. Consider accelerating repayment to free up cash flow.";
        } else if (debtToIncome < 0.35) {
            score = 8; status = "Fair";
            recommendation = "Debt is elevated. Prioritise repayment of high-interest debt (credit cards, personal loans).";
        } else if (debtToIncome < 0.50) {
            score = 3; status = "Poor";
            recommendation = "High debt load. Stop taking new debt and aggressively pay down existing balances.";
        } else {
            score = 0; status = "Poor";
            insight += " Debt exceeds 50% of annual income — urgent action required.";
            recommendation = "Seek debt restructuring. Consider a personal loan to consolidate high-interest debt.";
        }

        return new DimensionScore("Debt Management", score, MAX, status, insight, recommendation);
    }

    // ── Dimension 4: Cash Flow Health (max 10) ───────────────────────────────

    private DimensionScore scoreCashFlowHealth(HealthScoreInput input) {
        final int MAX = 10;
        double income = input.transactionSummary().totalIncome();
        double expenses = input.transactionSummary().totalExpenses();

        if (!input.transactionSummary().hasTransactions()) {
            return new DimensionScore("Cash Flow Health", 2, MAX, "Fair",
                    "No transaction data for this period — unable to assess cash flow trend.",
                    "Start logging transactions to track cash flow health.");
        }

        int score;
        String status;
        String insight;
        String recommendation;

        if (income > expenses * 1.10) {
            score = 10; status = "Excellent";
            insight = String.format("Income (₹%.0f) exceeds expenses (₹%.0f) by >10%%. Healthy surplus.", income, expenses);
            recommendation = "Strong cash flow. Channel surplus into investments or emergency fund.";
        } else if (income > expenses) {
            score = 6; status = "Good";
            insight = String.format("Income (₹%.0f) exceeds expenses (₹%.0f). Positive but thin margin.", income, expenses);
            recommendation = "Income covers expenses. Look for ways to increase the gap by reducing discretionary spend.";
        } else if (income >= expenses * 0.95) {
            score = 2; status = "Fair";
            insight = String.format("Income (₹%.0f) barely covers expenses (₹%.0f). Almost breakeven.", income, expenses);
            recommendation = "Tight cash flow. Identify one category to cut by 10–15%%.";
        } else {
            score = 0; status = "Poor";
            insight = String.format("Expenses (₹%.0f) exceed income (₹%.0f). Cash flow is negative.", expenses, income);
            recommendation = "Negative cash flow — urgent. Review all expense categories and cut non-essentials.";
        }

        return new DimensionScore("Cash Flow Health", score, MAX, status, insight, recommendation);
    }

    // ── Dimension 5: Investment Regularity (max 15) ──────────────────────────

    private DimensionScore scoreInvestmentRegularity(HealthScoreInput input) {
        final int MAX = 15;
        List<HealthScoreInput.GoalProgress> goals = input.goalList();

        if (goals == null || goals.isEmpty()) {
            return new DimensionScore("Investment Regularity", 0, MAX, "Poor",
                    "No investment goals set.",
                    "Set at least one financial goal and link a monthly SIP contribution to it.");
        }

        boolean hasAnyContributions = goals.stream().anyMatch(HealthScoreInput.GoalProgress::hasRegularContribution);
        long regularCount = goals.stream().filter(HealthScoreInput.GoalProgress::hasRegularContribution).count();
        boolean allRegular = regularCount == goals.size();

        int score;
        String status;
        String insight;
        String recommendation;

        if (allRegular) {
            score = 15; status = "Excellent";
            insight = String.format("All %d goal(s) have active regular contributions. Excellent discipline.", goals.size());
            recommendation = "Keep your SIPs running. Consider increasing contribution by 10% each year.";
        } else if (hasAnyContributions) {
            score = 10; status = "Good";
            insight = String.format("%d of %d goals have regular contributions.", regularCount, goals.size());
            recommendation = "Set up automatic contributions for goals that lack them.";
        } else if (!goals.isEmpty()) {
            score = 5; status = "Fair";
            insight = "Goals are set but no regular contributions found.";
            recommendation = "Convert goals into active SIPs. Even ₹500/month compounds significantly over time.";
        } else {
            score = 0; status = "Poor";
            insight = "No investment goals or contributions.";
            recommendation = "Start with one goal — even an emergency fund target — and automate contributions.";
        }

        return new DimensionScore("Investment Regularity", score, MAX, status, insight, recommendation);
    }

    // ── Dimension 6: Insurance Coverage (max 10) — Placeholder ──────────────

    private DimensionScore scoreInsuranceCoverage() {
        return new DimensionScore(
                "Insurance Coverage",
                7, 10,
                "Good",
                "Connect insurance data to compute exact coverage score.",
                "Ensure you have: term life (10× annual income), health cover (₹10L minimum), personal accident cover."
        );
    }

    // ── Dimension 7: Tax Efficiency (max 5) — Placeholder ────────────────────

    private DimensionScore scoreTaxEfficiency() {
        return new DimensionScore(
                "Tax Efficiency",
                4, 5,
                "Good",
                "Tax optimization analysis coming in Phase 2.",
                "Maximise Section 80C (₹1.5L), NPS (₹50k extra under 80CCD(1B)), and health insurance (80D)."
        );
    }

    // ── Dimension 8: Goal Progress (max 5) ───────────────────────────────────

    private DimensionScore scoreGoalProgress(HealthScoreInput input) {
        final int MAX = 5;
        List<HealthScoreInput.GoalProgress> goals = input.goalList();

        if (goals == null || goals.isEmpty()) {
            return new DimensionScore("Goal Progress", 0, MAX, "Poor",
                    "No financial goals set.",
                    "Define at least one goal with a target date to track progress.");
        }

        long onTrack = goals.stream()
                .filter(g -> g.targetAmount() > 0 && isOnTrack(g))
                .count();

        double ratio = (double) onTrack / goals.size();

        int score;
        String status;
        String insight = String.format("%d of %d goals are on track.", onTrack, goals.size());
        String recommendation;

        if (ratio >= 1.0) {
            score = 5; status = "Excellent";
            recommendation = "All goals on track. Review deadlines annually and adjust for inflation.";
        } else if (ratio >= 0.5) {
            score = 3; status = "Good";
            recommendation = "Review lagging goals — consider extending deadlines or increasing contributions.";
        } else if (ratio > 0) {
            score = 1; status = "Fair";
            recommendation = "Most goals are behind. Prioritise your top 2 goals and temporarily pause the rest.";
        } else {
            score = 0; status = "Poor";
            recommendation = "No goals are on track. Reassess timeline or target amounts for realism.";
        }

        return new DimensionScore("Goal Progress", score, MAX, status, insight, recommendation);
    }

    /**
     * A goal is "on track" if the current saved amount >= expected progress
     * based on a linear interpolation (proportional to time elapsed).
     */
    private boolean isOnTrack(HealthScoreInput.GoalProgress g) {
        if (g.targetAmount() <= 0) return false;
        // Assume goal started at same ratio of total months; on track = at least proportional progress
        // Without start date, use months remaining as proxy: if 0 months left and saved < target, not on track
        if (g.monthsRemaining() <= 0) {
            return g.currentSaved() >= g.targetAmount();
        }
        // Simple heuristic: at least 10% progress unless goal has < 3 months
        double progressPercent = g.currentSaved() / g.targetAmount() * 100;
        return progressPercent >= 10 || g.monthsRemaining() <= 3;
    }

    // ── Grade and summary ─────────────────────────────────────────────────────

    private String computeGrade(int score) {
        if (score >= 90) return "A+";
        if (score >= 80) return "A";
        if (score >= 70) return "B+";
        if (score >= 60) return "B";
        if (score >= 50) return "C";
        return "D";
    }

    private String computeSummary(int score) {
        if (score >= 90) return "Outstanding financial health. You're building real wealth.";
        if (score >= 80) return "Excellent financial health. Keep up the discipline.";
        if (score >= 70) return "Good financial health with a few areas to strengthen.";
        if (score >= 60) return "Decent foundation — focus on savings rate and emergency fund.";
        if (score >= 50) return "Financial health needs work. Start with budgeting and an emergency fund.";
        return "Financial health requires immediate attention. Address debt and emergency fund first.";
    }
}
