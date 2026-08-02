package com.pennywise.engine.twin;

import com.pennywise.entity.*;
import com.pennywise.exception.ResourceNotFoundException;
import com.pennywise.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Collects raw data from all repositories needed to assemble a FinancialDigitalTwin.
 */
@Component
@RequiredArgsConstructor
public class TwinAssembler {

    private final UserRepository userRepository;
    private final AssetRepository assetRepository;
    private final LiabilityRepository liabilityRepository;
    private final GoalRepository goalRepository;
    private final BehaviorProfileRepository behaviorProfileRepository;
    private final TransactionRepository transactionRepository;
    private final FinancialEventRepository financialEventRepository;
    private final DecisionMemoryRepository decisionMemoryRepository;

    /**
     * Fetches all raw data for a user to compute their Digital Twin.
     *
     * @param userId the authenticated user's UUID
     * @return a TwinData bundle containing all raw entities
     */
    public TwinData assemble(UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userId));

        List<Asset> assets = assetRepository.findByUserIdOrderByCreatedAtDesc(userId);
        List<Liability> liabilities = liabilityRepository.findByUserIdOrderByCreatedAtDesc(userId);
        List<Goal> goals = goalRepository.findByUserIdOrderByDeadlineAsc(userId);
        Optional<BehaviorProfile> behaviorProfile = behaviorProfileRepository.findByUserId(userId);

        // Last 90 days of transactions
        Instant ninetyDaysAgo = Instant.now().minus(90, ChronoUnit.DAYS);
        List<Transaction> recentTransactions =
                transactionRepository.findByUserIdAndTransactionDateBetween(userId, ninetyDaysAgo, Instant.now());

        long eventCount = financialEventRepository.countByUserId(userId);
        long decisionCount = decisionMemoryRepository.countByUserIdAndStatus(userId, "COMPLETED");

        return new TwinData(user, assets, liabilities, goals, behaviorProfile, recentTransactions, eventCount, decisionCount);
    }

    /**
     * Immutable bundle of all raw entities needed for twin computation.
     */
    public record TwinData(
            User user,
            List<Asset> assets,
            List<Liability> liabilities,
            List<Goal> goals,
            Optional<BehaviorProfile> behaviorProfile,
            List<Transaction> recentTransactions,
            long eventCount,
            long decisionCount
    ) {}
}
