package com.pennywise.domain.knowledge;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Read/write contract for the financial knowledge graph.
 *
 * Write operations create nodes and edges. They are idempotent on the
 * (node_type, entity_id) unique key — callers should use upsert semantics.
 *
 * Read operations never mutate state. Traversal queries use recursive CTEs
 * in the PostgreSQL implementation (ADR-012).
 */
public interface KnowledgeGraphRepository {

    // ── Node operations ───────────────────────────────────────────────

    KnowledgeGraphNode upsertNode(KnowledgeGraphNode node);

    Optional<KnowledgeGraphNode> findNode(NodeType type, String entityId);

    List<KnowledgeGraphNode> findNodesByUser(UUID userId);

    List<KnowledgeGraphNode> findNodesByType(NodeType type);

    // ── Edge operations ───────────────────────────────────────────────

    KnowledgeGraphEdge createEdge(KnowledgeGraphEdge edge);

    /** Soft-delete: sets valid_until = now() on all active edges of this type
     *  between source and target. */
    void deactivateEdge(UUID sourceNodeId, UUID targetNodeId, EdgeType edgeType);

    List<KnowledgeGraphEdge> findEdgesFrom(UUID sourceNodeId, EdgeType edgeType);

    List<KnowledgeGraphEdge> findEdgesTo(UUID targetNodeId, EdgeType edgeType);

    // ── Graph traversal ───────────────────────────────────────────────

    /** Returns all nodes reachable from {@code startNodeId} within {@code maxDepth} hops,
     *  following active edges of any type. Implemented with recursive CTE. */
    List<KnowledgeGraphNode> traverse(UUID startNodeId, int maxDepth);

    /** Returns all nodes of {@code targetType} reachable from {@code startNodeId}
     *  within {@code maxDepth} hops via active edges. */
    List<KnowledgeGraphNode> traverseToType(UUID startNodeId, NodeType targetType, int maxDepth);

    // ── Instrument graph queries (for ProductKnowledgeGraph) ──────────

    /** Returns the INSTRUMENT node for the given instrument enum name, or empty. */
    Optional<KnowledgeGraphNode> findInstrument(String instrumentName);

    /** Returns all INSTRUMENT nodes whose suitableForDecisionTypes array contains the given type. */
    List<KnowledgeGraphNode> findInstrumentsForDecisionType(String decisionType);
}
