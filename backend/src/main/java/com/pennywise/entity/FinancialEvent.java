package com.pennywise.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.Instant;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor
@Entity @Table(name = "financial_events")
public class FinancialEvent {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false)
    private UUID userId;

    @Column(nullable = false)
    private String eventType;

    @Column(columnDefinition = "text")
    private String payload; // JSON

    private UUID correlationId; // links related events (e.g. goal completed + decision recorded)

    private String source; // which service emitted this

    @Column(nullable = false, updatable = false)
    private Instant occurredAt = Instant.now();

    private Instant processedAt; // set by EventStore after listeners finish
}
