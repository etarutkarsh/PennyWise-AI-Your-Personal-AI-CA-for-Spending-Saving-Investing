-- =====================================================================
-- V14 — Knowledge Graph Snapshots
-- =====================================================================
-- Enables temporal graph queries: "What did the user's financial world
-- look like on 2026-08-03?" The Digital Twin (Phase 7+) replays snapshots
-- for counterfactual analysis and behavioral calibration.
--
-- A snapshot captures the state of all user-scoped kg_nodes at a point
-- in time. Immutable once created (append-only per event store rules).
-- =====================================================================

CREATE TABLE kg_snapshots (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    triggered_by    VARCHAR(64) NOT NULL,   -- HEALTH_SCORE_COMPUTED | TRANSACTION_INGESTED | GOAL_UPDATED | MANUAL
    snapshot_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    node_count      INT         NOT NULL DEFAULT 0,
    edge_count      INT         NOT NULL DEFAULT 0,
    health_score    INT,                    -- composite health score at time of snapshot (null if not computed)
    financial_state VARCHAR(16),            -- SURVIVE | STABILIZE | BUILD | OPTIMIZE
    properties      JSONB       NOT NULL DEFAULT '{}'  -- summary metadata (e.g. { "changedNodes": [...] })
);

CREATE INDEX idx_kg_snapshots_user     ON kg_snapshots(user_id);
CREATE INDEX idx_kg_snapshots_time     ON kg_snapshots(user_id, snapshot_at DESC);

-- Point-in-time node state within a snapshot.
-- Records the exact properties of each user node when the snapshot was taken.

CREATE TABLE kg_snapshot_nodes (
    snapshot_id UUID        NOT NULL REFERENCES kg_snapshots(id) ON DELETE CASCADE,
    node_id     UUID        NOT NULL REFERENCES kg_nodes(id) ON DELETE CASCADE,
    node_type   VARCHAR(32) NOT NULL,
    entity_id   VARCHAR(128) NOT NULL,
    properties  JSONB       NOT NULL DEFAULT '{}',
    PRIMARY KEY (snapshot_id, node_id)
);

CREATE INDEX idx_kg_snapshot_nodes_snap ON kg_snapshot_nodes(snapshot_id);
CREATE INDEX idx_kg_snapshot_nodes_node ON kg_snapshot_nodes(node_id);
