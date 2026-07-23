package com.pennywise.service;

import com.pennywise.ai.AffordabilityEngine;
import com.pennywise.dto.AffordabilityRequest;
import com.pennywise.dto.AffordabilityResponse;
import com.pennywise.entity.Transaction;
import com.pennywise.entity.User;
import com.pennywise.repository.TransactionRepository;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;

@Service
public class AffordabilityService {

    private static final int TRAILING_MONTHS_FOR_AVERAGE = 3;

    private final CurrentUserProvider currentUserProvider;
    private final TransactionRepository transactionRepository;
    private final AffordabilityEngine engine;

    public AffordabilityService(CurrentUserProvider currentUserProvider,
                                 TransactionRepository transactionRepository,
                                 AffordabilityEngine engine) {
        this.currentUserProvider = currentUserProvider;
        this.transactionRepository = transactionRepository;
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

        // TODO(Phase 3/4): replace with the user's real emergency-fund balance from
        // the InvestmentPortfolio/Assets tables once those are implemented. Approximated
        // here as 6 months of expenses minus zero, i.e. treated as unfunded until then.
        BigDecimal currentEmergencyFund = BigDecimal.ZERO;

        return engine.evaluate(request, monthlyIncome, avgMonthlyExpenses, currentEmergencyFund);
    }
}
