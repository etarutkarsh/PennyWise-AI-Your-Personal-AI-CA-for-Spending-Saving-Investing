package com.pennywise.domain.knowledge;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

/**
 * A typed directional relationship between two knowledge graph nodes.
 *
 * {@code validUntil} is null for currently active edges.
 * Soft-deleting an edge sets validUntil = now() rather than hard-deleting.
 *
 * {@code weight} [0.0–1.0] encodes edge confidence or strength (e.g. 1.0 = certain,
 * 0.3 = inferred from partial data).
 */
public record KnowledgeGraphEdge(
        UUID id,
        UUID sourceNodeId,
        UUID targetNodeId,
        EdgeType edgeType,
        Map<String, Object> properties,
        double weight,
        Instant validFrom,
        Instant validUntil,   // null = currently active
        Instant createdAt
) {
    /** True if this edge has not been soft-deleted. */
    public boolean isActive() {
        return validUntil == null || validUntil.isAfter(Instant.now());
    }
}
