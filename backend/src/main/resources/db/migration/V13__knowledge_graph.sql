-- =====================================================================
-- V13 — Financial Knowledge Graph
-- =====================================================================
-- Implements the entity-relationship graph that backs the ProductKnowledgeGraph
-- and future intelligence engines (Behavioral, Decision, Twin).
--
-- ADR-012: PostgreSQL with typed entity/edge tables + recursive CTEs.
-- Neo4j is premature — migrate when query complexity justifies it.
--
-- Node types: USER ACCOUNT GOAL INCOME COMMITMENT MERCHANT SUBSCRIPTION
--             LOAN INSURANCE ASSET INSTRUMENT REGULATOR LIFE_EVENT
--
-- Edge types: OWNS FUNDS SERVICES SUBSCRIBED_TO COVERED_BY EARNS_FROM
--             TRANSACTS_WITH IMPACTS_GOAL DEPENDS_ON BELONGS_TO
--             OFFERED_BY REGULATED_BY SUITABLE_FOR TRIGGERED
-- =====================================================================

-- ── Nodes ────────────────────────────────────────────────────────────

CREATE TABLE kg_nodes (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID        REFERENCES users(id) ON DELETE CASCADE,  -- NULL for system nodes
    node_type   VARCHAR(32) NOT NULL,
    entity_id   VARCHAR(128) NOT NULL,   -- domain ID (goalId, merchantId, instrument name, etc.)
    label       VARCHAR(255),
    properties  JSONB       NOT NULL DEFAULT '{}',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_kg_node UNIQUE (node_type, entity_id)
);

