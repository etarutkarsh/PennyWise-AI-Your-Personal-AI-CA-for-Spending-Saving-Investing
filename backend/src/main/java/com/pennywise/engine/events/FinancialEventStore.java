package com.pennywise.engine.events;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.pennywise.engine.events.domain.PennywiseEvent;
import com.pennywise.entity.FinancialEvent;
import com.pennywise.repository.FinancialEventRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionalEventListener;
import org.springframework.transaction.event.TransactionPhase;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Slf4j
@Component
@RequiredArgsConstructor
public class FinancialEventStore {

    private final FinancialEventRepository repository;
    private final ObjectMapper objectMapper;

    /**
     * Persists every domain event to the financial_events table.
     * Runs AFTER the originating transaction commits so no phantom events.
     * Async so it never blocks the main thread.
     */
    @Async
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void persist(PennywiseEvent event) {
        try {
            FinancialEvent entity = new FinancialEvent();
            entity.setUserId(event.getUserId());
            entity.setEventType(event.eventType());
            entity.setCorrelationId(event.getCorrelationId());
            entity.setSource(event.source());
            entity.setOccurredAt(event.getOccurredAt());
            entity.setPayload(objectMapper.writeValueAsString(event));
            entity.setProcessedAt(Instant.now());
            repository.save(entity);
            log.debug("Persisted event: type={} id={}", event.eventType(), entity.getId());
            // TODO (Sprint 3): publish async BehavioralRecomputeEvent here to trigger
            // BehavioralEngine.computeAndSave() after each event commit, keeping the
            // behavior profile near-real-time. Use ApplicationEventPublisher to avoid
            // circular dependency with BehavioralEngine.
        } catch (Exception e) {
            log.warn("Failed to persist event type={}: {}", event.eventType(), e.getMessage());
        }
    }

    public List<FinancialEvent> recentEvents(UUID userId, int limit) {
        return repository.findByUserIdOrderByOccurredAtDesc(userId, PageRequest.of(0, limit));
    }

    public List<FinancialEvent> eventsByType(UUID userId, String eventType) {
        return repository.findByUserIdAndEventTypeOrderByOccurredAtDesc(userId, eventType);
    }

    public long totalEvents(UUID userId) {
        return repository.countByUserId(userId);
    }
}
