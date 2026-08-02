package com.pennywise.repository;

import com.pennywise.entity.DecisionMemory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public interface DecisionMemoryRepository extends JpaRepository<DecisionMemory, UUID> {
    List<DecisionMemory> findByUserIdOrderByCreatedAtDesc(UUID userId);
    List<DecisionMemory> findByUserIdAndStatus(UUID userId, String status);

    @Query("SELECT d FROM DecisionMemory d WHERE d.userId = :userId AND d.reviewAfter <= :date AND d.status = 'PENDING_REVIEW' ORDER BY d.reviewAfter ASC")
    List<DecisionMemory> findPendingReviews(UUID userId, LocalDate date);

    long countByUserIdAndStatus(UUID userId, String status);

    @Query("SELECT AVG(o.accuracyScore) FROM DecisionOutcome o WHERE o.decisionId IN (SELECT d.id FROM DecisionMemory d WHERE d.userId = :userId)")
    Double avgAccuracyByUserId(UUID userId);
}
