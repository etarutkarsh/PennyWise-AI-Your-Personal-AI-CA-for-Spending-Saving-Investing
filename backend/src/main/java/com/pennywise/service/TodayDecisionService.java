package com.pennywise.service;

import com.pennywise.dto.decision.DecisionImpact;
import com.pennywise.dto.decision.PartnerOption;
import com.pennywise.dto.decision.RecommendedAction;
import com.pennywise.dto.decision.TodayDecisionResponse;
import com.pennywise.entity.Goal;
import com.pennywise.entity.Transaction;
import com.pennywise.entity.User;
import com.pennywise.repository.GoalRepository;
import com.pennywise.repository.TransactionRepository;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.Period;
import java.time.temporal.ChronoUnit;
import java.util.List;

@Service
public class TodayDecisionService {

    private final TransactionRepository transactionRepository;
    private final GoalRepository goalRepository;
    private final CurrentUserProvider currentUserProvider;
    private final HealthScoreService healthScoreService;

    public TodayDecisionService(
            TransactionRepository transactionRepository,
            GoalRepository goalRepository,
            CurrentUserProvider currentUserProvider,
            HealthScoreService healthScoreService) {
        this.transactionRepository = transactionRepository;
        this.goalRepository = goalRepository;
        this.currentUserProvider = currentUserProvider;
        this.healthScoreService = healthScoreService;
    }

    public TodayDecisionResponse compute() {
        User user = currentUserProvider.get();
        double monthlyIncome = user.getMonthlyIncome() != null
                ? user.getMonthlyIncome().doubleValue() : 0.0;

        // Average monthly expenses from last 90 days
        Instant cutoff = Instant.now().minus(90, ChronoUnit.DAYS);
        List<Transaction> recentTxs = transactionRepository
                .findByUserIdAndTransactionDateBetween(user.getId(), cutoff, Instant.now());

        double totalDebits90 = recentTxs.stream()
                .filter(t -> t.getDirection() == Transaction.TransactionDirection.DEBIT)
                .mapToDouble(t -> t.getAmount().doubleValue())
                .sum();

        double avgMonthlyExpenses = totalDebits90 > 0
                ? totalDebits90 / 3.0
                : (monthlyIncome > 0 ? monthlyIncome * 0.7 : 30000.0);

        List<Goal> goals = goalRepository.findByUserIdOrderByDeadlineAsc(user.getId());

        // Emergency fund: look for a goal typed "emergency_fund"
        double emergencyFundSaved = goals.stream()
                .filter(g -> "emergency_fund".equalsIgnoreCase(g.getGoalType()))
                .mapToDouble(g -> g.getCurrentSaved().doubleValue())
                .findFirst()
                .orElse(0.0);

        double emergencyFundMonths = avgMonthlyExpenses > 0
                ? emergencyFundSaved / avgMonthlyExpenses : 0.0;

        double savingsRate = monthlyIncome > 0
                ? Math.max(0, (monthlyIncome - avgMonthlyExpenses) / monthlyIncome) : 0.0;

        int currentHealthScore = healthScoreService.calculate().getScore();
        int goalSuccessRate = computeGoalSuccessRate(goals);

        // Rule 1: Emergency fund below 3 months
        if (emergencyFundMonths < 3.0) {
            double targetMonthly = roundToNearest500(
                    Math.max(500, (avgMonthlyExpenses * 6 - emergencyFundSaved) / 24.0));
            return buildEmergencyFundDecision(
                    emergencyFundMonths, savingsRate, currentHealthScore, goalSuccessRate, targetMonthly);
        }

        // Rule 2: Savings rate below 15%
        if (savingsRate < 0.15) {
            double targetMonthly = roundToNearest500(monthlyIncome * 0.05);
            return buildIncreaseSavingsDecision(
                    monthlyIncome, avgMonthlyExpenses, savingsRate,
                    currentHealthScore, goalSuccessRate, goals, targetMonthly);
        }

        // Rule 3: Goal without a monthly contribution
        boolean anyGoalNeedsContribution = goals.stream()
                .filter(g -> !"emergency_fund".equalsIgnoreCase(g.getGoalType()))
                .anyMatch(g -> g.getRecommendedMonthlyContribution() == null
                        || g.getRecommendedMonthlyContribution().compareTo(BigDecimal.ZERO) == 0);

        if (!goals.isEmpty() && anyGoalNeedsContribution) {
            Goal target = goals.stream()
                    .filter(g -> !"emergency_fund".equalsIgnoreCase(g.getGoalType()))
                    .filter(g -> g.getRecommendedMonthlyContribution() == null
                            || g.getRecommendedMonthlyContribution().compareTo(BigDecimal.ZERO) == 0)
                    .findFirst()
                    .orElse(goals.get(0));
            return buildStartSipDecision(target, currentHealthScore, goalSuccessRate);
        }

        // Default: tax optimization
        return buildOptimizeTaxDecision(monthlyIncome, currentHealthScore, goalSuccessRate);
    }

