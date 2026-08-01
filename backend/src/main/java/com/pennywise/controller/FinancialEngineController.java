package com.pennywise.controller;

import com.pennywise.financial.engine.AllocationEngine;
import com.pennywise.financial.engine.ExpectedReturnEngine;
import com.pennywise.financial.engine.HealthScoreEngine;
import com.pennywise.financial.engine.LoanRateRegistry;
import com.pennywise.financial.engine.ProjectionEngine;
import com.pennywise.financial.engine.RiskEngine;
import com.pennywise.financial.formula.Formula;
import com.pennywise.financial.model.AssetClass;
import com.pennywise.financial.model.ExpectedReturn;
import com.pennywise.financial.model.HealthScoreInput;
import com.pennywise.financial.model.HealthScoreResult;
import com.pennywise.financial.model.LoanRate;
import com.pennywise.financial.model.PortfolioAllocation;
import com.pennywise.financial.model.RiskCapacityInput;
import com.pennywise.financial.model.RiskCategory;
import com.pennywise.financial.model.RiskProfile;
import com.pennywise.financial.model.RiskWillingnessInput;
import com.pennywise.service.CurrentUserProvider;
import com.pennywise.entity.User;
import com.pennywise.repository.GoalRepository;
import com.pennywise.repository.TransactionRepository;
import com.pennywise.entity.Transaction;
import com.pennywise.entity.Goal;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.lang.reflect.Method;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.YearMonth;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Financial Intelligence Engine API.
 * All endpoints require authentication (JWT).
 *
 * Base path: /financial
 */
@RestController
@RequestMapping("/financial")
public class FinancialEngineController {

    private final ExpectedReturnEngine expectedReturnEngine;
    private final RiskEngine riskEngine;
    private final AllocationEngine allocationEngine;
    private final HealthScoreEngine healthScoreEngine;
    private final ProjectionEngine projectionEngine;
    private final LoanRateRegistry loanRateRegistry;
    private final CurrentUserProvider currentUserProvider;
    private final TransactionRepository transactionRepository;
    private final GoalRepository goalRepository;

    public FinancialEngineController(
            ExpectedReturnEngine expectedReturnEngine,
            RiskEngine riskEngine,
            AllocationEngine allocationEngine,
            HealthScoreEngine healthScoreEngine,
            ProjectionEngine projectionEngine,
            LoanRateRegistry loanRateRegistry,
            CurrentUserProvider currentUserProvider,
            TransactionRepository transactionRepository,
            GoalRepository goalRepository) {
        this.expectedReturnEngine = expectedReturnEngine;
        this.riskEngine = riskEngine;
        this.allocationEngine = allocationEngine;
        this.healthScoreEngine = healthScoreEngine;
        this.projectionEngine = projectionEngine;
        this.loanRateRegistry = loanRateRegistry;
        this.currentUserProvider = currentUserProvider;
        this.transactionRepository = transactionRepository;
        this.goalRepository = goalRepository;
    }

    // ── Expected Returns ──────────────────────────────────────────────────────

    /**
     * GET /financial/expected-returns
     * Returns expected returns for all asset classes.
     */
    @GetMapping("/expected-returns")
    public ResponseEntity<List<ExpectedReturn>> getAllExpectedReturns() {
        return ResponseEntity.ok(expectedReturnEngine.getAllReturns());
    }

    /**
     * GET /financial/expected-returns/{assetClass}
     * Returns expected return for a single asset class.
     * Asset class values: LIQUID_FUND, ARBITRAGE, DEBT_FUND, PPF, EPF, GOLD,
     *                     EQUITY_INDEX, INTERNATIONAL_EQUITY, DIRECT_EQUITY, REAL_ESTATE
     */
    @GetMapping("/expected-returns/{assetClass}")
    public ResponseEntity<ExpectedReturn> getExpectedReturn(@PathVariable String assetClass) {
        AssetClass ac = AssetClass.valueOf(assetClass.toUpperCase());
        return ResponseEntity.ok(expectedReturnEngine.getReturn(ac));
    }

    // ── Risk Profile ──────────────────────────────────────────────────────────

