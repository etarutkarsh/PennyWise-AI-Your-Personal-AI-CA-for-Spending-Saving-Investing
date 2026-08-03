package com.pennywise.domain.knowledge;

/**
 * Typed relationship between two knowledge graph nodes.
 *
 * Directionality: source → target (e.g. USER → ACCOUNT for OWNS).
 * See ADR-012 and the formal DDD specification for the full relationship matrix.
 */
public enum EdgeType {
    /** UserNode → AccountNode, AssetNode, InstrumentNode */
    OWNS,
    /** AccountNode → GoalNode */
    FUNDS,
    /** AccountNode → LoanNode */
    SERVICES,
    /** UserNode → SubscriptionNode */
    SUBSCRIBED_TO,
    /** UserNode → InsuranceNode */
    COVERED_BY,
    /** UserNode → IncomeNode */
    EARNS_FROM,
    /** UserNode → MerchantNode */
    TRANSACTS_WITH,
    /** CommitmentNode → GoalNode (positive or negative impact) */
    IMPACTS_GOAL,
    /** UserNode → UserNode (family dependency graph) */
    DEPENDS_ON,
    /** SubscriptionNode → MerchantNode */
    BELONGS_TO,
    /** InstrumentNode → PartnerNode */
    OFFERED_BY,
    /** InstrumentNode → RegulatorNode, PartnerNode → RegulatorNode */
    REGULATED_BY,
    /** InstrumentNode → GoalNode by GoalCategory */
    SUITABLE_FOR,
    /** LifeEventNode → GoalNode, UserNode */
    TRIGGERED
}