    private TodayDecisionResponse buildEmergencyFundDecision(
            double coverageMonths, double savingsRate, int healthScore, int goalSuccessRate, double targetMonthly) {

        List<String> reasons = List.of(
                String.format("Emergency fund covers %.1f months — target is 6 months", coverageMonths),
                String.format("Current savings rate is %.0f%% — a 5%% increase is achievable", savingsRate * 100),
                "A 6-month runway is the single highest-impact financial safety net"
        );

        return new TodayDecisionResponse(
                "build_emergency_fund",
                "Build Emergency Fund",
                String.format("Save ₹%.0f/month for a 6-month safety net", targetMonthly),
                "HIGH",
                "🛡",
                reasons,
                new DecisionImpact(
                        healthScore, Math.min(100, healthScore + 8),
                        goalSuccessRate, Math.min(100, goalSuccessRate + 15),
                        4, targetMonthly),
                new RecommendedAction("START_RD", targetMonthly, "Recurring Deposit", "24 months"),
                rdPartners()
        );
    }

    private TodayDecisionResponse buildIncreaseSavingsDecision(
            double income, double expenses, double savingsRate,
            int healthScore, int goalSuccessRate, List<Goal> goals, double targetMonthly) {

        List<String> reasons = List.of(
                String.format("Savings rate is %.0f%% — the ideal target is 20%%", savingsRate * 100),
                String.format("Monthly surplus of ₹%.0f is currently sitting idle", Math.max(0, income - expenses)),
                "Automating ₹500–₹2,000/month has zero lifestyle impact and compounds over time"
        );

        return new TodayDecisionResponse(
                "increase_savings_rate",
                "Increase Monthly Savings",
                String.format("Deploy ₹%.0f/month that's currently idle", targetMonthly),
                "HIGH",
                "📈",
                reasons,
                new DecisionImpact(
                        healthScore, Math.min(100, healthScore + 6),
                        goalSuccessRate, Math.min(100, goalSuccessRate + 10),
                        2, targetMonthly),
                new RecommendedAction("INCREASE_SIP", targetMonthly, "Recurring Deposit or Liquid Fund", "12 months"),
                savingsPartners()
        );
    }

    private TodayDecisionResponse buildStartSipDecision(
            Goal goal, int healthScore, int goalSuccessRate) {

        long monthsToGoal = goal.getDeadline() != null
                ? Math.max(1, Period.between(LocalDate.now(), goal.getDeadline()).toTotalMonths())
                : 24L;
        double outstanding = goal.getTargetAmount().subtract(goal.getCurrentSaved()).doubleValue();
        double targetMonthly = roundToNearest500(Math.max(500, outstanding / monthsToGoal));

        List<String> reasons = List.of(
                String.format("Goal \"%s\" has no active monthly contribution", goal.getName()),
                String.format("₹%.0f needed over %d months", outstanding, monthsToGoal),
                "Starting even ₹500/month now dramatically improves goal success probability"
        );

        String instrument = monthsToGoal < 24 ? "Recurring Deposit" : "Mutual Fund SIP";

        return new TodayDecisionResponse(
                "start_goal_sip",
                "Start SIP for " + goal.getName(),
                String.format("Invest ₹%.0f/month to hit your goal on time", targetMonthly),
                "MEDIUM",
                "🎯",
                reasons,
                new DecisionImpact(
                        healthScore, Math.min(100, healthScore + 10),
                        goalSuccessRate, Math.min(100, goalSuccessRate + 20),
                        0, targetMonthly),
                new RecommendedAction("START_SIP", targetMonthly, instrument, monthsToGoal + " months"),
                monthsToGoal < 24 ? rdPartners() : sipPartners()
        );
    }

