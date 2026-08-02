package com.pennywise.service;

import com.pennywise.dto.AffordabilityRequest;
import com.pennywise.dto.AffordabilityResponse;
import com.pennywise.dto.GoalImpactDto;
import com.pennywise.engine.decision.DecisionContext;
import com.pennywise.engine.decision.DecisionEngine;
import com.pennywise.engine.decision.GoalImpactEngine;
import com.pennywise.entity.Goal;
import com.pennywise.entity.Transaction;
import com.pennywise.entity.User;
import com.pennywise.repository.AssetRepository;
import com.pennywise.repository.GoalRepository;
import com.pennywise.repository.TransactionRepository;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Set;

@Service
public class AffordabilityService {

    private static final int TRAILING_MONTHS_FOR_AVERAGE = 3;
    private static final Set<String> LIQUID_ASSET_TYPES = Set.of("cash", "savings", "fd", "liquid_fund");

    private final CurrentUserProvider currentUserProvider;
    private final TransactionRepository transactionRepository;
    private final AssetRepository assetRepository;
    private final GoalRepository goalRepository;
    private final DecisionEngine decisionEngine;
    private final GoalImpactEngine goalImpactEngine;

    public AffordabilityService(CurrentUserProvider currentUserProvider,
                                TransactionRepository transactionRepository,
                                AssetRepository assetRepository,
                                GoalRepository goalRepository,
                                DecisionEngine decisionEngine,
                                GoalImpactEngine goalImpactEngine) {
        this.currentUserProvider = currentUserProvider;
        this.transactionRepository = transactionRepository;
        this.assetRepository = assetRepository;
        this.goalRepository = goalRepository;
        this.decisionEngine = decisionEngine;
        this.goalImpactEngine = goalImpactEngine;
    }

    public AffordabilityResponse check(AffordabilityRequest request) {
        User user = currentUserProvider.get();

        Instant from = Instant.now().minus(TRAILING_MONTHS_FOR_AVERAGE * 30L, ChronoUnit.DAYS);
        List<Transaction> recent = transactionRepository.findByUserIdAndTransactionDateBetween(
                user.getId(), from, Instant.now());

        BigDecimal totalExpenses = recent.stream()
                .filter(t -> t.getDirection() == Transaction.TransactionDirection.DEBIT)
                .map(Transaction::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal avgMonthlyExpenses = totalExpenses.divide(
                BigDecimal.valueOf(TRAILING_MONTHS_FOR_AVERAGE), 2, RoundingMode.HALF_UP);

        BigDecimal monthlyIncome = user.getMonthlyIncome() != null ? user.getMonthlyIncome() : BigDecimal.ZERO;

        BigDecimal currentEmergencyFund = assetRepository.findByUserIdOrderByCreatedAtDesc(user.getId())
                .stream()
                .filter(a -> LIQUID_ASSET_TYPES.contains(a.getAssetType()))
                .map(a -> a.getValue() != null ? a.getValue() : BigDecimal.ZERO)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        DecisionContext ctx = DecisionContext.builder()
                .itemName(request.getItemName())
                .price(request.getPrice())
                .downPayment(request.getDownPayment())
                .interestRatePercent(request.getInterestRatePercent())
                .tenureMonths(request.getTenureMonths())
                .existingMonthlyEmi(request.getExistingMonthlyEmi())
                .monthlyIncome(monthlyIncome)
                .avgMonthlyExpenses(avgMonthlyExpenses)
                .currentEmergencyFund(currentEmergencyFund)
                .build();

        AffordabilityResponse response = decisionEngine.evaluate(ctx);

        // Goal Impact — find the recommended scenario's EMI and compute downstream goal effects
        BigDecimal recommendedEmi = response.getScenarios() == null ? BigDecimal.ZERO
                : response.getScenarios().stream()
                        .filter(s -> s.isRecommended() && s.getMonthlyEmi() != null)
                        .findFirst()
                        .map(s -> s.getMonthlyEmi())
                        .orElse(BigDecimal.ZERO);

        BigDecimal grossSurplus = ctx.grossSurplus();
        BigDecimal surplusAfterPurchase = grossSurplus.subtract(recommendedEmi).max(BigDecimal.ZERO);

        // For cash (no loan EMI), the immediate outflow is the full price; for loan it's the down payment
        BigDecimal immediateOutflow = ctx.isLoan()
                ? DecisionContext.orZero(ctx.getDownPayment())
                : ctx.getPrice();

        List<Goal> goals = goalRepository.findByUserIdOrderByDeadlineAsc(user.getId());
        List<GoalImpactDto> goalImpacts = goalImpactEngine.evaluate(
                goals, grossSurplus, surplusAfterPurchase, immediateOutflow, ctx.getCurrentEmergencyFund());

        response.setGoalImpacts(goalImpacts);
        return response;
    }
}