CREATE INDEX idx_kg_nodes_user       ON kg_nodes(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX idx_kg_nodes_type       ON kg_nodes(node_type);
CREATE INDEX idx_kg_nodes_entity     ON kg_nodes(entity_id);
CREATE INDEX idx_kg_nodes_props      ON kg_nodes USING gin(properties);

-- ── Edges ────────────────────────────────────────────────────────────

CREATE TABLE kg_edges (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    source_node_id  UUID        NOT NULL REFERENCES kg_nodes(id) ON DELETE CASCADE,
    target_node_id  UUID        NOT NULL REFERENCES kg_nodes(id) ON DELETE CASCADE,
    edge_type       VARCHAR(64) NOT NULL,
    properties      JSONB       NOT NULL DEFAULT '{}',
    weight          NUMERIC(5,4) NOT NULL DEFAULT 1.0000,
    valid_from      TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_until     TIMESTAMPTZ,          -- NULL = currently active
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_kg_edge_weight CHECK (weight >= 0.0 AND weight <= 1.0),
    CONSTRAINT chk_kg_edge_no_self_loop CHECK (source_node_id <> target_node_id)
);

CREATE INDEX idx_kg_edges_source     ON kg_edges(source_node_id);
CREATE INDEX idx_kg_edges_target     ON kg_edges(target_node_id);
CREATE INDEX idx_kg_edges_type       ON kg_edges(edge_type);
CREATE INDEX idx_kg_edges_active     ON kg_edges(source_node_id, edge_type) WHERE valid_until IS NULL;
CREATE INDEX idx_kg_edges_props      ON kg_edges USING gin(properties);

-- ── Seed: Regulator nodes (system-level, no user_id) ─────────────────

INSERT INTO kg_nodes (node_type, entity_id, label, properties) VALUES
('REGULATOR', 'RBI',           'Reserve Bank of India',       '{"jurisdiction":"India","type":"banking_and_payment"}'::jsonb),
('REGULATOR', 'SEBI',          'Securities and Exchange Board of India', '{"jurisdiction":"India","type":"capital_markets"}'::jsonb),
('REGULATOR', 'IRDAI',         'Insurance Regulatory and Development Authority', '{"jurisdiction":"India","type":"insurance"}'::jsonb),
('REGULATOR', 'PFRDA',         'Pension Fund Regulatory and Development Authority', '{"jurisdiction":"India","type":"pension"}'::jsonb),
('REGULATOR', 'GOI',           'Government of India',         '{"jurisdiction":"India","type":"sovereign"}'::jsonb),
('REGULATOR', 'SELF_REGULATED','Self-Regulated Platform',     '{"jurisdiction":"India","type":"platform"}'::jsonb);

-- ── Seed: Instrument nodes (system-level, no user_id) ────────────────
-- Properties encode all facts the ProductKnowledgeGraph interface must answer:
--   riskLevel, liquidityScore, minHorizonMonths, capitalGuarantee, regulator,
--   returnType, lockInDays, suitableForDecisionTypes[], taxTreatment

INSERT INTO kg_nodes (node_type, entity_id, label, properties) VALUES
(
  'INSTRUMENT', 'recurringDeposit', 'Recurring Deposit',
  '{
    "riskLevel": "low",
    "liquidityScore": 0.60,
    "minHorizonMonths": 6,
    "capitalGuarantee": true,
    "regulator": "RBI",
    "returnType": "Guaranteed",
    "lockInDays": 0,
    "taxTreatment": "Interest taxable as income (TDS above ₹40,000/year)",
    "suitableForDecisionTypes": ["buildEmergencyFund", "increaseSavingsRate"]
  }'::jsonb
),
(
  'INSTRUMENT', 'liquidFund', 'Liquid Fund',
  '{
    "riskLevel": "low",
    "liquidityScore": 0.95,
    "minHorizonMonths": 1,
    "capitalGuarantee": false,
    "regulator": "SEBI",
    "returnType": "Market-linked",
    "lockInDays": 0,
    "taxTreatment": "STCG added to income slab; LTCG 20% with indexation after 3 years",
    "suitableForDecisionTypes": ["buildEmergencyFund", "increaseSavingsRate"]
  }'::jsonb
),
(
  'INSTRUMENT', 'indexFundSip', 'Index Fund SIP',
  '{
    "riskLevel": "medium",
    "liquidityScore": 0.85,
    "minHorizonMonths": 36,
    "capitalGuarantee": false,
    "regulator": "SEBI",
    "returnType": "Market-linked",
    "lockInDays": 0,
    "taxTreatment": "LTCG 10% after 12 months (above ₹1L per year)",
    "suitableForDecisionTypes": ["startGoalSip", "stepUpSip", "rebalancePortfolio"]
  }'::jsonb
),
(
  'INSTRUMENT', 'elssSip', 'ELSS SIP',
  '{
    "riskLevel": "high",
    "liquidityScore": 0.0,
    "minHorizonMonths": 36,
    "capitalGuarantee": false,
    "regulator": "SEBI",
    "returnType": "Market-linked",
    "lockInDays": 1095,
    "taxTreatment": "Exempt under Section 80C up to ₹1.5L; LTCG 10% after lock-in",
    "suitableForDecisionTypes": ["optimizeTax"]
  }'::jsonb
),
(
  'INSTRUMENT', 'digitalGold', 'Digital Gold',
  '{
    "riskLevel": "medium",
    "liquidityScore": 0.75,
    "minHorizonMonths": 12,
    "capitalGuarantee": false,
    "regulator": "SELF_REGULATED",
    "returnType": "Market-linked",
    "lockInDays": 0,
    "taxTreatment": "LTCG 20% with indexation after 36 months",
    "suitableForDecisionTypes": ["startGoalSip", "rebalancePortfolio"]
  }'::jsonb
),
(
  'INSTRUMENT', 'creditCardCashback', 'Credit Card (Cashback)',
  '{
    "riskLevel": "low",
    "liquidityScore": 1.0,
    "minHorizonMonths": 0,
    "capitalGuarantee": false,
    "regulator": "RBI",
    "returnType": "Guaranteed",
    "lockInDays": 0,
    "taxTreatment": "Cashback is non-taxable",
    "suitableForDecisionTypes": ["optimizeSubscription"]
  }'::jsonb
),
(
  'INSTRUMENT', 'ppf', 'Public Provident Fund (PPF)',
  '{
    "riskLevel": "low",
    "liquidityScore": 0.10,
    "minHorizonMonths": 180,
    "capitalGuarantee": true,
    "regulator": "GOI",
    "returnType": "Guaranteed",
    "lockInDays": 5475,
    "taxTreatment": "EEE — exempt at investment, accumulation, and withdrawal",
    "suitableForDecisionTypes": ["optimizeTax", "increaseSavingsRate"]
  }'::jsonb
),
(
  'INSTRUMENT', 'nps', 'National Pension System (NPS)',
  '{
    "riskLevel": "medium",
    "liquidityScore": 0.05,
    "minHorizonMonths": 240,
    "capitalGuarantee": false,
    "regulator": "PFRDA",
    "returnType": "Market-linked",
    "lockInDays": 0,
    "taxTreatment": "Additional ₹50,000 deduction u/s 80CCD(1B); 60% lump-sum tax-free at maturity",
    "suitableForDecisionTypes": ["optimizeTax", "rebalancePortfolio"]
  }'::jsonb
),
(
  'INSTRUMENT', 'termInsurance', 'Term Insurance',
  '{
    "riskLevel": "low",
    "liquidityScore": 0.0,
    "minHorizonMonths": 120,
    "capitalGuarantee": false,
    "regulator": "IRDAI",
    "returnType": "Protection",
    "lockInDays": 0,
    "taxTreatment": "Premium deductible u/s 80C up to ₹1.5L; death benefit tax-free u/s 10(10D)",
    "suitableForDecisionTypes": ["getInsurance"]
  }'::jsonb
),
(
  'INSTRUMENT', 'healthInsurance', 'Health Insurance',
  '{
    "riskLevel": "low",
    "liquidityScore": 0.0,
    "minHorizonMonths": 12,
    "capitalGuarantee": false,
    "regulator": "IRDAI",
    "returnType": "Protection",
    "lockInDays": 0,
    "taxTreatment": "Premium deductible u/s 80D — ₹25,000 self+family, ₹50,000 senior parents",
    "suitableForDecisionTypes": ["getInsurance"]
  }'::jsonb
);

-- ── Seed: REGULATED_BY edges (Instrument → Regulator) ────────────────

INSERT INTO kg_edges (source_node_id, target_node_id, edge_type)
SELECT
    i.id AS source_node_id,
    r.id AS target_node_id,
    'REGULATED_BY' AS edge_type
FROM kg_nodes i
JOIN kg_nodes r
  ON r.node_type = 'REGULATOR'
  AND r.entity_id = UPPER(i.properties->>'regulator')
WHERE i.node_type = 'INSTRUMENT';
