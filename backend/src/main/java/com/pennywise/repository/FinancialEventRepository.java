package com.pennywise.repository;

import com.pennywise.entity.FinancialEvent;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

public interface FinancialEventRepository extends JpaRepository<FinancialEvent, UUID> {

    List<FinancialEvent> findByUserId(UUID userId);

    List<FinancialEvent> findByUserIdOrderByOccurredAtDesc(UUID userId, Pageable pageable);

    List<FinancialEvent> findByUserIdAndEventTypeOrderByOccurredAtDesc(UUID userId, String eventType);

    @Query("SELECT e FROM FinancialEvent e WHERE e.userId = :userId AND e.occurredAt >= :since ORDER BY e.occurredAt DESC")
    List<FinancialEvent> findRecentByUserId(UUID userId, Instant since);

    @Query("SELECT e.eventType, COUNT(e) FROM FinancialEvent e WHERE e.userId = :userId GROUP BY e.eventType ORDER BY COUNT(e) DESC")
    List<Object[]> countByEventTypeForUser(UUID userId);

    long countByUserId(UUID userId);
}
