package com.pennywise.service;

import com.pennywise.ai.AffordabilityEngine;
import com.pennywise.dto.AffordabilityRequest;
import com.pennywise.dto.AffordabilityResponse;
import com.pennywise.entity.Transaction;
import com.pennywise.entity.User;
import com.pennywise.repository.AssetRepository;
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
    private final AffordabilityEngine engine;

    public AffordabilityService(CurrentUserProvider currentUserProvider,
                                 TransactionRepository transactionRepository,
                                 AssetRepository assetRepository,
                                 AffordabilityEngine engine) {
        this.currentUserProvider = currentUserProvider;
        this.transactionRepository = transactionRepository;
        this.assetRepository = assetRepository;
        this.engine = engine;
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

        // Sum liquid assets (cash, savings, FDs, liquid funds) as the emergency fund balance
        BigDecimal currentEmergencyFund = assetRepository.findByUserIdOrderByCreatedAtDesc(user.getId())
                .stream()
                .filter(a -> LIQUID_ASSET_TYPES.contains(a.getAssetType()))
                .map(a -> a.getValue() != null ? a.getValue() : BigDecimal.ZERO)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        return engine.evaluate(request, monthlyIncome, avgMonthlyExpenses, currentEmergencyFund);
    }
}