    private TodayDecisionResponse buildOptimizeTaxDecision(
            double income, int healthScore, int goalSuccessRate) {

        double annualIncome = income * 12;
        double taxSavingTarget = Math.min(150000, annualIncome * 0.3);
        double targetMonthly = roundToNearest500(taxSavingTarget / 12);

        List<String> reasons = List.of(
                "Section 80C limit (₹1.5L/year) reduces your taxable income directly",
                String.format("At ₹%.0f/month, you can fully exhaust the 80C limit in 12 months", targetMonthly),
                "ELSS funds are the most flexible: 3-year lock-in vs PPF's 15 years"
        );

        return new TodayDecisionResponse(
                "optimize_tax",
                "Maximize Tax Savings",
                String.format("Save ₹%.0f/month to fully use Section 80C", targetMonthly),
                "MEDIUM",
                "💰",
                reasons,
                new DecisionImpact(
                        healthScore, Math.min(100, healthScore + 5),
                        goalSuccessRate, goalSuccessRate,
                        0, targetMonthly),
                new RecommendedAction("START_ELSS_SIP", targetMonthly, "ELSS Mutual Fund", "12 months"),
                elssPartners()
        );
    }

    // ── Partner catalogs ───────────────────────────────────────────────────────

    private List<PartnerOption> rdPartners() {
        return List.of(
                new PartnerOption("IDFC FIRST Bank", 7.25, 500, "Flexible tenure, instant KYC", "Open", ""),
                new PartnerOption("HDFC Bank", 7.10, 1000, "Premature withdrawal allowed", "Open", ""),
                new PartnerOption("Axis Bank", 7.20, 500, "Auto-renew option available", "Open", ""),
                new PartnerOption("SBI", 6.80, 100, "Widest branch network", "Open", ""),
                new PartnerOption("PPF", 7.10, 500, "Tax-free returns under Section 80C", "Learn", ""),
                new PartnerOption("Liquid Fund", 7.50, 500, "No lock-in, instant redemption", "Compare", "")
        );
    }

    private List<PartnerOption> savingsPartners() {
        return List.of(
                new PartnerOption("Mirae Asset Liquid", 7.50, 500, "Top-rated, T+1 redemption", "Compare", ""),
                new PartnerOption("HDFC Liquid Fund", 7.40, 500, "Low risk, consistent returns", "Compare", ""),
                new PartnerOption("IDFC FIRST Bank RD", 7.25, 500, "Flexible, no lock-in penalty", "Open", ""),
                new PartnerOption("Axis Liquid Fund", 7.30, 500, "Stable NAV, low volatility", "Compare", ""),
                new PartnerOption("SBI Liquid Fund", 7.20, 500, "Government-backed safety", "Compare", "")
        );
    }

    private List<PartnerOption> sipPartners() {
        return List.of(
                new PartnerOption("Mirae Asset Large Cap", 14.20, 500, "Large-cap, lower volatility", "Compare", ""),
                new PartnerOption("HDFC Flexicap Fund", 13.80, 500, "Flexible across market caps", "Compare", ""),
                new PartnerOption("Axis Bluechip Fund", 12.90, 500, "Quality-focused portfolio", "Compare", ""),
                new PartnerOption("PPF", 7.10, 500, "Guaranteed returns, tax-free", "Learn", ""),
                new PartnerOption("NPS (National Pension)", 10.50, 500, "Tax benefit + retirement corpus", "Learn", "")
        );
    }

    private List<PartnerOption> elssPartners() {
        return List.of(
                new PartnerOption("Mirae Asset Tax Saver", 16.10, 500, "3-yr lock-in, 80C eligible", "Compare", ""),
                new PartnerOption("IDFC Tax Advantage", 15.30, 500, "Multi-cap ELSS exposure", "Compare", ""),
                new PartnerOption("Axis Long Term Equity", 14.80, 500, "Consistent outperformer", "Compare", ""),
                new PartnerOption("PPF", 7.10, 500, "Guaranteed returns, 15-yr tenure", "Learn", ""),
                new PartnerOption("NPS", 10.50, 500, "Additional ₹50K deduction u/s 80CCD", "Learn", "")
        );
    }

    // ── Helpers ────────────────────────────────────────────────────────────────

    private int computeGoalSuccessRate(List<Goal> goals) {
        if (goals.isEmpty()) return 0;
        long withContribution = goals.stream()
                .filter(g -> g.getRecommendedMonthlyContribution() != null
                        && g.getRecommendedMonthlyContribution().compareTo(BigDecimal.ZERO) > 0)
                .count();
        return (int) (withContribution * 100L / goals.size());
    }

    private double roundToNearest500(double amount) {
        return Math.ceil(amount / 500.0) * 500.0;
    }
}
