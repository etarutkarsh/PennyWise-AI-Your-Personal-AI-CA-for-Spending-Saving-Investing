package com.pennywise.domain.knowledge;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

/**
 * An entity node in the financial knowledge graph.
 *
 * System nodes (INSTRUMENT, REGULATOR) have a null userId.
 * All user-scoped nodes carry the owner's userId.
 *
 * {@code properties} is a typed JSONB blob — structure depends on {@code nodeType}.
 * Callers should use {@link #getProperty(String)} rather than raw map access.
 */
public record KnowledgeGraphNode(
        UUID id,
        UUID userId,          // null for system nodes
        NodeType nodeType,
        String entityId,      // domain-specific ID (e.g. goalId, "recurringDeposit")
        String label,
        Map<String, Object> properties,
        Instant createdAt,
        Instant updatedAt
) {
    public Object getProperty(String key) {
        return properties == null ? null : properties.get(key);
    }

    public String getStringProperty(String key) {
        Object v = getProperty(key);
        return v instanceof String s ? s : null;
    }

    public Double getDoubleProperty(String key) {
        Object v = getProperty(key);
        if (v instanceof Number n) return n.doubleValue();
        return null;
    }

    public Boolean getBooleanProperty(String key) {
        Object v = getProperty(key);
        return v instanceof Boolean b ? b : null;
    }

    public Integer getIntProperty(String key) {
        Object v = getProperty(key);
        if (v instanceof Number n) return n.intValue();
        return null;
    }
}