    /**
     * POST /financial/risk-profile
     * Computes a two-layer risk profile from psychographic willingness and financial capacity inputs.
     *
     * Request body: { "willingness": { lossReaction, timeHorizon, investmentExperience, volatilityComfort, goalFlexibility },
     *                "capacity":    { monthlyIncome, monthlyExpenses, totalSavings, totalDebt, dependents,
     *                                 hasEmergencyFund, hasStableJob, yearsToMajorGoal } }
     */
    @PostMapping("/risk-profile")
    public ResponseEntity<RiskProfile> assessRiskProfile(@RequestBody RiskProfileRequest request) {
        RiskProfile profile = riskEngine.assess(request.willingness(), request.capacity());
        return ResponseEntity.ok(profile);
    }

    // ── Portfolio Allocation ──────────────────────────────────────────────────

    /**
     * POST /financial/allocation
     * Returns the recommended portfolio allocation for a given risk category and age.
     *
     * Request body: { "riskCategory": "MODERATE", "age": 32 }
     */
    @PostMapping("/allocation")
    public ResponseEntity<PortfolioAllocation> getAllocation(@RequestBody AllocationRequest request) {
        RiskCategory category = RiskCategory.valueOf(request.riskCategory().toUpperCase());
        PortfolioAllocation allocation = allocationEngine.allocate(category, request.age());
        return ResponseEntity.ok(allocation);
    }

    // ── Financial Health Score ────────────────────────────────────────────────

    /**
     * GET /financial/health-score
     * Computes the 8-dimension financial health score for the authenticated user.
     * Pulls live data from the user's transactions and goals.
     */
    @GetMapping("/health-score")
    public ResponseEntity<HealthScoreResult> getHealthScore() {
        User user = currentUserProvider.get();

        // Gather transaction data for current month
        YearMonth current = YearMonth.now();
        Instant from = current.atDay(1).atStartOfDay().toInstant(ZoneOffset.UTC);
        Instant to = current.atEndOfMonth().atTime(23, 59, 59).toInstant(ZoneOffset.UTC);
        List<Transaction> txs = transactionRepository.findByUserIdAndTransactionDateBetween(user.getId(), from, to);

        double totalIncome = txs.stream()
                .filter(t -> "CREDIT".equals(t.getDirection().name()))
                .mapToDouble(t -> t.getAmount().doubleValue())
                .sum();
        double totalExpenses = txs.stream()
                .filter(t -> "DEBIT".equals(t.getDirection().name()))
                .mapToDouble(t -> t.getAmount().doubleValue())
                .sum();

        // Gather goals
        List<Goal> goals = goalRepository.findByUserIdOrderByDeadlineAsc(user.getId());
        List<HealthScoreInput.GoalProgress> goalProgresses = goals.stream()
                .map(g -> {
                    long months = java.time.Period.between(java.time.LocalDate.now(), g.getDeadline()).toTotalMonths();
                    double currentSaved = g.getCurrentSaved().doubleValue();
                    double targetAmount = g.getTargetAmount().doubleValue();
                    boolean hasContribution = g.getRecommendedMonthlyContribution() != null
                            && g.getRecommendedMonthlyContribution().compareTo(BigDecimal.ZERO) > 0;
                    return new HealthScoreInput.GoalProgress(currentSaved, targetAmount, (int) months, hasContribution);
                })
                .toList();

        double monthlySalary = user.getMonthlyIncome() != null
                ? user.getMonthlyIncome().doubleValue() : 0.0;

        HealthScoreInput input = new HealthScoreInput(
                monthlySalary,
                totalExpenses > 0 ? totalExpenses : monthlySalary * 0.7,
                0.0,  // totalSavings — not yet tracked in Phase 1 entity
                0.0,  // totalDebt — not yet tracked in Phase 1 entity
                goalProgresses,
                new HealthScoreInput.TransactionSummary(totalIncome, totalExpenses, !txs.isEmpty())
        );

        return ResponseEntity.ok(healthScoreEngine.compute(input));
    }

    // ── Projections ───────────────────────────────────────────────────────────

    /**
     * POST /financial/projection/sip
     * Computes SIP future value.
     *
     * Request body: { "monthlyInvestment": 5000, "annualReturnPercent": 12.0, "months": 120 }
     */
    @PostMapping("/projection/sip")
    public ResponseEntity<Map<String, Object>> sipProjection(@RequestBody SipRequest request) {
        double fv = projectionEngine.sipFutureValue(
                request.monthlyInvestment(), request.annualReturnPercent(), request.months());

        Map<String, Object> result = new HashMap<>();
        result.put("futureValue", round(fv));
        result.put("monthlyInvestment", request.monthlyInvestment());
        result.put("annualReturnPercent", request.annualReturnPercent());
        result.put("months", request.months());
        result.put("totalInvested", round(request.monthlyInvestment() * request.months()));
        result.put("wealthGained", round(fv - request.monthlyInvestment() * request.months()));

        return ResponseEntity.ok(result);
    }

