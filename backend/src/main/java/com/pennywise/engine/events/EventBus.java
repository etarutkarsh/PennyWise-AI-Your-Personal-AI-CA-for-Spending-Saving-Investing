package com.pennywise.engine.events;

import com.pennywise.engine.events.domain.PennywiseEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Component;

/**
 * Central event bus for PennyWise. Publishes domain events through Spring's
 * ApplicationEventPublisher. Listeners use @TransactionalEventListener to
 * ensure events are only processed after the originating transaction commits.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class EventBus {

    private final ApplicationEventPublisher publisher;

    public void publish(PennywiseEvent event) {
        try {
            log.debug("Publishing event: type={} user={}", event.eventType(), event.getUserId());
            publisher.publishEvent(event);
        } catch (Exception e) {
            log.warn("Failed to publish event type={}: {}", event.eventType(), e.getMessage());
        }
    }
}
