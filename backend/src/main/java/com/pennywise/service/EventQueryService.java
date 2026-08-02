package com.pennywise.service;

import com.pennywise.engine.events.FinancialEventStore;
import com.pennywise.entity.FinancialEvent;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class EventQueryService {

    private final CurrentUserProvider currentUserProvider;
    private final FinancialEventStore eventStore;

    public List<FinancialEvent> recentEvents(int limit) {
        return eventStore.recentEvents(currentUserProvider.get().getId(), limit);
    }

    public List<FinancialEvent> eventsByType(String eventType) {
        return eventStore.eventsByType(currentUserProvider.get().getId(), eventType);
    }

    public long totalEvents() {
        return eventStore.totalEvents(currentUserProvider.get().getId());
    }
}