    /**
     * POST /financial/projection/goal-contribution
     * Computes monthly contribution needed to reach a goal.
     *
     * Request body: { "targetAmount": 500000, "currentSaved": 50000, "months": 36, "annualReturnPercent": 7.0 }
     */
    @PostMapping("/projection/goal-contribution")
    public ResponseEntity<Map<String, Object>> goalContributionProjection(@RequestBody GoalContributionRequest request) {
        double shortfall = Math.max(0, request.targetAmount() - request.currentSaved());
        double monthly = projectionEngine.goalMonthlyContribution(
                shortfall, request.annualReturnPercent(), request.months());

        Map<String, Object> result = new HashMap<>();
        result.put("monthlyNeeded", round(monthly));
        result.put("targetAmount", request.targetAmount());
        result.put("currentSaved", request.currentSaved());
        result.put("shortfall", round(shortfall));
        result.put("months", request.months());
        result.put("annualReturnPercent", request.annualReturnPercent());

        return ResponseEntity.ok(result);
    }

    /**
     * POST /financial/projection/emi
     * Computes loan EMI.
     *
     * Request body: { "principal": 1000000, "annualRatePercent": 8.5, "months": 240 }
     */
    @PostMapping("/projection/emi")
    public ResponseEntity<Map<String, Object>> emiProjection(@RequestBody EmiRequest request) {
        double emi = projectionEngine.emi(request.principal(), request.annualRatePercent(), request.months());
        double totalPayment = emi * request.months();
        double totalInterest = totalPayment - request.principal();

        Map<String, Object> result = new HashMap<>();
        result.put("emi", round(emi));
        result.put("principal", request.principal());
        result.put("annualRatePercent", request.annualRatePercent());
        result.put("months", request.months());
        result.put("totalPayment", round(totalPayment));
        result.put("totalInterest", round(totalInterest));

        return ResponseEntity.ok(result);
    }

    // ── Loan Rates ────────────────────────────────────────────────────────────

    /**
     * GET /financial/loan-rates
     * Returns benchmark rates for all supported loan types.
     */
    @GetMapping("/loan-rates")
    public ResponseEntity<List<LoanRate>> getLoanRates() {
        return ResponseEntity.ok(loanRateRegistry.getAllRates());
    }

    // ── Formula Registry ──────────────────────────────────────────────────────

    /**
     * GET /financial/formula-registry
     * Returns metadata for all @Formula-annotated engine methods.
     */
    @GetMapping("/formula-registry")
    public ResponseEntity<List<Map<String, Object>>> getFormulaRegistry() {
        List<Map<String, Object>> registry = new ArrayList<>();
        scanForFormulas(projectionEngine.getClass(), registry);
        return ResponseEntity.ok(registry);
    }

    private void scanForFormulas(Class<?> clazz, List<Map<String, Object>> registry) {
        for (Method method : clazz.getDeclaredMethods()) {
            Formula annotation = method.getAnnotation(Formula.class);
            if (annotation != null) {
                Map<String, Object> entry = new HashMap<>();
                entry.put("name", annotation.name());
                entry.put("purpose", annotation.purpose());
                entry.put("expression", annotation.expression());
                entry.put("variables", annotation.variables());
                entry.put("reference", annotation.reference());
                entry.put("assumptions", annotation.assumptions());
                entry.put("limitations", annotation.limitations());
                entry.put("version", annotation.version());
                entry.put("method", method.getName());
                registry.add(entry);
            }
        }
    }

    // ── Helper ────────────────────────────────────────────────────────────────

    private double round(double value) {
        return BigDecimal.valueOf(value).setScale(2, RoundingMode.HALF_UP).doubleValue();
    }

    // ── Inner request records ─────────────────────────────────────────────────

    public record RiskProfileRequest(RiskWillingnessInput willingness, RiskCapacityInput capacity) {}

    public record AllocationRequest(String riskCategory, int age) {}

    public record SipRequest(double monthlyInvestment, double annualReturnPercent, int months) {}

    public record GoalContributionRequest(double targetAmount, double currentSaved,
                                          int months, double annualReturnPercent) {}

    public record EmiRequest(double principal, double annualRatePercent, int months) {}
}
